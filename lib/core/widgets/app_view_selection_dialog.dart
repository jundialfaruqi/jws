import 'package:flutter/material.dart';
import 'tv/tv_button.dart';

class AppViewSelectionDialog extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onPrimarySelected;
  final VoidCallback onSecondarySelected;
  final String primaryLabel;
  final String secondaryLabel;

  const AppViewSelectionDialog({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onPrimarySelected,
    required this.onSecondarySelected,
    required this.primaryLabel,
    required this.secondaryLabel,
  });

  static Future<void> show(
    BuildContext context, {
    required String title,
    required String subtitle,
    required VoidCallback onPrimarySelected,
    required VoidCallback onSecondarySelected,
    String primaryLabel = 'Tampilkan Aplikasi',
    String secondaryLabel = 'Tampilkan Web',
  }) {
    return showDialog(
      context: context,
      builder: (context) => AppViewSelectionDialog(
        title: title,
        subtitle: subtitle,
        onPrimarySelected: onPrimarySelected,
        onSecondarySelected: onSecondarySelected,
        primaryLabel: primaryLabel,
        secondaryLabel: secondaryLabel,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      content: Text(
        subtitle,
        style: const TextStyle(fontSize: 16),
      ),
      actions: [
        TvButton(
          label: secondaryLabel,
          variant: TvButtonVariant.ghost,
          fontSize: 16,
          onPressed: () {
            Navigator.of(context).pop();
            onSecondarySelected();
          },
        ),
        const SizedBox(width: 8),
        TvButton(
          label: primaryLabel,
          autofocus: true,
          variant: TvButtonVariant.primary,
          fontSize: 16,
          onPressed: () {
            Navigator.of(context).pop();
            onPrimarySelected();
          },
        ),
      ],
    );
  }
}
