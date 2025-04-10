import 'package:flutter/material.dart';

const List<PopupMenuItem<String>> dummyOptions = [
  PopupMenuItem<String>(value: 'Option 1', child: Text('Option 1')),
  PopupMenuItem<String>(value: 'Option 2', child: Text('Option 2')),
  PopupMenuItem<String>(value: 'Option 3', child: Text('Option 3')),
];

class CustomContextMenu extends StatelessWidget {
  final Icon icon;
  final List<PopupMenuEntry<String>> menuItems;
  /// Does not work without menuItems
  final void Function(String)? onSelected;

  const CustomContextMenu({
    Key? key,
    required this.icon,
    this.menuItems = dummyOptions,
    this.onSelected, /// Does not work without menuItems
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: icon,
      onSelected: onSelected,
      itemBuilder: (BuildContext context) => menuItems,
    );
  }
}
