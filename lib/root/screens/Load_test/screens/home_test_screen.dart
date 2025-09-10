import 'package:flutter/material.dart';
import 'package:notesapp/core/Theme/icon_paths.dart';

class HomeTestScreen extends StatelessWidget {
  final void Function()? onProfileTap;
  const HomeTestScreen({super.key, required this.onProfileTap});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actionsPadding: EdgeInsets.all(8),
        automaticallyImplyLeading: false,
        // leading: Padding(
        //   padding: const EdgeInsets.all(8.0),
        //   child: Material(
        //     shape: const CircleBorder(),
        //     clipBehavior: Clip.antiAlias, // ensures splash is clipped to circle
        //     child: Ink.image(
        //       image: AssetImage(IconPaths.avatarLight),
        //       fit: BoxFit.cover,
        //       width: 40,
        //       height: 40,
        //       child: InkWell(
        //         onTap: onProfileTap
        //       ),
        //     ),
        //   ),
        // ),
        actions: [
          IconButton.filled(
                style: IconButton.styleFrom(backgroundColor: Colors.white),
                color: Colors.black,
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.clear),
              ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [Text("HOMESCREEN", style: TextStyle(fontSize: 25))],
        ),
      ),
    );
  }
}
