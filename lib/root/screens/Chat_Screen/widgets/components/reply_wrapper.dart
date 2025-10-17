import 'dart:io';
import 'package:flutter/material.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/ph.dart';
import 'package:notesapp/root/data/enums/media_type.dart';
import 'package:notesapp/root/data/models/message_model.dart';
import 'package:notesapp/root/screens/Chat_screen/widgets/components/message_bubble/helpers/ripple_well.dart';


/// A reusable reply bubble with ripple effect.
/// Shows "reply-to" text and optional media preview.
/// Extracts its data directly from a [Message].
class ReplyWrapper extends StatelessWidget {
  final Message replyMessage;

  /// UI
  final Color? backgroundColor;
  final BorderRadius borderRadius;
  final double imageSize;
  final EdgeInsetsGeometry margin;
  final EdgeInsetsGeometry padding;

  /// Icon
  final Color? iconColor;
  final double iconSize;

  /// Text
  final TextStyle? textStyle;
  final int maxLines;

  /// Interactivity
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const ReplyWrapper({
    super.key,
    required this.replyMessage,
    this.backgroundColor,
    this.borderRadius = const BorderRadius.all(Radius.circular(15)),
    this.imageSize = 40,
    this.margin = const EdgeInsets.only(top: 5),
    this.padding = const EdgeInsets.all(8),
    this.iconColor,
    this.iconSize = 18,
    this.textStyle,
    this.maxLines = 3,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    // Extract message properties for readability & separation of concerns
    final replyText = replyMessage.text;
    final media = replyMessage.media.value;
    final hasMedia = media != null && media.path != null && File(media.path!).existsSync();
    final mediaPath = hasMedia ? media!.path! : null;

    return RippleWell(
          margin: margin,
          padding: padding,
          decoration: BoxDecoration(
            color: backgroundColor ?? Colors.blueGrey.withOpacity(0.08),
            borderRadius: borderRadius,
          ),
          onTap: onTap,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Iconify(
                Ph.arrow_bend_down_right,
                color: iconColor ?? Theme.of(context).textTheme.bodyMedium?.color,
                size: iconSize,
              ),

              const SizedBox(width: 5),

              Flexible(
                child: Text(
                  replyText,
                  overflow: TextOverflow.ellipsis,
                  maxLines: maxLines,
                  style: textStyle ?? TextStyle(fontSize: 12, fontWeight: FontWeight.w300, ),
                ),
              ),

              if (mediaPath != null && media?.type == Mediatype.image) ...[
                const SizedBox(width: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: Image.file(
                    File(mediaPath),
                    width: imageSize,
                    height: imageSize,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
            ],
          ),
    );
  }
}
