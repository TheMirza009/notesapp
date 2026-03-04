import 'dart:convert';
import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:crypto/crypto.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:isar_community/isar.dart';
import 'package:notesapp/core/controllers/isar_database.dart';
import 'package:notesapp/main.dart';
import 'package:notesapp/root/data/models/chat_model.dart';
import 'package:notesapp/root/data/models/media_model.dart';
import 'package:notesapp/root/data/models/message_model.dart';
import 'package:notesapp/root/data/models/settings_model.dart';
import 'package:notesapp/root/data/models/user_model.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

// ─── Backup Exceptions ────────────────────────────────────────────────────────

class BackupException implements Exception {
  final String message;
  final Object? cause;
  const BackupException(this.message, [this.cause]);

  @override
  String toString() =>
      'BackupException: $message${cause != null ? ' ($cause)' : ''}';
}

class InvalidBackupException extends BackupException {
  const InvalidBackupException(super.message, [super.cause]);
}

class BackupCancelledException extends BackupException {
  const BackupCancelledException() : super('Operation cancelled by user');
}

// ─── Backup Manifest ──────────────────────────────────────────────────────────
// JSON validity marker embedded in the archive root.
// Small enough that JSON overhead is irrelevant (~200 bytes).
// Human-readable — lets you inspect a backup in any text editor.

class BackupManifest {
  static const int currentSchemaVersion = 1;
  static const String fileName = 'BACKUP_MANIFEST.json';

  final int formatVersion;
  final int schemaVersion;
  final String backupTimestamp;
  final int chatCount;
  final int messageCount;
  final int mediaFileCount;
  final String contentHash; // SHA-256 of raw DB bytes at export time

  const BackupManifest({
    required this.formatVersion,
    required this.schemaVersion,
    required this.backupTimestamp,
    required this.chatCount,
    required this.messageCount,
    required this.mediaFileCount,
    required this.contentHash,
  });

  Map<String, dynamic> toJson() => {
        'formatVersion': formatVersion,
        'schemaVersion': schemaVersion,
        'backupTimestamp': backupTimestamp,
        'chatCount': chatCount,
        'messageCount': messageCount,
        'mediaFileCount': mediaFileCount,
        'contentHash': contentHash,
      };

  factory BackupManifest.fromJson(Map<String, dynamic> json) => BackupManifest(
        formatVersion: json['formatVersion'] as int,
        schemaVersion: json['schemaVersion'] as int,
        backupTimestamp: json['backupTimestamp'] as String,
        chatCount: json['chatCount'] as int,
        messageCount: json['messageCount'] as int,
        mediaFileCount: json['mediaFileCount'] as int,
        contentHash: json['contentHash'] as String,
      );

  void validate() {
    if (formatVersion < 1) {
      throw const InvalidBackupException('Unsupported backup format version');
    }
    if (schemaVersion > currentSchemaVersion) {
      throw InvalidBackupException(
        'Backup was created with a newer app version (schema v$schemaVersion). '
        'Please update the app to restore this backup.',
      );
    }
    if (backupTimestamp.isEmpty || contentHash.isEmpty) {
      throw const InvalidBackupException(
          'Backup manifest is incomplete or corrupted');
    }
  }
}

// ─── Progress Types ───────────────────────────────────────────────────────────
// Public callback carries both progress + status text.
// Internal callback carries only progress — the caller sets the status string.

typedef ProgressCallback = void Function(double progress, String status);
typedef _InternalProgress = void Function(double progress);

// ─── BackupService ────────────────────────────────────────────────────────────

class BackupService {
  BackupService._(); // static-only — never instantiate

  static const _backupExtension = 'notesbackup';
  static const _dbFileName = 'isar.db';
  static const _mediaFolder = 'Media';
  static const _internalBackupFolder = 'Backups';


  // ─── EXPORT ─────────────────────────────────────────────────────────────────

  static Future<String?> exportBackup({
    required ProgressCallback onProgress,
  }) async {
    String? archivePath;

    try {
      // ── Step 1: Prepare staging dir ─────────────────────────────────────────
      onProgress(0.05, 'Preparing backup...');
      final appDir = await getApplicationDocumentsDirectory();
      final backupDir = Directory('${appDir.path}/$_internalBackupFolder');
      if (!await backupDir.exists()) await backupDir.create(recursive: true);

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      archivePath = '${backupDir.path}/notes_backup_$timestamp.$_backupExtension';

      // ── Step 2: Read DB ──────────────────────────────────────────────────────
      onProgress(0.1, 'Reading database...');
      final dbPath = await _getDbPath();
      final dbFile = File(dbPath);
      if (!await dbFile.exists()) {
        throw const BackupException('Database file not found');
      }

      // ── Step 3: Compute hash ─────────────────────────────────────────────────
      onProgress(0.15, 'Computing integrity hash...');
      final dbBytes = await dbFile.readAsBytes();
      final contentHash = sha256.convert(dbBytes).toString();

      // ── Step 4: Collect media ────────────────────────────────────────────────
      onProgress(0.2, 'Scanning media files...');
      final mediaDir = Directory('${appDir.path}/$_mediaFolder');
      final mediaFiles = await _collectMediaFiles(mediaDir);

      // ── Step 5: Build manifest ───────────────────────────────────────────────
      onProgress(0.25, 'Building manifest...');
      final chatCount = await IsarDatabase.isar.chats.count();
      final messageCount = await IsarDatabase.isar.messages.count();
      final manifest = BackupManifest(
        formatVersion: 1,
        schemaVersion: BackupManifest.currentSchemaVersion,
        backupTimestamp: DateTime.now().toIso8601String(),
        chatCount: chatCount,
        messageCount: messageCount,
        mediaFileCount: mediaFiles.length,
        contentHash: contentHash,
      );

      // ── Step 6: Create zip ───────────────────────────────────────────────────
      onProgress(0.3, 'Creating archive...');
      await _createArchive(
        outputPath: archivePath,
        dbFile: dbFile,
        mediaFiles: mediaFiles,
        mediaBaseDir: appDir,
        manifest: manifest,
        onProgress: (p) => onProgress(0.3 + (p * 0.6), 'Archiving files...'),
      );

      // ── Step 7: Verify ───────────────────────────────────────────────────────
      onProgress(0.92, 'Verifying integrity...');
      await _verifyArchiveIntegrity(
        archivePath: archivePath,
        expectedHash: contentHash,
        expectedSize: await File(archivePath).length(),
      );

      // ── Step 8: Share via system sheet ───────────────────────────────────────
      // SharePlus returns a result — dismissed means user cancelled without saving.
      // In that case clean up the archive so it doesn't accumulate in app storage.
      onProgress(0.97, 'Opening share sheet...');
      final shareResult = await SharePlus.instance.share(
        ShareParams(
          files: [XFile(archivePath)],
          subject: 'NotesApp Backup',
          text: 'notes_backup_$timestamp.$_backupExtension',
        ),
      );

      if (shareResult.status == ShareResultStatus.dismissed) {
        await _safeDelete(archivePath);
        throw const BackupCancelledException();
      }

      onProgress(1.0, 'Backup complete!');
      debugPrint('✅ Backup shared from $archivePath');
      return archivePath;
    } on BackupCancelledException {
      await _safeDelete(archivePath);
      rethrow;
    } catch (e) {
      await _safeDelete(archivePath);
      debugPrint('❌ Export failed: $e');
      if (e is BackupException) rethrow;
      throw BackupException('Export failed unexpectedly', e);
    }
  }

  // ─── IMPORT ─────────────────────────────────────────────────────────────────

  static Future<void> importBackup({
    required ProgressCallback onProgress,
  }) async {
    String? extractDir;

    try {
      // ── Step 1: Pick file ────────────────────────────────────────────────────
      onProgress(0.0, 'Selecting backup file...');
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [_backupExtension],
        dialogTitle: 'Select a NotesApp backup',
      );
      if (result == null || result.files.single.path == null) {
        throw const BackupCancelledException();
      }
      final backupPath = result.files.single.path!;

      // ── Step 2: Validate manifest without full extraction ────────────────────
      onProgress(0.05, 'Validating backup...');
      final manifest = await _readManifestFast(backupPath);
      manifest.validate();
      debugPrint(
        '📦 Importing backup from ${manifest.backupTimestamp} '
        '(${manifest.chatCount} chats, ${manifest.messageCount} messages)',
      );

      // ── Step 3: Extract to temp dir ──────────────────────────────────────────
      onProgress(0.1, 'Extracting archive...');
      final tempDir = await getTemporaryDirectory();
      extractDir =
          '${tempDir.path}/notesapp_import_${DateTime.now().millisecondsSinceEpoch}';
      await Directory(extractDir).create(recursive: true);

      await _extractArchive(
        archivePath: backupPath,
        targetDir: extractDir,
        onProgress: (p) => onProgress(0.1 + (p * 0.3), 'Extracting...'),
      );

      // ── Step 4: Verify hash on extractedRawDB BEFORE rename ─────────────────
      onProgress(0.4, 'Verifying data integrity...');
      final extractedRawDB = File('$extractDir/$_dbFileName'); // looks for isar.db
      
      if (!await extractedRawDB.exists()) {
        throw const InvalidBackupException('Backup is missing the database file');
      }
      
      final actualHash = sha256.convert(await extractedRawDB.readAsBytes()).toString();
      if (actualHash != manifest.contentHash) {
        throw const InvalidBackupException(
          'Integrity check failed — backup file may be corrupted',
        );
      }

      // ── Step 4b: Rename so Isar can open it (Use a UNIQUE name) ─────────────
      // We use 'imported_repo' to prevent clashing with your main 'chat_repo'
      final renamedDbRepo = File('$extractDir/imported_repo.isar');
      await extractedRawDB.rename(renamedDbRepo.path);
      debugPrint('🗄️ Renamed isar.db → imported_repo.isar at ${renamedDbRepo.path}');

      // ── Step 5: Open with matching unique name ──────────────────────────────
      onProgress(0.45, 'Reading backup data...');
      final importedIsar = await Isar.open(
        [ChatSchema, MessageSchema, MediaSchema, UserSchema, SettingsSchema],
        directory: extractDir,
        name: 'imported_repo', // MUST match the filename above
      );

      try {
        // ── Step 6: Upsert chats + messages ──────────────────────────────────
        onProgress(0.5, 'Importing chats...');
        await _upsertChats(
          source: importedIsar,
          onProgress: (p) => onProgress(0.5 + (p * 0.3), 'Importing chats...'),
        );

        // ── Step 7: Restore media files ───────────────────────────────────────
        onProgress(0.8, 'Restoring media...');
        final appDir = await getApplicationDocumentsDirectory();
        await _restoreMediaFiles(
          extractDir: extractDir,
          appDir: appDir,
          onProgress: (p) =>
              onProgress(0.8 + (p * 0.15), 'Restoring media...'),
        );
      } finally {
        await importedIsar.close();
      }

      // ── Step 8: Clean up ─────────────────────────────────────────────────────
      onProgress(0.95, 'Cleaning up...');
      await _safeDeleteDir(extractDir);
      extractDir = null;

      onProgress(1.0, 'Import complete!');
      debugPrint('✅ Backup imported successfully');
    } on BackupCancelledException {
      await _safeDeleteDir(extractDir);
      rethrow;
    } catch (e) {
      await _safeDeleteDir(extractDir);
      debugPrint('❌ Import failed: $e');
      if (e is BackupException) rethrow;
      throw BackupException('Import failed unexpectedly', e);
    }
  }

  // ─── Archive Creation ────────────────────────────────────────────────────────

  static Future<void> _createArchive({
    required String outputPath,
    required File dbFile,
    required List<File> mediaFiles,
    required Directory mediaBaseDir,
    required BackupManifest manifest,
    required _InternalProgress onProgress,
  }) async {
    final encoder = ZipFileEncoder();
    encoder.create(outputPath);

    try {
      // Manifest — validity marker, stored uncompressed for fast reads
      final manifestBytes = utf8.encode(jsonEncode(manifest.toJson()));
      encoder.addArchiveFile(
        ArchiveFile.noCompress(
          BackupManifest.fileName,
          manifestBytes.length,
          manifestBytes,
        ),
      );

      // Raw Isar DB — already binary, compression adds overhead with little gain
      await encoder.addFile(dbFile, _dbFileName);

      // Media files — preserve relative paths
      final total = mediaFiles.length;
      for (int i = 0; i < total; i++) {
        final file = mediaFiles[i];
        final relativePath = file.path
            .replaceFirst(
              '${mediaBaseDir.path}${Platform.pathSeparator}',
              '',
            )
            .replaceAll(Platform.pathSeparator, '/');
        await encoder.addFile(file, relativePath);
        onProgress(total == 0 ? 1.0 : (i + 1) / total);
      }
    } finally {
      encoder.close();
    }
  }

  // ─── Archive Extraction ───────────────────────────────────────────────────────

  static Future<void> _extractArchive({
    required String archivePath,
    required String targetDir,
    required _InternalProgress onProgress,
  }) async {
    final bytes = await File(archivePath).readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);
    final files = archive.files.where((f) => f.isFile).toList();
    final total = files.length;

    for (int i = 0; i < total; i++) {
      final file = files[i];
      final targetFile = File('$targetDir/${file.name}');
      await targetFile.parent.create(recursive: true);
      await targetFile.writeAsBytes(file.content as List<int>);
      onProgress(total == 0 ? 1.0 : (i + 1) / total);
    }
  }

  // ─── Fast Manifest Read ───────────────────────────────────────────────────────
  // Decodes the archive and reads only the manifest entry.
  // Does not extract any other files.

  static Future<BackupManifest> _readManifestFast(String archivePath) async {
    try {
      final bytes = await File(archivePath).readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);
      final manifestFile = archive.findFile(BackupManifest.fileName);

      if (manifestFile == null) {
        throw const InvalidBackupException(
          'Not a valid NotesApp backup — missing manifest',
        );
      }

      final content = utf8.decode(manifestFile.content as List<int>);
      final decoded = jsonDecode(content) as Map<String, dynamic>;
      return BackupManifest.fromJson(decoded);
    } on BackupException {
      rethrow;
    } catch (e) {
      throw InvalidBackupException('Could not read backup manifest', e);
    }
  }

  // ─── Upsert ───────────────────────────────────────────────────────────────────
  // Chat.uuid and Message.id are UUID v7 — cross-device identity.
  // Never use isarID / isarId for deduplication — it is autoIncrement
  // and will collide between devices.
static Future<void> _upsertChats({
    required Isar source,
    required _InternalProgress onProgress,
  }) async {
    final target = IsarDatabase.isar;
    final sourceChats = await source.chats.where().findAll();
    
    debugPrint('📦 Source has ${sourceChats.length} chats to import');
    
    if (sourceChats.isEmpty) {
      debugPrint('⚠️ No chats found in backup — DB may be empty or path mismatch');
      return;
    }

    final total = sourceChats.length;

    for (int i = 0; i < total; i++) {
      final sourceChat = sourceChats[i];
      
      // 1. LOAD EVERYTHING FROM SOURCE FIRST (Outside the target transaction)
      await sourceChat.messages.load();
      final sourceMessages = sourceChat.messages.toList();
      
      // Pre-load media for all messages to avoid lazy-loading inside the txn
      for (final msg in sourceMessages) {
        await msg.media.load();
      }

      debugPrint('💬 Chat ${sourceChat.uuid}: ${sourceMessages.length} messages');

      // 2. NOW START THE TARGET TRANSACTION
      await target.writeTxn(() async {
        final existing = await target.chats
            .where()
            .uuidEqualTo(sourceChat.uuid)
            .findFirst();

        late Chat targetChat;

        if (existing == null) {
          targetChat = Chat()
            ..uuid = sourceChat.uuid
            ..title = sourceChat.title
            ..preview = sourceChat.preview
            ..date = sourceChat.date
            ..isPinned = sourceChat.isPinned
            ..chatPhotoPath = sourceChat.chatPhotoPath
            ..bubbleStyle = sourceChat.bubbleStyle;
          await target.chats.put(targetChat);
          debugPrint('✅ Inserted new chat: ${targetChat.uuid}');
        } else {
          // Update if source is newer
          if (sourceChat.date.isAfter(existing.date)) {
            existing
              ..title = sourceChat.title
              ..preview = sourceChat.preview
              ..date = sourceChat.date
              ..isPinned = sourceChat.isPinned
              ..chatPhotoPath = sourceChat.chatPhotoPath
              ..bubbleStyle = sourceChat.bubbleStyle;
            await target.chats.put(existing);
            targetChat = existing;
          } else {
            targetChat = existing;
          }
        }

        await targetChat.messages.load();

        for (final sourceMsg in sourceMessages) {
          final exists = await target.messages
              .filter()
              .idEqualTo(sourceMsg.id)
              .findFirst();
          
          if (exists != null) continue;

          final newMsg = Message()
            ..id = sourceMsg.id
            ..text = sourceMsg.text
            ..time = sourceMsg.time
            ..isSender = sourceMsg.isSender;

          await target.messages.put(newMsg);

          // sourceMsg.media is already loaded now, so this is safe:
          final sourceMedia = sourceMsg.media.value;
          if (sourceMedia != null) {
            final newMedia = Media()
              ..name = sourceMedia.name
              ..path = sourceMedia.path
              ..extension = sourceMedia.extension
              ..type = sourceMedia.type
              ..fileSize = sourceMedia.fileSize
              ..aspectRatio = sourceMedia.aspectRatio
              ..blurHash = sourceMedia.blurHash
              ..duration = sourceMedia.duration
              ..thumbnailPath = sourceMedia.thumbnailPath;

            await target.medias.put(newMedia);
            newMsg.media.value = newMedia;
            await newMsg.media.save();
          }

          targetChat.messages.add(newMsg);
        }

        await targetChat.messages.save();
        await target.chats.put(targetChat);
      });

      onProgress(total == 0 ? 1.0 : (i + 1) / total);
    }
    
    debugPrint('✅ Upsert complete — ${await target.chats.count()} total chats in DB');
  }

  // ─── Media Restoration ────────────────────────────────────────────────────────

  static Future<void> _restoreMediaFiles({
    required String extractDir,
    required Directory appDir,
    required _InternalProgress onProgress,
  }) async {
    final mediaSource = Directory('$extractDir/$_mediaFolder');
    if (!await mediaSource.exists()) return;

    final files = await _collectMediaFiles(mediaSource);
    final total = files.length;

    for (int i = 0; i < total; i++) {
      final file = files[i];
      final relativePath =
          file.path.replaceFirst('${mediaSource.parent.path}/', '');
      final targetPath = '${appDir.path}/$relativePath';
      final targetFile = File(targetPath);

      if (!await targetFile.exists()) {
        await targetFile.parent.create(recursive: true);
        await file.copy(targetPath);
      }

      onProgress(total == 0 ? 1.0 : (i + 1) / total);
    }
  }

  // ─── Integrity Verification ───────────────────────────────────────────────────

  static Future<void> _verifyArchiveIntegrity({
    required String archivePath,
    required String expectedHash,
    required int expectedSize,
  }) async {
    final file = File(archivePath);
    if (!await file.exists()) {
      throw const BackupException('Output file not found after save');
    }

    final actualSize = await file.length();
    if (actualSize != expectedSize) {
      throw BackupException(
        'File size mismatch — expected $expectedSize bytes, got $actualSize',
      );
    }

    final savedManifest = await _readManifestFast(archivePath);
    if (savedManifest.contentHash != expectedHash) {
      throw const BackupException(
        'Archive hash mismatch after save — file may be corrupted',
      );
    }
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────────
static Future<String> _getDbPath() async {
  final dir = kisDesktop
      ? await getApplicationSupportDirectory()
      : await IsarDatabase.getDatabaseDirectory();
  final path = '${dir.path}/chat_repo.isar';
  debugPrint('🗄️ DB path resolved: $path');
  return path;
}

  static Future<List<File>> _collectMediaFiles(Directory dir) async {
    if (!await dir.exists()) return [];
    return dir
        .list(recursive: true)
        .where((e) => e is File)
        .cast<File>()
        .toList();
  }

  static Future<void> _safeDelete(String? path) async {
    if (path == null) return;
    try {
      final f = File(path);
      if (await f.exists()) await f.delete();
    } catch (e) {
      debugPrint('⚠️ Could not clean up temp file: $e');
    }
  }

  static Future<void> _safeDeleteDir(String? path) async {
    if (path == null) return;
    try {
      final d = Directory(path);
      if (await d.exists()) await d.delete(recursive: true);
    } catch (e) {
      debugPrint('⚠️ Could not clean up temp dir: $e');
    }
  }
}