import 'package:flutter/material.dart';
import 'audio_download_overlay.dart';
import 'app_toast_overlay.dart';

class TvScaffold extends StatelessWidget {
  final Widget body;
  final Color backgroundColor;

  const TvScaffold({
    super.key,
    required this.body,
    this.backgroundColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Latar belakang luar jika rasio TV berbeda (letterbox)
      body: Center(
        child: FittedBox(
          fit: BoxFit.contain,
          clipBehavior: Clip.hardEdge,
          child: SizedBox(
            width: 1920, // Resolusi standar Full HD TV
            height: 1080,
            child: Scaffold(
              backgroundColor: backgroundColor,
              body: Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  body,
                  const AudioDownloadOverlay(),
                  const AppToastOverlay(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
