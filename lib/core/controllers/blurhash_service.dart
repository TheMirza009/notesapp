// lib/core/controllers/blurhash_service.dart
import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:blurhash_dart/blurhash_dart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:notesapp/core/controllers/isar_database.dart';
import 'package:notesapp/root/data/models/media_model.dart';

class BlurHashService {
  static const int defaultComponentX = 4;
  static const int defaultComponentY = 3;
  static const int cacheWidth = 32; // Small for performance
  
  // ✅ In-memory cache (hash → decoded PNG bytes)
  static final Map<String, Uint8List> _memoryCache = {};
  
  // ✅ Persistent cache (hash → base64 encoded PNG)
  static SharedPreferences? _prefs;
  static const String _cachePrefix = 'blur_';
  static const int _maxCacheSize = 100; // Limit cache size

  /// Initialize persistent cache
  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// ✅ Get decoded blur from memory or persistent cache
  static Future<Uint8List?> getDecoded(String hash) async {
    // Check memory first
    if (_memoryCache.containsKey(hash)) {
      return _memoryCache[hash];
    }

    // Check persistent cache
    await init();
    final cached = _prefs?.getString('$_cachePrefix$hash');
    if (cached != null) {
      try {
        final bytes = base64Decode(cached);
        _memoryCache[hash] = bytes; // Store in memory too
        return bytes;
      } catch (e) {
        debugPrint('⚠️ Failed to decode cached blur: $e');
      }
    }

    return null;
  }

  /// ✅ Cache decoded blur (memory + persistent)
  static Future<void> cacheDecoded(String hash, Uint8List bytes) async {
    _memoryCache[hash] = bytes;

    // Persist to disk (async, non-blocking)
    unawaited(_persistCacheAsync(hash, bytes));
  }

  static Future<void> _persistCacheAsync(String hash, Uint8List bytes) async {
    try {
      await init();
      
      // Limit cache size
      final keys = _prefs?.getKeys().where((k) => k.startsWith(_cachePrefix)).toList() ?? [];
      if (keys.length >= _maxCacheSize) {
        // Remove oldest
        _prefs?.remove(keys.first);
      }

      await _prefs?.setString('$_cachePrefix$hash', base64Encode(bytes));
    } catch (e) {
      debugPrint('⚠️ Failed to persist blur cache: $e');
    }
  }

  /// ✅ Decode blurhash (checks cache first)
  static Future<Uint8List?> decodeBlurHash(String hash, double aspectRatio) async {
    try {
      // Check cache first
      final cached = await getDecoded(hash);
      if (cached != null) return cached;

      // Decode in isolate for performance
      final result = await compute(_decodeInIsolate, {
        'hash': hash,
        'aspectRatio': aspectRatio,
      });

      if (result != null) {
        await cacheDecoded(hash, result);
      }

      return result;
    } catch (e) {
      debugPrint('⚠️ BlurHash decode failed: $e');
      return null;
    }
  }

  /// ✅ Pre-decode multiple hashes in parallel (CRITICAL for performance)
  static Future<void> batchDecode(List<MapEntry<String, double>> hashesWithRatios) async {
    if (hashesWithRatios.isEmpty) return;

    try {
      // Decode all in parallel
      await Future.wait(
        hashesWithRatios.map((entry) => decodeBlurHash(entry.key, entry.value)),
        eagerError: false,
      );
    } catch (e) {
      debugPrint('⚠️ Batch decode error: $e');
    }
  }

  /// ✅ Isolate decoder
  static Future<Uint8List?> _decodeInIsolate(Map<String, dynamic> args) async {
    try {
      final hash = args['hash'] as String;
      final aspectRatio = args['aspectRatio'] as double;

      final height = max(1, (cacheWidth / aspectRatio).round());

      final blurHashObj = BlurHash.decode(hash);
      final imageBytes = blurHashObj.toImage(cacheWidth, height);
      final pngBytes = Uint8List.fromList(img.encodePng(imageBytes));

      return pngBytes;
    } catch (e) {
      debugPrint('⚠️ Isolate decode error: $e');
      return null;
    }
  }

  /// ✅ Generate blurhash (unchanged but optimized)
  static Future<String?> generateBlurHash(String imagePath) async {
    try {
      final token = ServicesBinding.rootIsolateToken;
      return await compute(_encodeInIsolate, {
        'path': imagePath,
        'token': token,
      });
    } catch (e) {
      debugPrint('❌ Blurhash generation error: $e');
      return null;
    }
  }

  /// ✅ Generate during image pick (BEFORE save)
  static Future<String?> generateFromBytes(Uint8List bytes) async {
    try {
      return await compute(_encodeFromBytesInIsolate, bytes);
    } catch (e) {
      debugPrint('❌ Blurhash from bytes error: $e');
      return null;
    }
  }

  static Future<String?> _encodeFromBytesInIsolate(Uint8List bytes) async {
    try {
      final image = img.decodeImage(bytes);
      if (image == null) return null;

      final blurHash = BlurHash.encode(
        image,
        numCompX: defaultComponentX,
        numCompY: defaultComponentY,
      );
      return blurHash.hash;
    } catch (e) {
      debugPrint('❌ Encode from bytes error: $e');
      return null;
    }
  }

  static Future<String?> _encodeInIsolate(Map<String, dynamic> args) async {
    try {
      final path = args['path'] as String;
      final token = args['token'] as RootIsolateToken?;

      if (token != null) {
        BackgroundIsolateBinaryMessenger.ensureInitialized(token);
      }

      final bytes = await File(path).readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) return null;

      final blurHash = BlurHash.encode(
        image,
        numCompX: defaultComponentX,
        numCompY: defaultComponentY,
      );
      return blurHash.hash;
    } catch (e) {
      debugPrint('❌ Encode error: $e');
      return null;
    }
  }

  /// ✅ Generate and persist (for existing images without blur)
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

      return blurHash;
    } catch (e) {
      debugPrint('❌ Generate/persist error: $e');
      return null;
    }
  }

  /// Clear cache
  static Future<void> clearCache() async {
    _memoryCache.clear();
    await init();
    final keys = _prefs?.getKeys().where((k) => k.startsWith(_cachePrefix)).toList() ?? [];
    for (final key in keys) {
      await _prefs?.remove(key);
    }
  }
}