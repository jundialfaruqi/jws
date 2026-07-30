import 'package:flutter/material.dart';
import 'app_offline_banner.dart';
import 'audio_download_overlay.dart';

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
      body: Stack(
        children: [
          body,
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AppOfflineBanner(),
          ),
          const AudioDownloadOverlay(),
        ],
      ),
    );
  }
}
