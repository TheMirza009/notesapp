import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/bxs.dart';
import 'package:iconify_flutter/icons/ph.dart';
import 'package:iconify_flutter/icons/mdi.dart';


class IconPaths {
  static const String root = "assets/";
  static const String iconRoot = "assets/icons";

  // Vectors
  static const String addNote = "$iconRoot/add_note.svg";
  static const String nothing = "$iconRoot/nothing.svg";

  // PNGs
  static const String addNoteLight = "$iconRoot/add_note_light.png";
  static const String addNoteDark = "$iconRoot/add_note_dark.png";
  static const String avatarLight = "$iconRoot/avatar_light.png";
  static const String avatarDark = "$iconRoot/avatar_dark.png";
  static const String coin = "$iconRoot/coin.png";

  // Cat Icons | Iconify
  static const catFull = Iconify(Bxs.cat);
  static const catFace = Iconify(Ph.cat) ;
  static const catFaceHappy = Iconify(Mdi.cat);
  static const catSitting = '''<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 16 16"><rect width="16" height="16" fill="none"/><path fill="currentColor" d="M3.64 15h8.043c.858 0 1.553-.696 1.553-1.554V6.914c1.407-.101 2.236-1.676 1.475-2.905l-.435-.702a1.9 1.9 0 0 0-1.619-.902h-1.176v-.483A.92.92 0 0 0 10.56 1a2.186 2.186 0 0 0-2.186 2.186v2.936c-1.096.123-1.93.652-2.542 1.388c-.688.826-1.09 1.899-1.33 2.924a15 15 0 0 0-.35 2.814c-.01.292-.01.548-.008.752h-.503a1.642 1.642 0 0 1-1.2-2.763l.797-.855a3.177 3.177 0 0 0-.076-4.412l-.782-.783a.5.5 0 1 0-.707.707l.783.783A2.176 2.176 0 0 1 2.508 9.7l-.798.855A2.643 2.643 0 0 0 3.64 15m6.841-12.997v.902a.5.5 0 0 0 .5.5h1.676c.313 0 .604.162.77.429l.435.702a.905.905 0 0 1-.77 1.383h-.355a.5.5 0 0 0-.5.5v7.027a.554.554 0 0 1-.554.554h-.553v-.554a2.607 2.607 0 0 0-2.607-2.608h-.878a.5.5 0 0 0 0 1h.878c.887 0 1.607.72 1.607 1.608V14H5.144c-.003-.193-.002-.437.007-.719c.024-.722.105-1.675.325-2.62c.222-.952.577-1.855 1.124-2.511c.531-.638 1.25-1.055 2.274-1.055a.5.5 0 0 0 .5-.5V3.186c0-.628.489-1.143 1.107-1.183"/></svg>''';
  static const roundedDoc = '''<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24"><rect width="24" height="24" fill="none"/><path fill="currentColor" fill-rule="evenodd" d="M12 2v5.054c0 .424 0 .837.046 1.177c.051.383.177.82.54 1.183s.8.489 1.184.54c.34.046.752.046 1.176.046H20v6c0 2.828 0 4.243-.879 5.121C18.243 22 16.828 22 14 22h-4c-2.828 0-4.243 0-5.121-.879C4 20.243 4 18.828 4 16V8c0-2.828 0-4.243.879-5.121C5.757 2 7.172 2 10 2zm2 .005V7c0 .5.002.774.028.964v.007l.008.001c.19.026.464.028.964.028h4.995c-.01-.412-.043-.684-.147-.937c-.152-.367-.441-.657-1.02-1.235l-2.656-2.656c-.578-.578-.867-.868-1.235-1.02c-.253-.105-.525-.137-.937-.147M8 13a1 1 0 0 1 1-1h6a1 1 0 1 1 0 2H9a1 1 0 0 1-1-1m1 3a1 1 0 1 0 0 2h4a1 1 0 1 0 0-2z" clip-rule="evenodd"/></svg>''';
}