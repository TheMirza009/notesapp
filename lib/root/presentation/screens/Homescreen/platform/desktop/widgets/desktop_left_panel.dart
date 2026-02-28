// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:notesapp/core/Theme/gradients.dart';
// import 'package:notesapp/core/Theme/theme_constants.dart';
// import 'package:notesapp/core/utils/context_menu_options.dart';
// import 'package:notesapp/core/utils/time_format.dart';
// import 'package:notesapp/root/data/chat_list_provider/chat_list_notifier.dart';
// import 'package:notesapp/root/data/enums/chatlist_filter.dart';
// import 'package:notesapp/root/data/models/chat_model.dart';
// import 'package:notesapp/root/data/models/message_model.dart';
// import 'package:notesapp/root/presentation/screens/Homescreen/components/chat_list/doc_icon.dart';
// import 'package:notesapp/root/presentation/screens/Homescreen/platform/desktop/homescreen_desktop.dart';
// import 'package:notesapp/root/presentation/widgets/context_menus/custom_context_menu.dart';
// import 'package:notesapp/root/presentation/widgets/nothing_to_see.dart';
// import 'package:typeset/typeset.dart';

// class DesktopLeftPanel extends ConsumerStatefulWidget {
//   final bool isLight;

//   const DesktopLeftPanel({
//     super.key,
//     required this.isLight,
//   });

//   @override
//   ConsumerState<DesktopLeftPanel> createState() => _DesktopLeftPanelState();
// }

// class _DesktopLeftPanelState extends ConsumerState<DesktopLeftPanel> {
//   late final TextEditingController _searchController;
//   late final FocusNode _searchFocusNode;

//   @override
//   void initState() {
//     super.initState();
//     _searchController = TextEditingController();
//     _searchFocusNode = FocusNode();
//   }

//   @override
//   void dispose() {
//     _searchController.dispose();
//     _searchFocusNode.dispose();
//     super.dispose();
//   }

//   // ─── LOGIC METHODS ─────────────────────────────────────────────────────────

//   void _handleSearch(String value) async {
//     final chatNotifier = ref.read(chatListProvider.notifier);
//     if (value.isNotEmpty) {
//       await chatNotifier.searchMessages(value);
//     } else {
//       chatNotifier.clearSearch();
//     }
//     setState(() {}); // Refresh trailing icon state
//   }

//   void _clearSearch() {
//     _searchController.clear();
//     ref.read(chatListProvider.notifier).clearSearch();
//     setState(() {});
//   }

//   void _createNewChat() {
//     // Logic for creating new chat
//   }

//   void _selectChat(dynamic chat) {
//     // Logic for selecting chat
//   }

//   void _deleteChatWithFade(dynamic chat) {
//     // Logic for deletion animation
//   }

//   GlobalKey _getChatKey(dynamic chat) => GlobalKey(); // Placeholder for your logic

//   @override
//   Widget build(BuildContext context) {
//     final chatNotifier = ref.read(chatListProvider.notifier);
//     final chatlist = ref.watch(chatListProvider.select((state) => state.chats));
//     final isLoading = ref.watch(chatListProvider.select((state) => state.isLoading));
//     final searchResults = ref.watch(chatListProvider.select((state) => state.searchResults));

//     // Styles & Colors
//     final headerColor = widget.isLight ? ThemeConstants.hometoolbarLight2 : ThemeConstants.darkAppbar;
//     final dividerColor = widget.isLight ? ThemeConstants.homeDividerLight : ThemeConstants.darkIconBorder;
//     const accentColor = Color(0xFF00BCD4);

//     return Container(
//       width: 340,
//       clipBehavior: Clip.antiAlias,
//       decoration: BoxDecoration(
//         gradient: widget.isLight ? Gradients.lightBackground : Gradients.darkBackground,
//         color: headerColor,
//         borderRadius: const BorderRadius.only(topLeft: Radius.circular(10)),
//         border: Border(right: BorderSide(color: dividerColor)),
//       ),
//       child: Column(
//         children: [
//           // ─── SEARCH & FILTER ───────────────────────────────────────────────
//           Padding(
//             padding: const EdgeInsets.fromLTRB(12, 12, 0, 8),
//             child: Row(
//               children: [
//                 Expanded(
//                   child: SizedBox(
//                     height: 40,
//                     child: SearchBar(
//                       focusNode: _searchFocusNode,
//                       controller: _searchController,
//                       shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
//                       padding: const WidgetStatePropertyAll(EdgeInsets.zero),
//                       shadowColor: const WidgetStatePropertyAll(Colors.transparent),
//                       backgroundColor: WidgetStatePropertyAll(headerColor),
//                       leading: const Padding(
//                         padding: EdgeInsets.symmetric(horizontal: 10.0),
//                         child: Icon(Icons.search, color: ThemeConstants.iconLight),
//                       ),
//                       trailing: [
//                         if (_searchController.text.isNotEmpty)
//                           IconButton(icon: const Icon(Icons.clear_rounded), onPressed: _clearSearch)
//                       ],
//                       hintText: "Search in notes...",
//                       hintStyle: const WidgetStatePropertyAll(TextStyle(
//                         color: ThemeConstants.iconLight,
//                         fontWeight: FontWeight.w500,
//                       )),
//                       onChanged: _handleSearch,
//                     ),
//                   ),
//                 ),
//                 IconButton(
//                   onPressed: () => CustomContextMenu.showMenuAt(
//                     context,
//                     position: const Offset(340, kToolbarHeight),
//                     showTail: false,
//                     menuItems: chatFilterOptions,
//                     onSelected: (value) {
//                       final filter = ChatlistFilter.values.firstWhere((f) => f.name == value);
//                       chatNotifier.applyFilter(filter);
//                     },
//                     triangleHorizontalOffset: 200,
//                   ),
//                   icon: const Icon(Icons.filter_list, color: ThemeConstants.iconLight),
//                 ),
//               ],
//             ),
//           ),

//           // ─── SECTION LABEL ─────────────────────────────────────────────────
//           const Padding(
//             padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
//             child: Align(
//               alignment: Alignment.centerLeft,
//               child: Text(
//                 "RECENT",
//                 style: TextStyle(
//                   fontSize: 11,
//                   fontWeight: FontWeight.w600,
//                   letterSpacing: 1.2,
//                   color: ThemeConstants.subtitleLight,
//                 ),
//               ),
//             ),
//           ),

//           // ─── CONTENT AREA (LIST) ───────────────────────────────────────────
//           Expanded(
//             child: isLoading
//                 ? const Center(child: CircularProgressIndicator())
//                 : chatlist.isEmpty
//                     ? const NothingToSee()
//                     : ListView.separated(
//                         itemCount: chatlist.length,
//                         separatorBuilder: (_, __) => Divider(
//                           thickness: 0.5,
//                           indent: 24,
//                           height: 1,
//                           color: dividerColor,
//                         ),
//                         itemBuilder: (context, index) {
//                           final chat = chatlist[index];
//                           final matchingMessages = searchResults[chat] ?? [];
//                           final isSelected = ref.watch(chatListProvider.select((s) => s.selectedChat?.isarID == chat.isarID));

//                           return TweenAnimationBuilder<double>(
//                             duration: const Duration(milliseconds: 300),
//                             tween: Tween(
//                               begin: chatNotifier.isDeleting[chat.isarID] == true ? 1.0 : 0.0,
//                               end: chatNotifier.isDeleting[chat.isarID] == true ? 0.0 : 1.0,
//                             ),
//                             builder: (context, value, child) => Opacity(opacity: value, child: child),
//                             child: matchingMessages.isEmpty
//                                 ? DesktopChatTile(
//                                     key: ValueKey(chat.isarID),
//                                     chatTileKey: _getChatKey(chat),
//                                     chat: chat,
//                                     isSelected: isSelected,
//                                     onTap: () => _selectChat(chat),
//                                     onDismissed: (_) => chatNotifier.deleteChatWithUndo(chat),
//                                     onRightClick: (position) => CustomContextMenu.showMenuAt(
//                                       context,
//                                       position: position,
//                                       menuItems: chatTileOptions(chat),
//                                       onSelected: (value) {
//                                         if (value == "delete") _deleteChatWithFade(chat);
//                                         chatNotifier.handleChatHoldOptions(value, chat);
//                                       },
//                                     ),
//                                   )
//                                 : _buildSearchResultTile(chat, matchingMessages), // Rule #1: Shared internal helper allowed
//                           );
//                         },
//                       ),
//           ),

//           // ─── FOOTER (NEW NOTE) ─────────────────────────────────────────────
//           Padding(
//             padding: const EdgeInsets.all(12.0),
//             child: SizedBox(
//               width: double.infinity,
//               height: 42,
//               child: ElevatedButton.icon(
//                 onPressed: _createNewChat,
//                 icon: const Icon(Icons.add, size: 18),
//                 label: const Text(
//                   "New Note",
//                   style: TextStyle(fontFamily: "Poppins", fontWeight: FontWeight.w500),
//                 ),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: accentColor,
//                   foregroundColor: Colors.white,
//                   elevation: 0,
//                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

  
//   Widget _buildSearchResultTile(Chat chat, List<Message> matchingMessages) {
//     final isLight = Theme.of(context).brightness == Brightness.light;
//     final dividerColor = isLight
//         ? ThemeConstants.homeDividerLight
//         : ThemeConstants.darkIconBorder;

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Padding(
//           padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 14),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               TypeSet(
//                 "_${matchingMessages.length} matches found",
//                 style: TextStyle(
//                     fontSize: 11, color: ThemeConstants.subtitleLight),
//               ),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Row(
//                     spacing: 8,
//                     crossAxisAlignment: CrossAxisAlignment.end,
//                     children: [
//                       chat.chatPhotoPath == null
//                           ? const DocumentIcon(
//                               size: 20,
//                               iconPadding: EdgeInsets.all(2),
//                               borderWidth: 1.5)
//                           : Container(
//                               margin: const EdgeInsets.only(top: 4),
//                               height: 20,
//                               width: 20,
//                               clipBehavior: Clip.antiAlias,
//                               decoration: const BoxDecoration(
//                                   shape: BoxShape.circle),
//                               child: Image.file(
//                                   File(chat.chatPhotoPath!),
//                                   fit: BoxFit.cover),
//                             ),
//                       Text(
//                         chat.title ?? "New Note",
//                         style: const TextStyle(fontSize: 14),
//                       ),
//                     ],
//                   ),
//                   Text(
//                     TimeFormat.formatChatTime(chat.date),
//                     style: TextStyle(
//                         fontSize: 11,
//                         color: ThemeConstants.subtitleLight),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//         Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 4),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: matchingMessages
//                 .map((message) => _buildMessagePreview(
//                     message, _searchController.text, chat))
//                 .toList(),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildMessagePreview(Message message, String query, Chat chat) {
//     final isLight = Theme.of(context).brightness == Brightness.light;
//     final dividerColor = isLight
//         ? ThemeConstants.homeDividerLight
//         : ThemeConstants.darkIconBorder;

//     return Column(
//       children: [
//         Divider(
//             thickness: 0.5,
//             height: 2,
//             color: dividerColor.withOpacity(0.5),
//             indent: 10,
//             endIndent: 10),
//         Material(
//           color: Colors.transparent,
//           borderRadius: BorderRadius.circular(6),
//           clipBehavior: Clip.antiAlias,
//           child: InkWell(
//             onTap: () async {
//               await _selectChat(chat);
//               ref
//                   .read(chatListProvider.notifier)
//                   .navigateAndHighlight(context, message, chat);
//             },
//             child: Container(
//               width: double.infinity,
//               padding: const EdgeInsets.all(8.0),
//               child: Row(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   const SizedBox(width: 4),
//                   Expanded(
//                     child: Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         _buildHighlightedText(message.text, query, isLight),
//                         const SizedBox(height: 4),
//                         Text(
//                           TimeFormat.formatChatTime(message.time),
//                           style: TextStyle(
//                             fontSize: 10,
//                             color:
//                                 ThemeConstants.subtitleLight.withOpacity(0.6),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildHighlightedText(String text, String query, bool isLight) {
//     if (query.isEmpty) {
//       return Text(
//         text,
//         style:
//             TextStyle(fontSize: 12, color: ThemeConstants.subtitleLight),
//         maxLines: 2,
//         overflow: TextOverflow.ellipsis,
//       );
//     }

//     final lowercaseText = text.toLowerCase();
//     final lowercaseQuery = query.toLowerCase();
//     final List<TextSpan> spans = [];
//     int currentIndex = 0;

//     while (currentIndex < text.length) {
//       final queryIndex =
//           lowercaseText.indexOf(lowercaseQuery, currentIndex);
//       if (queryIndex == -1) {
//         spans.add(TextSpan(text: text.substring(currentIndex)));
//         break;
//       }
//       if (queryIndex > currentIndex) {
//         spans.add(
//             TextSpan(text: text.substring(currentIndex, queryIndex)));
//       }
//       spans.add(TextSpan(
//         text: text.substring(queryIndex, queryIndex + query.length),
//         style: TextStyle(
//           backgroundColor:
//               isLight ? Colors.yellow[300] : Colors.amber[700],
//           color: isLight ? Colors.black87 : Colors.white,
//           fontWeight: FontWeight.w600,
//         ),
//       ));
//       currentIndex = queryIndex + query.length;
//     }

//     return Expanded(
//       child: RichText(
//         text: TextSpan(
//           style: TextStyle(
//               overflow: TextOverflow.fade,
//               fontFamily: 'Poppins',
//               fontSize: 12,
//               color: ThemeConstants.subtitleLight),
//           children: spans,
//         ),
//         maxLines: 2,
//         overflow: TextOverflow.ellipsis,
//       ),
//     );
//   }
// }

