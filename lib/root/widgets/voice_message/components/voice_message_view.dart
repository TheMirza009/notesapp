import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:notesapp/core/Theme/theme_constants.dart';
import 'package:notesapp/root/widgets/voice_message/components/helpers/play_status.dart';
import 'package:notesapp/root/widgets/voice_message/components/helpers/utils.dart';
import 'package:notesapp/root/widgets/voice_message/components/voice_controller.dart';
import 'package:notesapp/root/widgets/voice_message/components/widgets/noises.dart';
import 'package:notesapp/root/widgets/voice_message/components/widgets/play_pause_button.dart';

/// A widget that displays a voice message view with play/pause functionality.
///
/// The [VoiceMessageView] widget is used to display a voice message with customizable appearance and behavior.
/// It provides a play/pause button, a progress slider, and a counter for the remaining time.
/// The appearance of the widget can be customized using various properties such as background color, slider color, and text styles.
///
class VoiceMessageView extends StatelessWidget {
  const VoiceMessageView(
      {super.key,
      required this.controller,
      this.backgroundColor = Colors.white,
      this.activeSliderColor = Colors.red,
      this.notActiveSliderColor,
      this.circlesColor = Colors.red,
      this.innerPadding = 12,
      this.cornerRadius = 20,
      // this.playerWidth = 170,
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
      
      this.showDuration = true,
      
      this.showSentTime = true,

      this.sentTime,
      });

  /// The controller for the voice message view.
  final VoiceController controller;

  /// The background color of the voice message view.
  final Color backgroundColor;

  ///
  final Color circlesColor;

  /// The color of the active slider.
  final Color activeSliderColor;

  /// The color of the not active slider.
  final Color? notActiveSliderColor;

  /// The text style of the circles.
  final TextStyle circlesTextStyle;

  /// The text style of the counter.
  final TextStyle counterTextStyle;

  /// The padding between the inner content and the outer container.
  final double innerPadding;

  /// The corner radius of the outer container.
  final double cornerRadius;

  /// The size of the play/pause button.
  final double size;

  /// The refresh icon of the play/pause button.
  final Widget refreshIcon;

  /// The pause icon of the play/pause button.
  final Widget pauseIcon;

  /// The play icon of the play/pause button.
  final Widget playIcon;

  /// The stop downloading icon of the play/pause button.
  final Widget stopDownloadingIcon;

  /// The play Decoration of the play/pause button.
  final Decoration? playPauseButtonDecoration;

  /// The loading Color of the play/pause button.
  final Color playPauseButtonLoadingColor;

  /// Show Remaining Time / Duration
  final bool? showDuration;

  /// Show The time message was sent
  final bool? showSentTime;

  final DateTime? sentTime;

  @override

  /// Build voice message view.
  Widget build(BuildContext context) {
  final theme = Theme.of(context);
  final color = circlesColor;

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

  final bool showBothTimes = showDuration == true && showSentTime == true;
  final bool showEither = showDuration == true || showSentTime == true;

  return Container(
    width: 130 + (controller.noiseCount * .72.width()),
    padding: EdgeInsets.all(innerPadding),
    decoration: BoxDecoration(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(cornerRadius),
    ),
    child: ValueListenableBuilder(
      valueListenable: controller.updater,
      builder: (context, value, child) {
        final playPauseButton = PlayPauseButton(
          controller: controller,
          color: color,
          loadingColor: playPauseButtonLoadingColor,
          size: size * (1.2),
          refreshIcon: refreshIcon,
          pauseIcon: pauseIcon,
          playIcon: playIcon,
          stopDownloadingIcon: stopDownloadingIcon,
          buttonDecoration: playPauseButtonDecoration,
        );

        final mainRow = Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: showBothTimes ? Alignment.topCenter : Alignment.center,
              child: playPauseButton,
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
                width: 175,
                child: Row(
                  mainAxisAlignment: showBothTimes ? MainAxisAlignment.spaceBetween : MainAxisAlignment.end,
                  children: [
                    if (showDuration ?? true) Text(
                      controller.remainingTime,
                      style: timeStyle,
                    ),
                    if (showSentTime ?? true) Text(
                      DateFormat.jm().format(sentTime ?? DateTime.now()),
                      style: timeStyle,
                    ),
                  ],
                ),
              ),
            ],
          );
        }
  ));
}


  Widget _noises(ThemeData newTheme) => SizedBox(
      height: 40,
      width: controller.noiseWidth,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // ShaderMask for waveform coloring
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
                      activeSliderColor, // played
                      notActiveSliderColor ?? backgroundColor.withOpacity(.4), // unplayed
                    ],
                  ).createShader(Rect.fromLTWH(0, 0, rect.width, rect.height));
                },
                child: Center(
                  child: Noises(
                    rList: controller.randoms!,
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
        style: circlesTextStyle,
      ),
    ),
  );
}

///
/// A custom track shape for a slider that is rounded rectangular in shape.
/// Extends the [RoundedRectSliderTrackShape] class.
class CustomTrackShape extends RoundedRectSliderTrackShape {
  @override

  /// Returns the preferred rectangle for the voice message view.
  ///
  /// The preferred rectangle is calculated based on the current state and layout
  /// of the voice message view. It represents the area where the view should be
  /// displayed on the screen.
  ///
  /// Returns a [Rect] object representing the preferred rectangle.
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    const double trackHeight = 10;
    final double trackLeft = offset.dx,  trackTop = offset.dy + (parentBox.size.height - trackHeight) / 2;
    final double trackWidth = parentBox.size.width;
    return Rect.fromLTWH(trackLeft, trackTop, trackWidth, trackHeight);
  }
}
