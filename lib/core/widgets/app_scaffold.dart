import 'package:flutter/material.dart';
import 'app_offline_banner.dart';

class AppScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget body;
  final Color backgroundColor;

  const AppScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.backgroundColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: appBar,
      body: Column(
        children: [
          // Banner otomatis muncul di atas seluruh body halaman (tanpa menimpa AppBar)
          AppOfflineBanner(
            onRetry: () {},
          ),
          Expanded(child: body),
        ],
      ),
    );
  }
}
