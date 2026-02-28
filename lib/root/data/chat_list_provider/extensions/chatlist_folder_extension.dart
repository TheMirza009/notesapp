// import 'package:notesapp/core/controllers/isar_database.dart';
// import 'package:notesapp/root/data/chat_list_provider/chat_list_notifier.dart';
// import 'package:notesapp/root/data/models/folder_model.dart';

// extension FolderExtension on ChatListNotifier {
//   // CREATE
//   Future<Folder> createFolder(String name) async {
//     final folder = await IsarDatabase.addNewFolder(name);
//     state = state.copyWith(folders: [...state.folders, folder]);
//     return folder;
//   }

//   // READ — called once on init, add to loadChats()
//   Future<void> loadFolders() async {
//     final folders = await IsarDatabase.loadAllFolders();
//     state = state.copyWith(folders: folders);
//   }

//   // UPDATE — rename
//   Future<void> renameFolder(Folder folder, String newName) async {
//     folder.name = newName;
//     await IsarDatabase.isar.writeTxn(() => IsarDatabase.isar.folders.put(folder));
//     state = state.copyWith(
//       folders: state.folders
//           .map((f) => f.isarID == folder.isarID ? folder : f)
//           .toList(),
//     );
//   }

//   // DELETE
//   Future<void> deleteFolder(Folder folder) async {
//     await IsarDatabase.isar.writeTxn(() async {
//       // Unlink all chats first — chats themselves are NOT deleted
//       folder.chats.clear();
//       await folder.chats.save();
//       await IsarDatabase.isar.folders.delete(folder.isarID);
//     });
//     state = state.copyWith(
//       folders: state.folders
//           .where((f) => f.isarID != folder.isarID)
//           .toList(),
//       // If this was the active folder, fall back to all chats
//       activeFolder: state.activeFolder?.isarID == folder.isarID
//           ? null
//           : state.activeFolder,
//       chats: state.activeFolder?.isarID == folder.isarID
//           ? _allChats
//           : state.chats,
//     );
//     if (state.activeFolder == null) applyFilter(_currentFilter);
//   }

//   // SELECT — drives state.chats downstream
//   Future<void> selectFolder(Folder folder) async {
//     await folder.chats.load();
//     _allChats = folder.chats.toList();
//     state = state.copyWith(activeFolder: folder);
//     applyFilter(_currentFilter); // re-sort the folder's chats
//   }

//   // CLEAR — back to all chats across all folders
//   Future<void> clearFolder() async {
//     _allChats = await IsarDatabase.loadAllChats();
//     state = state.copyWith(activeFolder: null);
//     applyFilter(_currentFilter);
//   }

//   // ASSIGN chat to folder
//   Future<void> addChatToFolder(Chat chat, Folder folder) async {
//     await IsarDatabase.addChatToFolder(chat, folder);
//     // Refresh the folder in state
//     await folder.chats.load();
//     state = state.copyWith(
//       folders: state.folders
//           .map((f) => f.isarID == folder.isarID ? folder : f)
//           .toList(),
//     );
//   }

//   // REMOVE chat from folder
//   Future<void> removeChatFromFolder(Chat chat, Folder folder) async {
//     await IsarDatabase.removeChatFromFolder(chat, folder);
//     await folder.chats.load();
//     state = state.copyWith(
//       folders: state.folders
//           .map((f) => f.isarID == folder.isarID ? folder : f)
//           .toList(),
//       // If we're currently viewing this folder, remove chat from active view
//       chats: state.activeFolder?.isarID == folder.isarID
//           ? state.chats.where((c) => c.isarID != chat.isarID).toList()
//           : state.chats,
//     );
//   }
// }