import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notesapp/core/Theme/gradients.dart';
import 'package:notesapp/core/Theme/icon_paths.dart';
import 'package:notesapp/core/Theme/theme_constants.dart';
import 'package:notesapp/core/controllers/theme_provider.dart';
import 'package:notesapp/core/extensions/context_extensions.dart';
import 'package:notesapp/core/utils/context_menu_options.dart';
import 'package:notesapp/root/screens/Load_test/widgets/pulldown_wrapper.dart';
import 'package:notesapp/root/screens/Profile/hero_wrapper.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  final Widget? leading;
  const ProfileScreen({super.key, this.leading});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late TextEditingController titleController;
  late FocusNode _focusNode;
  bool isEditing = false;
  String name = "Name";

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    titleController = TextEditingController(text: name);
  }

  @override
  void dispose() {
    titleController.dispose();
    super.dispose();
  }

  void _startEditing() {
    setState(() => isEditing = true);
    Future.delayed(Duration.zero, () {
      _focusNode.requestFocus();
      titleController.selection = TextSelection.fromPosition(
        TextPosition(offset: titleController.text.length),
      );
    });
  }

  void _finishEditing() {
    final newText = titleController.text.trim();
    setState(() {
      name = newText;
      isEditing = false;
      _focusNode.unfocus();
      
      });
  }

  @override
  Widget build(BuildContext context) {
    Size screensize = MediaQuery.sizeOf(context);
    bool isLight = Theme.brightnessOf(context) == Brightness.light;
    LinearGradient backgroundGradient =
        isLight ? Gradients.lightBackground : Gradients.darkBackground;
    Color headerColor =
        isLight ? ThemeConstants.hometoolbarLight2 : ThemeConstants.darkAppbar;
    Color dividerColor =
        isLight
            ? ThemeConstants.homeDividerLight
            : ThemeConstants.darkIconBorder;
    return PullDownWrapper(
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: Colors.transparent, // headerColor,
          leading: widget.leading,
          title: const Text(
            "Profile",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
          ),
          actionsPadding: EdgeInsets.all(10),
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
          padding: EdgeInsets.only(top: 12),
          decoration: BoxDecoration(gradient: backgroundGradient),
          child: Column(
            children: [
              SizedBox(height: 75),
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
                // topWidget: const Text( "Profile", style: TextStyle(color: Colors.white), ),
                bottomWidget: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Back"),
                ),
              ),
      
              Container(
                margin: const EdgeInsets.all(30),
                padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 5),
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
                        focusNode: _focusNode,
                        enableInteractiveSelection: isEditing,
                        controller: titleController,
                        autofocus: isEditing,
                        readOnly: !isEditing, // 👈 makes it read-only after finishing
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
                          _finishEditing(); // saves and sets readOnly
                        } else {
                          _startEditing(); // enables editing
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
