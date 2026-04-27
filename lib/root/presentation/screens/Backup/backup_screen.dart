import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notesapp/core/Theme/icon_paths.dart';
import 'package:notesapp/core/Theme/theme_constants.dart';
import 'package:notesapp/core/extensions/context_extensions.dart';
import 'package:notesapp/core/utils/context_menu_options.dart';
import 'package:notesapp/main.dart';
import 'package:notesapp/root/data/chat_list_provider/chat_list_notifier.dart';
import 'package:notesapp/root/presentation/screens/Backup/backup_notifier.dart';
import 'package:notesapp/root/presentation/screens/Backup/widgets/backup_hero_icon.dart';

// ─── BackupScreen ─────────────────────────────────────────────────────────────

class BackupScreen extends ConsumerWidget {
  const BackupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(backupProvider);

    // Show snackbars on status transitions
    ref.listen<BackupState>(backupProvider, (previous, next) {
      if (previous?.status == next.status) return;
      switch (next.status) {
        case BackupStatus.completed:
          _showSnackbar(
            context,
            message: next.isExport
                ? (kisDesktop ? 'Backup saved successfully!' : 'Backup ready — share sheet opened!')
                : 'Import complete! Your notes have been merged.',
            icon: Icons.check_circle_outline_rounded,
            color: Colors.green,
          );
        case BackupStatus.error:
          _showSnackbar(
            context,
            message: next.errorMessage ?? 'Something went wrong.',
            icon: Icons.error_outline_rounded,
            color: Colors.redAccent,
            duration: const Duration(seconds: 5),
          );
        case BackupStatus.cancelled:
          _showSnackbar(
            context,
            message: next.isExport ? 'Export cancelled.' : 'Import cancelled.',
            icon: Icons.cancel_outlined,
            color: ThemeConstants.subtitleLight,
          );
        default:
          break;
      }
    });

    return PopScope(
      canPop: state.isRunning == false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop && state.status == BackupStatus.completed && !state.isExport) {
          ref.invalidate(chatListProvider);
          ref.read(chatListProvider.notifier).loadChats();
        }
      },
      child: Scaffold(
        // backgroundColor: context.isLight
        //     ? const Color(0xFFF0F4F6)
        //     : ThemeConstants.messageBarDark,
        appBar: AppBar(
          toolbarHeight: 60,
          backgroundColor: Colors.transparent,
          elevation: 0,
          shadowColor: Colors.transparent,
          title: const Text(
            'Backup & Restore',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
          leading: Opacity(
            opacity: state.isRunning ? 0.5 : 1.0,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              onPressed: state.isRunning ? null : () => Navigator.pop(context),
            ),
          ),
        ),
        // bottomNavigationBar: const BackupInfoFooter(),
        body: SafeArea(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: state.isRunning
                ? BackupProgressView(key: const ValueKey('progress'), state: state)
                : BackupIdleView(key: const ValueKey('idle'), state: state),
          ),
        ),
      ),
    );
  }

  void _showSnackbar(
    BuildContext context, {
    required String message,
    required IconData icon,
    required Color color,
    Duration duration = const Duration(seconds: 3),
  }) {
    final isLight = context.isLight;
    final bgColor = isLight
        ? ThemeConstants.textDark2
        : ThemeConstants.darkIconBorder;
    final borderColor = isLight
        ? ThemeConstants.homeDividerLight
        : ThemeConstants.darkIconBorder;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: duration,
          backgroundColor: bgColor,
          behavior: SnackBarBehavior.floating,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: borderColor),
          ),
          content: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              spacing: 12,
              children: [
                Icon(icon, color: color, size: 20),
                Expanded(
                  child: Text(
                    message,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      color: color,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
                  child: Icon(Icons.close_rounded, color: color.withOpacity(0.6), size: 16),
                ),
              ],
            ),
          ),
        ),
      );
  }
}

// ─── Idle View ────────────────────────────────────────────────────────────────

class BackupIdleView extends ConsumerWidget {
  final BackupState state;
  const BackupIdleView({super.key, required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLight = context.isLight;
    final accentColor = isLight ? ThemeConstants.sacredSeed : ThemeConstants.sinisterSeed;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      children: [
        // ── Hero icon ──────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: BackupHeroIcon(
            circleSize: 150,
            iconSize: 60,
            circleColor: isLight
                ? ThemeConstants.sacredSeed.withAlpha(30)
                : ThemeConstants.darkIconBorder.withAlpha(100),
            child: Transform.scale(
              scale: 2.0,
              child: Image.asset(IconPaths.floppy),
            ),
          ),
        ),

        const SizedBox(height: 8),

        // ── Export Card ────────────────────────────────────────────────────
        BackupActionCard(
          icon: Icons.upload_rounded,
          child: vectorBuild(IconPaths.uploadDB, color: accentColor),
          title: 'Export My Data',
          description:
              'Creates a backup of all your notes and media. '
              'The file will be shared via the system share sheet.',
          buttonLabel: 'Export',
          accentColor: accentColor,
          // No confirmation dialog — export starts immediately
          onPressed: () => ref.read(backupProvider.notifier).startExport(),
        ),

        const SizedBox(height: 16),

        // ── Import Card ────────────────────────────────────────────────────
        BackupActionCard(
          icon: Icons.download_rounded,
          child: vectorBuild(IconPaths.downloadDB, color: accentColor),
          title: 'Import My Data',
          description:
              'Restore from a previously exported backup. '
              'Existing data will be merged — nothing will be deleted.',
          buttonLabel: 'Import',
          accentColor: accentColor,
          onPressed: () => _confirmImport(context, ref),
        ),

        const SizedBox(height: 24),
        const SizedBox(height: 8),
const BackupInfoFooter(),
const SizedBox(height: 16),
      ],
    );
  }

  void _confirmImport(BuildContext context, WidgetRef ref) {
    const TextStyle style = TextStyle(fontFamily: 'Poppins');
    showAdaptiveDialog(
      context: context,
      builder: (_) => AlertDialog.adaptive(
        title: const Text('Import Data', style: style),
        content: const Text(
          'Your existing data will be kept. '
          'Imported notes will be merged in. '
          'This cannot be undone — consider exporting first.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: style),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(backupProvider.notifier).startImport(ref);
            },
            child: const Text('Import', style: style),
          ),
        ],
      ),
    );
  }
}

// ─── Progress View ────────────────────────────────────────────────────────────

class BackupProgressView extends StatelessWidget {
  final BackupState state;
  const BackupProgressView({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final isLight = context.isLight;
    final accentColor = isLight ? ThemeConstants.sacredSeed : ThemeConstants.sinisterSeed;
    final label = state.isExport ? 'Exporting...' : 'Importing...';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ── Circular progress with percentage ──────────────────────────
            BackupProgressRing(
              progress: state.progress,
              accentColor: accentColor,
              icon: state.isExport
                  ? Icons.upload_rounded
                  : Icons.download_rounded,
            ),
        
            const SizedBox(height: 36),
        
            // ── Title ──────────────────────────────────────────────────────
            Text(
              label,
              style: const TextStyle(
                fontSize: 20,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
              ),
            ),
        
            const SizedBox(height: 10),
        
            // ── Animated status text ───────────────────────────────────────
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Text(
                state.statusText,
                key: ValueKey(state.statusText),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontFamily: 'Poppins',
                  color: ThemeConstants.subtitleLight.withOpacity(0.7),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Circular Progress Ring ───────────────────────────────────────────────────

class BackupProgressRing extends StatelessWidget {
  final double progress;
  final Color accentColor;
  final IconData icon;
  final double size;

  const BackupProgressRing({
    super.key,
    required this.progress,
    required this.accentColor,
    required this.icon,
    this.size = 160,
  });

  @override
  Widget build(BuildContext context) {
    final percent = (progress * 100).toInt();

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // ── Track ──────────────────────────────────────────────────────
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: 1.0,
              strokeWidth: 8,
              strokeCap: StrokeCap.round,
              color: ThemeConstants.subtitleLight.withOpacity(0.12),
            ),
          ),
          // ── Fill ───────────────────────────────────────────────────────
          SizedBox(
            width: size,
            height: size,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOut,
              builder: (_, value, __) => CircularProgressIndicator(
                value: value,
                strokeWidth: 8,
                strokeCap: StrokeCap.round,
                color: accentColor,
              ),
            ),
          ),
          // ── Center content ─────────────────────────────────────────────
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 28, color: accentColor),
              const SizedBox(height: 4),
              Text(
                '$percent%',
                style: TextStyle(
                  fontSize: 22,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                  color: accentColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Action Card ──────────────────────────────────────────────────────────────

class BackupActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String buttonLabel;
  final Color accentColor;
  final VoidCallback onPressed;
  final Widget? child;

  const BackupActionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.buttonLabel,
    required this.accentColor,
    required this.onPressed,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = context.isLight;
    final cardColor = isLight
        ? Colors.white
        : ThemeConstants.darkAppbar;
    final borderColor = isLight
        ? ThemeConstants.homeDividerLight.withOpacity(0.6)
        : ThemeConstants.darkIconBorder;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isLight ? 0.05 : 0.15),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────────────────
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(isLight ? 0.1 : 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: child ?? Icon(icon, color: accentColor, size: 22),
              ),
              const SizedBox(width: 14),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ── Description ───────────────────────────────────────────────
          Text(
            description,
            style: TextStyle(
              fontSize: 13,
              fontFamily: 'Poppins',
              color: ThemeConstants.subtitleLight.withOpacity(0.75),
              height: 1.5,
            ),
          ),

          const SizedBox(height: 16),

          // ── Button ────────────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                buttonLabel,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Info Footer ──────────────────────────────────────────────────────────────

class BackupInfoFooter extends StatelessWidget {
  const BackupInfoFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: Text(
        'Backup files use the .notesbackup format and include all '
        'notes, messages, and media. Import merges data without '
        'overwriting existing content.',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 11,
          fontFamily: 'Poppins',
          color: ThemeConstants.subtitleLight.withOpacity(0.5),
          height: 1.6,
        ),
      ),
    );
  }
}