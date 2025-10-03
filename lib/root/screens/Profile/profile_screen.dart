import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:notesapp/core/Theme/gradients.dart';
import 'package:notesapp/core/Theme/icon_paths.dart';
import 'package:notesapp/core/Theme/theme_constants.dart';
import 'package:notesapp/core/controllers/theme_provider.dart';
import 'package:notesapp/core/extensions/context_extensions.dart';
import 'package:notesapp/core/utils/context_menu_options.dart';
import 'package:notesapp/root/screens/Load_test/widgets/pulldown_wrapper.dart';
import 'package:notesapp/root/screens/Profile/wrappers/hero_wrapper.dart';

import 'profile_screen_state.dart'; // import the state class

class ProfileScreen extends ConsumerStatefulWidget {
  final Widget? leading;
  const ProfileScreen({super.key, this.leading});

  @override
  ConsumerState<ProfileScreen> createState() => ProfileScreenState();
}

class ProfileScreenState extends ProfileScreenBaseState {
  @override
  Widget build(BuildContext context) {
    final screensize = MediaQuery.sizeOf(context);
    final isLight = Theme.of(context).brightness == Brightness.light;
    final backgroundGradient =
        isLight ? Gradients.lightBackground : Gradients.darkBackground;
    final dividerColor =
        isLight ? ThemeConstants.homeDividerLight : ThemeConstants.darkIconBorder;

    return PullDownWrapper(
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          leading: widget.leading,
          title: const Text(
            "Profile",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
          ),
          actions: [
            IconButton(
              icon: Icon(
                isLight ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
              ),
              onPressed:
                  () => ref.read(themeNotifierProvider.notifier).toggleTheme(),
            ),
          ],
        ),
        body: Container(
          height: screensize.height,
          width: screensize.width,
          padding: const EdgeInsets.only(top: 12),
          decoration: BoxDecoration(gradient: backgroundGradient),
          child: Column(
            children: [
              const SizedBox(height: 75),
              HeroWrapper(
                tag: "profile-avatar",
                defaultChild: Image.asset(
                  height: context.screenHeight / 4,
                  context.isLight ? IconPaths.avatarLight : IconPaths.avatarDark,
                  fit: BoxFit.contain,
                ),
                expandedChild: Image.asset(
                  context.isLight ? IconPaths.avatarLight : IconPaths.avatarDark,
                  fit: BoxFit.contain,
                ),
                bottomWidget: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Back"),
                ),
              ),
              Container(
                margin: const EdgeInsets.all(30),
                padding:
                    const EdgeInsets.symmetric(horizontal: 13, vertical: 5),
                decoration: BoxDecoration(
                  border: Border.all(width: 1.5, color: dividerColor),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 5.0, right: 20),
                      child: vectorBuild(IconPaths.userHUGE),
                    ),
                    Expanded(
                      child: TextField(
                        focusNode: focusNode,
                        enableInteractiveSelection: isEditing,
                        controller: titleController,
                        autofocus: isEditing,
                        readOnly: !isEditing,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isCollapsed: true,
                        ),
                        style: const TextStyle(
                          fontSize: 21.5,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(isEditing ? Icons.check : Icons.edit),
                      onPressed: () {
                        if (isEditing) {
                          finishEditing();
                          setState(() {});
                        } else {
                          startEditing();
                          setState(() {});
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
