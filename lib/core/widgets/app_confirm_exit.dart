import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
            _TvGhostButton(
              label: 'Batal',
              autofocus: true,
              onPressed: () => Navigator.of(context).pop(false),
            ),
            const SizedBox(width: 8),
            _TvRedButton(
              label: 'Ya, Keluar',
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
      onPopInvoked: (didPop) async {
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

class _TvGhostButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  final bool autofocus;

  const _TvGhostButton({
    required this.label,
    required this.onPressed,
    this.autofocus = false,
  });

  @override
  State<_TvGhostButton> createState() => _TvGhostButtonState();
}

class _TvGhostButtonState extends State<_TvGhostButton> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      autofocus: widget.autofocus,
      onFocusChange: (hasFocus) => setState(() => _isFocused = hasFocus),
      onPressed: widget.onPressed,
      style: TextButton.styleFrom(
        foregroundColor: _isFocused ? Colors.blue.shade900 : Colors.black87,
        backgroundColor: _isFocused ? Colors.blue.shade50 : Colors.transparent,
        side: BorderSide(
          color: _isFocused ? Colors.blue : Colors.transparent,
          width: 3,
        ),
      ),
      child: Text(
        widget.label,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _TvRedButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;

  const _TvRedButton({
    required this.label,
    required this.onPressed,
  });

  @override
  State<_TvRedButton> createState() => _TvRedButtonState();
}

class _TvRedButtonState extends State<_TvRedButton> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onFocusChange: (hasFocus) => setState(() => _isFocused = hasFocus),
      onPressed: widget.onPressed,
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: _isFocused ? Colors.red.shade900 : Colors.red,
        side: BorderSide(
          color: _isFocused ? Colors.black : Colors.transparent,
          width: 3,
        ),
      ),
      child: Text(
        widget.label,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }
}
