import 'package:flutter/material.dart';
import 'package:notesapp/core/Theme/icon_paths.dart';
import 'package:notesapp/core/extensions/context_extensions.dart';

class ProfileScreen extends StatelessWidget {
  final void Function()? onClose;
  const ProfileScreen({super.key, this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blueGrey,
        borderRadius: BorderRadius.circular(30),
      ),
      height: context.screenHeight,
      width: context.screenWidth, // 400,
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.all(5.0),
                child: Text("Profile", style: TextStyle(fontSize: 30)),
              ),
              IconButton.filled(
                style: IconButton.styleFrom(backgroundColor: Colors.white),
                color: Colors.black,
                onPressed: onClose,
                icon: Icon(Icons.clear),
              ),
            ],
          ),
          Divider(color: Colors.white,),
          SizedBox(height: 20),
          Center(child: SizedBox(height: 200,)),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SizedBox(
              height: 500,
              child: ListView.builder(
                physics: BouncingScrollPhysics(),
                itemCount: 50,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text("Entry $index"),
                  );
                }),
            ),
          )
        ],
      ),
    );
  }
}
