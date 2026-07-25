import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'tv/tv_button.dart';

class AppConfirmExit extends StatelessWidget {
  final Widget child;

  const AppConfirmExit({super.key, required this.child});

  Future<bool> _showExitDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent, // Menghilangkan efek tint bawaan Material 3
          title: const Text(
            'Keluar Aplikasi',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'Apakah Anda yakin ingin keluar dari aplikasi?',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TvButton(
              label: 'Batal',
              autofocus: true,
              variant: TvButtonVariant.ghost,
              fontSize: 16,
              onPressed: () => Navigator.of(context).pop(false),
            ),
            const SizedBox(width: 8),
            TvButton(
              label: 'Ya, Keluar',
              variant: TvButtonVariant.danger,
              fontSize: 16,
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    ) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final bool shouldExit = await _showExitDialog(context);
        if (shouldExit) {
          SystemNavigator.pop(); // Menutup aplikasi secara paksa
        }
      },
      child: child,
    );
  }
}
