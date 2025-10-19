import 'package:flutter/material.dart';
import 'package:notesapp/root/widgets/voice_message/components/voice_controller.dart';
import 'package:notesapp/root/widgets/voice_message/components/widgets/loading_widget.dart';

/// PlayPauseButton: fixed ripple/clipping by using Material + InkWell with CircleBorder
class PlayPauseButton extends StatelessWidget {
  const PlayPauseButton(
      {super.key,
      required this.controller,
      required this.color,
      required this.size,
      required this.playIcon,
      required this.pauseIcon,
      required this.refreshIcon,
      required this.stopDownloadingIcon,
      required this.loadingColor,
      this.buttonDecoration,
      });

  final double size;
  final VoiceController controller;
  final Color color;
  final Widget playIcon;
  final Widget pauseIcon;
  final Widget refreshIcon;
  final Widget stopDownloadingIcon;
  final Color loadingColor;
  final Decoration? buttonDecoration;

  @override
  Widget build(BuildContext context) {
    // Use Material as ancestor for InkWell splash to render correctly.
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: controller.isDownloadError
            ? controller.play
            : controller.isPlaying
                ? controller.pausePlaying
                : controller.play,
        customBorder: const CircleBorder(),
        child: Container(
          height: size,
          width: size,
          alignment: Alignment.center,
          decoration: buttonDecoration ?? BoxDecoration(color: color, shape: BoxShape.circle),
          // child content
          child: _buildInner(),
        ),
      ),
    );
  }

  Widget _buildInner() {
    if (controller.isDownloading) {
      return LoadingWidget(
        progress: controller.downloadProgress,
        loadingColor: loadingColor,
        onClose: () {
          controller.cancelDownload();
        },
        stopDownloadingIcon: stopDownloadingIcon,
      );
    }

    if (controller.isDownloadError) {
      return refreshIcon;
    }

    return controller.isPlaying ? pauseIcon : playIcon;
  }
}