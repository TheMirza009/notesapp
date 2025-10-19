import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:notesapp/core/Theme/theme_constants.dart';
import 'package:notesapp/core/extensions/context_extensions.dart';
import 'package:notesapp/root/widgets/voice_message/components/helpers/custom_track_shape.dart';
import 'package:notesapp/root/widgets/voice_message/components/helpers/play_status.dart';
import 'package:notesapp/root/widgets/voice_message/components/helpers/utils.dart';
import 'package:notesapp/root/widgets/voice_message/components/voice_controller.dart';
import 'package:notesapp/root/widgets/voice_message/components/widgets/noises.dart';
import 'package:notesapp/root/widgets/voice_message/components/widgets/play_pause_button.dart';

/// VoiceMessageView now owns the VoiceController lifecycle.
/// Create one controller per view in initState and dispose it in dispose().
class VoiceMessageView extends StatefulWidget {
  const VoiceMessageView({
    super.key,
    required this.audioSrc,
    required this.isFile,
    this.backgroundColor = Colors.white,
    this.activeWaveColor = Colors.red,
    this.inactiveWaveColor,
    this.circlesColor = Colors.red,
    this.innerPadding = 12,
    this.cornerRadius = 20,
    this.size = 38,
    this.refreshIcon = const Icon(
      Icons.refresh,
      color: Colors.white,
    ),
    this.pauseIcon = const Icon(
      Icons.pause_rounded,
      color: Colors.white,
    ),
    this.playIcon = const Icon(
      Icons.play_arrow_rounded,
      color: Colors.white,
    ),
    this.stopDownloadingIcon = const Icon(
      Icons.close,
      color: Colors.white,
    ),
    this.playPauseButtonDecoration,
    this.circlesTextStyle = const TextStyle(
      color: Colors.white,
      fontSize: 10,
      fontWeight: FontWeight.bold,
    ),
    this.counterTextStyle = const TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w500,
    ),
    this.playPauseButtonLoadingColor = Colors.white,
    this.noiseCount = 35,
    this.showDuration = true,
    this.showSentTime = true,
    this.sentTime,
  });

  final String audioSrc;
  final bool isFile;
  final Color backgroundColor;
  final Color circlesColor;
  final Color activeWaveColor;
  final Color? inactiveWaveColor;
  final TextStyle circlesTextStyle;
  final TextStyle counterTextStyle;
  final double innerPadding;
  final double cornerRadius;
  final double size;
  final Widget refreshIcon;
  final Widget pauseIcon;
  final Widget playIcon;
  final Widget stopDownloadingIcon;
  final Decoration? playPauseButtonDecoration;
  final Color playPauseButtonLoadingColor;
  final int noiseCount;
  final bool? showDuration;
  final bool? showSentTime;
  final DateTime? sentTime;

  @override
  State<VoiceMessageView> createState() => _VoiceMessageViewState();
}

class _VoiceMessageViewState extends State<VoiceMessageView> with TickerProviderStateMixin {
  late VoiceController controller;

  @override
  void initState() {
    super.initState();

    // Create the controller once and dispose it when the widget is removed.
    controller = VoiceController(
      audioSrc: widget.audioSrc,
      maxDuration: Duration.zero, // will be set in init()
      isFile: widget.isFile,
      noiseCount: widget.noiseCount,
      onComplete: () {
        // update UI or callbacks if needed
        if (mounted) setState(() {});
      },
      onPause: () {
        if (mounted) setState(() {});
      },
      onPlaying: () {
        if (mounted) setState(() {});
      },
      onError: (err) {
        // handle error if necessary
      },
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = widget.circlesColor;

    final newTheme = theme.copyWith(
      sliderTheme: SliderThemeData(
        trackShape: CustomTrackShape(),
        thumbShape: SliderComponentShape.noThumb,
        minThumbSeparation: 0,
      ),
      splashColor: Colors.transparent,
    );

    final timeStyle = const TextStyle(
      height: 1,
      fontSize: 12,
      color: ThemeConstants.subtitleLight,
    );

    final bool showBothTimes = widget.showDuration == true && widget.showSentTime == true;
    final bool showEither = widget.showDuration == true || widget.showSentTime == true;
    final maxWidth = 130 + (controller.noiseCount * .72.width());

    return Container(
      width: maxWidth,
      padding: EdgeInsets.all(widget.innerPadding),
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        borderRadius: BorderRadius.circular(widget.cornerRadius),
      ),
      child: ValueListenableBuilder(
        valueListenable: controller.updater,
        builder: (context, value, child) {
          final playPauseButton = PlayPauseButton(
            controller: controller,
            color: color,
            loadingColor: widget.playPauseButtonLoadingColor,
            size: widget.size * (1.2),
            refreshIcon: widget.refreshIcon,
            pauseIcon: widget.pauseIcon,
            playIcon: widget.playIcon,
            stopDownloadingIcon: widget.stopDownloadingIcon,
            buttonDecoration: widget.playPauseButtonDecoration,
          );

          final mainRow = Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: showBothTimes ? Alignment.topCenter : Alignment.center,
                child: ClipOval(child: playPauseButton),
              ),
              Flexible(child: _noises(newTheme)),
              _changeSpeedButton(color),
            ],
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              mainRow,
              SizedBox(
                height: showEither ? 10 : 0,
                width: maxWidth - (widget.size * 1.2),
                child: Row(
                  mainAxisAlignment: showBothTimes ? MainAxisAlignment.spaceBetween : MainAxisAlignment.end,
                  children: [
                    if (widget.showDuration ?? true) Text(
                      controller.remainingTime,
                      style: timeStyle,
                    ),
                    if (widget.showSentTime ?? true) Text(
                      DateFormat.jm().format(widget.sentTime ?? DateTime.now()),
                      style: timeStyle,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _noises(ThemeData newTheme) => SizedBox(
    height: 40,
    width: controller.noiseWidth,
    child: Stack(
      alignment: Alignment.center,
      children: [
        AnimatedBuilder(
          animation: CurvedAnimation(
            parent: controller.animController,
            curve: Curves.ease,
          ),
          builder: (context, child) {
            final playedFraction = (controller.animController.value / controller.noiseWidth).clamp(0.0, 1.0);

            return ShaderMask(
              blendMode: BlendMode.srcATop,
              shaderCallback: (rect) {
                return LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  stops: [playedFraction, playedFraction],
                  colors: [
                    widget.activeWaveColor, // played
                    widget.inactiveWaveColor ?? widget.backgroundColor.withOpacity(.4), // unplayed
                  ],
                ).createShader(Rect.fromLTWH(0, 0, rect.width, rect.height));
              },
              child: Center(
                child: Noises(
                  rList: controller.randoms ?? [],
                  activeSliderColor: Colors.white, // placeholder for ShaderMask
                ),
              ),
            );
          },
        ),
        // Invisible Slider on top to detect gestures
        Opacity(
          opacity: 0,
          child: SizedBox(
            width: controller.noiseWidth,
            child: Theme(
              data: newTheme,
              child: Slider(
                value: controller.currentMillSeconds,
                max: controller.maxMillSeconds,
                onChangeStart: controller.onChangeSliderStart,
                onChanged: controller.onChanging,
                onChangeEnd: (value) {
                  controller.onSeek(Duration(milliseconds: value.toInt()));
                  controller.play();
                },
              ),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _changeSpeedButton(Color color) => GestureDetector(
    onTap: () {
      controller.changeSpeed();
    },
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        controller.speed.playSpeedStr,
        style: widget.circlesTextStyle,
      ),
    ),
  );
}