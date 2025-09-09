import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notesapp/core/Theme/gradients.dart';
import 'package:notesapp/core/Theme/icon_paths.dart';
import 'package:notesapp/core/Theme/theme_constants.dart';
import 'package:notesapp/core/controllers/theme_provider.dart';
import 'package:notesapp/core/extensions/context_extensions.dart';
import 'package:notesapp/root/screens/Load_test/coin_animation.dart';
import 'package:notesapp/root/widgets/nothing_to_see.dart';
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
        context.isLight ? Gradients.lightBackground : Gradients.darkChatBackground;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text("Load Test"),
        actions: [
          IconButton(
            icon: Icon(
              context.isLight ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
            ),
            onPressed: () =>
                ref.read(themeNotifierProvider.notifier).toggleTheme(),
          ),
        ],
      ),
      body: SmartRefresher(
        controller: _refreshController,
        enablePullDown: true,
        header: const TwoLevelHeader(
          decoration: BoxDecoration(color: Colors.white),
        ),
        onRefresh: () async {
          await Future.delayed(const Duration(seconds: 1));
          _refreshController.refreshCompleted();
        },
        child: SingleChildScrollView(
          child: Container(
            width: ThemeConstants.screenWidth,
            decoration: BoxDecoration(gradient: backgroundGradient),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                ElevatedButton(onPressed: () => _refreshController.requestRefresh(), child: Row(children: [Icon(Icons.refresh), Text("Refresh")],)),
                Image.asset(IconPaths.coin),
                CoinAnimation(),
                // const NothingToSee(),
                // const NothingToSee(),
                // const NothingToSee(),
                // const NothingToSee(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
