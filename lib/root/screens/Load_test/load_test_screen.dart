import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notesapp/core/Theme/gradients.dart';
import 'package:notesapp/core/controllers/theme_provider.dart';
import 'package:notesapp/core/extensions/context_extensions.dart';
import 'package:notesapp/root/screens/Load_test/widgets/custom_pull_to_refresh.dart';
import 'package:pull_to_refresh_flutter3/pull_to_refresh_flutter3.dart';

class LoadTestScreen extends ConsumerStatefulWidget {
  const LoadTestScreen({super.key});

  @override
  ConsumerState<LoadTestScreen> createState() => _LoadTestScreenState();
}

class _LoadTestScreenState extends ConsumerState<LoadTestScreen> {
  final RefreshController _refreshController = RefreshController();

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final backgroundGradient =
        context.isLight
            ? Gradients.lightBackground
            : Gradients.darkChatBackground;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text("Load Test"),
        actions: [
          IconButton(
            icon: Icon(
              context.isLight
                  ? Icons.dark_mode_outlined
                  : Icons.light_mode_outlined,
            ),
            onPressed:
                () => ref.read(themeNotifierProvider.notifier).toggleTheme(),
          ),
        ],
      ),
      body: CoinStackPullDown(
        triggerDistance: 100,
        onRefresh: () async {
          await Future.delayed(const Duration(seconds: 2));
        },
        coinSize: 15,
        coinCount: 15,
        backgroundColor: context.isLight ? Colors.white : Colors.deepOrange,
        // child: Center(child: CoinAnimation(coinSize: 50,))
        child: ListView.builder(
          physics: NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          itemCount: 10,
          itemBuilder: (context, index) => ListTile(title: Text("Item $index")),
        ),
      ),
    );
  }
}
