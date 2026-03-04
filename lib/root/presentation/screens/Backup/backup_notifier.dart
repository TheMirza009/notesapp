import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:notesapp/core/controllers/backup/backup_service.dart';
import 'package:notesapp/root/data/chat_list_provider/chat_list_notifier.dart';

// ─── Backup Operation Status ──────────────────────────────────────────────────

enum BackupStatus { idle, inProgress, completed, error, cancelled }

// ─── Backup State ─────────────────────────────────────────────────────────────

class BackupState {
  final BackupStatus status;
  final double progress;       // 0.0 – 1.0
  final String statusText;
  final String? errorMessage;
  final String? outputPath;    // set on successful export
  final bool isExport;         // true = export, false = import

  const BackupState({
    this.status = BackupStatus.idle,
    this.progress = 0.0,
    this.statusText = '',
    this.errorMessage,
    this.outputPath,
    this.isExport = true,
  });

  bool get isIdle => status == BackupStatus.idle;
  bool get isRunning => status == BackupStatus.inProgress;
  bool get isDone => status == BackupStatus.completed;
  bool get hasError => status == BackupStatus.error;
  bool get wasCancelled => status == BackupStatus.cancelled;

  BackupState copyWith({
    BackupStatus? status,
    double? progress,
    String? statusText,
    String? errorMessage,
    String? outputPath,
    bool? isExport,
  }) =>
      BackupState(
        status: status ?? this.status,
        progress: progress ?? this.progress,
        statusText: statusText ?? this.statusText,
        errorMessage: errorMessage ?? this.errorMessage,
        outputPath: outputPath ?? this.outputPath,
        isExport: isExport ?? this.isExport,
      );

  BackupState get reset => const BackupState();
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final backupProvider = StateNotifierProvider<BackupNotifier, BackupState>(
  (ref) => BackupNotifier(ref),
);

// ─── BackupNotifier ───────────────────────────────────────────────────────────

class BackupNotifier extends StateNotifier<BackupState> {
  final Ref _ref;

  BackupNotifier(this._ref) : super(const BackupState());

  // ─── Export ─────────────────────────────────────────────────────────────────

  Future<void> startExport() async {
    if (state.isRunning) return;

    state = const BackupState(
      status: BackupStatus.inProgress,
      isExport: true,
      statusText: 'Starting export...',
    );

    try {
      final outputPath = await BackupService.exportBackup(
        onProgress: (progress, text) {
          if (!mounted) return;
          state = state.copyWith(progress: progress, statusText: text);
        },
      );

      if (!mounted) return;
      state = state.copyWith(
        status: BackupStatus.completed,
        progress: 1.0,
        statusText: 'Backup saved successfully!',
        outputPath: outputPath,
      );
    } on BackupCancelledException {
      if (!mounted) return;
      state = state.copyWith(
        status: BackupStatus.cancelled,
        statusText: 'Export cancelled',
      );
    } on BackupException catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        status: BackupStatus.error,
        errorMessage: e.message,
        statusText: 'Export failed',
      );
    }
  }

  // ─── Import ─────────────────────────────────────────────────────────────────

  Future<void> startImport(WidgetRef ref) async {
  if (state.isRunning) return;

  state = const BackupState(
    status: BackupStatus.inProgress,
    isExport: false,
    statusText: 'Starting import...',
  );

  try {
    await BackupService.importBackup(
      onProgress: (progress, text) {
        state = state.copyWith(progress: progress, statusText: text);
      },
    );

    state = state.copyWith(
      status: BackupStatus.completed,
      progress: 1.0,
      statusText: 'Import complete!',
    );

    // // Invalidate first — wipes stale in-memory state
    // ref.invalidate(chatListProvider);
    // // Then force a fresh load from Isar
    // await ref.read(chatListProvider.notifier).loadChats();
  } on BackupCancelledException {
    state = state.copyWith(
      status: BackupStatus.cancelled,
      statusText: 'Import cancelled',
    );
  } on InvalidBackupException catch (e) {
    state = state.copyWith(
      status: BackupStatus.error,
      errorMessage: e.message,
      statusText: 'Invalid backup file',
    );
  } on BackupException catch (e) {
    state = state.copyWith(
      status: BackupStatus.error,
      errorMessage: e.message,
      statusText: 'Import failed',
    );
  }
}

  // ─── Reset ──────────────────────────────────────────────────────────────────

  void reset() {
    if (state.isRunning) return; // don't reset mid-operation
    state = const BackupState();
  }
}