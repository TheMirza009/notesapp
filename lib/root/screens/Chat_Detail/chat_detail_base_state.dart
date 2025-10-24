
import 'dart:io';
import 'package:notesapp/core/controllers/isar_database.dart';
import 'package:notesapp/core/controllers/media_handler.dart';
import 'package:notesapp/root/data/chat_list_provider/chat_list_notifier.dart';
import 'package:notesapp/root/data/enums/bubble_color.dart';
import 'package:notesapp/root/data/models/chat_model.dart';
import 'package:notesapp/root/data/models/message_model.dart';
import 'package:notesapp/root/screens/Chat_Detail/screens/chat_detail_screen_divided.dart';
import 'package:notesapp/root/screens/Chat_screen/notifier/chat_state_notifier.dart';
import 'package:notesapp/root/screens/Chat_screen/notifier/chat_state_notifier_o.dart';
import 'package:notesapp/root/screens/Profile/profile_screen.dart';
import 'package:notesapp/root/screens/Profile/profile_screen_state.dart';
import 'package:notesapp/root/widgets/crop/crop_screen.dart';
import 'package:notesapp/root/widgets/crop/croppyImage.dart';
import 'package:notesapp/root/widgets/photo_view/croppy_example.dart';
import 'package:photo_view/photo_view.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:notesapp/core/Theme/theme_constants.dart';
import 'package:notesapp/core/extensions/context_extensions.dart';
import 'package:notesapp/core/utils/utils.dart';
import 'package:notesapp/root/data/models/media_model.dart' show Media;
import 'package:notesapp/root/screens/Chat_Detail/chat_detail_notifier.dart';
import 'package:notesapp/root/screens/Chat_Detail/chat_detail_screen.dart';
import 'package:notesapp/root/screens/Chat_Forward/chat_forward_screen.dart';
import 'package:notesapp/root/screens/Homescreen/components/doc_icon.dart';

/// ---------------------------------------------------------------------------
/// ChatDetailBase
///
/// This class contains the instance fields and methods for the state so it can
/// be moved into a separate file (e.g. `chat_detail_base.dart`) if you wish.
/// Simply move this class to another file and import it; then keep
/// `_ChatDetailScreenState extends ChatDetailBase`.
/// ---------------------------------------------------------------------------
abstract class ChatDetailBase extends ConsumerState<ChatDetailScreen> {
  late final TextEditingController titleController;
  final ScrollController scrollController = ScrollController();
  bool isEditing = false;
  static const TextStyle subStyle = TextStyle(color: ThemeConstants.iconColorNeutral, fontSize: 13);

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.chat.title ?? "New Chat");

    if (widget.scrollToMedia == true) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        scrollHeaderToTop();
      });
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  void scrollHeaderToTop() {
    // Animate until the header is pinned (guard for scrollable extents)
    final maxExtent = scrollController.hasClients ? scrollController.position.maxScrollExtent : 0.0;
    scrollController.animateTo(
      maxExtent,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOutQuad,
    );
  }

  void startEditing() {
    setState(() => isEditing = true);
    // move caret to end
    Future.delayed(Duration.zero, () {
      titleController.selection = TextSelection.fromPosition(
        TextPosition(offset: titleController.text.length),
      );
    });
  }

  void finishEditing(ChatDetailNotifier notifier) {
    final newText = titleController.text.trim();
    notifier.updateTitle(newText);
    setState(() => isEditing = false);
  }

  /// Build profile image for hero wrapper. `path` can be null.
  Widget buildProfileImage(BuildContext context, String? path, {bool expanded = false}) {
  final isLight = context.isLight;

  if (expanded) {
    final double availableHeight = context.screenHeight - 200;

    // ✅ If no photo is selected, show the DocumentIcon in PhotoView
    if (path == null || path.isEmpty) {
      return SizedBox(
        height: availableHeight,
        width: context.screenWidth,
        child: Center(
          child: Material(
            color: Colors.transparent,
            clipBehavior: Clip.antiAlias,
            child: DocumentIcon(
              size: availableHeight / 2,
              borderWidth: 6,
              iconPadding: const EdgeInsets.all(24),
            ),
          ),
        ),
      );
    }

    // ✅ Otherwise, show the selected image
    final ImageProvider provider = FileImage(File(path));

    return SizedBox(
      height: availableHeight,
      width: context.screenWidth,
      child: PhotoView(
        gestureDetectorBehavior: HitTestBehavior.opaque,
        imageProvider: provider,
        minScale: PhotoViewComputedScale.contained,
        initialScale: PhotoViewComputedScale.contained,
        maxScale: PhotoViewComputedScale.covered * 3,
        tightMode: true,
        backgroundDecoration: const BoxDecoration(color: Colors.transparent),
      ),
    );
  }

  // Compact version (non-expanded)
  final double size = context.screenHeight / 4;

  final Widget image = (path != null && path.isNotEmpty)
      ? ExtendedImage.file(
          File(path),
          key: ValueKey<String>(path),
          width: size,
          height: size,
          fit: BoxFit.cover,
          cacheRawData: true,
        )
      : DocumentIcon(
          size: context.screenHeight / 3,
          borderWidth: 12,
          iconPadding: const EdgeInsets.all(26),
        );

  return Container(
    height: size,
    width: size,
    decoration: const BoxDecoration(shape: BoxShape.circle),
    clipBehavior: Clip.antiAlias,
    child: image,
  );
}

}


  void handleGalleryOptions(BuildContext context, WidgetRef ref, String value, Media image) async {
    switch (value) {
      case "shareImage":
        await Utils.shareToApps(XFile(image.path!));
        break;
      case "deleteImage":
        await image.messagesBacklink.load();  
        final message = image.messagesBacklink.isNotEmpty ? image.messagesBacklink.first : null; 
        if (message == null) {
          debugPrint("No linked message found for this image.");
          return;
        }
        if (!context.mounted) return; // Prevent navigation if context is disposed

        await ref.read(chatStateController.notifier).deleteMessage(message);
        // ref.invalidate(chatStateController);
        ref.read(chatDetailProvider.notifier).getMedia();
        Navigator.pop(context);
        break;
      case "forwardimage":
        await image.messagesBacklink.load();  
        final message = image.messagesBacklink.isNotEmpty ? image.messagesBacklink.first : null; 
        if (message == null) {
          debugPrint("No linked message found for this image.");
          return;
        }
        if (!context.mounted) return; // Prevent navigation if context is disposed

        // Navigate to the forwarding screen
        Navigator.push(
          context,
          CupertinoPageRoute(
            builder: (_) => ChatForwardScreen(message: message),
          ),
        );
        break;
      case 'setChatPhoto':
         final media = await MediaHandler.cropAndSavePhoto(image.path!);
         if (media == null) return;

         await ref.read(chatDetailProvider.notifier).saveAndUpdateChatPhoto(media);
         Navigator.pop(context);
         break;
      case 'setProfilePhoto':
        final media = await MediaHandler.cropAndSavePhoto(image.path!);
         if (media == null) return;
         await saveNewProfilePhoto(ref, media);
        Navigator.push(
          context,
          CupertinoPageRoute(builder: (_) => ProfileScreen()),
        );
      case 'croppy':
        final media = await MediaHandler.cropAndSavePhoto(image.path!, isProfilePicture: false);
        if (media == null) return;

        final Message message = Message.fromCroppedImage(media);
        Navigator.push(
          context,
          CupertinoPageRoute(builder: (_) => ChatForwardScreen(message: message)),
        );
      //  await ref.read(chatStateController.notifier).forwardMessage(original: message, targetChat: ref.read(chatListProvider).selectedChat!);

    default:
  }
}

void handleChatBackgroundAction(
  BuildContext context,
  WidgetRef ref,
  String value,
) async {
  switch (value) {
    case "chooseNew":
      Navigator.push(
        context,
        CupertinoPageRoute(builder: (_) => CropScreen(isChatBackground: true)),
      );
      break;
    case "clearBackground":
      final Chat? selectedChat = ref.read(chatListProvider).selectedChat;
      final isar = IsarDatabase.isar;
      if (selectedChat == null) return;
      final managedChat = await isar.chats.get(selectedChat.isarID);
      if (managedChat == null) return;

      // Update chat photo
      await isar.writeTxn(() async {
        managedChat.chatBackgroundPath = null;
        await isar.chats.put(managedChat);
      });

      // Refresh chat in provider
      ref.read(chatListProvider.notifier).refreshChat(managedChat.isarID);

    default:
  }
}

void handleBubbleColor(
  BuildContext context,
  WidgetRef ref,
  String value,
) async {
  switch (value) {
    case "seed":
      ref.read(chatStateController.notifier).setBubbleColor(scheme: BubbleColor.seed);
      break;
    case "red":
      ref.read(chatStateController.notifier).setBubbleColor(scheme: BubbleColor.red);
      break;
    case "amber":
      // ref.read(chatStateController.notifier).setBubbleColor(scheme: BubbleColor.amber);
      ref.read(chatStateController.notifier).setBubbleColor(scheme: BubbleColor.amber);
      break;
    default:
  }
}


class SlowMaterialPageRoute<T> extends MaterialPageRoute<T> {
  SlowMaterialPageRoute({
    required super.builder,
    super.settings,
  });

  @override
  Duration get transitionDuration => const Duration(milliseconds: 600);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 400);

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) {
    // Apply a custom curve to Material's default fade/slide
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    return super
        .buildTransitions(context, curved, secondaryAnimation, child);
  }
}