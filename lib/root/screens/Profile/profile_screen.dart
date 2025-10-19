import 'dart:io';
import 'dart:ui';

import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:notesapp/core/Theme/gradients.dart';
import 'package:notesapp/core/Theme/icon_paths.dart';
import 'package:notesapp/core/Theme/theme_constants.dart';
import 'package:notesapp/core/controllers/theme_provider.dart';
import 'package:notesapp/core/controllers/user_provider.dart';
import 'package:notesapp/core/extensions/context_extensions.dart';
import 'package:notesapp/core/utils/context_menu_options.dart';
import 'package:notesapp/core/utils/global_keys.dart';
import 'package:notesapp/core/utils/utils.dart';
import 'package:notesapp/root/screens/Load_test/widgets/pulldown_wrapper.dart';
import 'package:notesapp/root/screens/Profile/widgets/tile_container.dart';
import 'package:notesapp/root/screens/Profile/wrappers/hero_wrapper.dart';
import 'package:notesapp/root/widgets/theme_switch.dart';
import 'package:photo_view/photo_view.dart';
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
    final backgroundGradient = isLight ? Gradients.lightBackground : Gradients.darkBackground;
    final dividerColor = isLight ? ThemeConstants.homeDividerLight : ThemeConstants.darkIconBorder;
    const Color darkPrimary = Color(0xFF81D3DF);
    final user = ref.watch(userController);
    final Color shareColor = user?.profilePhotoPath == null ? ThemeConstants.iconColorNeutral : darkPrimary;

    titleController.text = ref.watch(userController)?.name ?? "Name"; 
    print("Profile Screen built");
    return PullDownWrapper(
      child: Scaffold(
        extendBodyBehindAppBar: true,
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          leading: widget.leading,
          title: const Text(
            "Profile",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
          ),
          actions: [
            ThemeSwitch()
          ],
        ),
        body: Container(
          height: screensize.height,
          width: screensize.width,
          padding: const EdgeInsets.only(top: 12),
          decoration: BoxDecoration(gradient: backgroundGradient),
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 75),
                HeroWrapper(
                  tag: "profile-avatar",
                  defaultChild: _buildProfileImage(context, user?.profilePhotoPath, expanded: false),
                  expandedChild: _buildProfileImage(context, user?.profilePhotoPath, expanded: true),
                  topWidget: Align(
                    alignment: Alignment.topLeft,
                    child: TextButton.icon(
                      icon: Icon(Icons.arrow_back_rounded),
                      onPressed: () => Navigator.pop(context),
                      label: const Text("Back"),
                    ),
                  ),
                  bottomWidget: Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: Row(
                      spacing: 10,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton.icon(
                          icon: vectorBuild(IconPaths.uploadImage, color: darkPrimary),
                          onPressed: () => pickNewProfilePhoto(),
                          label: const Text("Upload", style: TextStyle(color: darkPrimary),),
                        ),
                        TextButton.icon(
                          icon: vectorBuild(IconPaths.shareIcon, color:  shareColor),
                          onPressed: () => Utils.shareToApps(XFile(user!.profilePhotoPath!)), // () => Navigator.pop(context),
                          label: Text("Share", style: TextStyle(color: shareColor),),
                        ),
                      ],
                    ),
                  ),
                ),
                // nameBuilderBordered(),
                nameBuilderSimple(),
                // SizedBox(height: 50),
                TileContainer.solidBox(
                  backgroundColor: Colors.transparent,
                  dividerColor: context.isLight ? dividerColor : null,
                  tilePadding: EdgeInsets.symmetric(vertical: 10),
                  iconPadding: EdgeInsets.only(left: 20, right: 12),
                  borderRadius: 25,
                  borderThickness: 2,
                  dividerThickness: 2,
                  items: [
                    TileItem(title: "Settings", icon: vectorBuild(IconPaths.setting1, scale: 1.3), onTap: navigateToSettings),
                    TileItem(title: "Refer a friend", icon: vectorBuild(IconPaths.mailHeart, scale: 1.3), onTap: () async => await refer()),
                    TileItem(title: "Contact us", icon: vectorBuild(IconPaths.mail, scale: 1.3), onTap: () async => await contactUs()),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Widget _buildProfileImage(BuildContext context, String? path, {bool expanded = false}) {
  if (expanded) {
    final double availableHeight = context.screenHeight - 200; // leave space for buttons

    return SizedBox(
      height: availableHeight,
      width: context.screenWidth,
      child: PhotoView(
        gestureDetectorBehavior: HitTestBehavior.opaque,
        imageProvider: path != null
            ? FileImage(File(path))
            : AssetImage(
                context.isLight ? IconPaths.avatarLight : IconPaths.avatarDark,
              ) as ImageProvider,
        minScale: PhotoViewComputedScale.contained, // can zoom out to fit
        initialScale: PhotoViewComputedScale.contained, // start fitting inside
        maxScale: PhotoViewComputedScale.covered * 3,
        tightMode: true,
        disableGestures: false,
        backgroundDecoration: BoxDecoration(color: Colors.transparent),
      ),
    );
  }

  // Default (small avatar) -> circle clipped
  final double size = context.screenHeight / 4;

  final Widget image = path != null
      ? ExtendedImage.file(
          key: ValueKey(path), 
          File(path),
          width: size,
          height: size,
          fit: BoxFit.cover,
          cacheRawData: true,
        )
      : Image.asset(
          context.isLight ? IconPaths.avatarLight : IconPaths.avatarDark,
          width: size,
          height: size,
          fit: BoxFit.cover,
        );

  return Container(
    height: size,
    width: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
    ),
    clipBehavior: Clip.antiAlias,
    child: image);
}

Widget buildOptionsColumn() {
  final context = navigatorKey.currentContext!;
  final isLight = context.isLight;

  const lightBG = Color.fromARGB(255, 228, 239, 240);
  const darkBG = Color.fromARGB(255, 34, 52, 65);

  final backgroundColor = isLight ? lightBG : darkBG;
  final dividerColor = isLight
      ? ThemeConstants.homeDividerLight.withValues(alpha: 0.3)
      : ThemeConstants.homeDividerLight.withValues(alpha: 0.2);

  Widget _buildTile({
    required String title,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Icon(icon),
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w200),
      ),
      onTap: onTap,
    );
  }

  return Container(
    width: context.screenWidth - 70,
    decoration: ShapeDecoration(
      color: backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: dividerColor, width: 1.5),
      ),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildTile(
          title: "Settings",
          icon: Icons.settings,
          onTap: () => print("Tapped Settings 1"),
        ),
        Divider(
          height: 1,
          thickness: 1.5,
          color: dividerColor,
          indent: 15,
          endIndent: 15,
        ),
        _buildTile(
          title: "Refer a friend",
          icon: Icons.tune_rounded,
          onTap: () => print("Tapped Settings 2"),
        ),
        Divider(
          height: 1,
          thickness: 1.5,
          color: dividerColor,
          indent: 15,
          endIndent: 15,
        ),
        _buildTile(
          title: "Contact us",
          icon: Icons.mail_outline_outlined,
          onTap: () => print("Tapped Settings 3"),
        ),
      ],
    ),
  );
}
