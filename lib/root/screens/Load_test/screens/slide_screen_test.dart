import 'package:flutter/material.dart';
import 'package:notesapp/core/Theme/icon_paths.dart';
import 'package:notesapp/root/screens/Homescreen/homescreen.dart';
import 'package:notesapp/root/screens/Load_test/screens/profile_screen.dart';

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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final statusBarHeight = MediaQuery.of(context).padding.top;

    const double avatarSize = 40.0;
    const double shownScale = 5.0;
    const double hiddenScale = 1.0;
    const double profileTop = avatarSize * shownScale + 10;

    final double topWhenHidden = statusBarHeight + (kToolbarHeight - avatarSize + 10) / 2;
    final double leftWhenHidden = 16.0;
    final double leftWhenShown = (screenWidth / 2) - avatarSize + 20;

    return Scaffold(
      
      body: Stack(
        clipBehavior: Clip.none,
        fit: StackFit.expand,
        children: [
          // AppBar + HomeBody as a Column
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 5.0, right: 15),
                child: AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  automaticallyImplyLeading: false,
                  title: Text("Homescreen"),
                  leading: SizedBox(width: 40,),
                  actions: [
                    IconButton.filled(
                      style: IconButton.styleFrom(backgroundColor: Colors.white),
                      color: Colors.black,
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.clear),
                    ),
                  ],
                ),
              ),
              Expanded(child: HomeBody(onProfileTap: () => setState(() => showingProfileScreen = true))),
            ],
          ),

          // ProfileScreen slides in from right
          AnimatedSlide(
            offset: showingProfileScreen ? Offset.zero : const Offset(1, 0),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOutQuint,
            child: IgnorePointer(
              ignoring: !showingProfileScreen,
              child: ProfileScreen(
                onClose: () => setState(() => showingProfileScreen = false),
              ),
            ),
          ),

          // Floating Avatar (fully above AppBar)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOutQuint,
            top: showingProfileScreen ? profileTop : topWhenHidden,
            left: showingProfileScreen ? leftWhenShown : leftWhenHidden,
            child: AnimatedScale(
              scale: showingProfileScreen ? shownScale : hiddenScale,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOutQuint,
              child: GestureDetector(
                onTap: () => setState(() => showingProfileScreen = true),
                child: Image.asset(
                  IconPaths.avatarLight,
                  width: avatarSize,
                  height: avatarSize,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
