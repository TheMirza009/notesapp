// lib/core/controllers/blurhash_service.dart
import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img; // ✅ pure Dart image lib
import 'package:blurhash_dart/blurhash_dart.dart';
import 'package:notesapp/core/controllers/isar_database.dart';
import 'package:notesapp/root/data/models/media_model.dart';

class BlurHashService {
  static const int defaultComponentX = 4;
  static const int defaultComponentY = 3;

  // 🔹 In-memory cache (blurHash → decoded bytes)
  static final Map<String, Uint8List> _decodedCache = {};

  static Uint8List? getCached(String hash) => _decodedCache[hash];

  static void cacheDecoded(String hash, Uint8List bytes) {
    _decodedCache[hash] = bytes;
  }

  
  /// Decode a blurhash and cache result
  static Future<Uint8List?> decodeBlurHash(String hash, double aspectRatio) async {
    try {
      // ✅ Return cached result if available
      if (_decodedCache.containsKey(hash)) return _decodedCache[hash];

      const width = 32;
      final height = max(1, (width / aspectRatio).round());

      final blurHashObj = BlurHash.decode(hash);
      final imageBytes = blurHashObj.toImage(width, height);
      final pngBytes = Uint8List.fromList(img.encodePng(imageBytes));
      // ✅ Store in cache
      cacheDecoded(hash, pngBytes);
      return pngBytes;
    } catch (e) {
      debugPrint('⚠️ BlurHash decode failed: $e');
      return null;
    }
  }

  /// Pre-decode a blurhash in background (non-blocking)
  static Future<void> warmup(String? hash, double aspectRatio) async {
    if (hash == null || _decodedCache.containsKey(hash)) return;
    unawaited(decodeBlurHash(hash, aspectRatio));
  }

  static Future<String?> generateBlurHash(String imagePath) async {
    try {
      final token = ServicesBinding.rootIsolateToken;
      return await compute(_encodeInIsolate, {
        'path': imagePath,
        'token': token,
      });
    } catch (e) {
      debugPrint('❌ Blurhash isolate error: $e');
      return null;
    }
  }

  static Future<String?> generateAndPersist(Media media) async {
    try {
      final path = media.path;
      if (path == null) return null;

      final blurHash = await generateBlurHash(path);
      if (blurHash == null) return null;

      // Persist to Isar
      final isar = IsarDatabase.isar;
      await isar.writeTxn(() async {
        media.blurHash = blurHash;
        await isar.medias.put(media);
      });

      debugPrint(
        '✅ BlurHash generated and stored: ${blurHash.substring(0, 20)}...',
      );
      return blurHash;
    } catch (e) {
      debugPrint('❌ Error generating/persisting blurHash: $e');
      return null;
    }
  }
}

Future<String?> _encodeInIsolate(Map<String, dynamic> args) async {
    try {
      final path = args['path'] as String;
      final token = args['token'] as RootIsolateToken?;

      if (token != null) {
        BackgroundIsolateBinaryMessenger.ensureInitialized(token);
      }

      final bytes = await File(path).readAsBytes();

      // ✅ Decode the image using the pure Dart package
      final image = img.decodeImage(bytes);
      if (image == null) return null;

      // ✅ Encode using blurhash_dart
      final blurHash = BlurHash.encode(
        image,
        numCompX: BlurHashService.defaultComponentX,
        numCompY: BlurHashService.defaultComponentY,
      );
      return blurHash.hash;
    } catch (e) {
      debugPrint('❌ Error in isolate encoding: $e');
      return null;
    }
  }
