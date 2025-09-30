import 'package:flutter/material.dart';
import 'package:notesapp/core/Theme/icon_paths.dart';
import 'package:notesapp/root/data/models/chat_model.dart';
import 'package:notesapp/root/screens/Homescreen/homescreen.dart';
import 'package:notesapp/root/screens/Load_test/screens/profile_screen.dart';
import 'package:notesapp/root/screens/Load_test/screens/sliding_profile_wrapper/sliding_profile_screen_wrapper.dart';
import 'package:notesapp/root/screens/Load_test/screens/sliding_profile_wrapper/sliding_profile_controller.dart';

class HomeBody extends StatelessWidget {
  final VoidCallback? onProfileTap;
  const HomeBody({super.key, this.onProfileTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const Text("HOMESCREEN", style: TextStyle(fontSize: 25)),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: onProfileTap,
            child: const Text("Open Profile"),
          ),
        ],
      ),
    );
  }
}

class SlideScreenTest extends StatefulWidget {
  const SlideScreenTest({super.key});

  @override
  State<SlideScreenTest> createState() => _SlideScreenTestState();
}

class _SlideScreenTestState extends State<SlideScreenTest> {
  bool showingProfileScreen = false;
  final SlidingProfileController controller = SlidingProfileController();

  @override
  Widget build(BuildContext context) {
    return SlidingProfileScreenWrapper(
      controller: controller,
      floatingWidget: Icon(Icons.person),
      appBarTitle: Text("Profile Slide Test"),
      parentBody: HomeBody(),
      slideFromRight: true,
      profileBody: ProfileScreen(
        onClose: controller.close,
      ),
    );
  }
}
