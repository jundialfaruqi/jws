import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/app_offline_banner.dart';
import '../../../core/widgets/tv_scaffold.dart';
import '../widgets/main_content_widget.dart';

class MainScreen extends ConsumerWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TvScaffold(
      body: Column(
        children: [
          AppOfflineBanner(
            onRetry: () {
              // Reload logika di sini
            },
          ),
          const MainContentWidget(),
        ],
      ),
    );
  }
}
