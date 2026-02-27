// chat_media_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notesapp/core/Theme/icon_paths.dart';
import 'package:notesapp/core/Theme/theme_constants.dart';
import 'package:notesapp/core/extensions/context_extensions.dart';
import 'package:notesapp/core/extensions/media_extensions.dart';
import 'package:notesapp/core/utils/context_menu_options.dart';
import 'package:notesapp/core/utils/utils.dart';
import 'package:notesapp/root/data/models/chat_model.dart';
import 'package:notesapp/root/data/models/media_model.dart';
import 'package:notesapp/root/presentation/screens/Chat_Detail/chat_detail_base_state.dart';
import 'package:notesapp/root/presentation/screens/Chat_Detail/chat_detail_notifier.dart';
import 'package:notesapp/root/presentation/screens/Chat_Detail/chat_detail_screen.dart';
import 'package:notesapp/root/presentation/widgets/photo_view/gallery_view_wrapper.dart';
import 'package:open_file/open_file.dart';
import 'package:svg_flutter/svg.dart';

class ChatMediaScreen extends ConsumerStatefulWidget {
  final Chat chat;
  const ChatMediaScreen({super.key, required this.chat});

  @override
  ConsumerState<ChatMediaScreen> createState() => _ChatMediaScreenState();
}

class _ChatMediaScreenState extends ConsumerState<ChatMediaScreen> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chatDetailProvider);
    final photoMessages = state.photos;
    final docMessages = state.documents;
    final isLight = context.isLight;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text("${widget.chat.title} - Media"),
          bottom: TabBar(
            indicatorSize: TabBarIndicatorSize.label,
            dividerColor: isLight
                ? ThemeConstants.homeSearchbarLight
                : ThemeConstants.darkAppbar,
            dividerHeight: 1,
            tabs: const [Tab(text: "Photos"), Tab(text: "Documents")],
          ),
        ),
        body: TabBarView(
          children: [
            // Photos tab
            photoMessages.isEmpty
                ? Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SvgPicture.string(
                          IconPaths.catSitting,
                          color: ThemeConstants.iconLight,
                          height: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text("No Photos in chat yet"),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(8),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 2,
                      crossAxisSpacing: 2,
                    ),
                    itemCount: photoMessages.length,
                    itemBuilder: (context, index) {
                      final media = photoMessages[index];
                      final path = media.path;
                      return Container(
                        margin: const EdgeInsets.all(0.75),
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: InkWell(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => GalleryViewWrapper(
                                chatTitle: widget.chat.title ?? '',
                                galleryItems: photoMessages,
                                initialIndex: index,
                                showOptions: true,
                                options: galleryOptions,
                                onOptionSelect: (value) => handleGalleryOptions(
                                  context,
                                  ref,
                                  value,
                                  photoMessages[index],
                                ),
                              ),
                            ),
                          ),
                          child: FadeInDynamic.filePath(path, index: index),
                        ),
                      );
                    },
                  ),

            // Documents tab
            docMessages.isEmpty
                ? Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SvgPicture.string(
                          IconPaths.catSitting,
                          color: ThemeConstants.iconLight,
                          height: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text("No Documents in chat yet"),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: docMessages.length + 1,
                    itemBuilder: (context, index) {
                      if (index == docMessages.length) {
                        return const SizedBox(height: 100);
                      }

                      final doc = docMessages[index];
                      return FadeInDynamic.widget(
                        Card(
                          elevation: 1,
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            onTap: () async {
                              if (doc.path != null && doc.path!.isNotEmpty) {
                                await OpenFile.open(doc.path);
                              }
                            },
                            leading: const Icon(
                              Icons.insert_drive_file,
                              color: Colors.red,
                            ),
                            title: Text(
                              doc.name ?? "Unknown file",
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                            subtitle: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    if (doc.path != null && doc.path!.isNotEmpty)
                                      FutureBuilder<String>(
                                        future: Utils.getFileSize(doc.path!),
                                        builder: (context, snapshot) {
                                          if (snapshot.connectionState ==
                                              ConnectionState.waiting) {
                                            return const Text(
                                              'Loading size...',
                                              style: ChatDetailBase.subStyle,
                                            );
                                          } else if (snapshot.hasError) {
                                            return const Text(
                                              'Size unknown',
                                              style: ChatDetailBase.subStyle,
                                            );
                                          } else {
                                            return Text(
                                              snapshot.data ?? '',
                                              style: ChatDetailBase.subStyle,
                                            );
                                          }
                                        },
                                      ),
                                    const SizedBox(width: 8),
                                    Text(
                                      doc.extension?.toUpperCase() ?? "",
                                      style: ChatDetailBase.subStyle,
                                    ),
                                  ],
                                ),
                                Text(
                                  doc.timeString ?? '',
                                  style: ChatDetailBase.subStyle,
                                ),
                              ],
                            ),
                          ),
                        ),
                        index: index,
                        isImage: false,
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }
}