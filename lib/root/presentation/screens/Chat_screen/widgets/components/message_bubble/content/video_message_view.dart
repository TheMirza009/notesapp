import 'package:flutter/material.dart';
import 'package:notesapp/root/data/models/message_model.dart';
import 'package:notesapp/root/presentation/screens/Chat_screen/widgets/components/message_bubble/content/image_message_view.dart';

class VideoMessageView extends StatelessWidget {
  final Message message;
  const VideoMessageView({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        ImageMessageView(message: message, isVideo: true,),
        Icon(Icons.phone, 
        size: 50,
        shadows: [
          BoxShadow(
            blurRadius: 25,
            color: Colors.black.withValues(alpha: 0.5),
            blurStyle: BlurStyle.outer,
            spreadRadius: 10,
          )
        ],)
      ],
    );
  }
}