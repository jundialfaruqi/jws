import 'package:flutter/material.dart';
import 'tv_focus_wrapper.dart';

enum TvButtonVariant { primary, danger, ghost }

class TvButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onPressed;
  final TvButtonVariant variant;
  final bool autofocus;
  final double fontSize;

  const TvButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = TvButtonVariant.primary,
    this.autofocus = false,
    this.fontSize = 24,
  });

  @override
  Widget build(BuildContext context) {
    return TvFocusWrapper(
      autofocus: autofocus,
      onTap: onPressed,
      borderRadius: BorderRadius.circular(100), // Bentuk pill membulat
      builder: (context, isFocused) {
        Color bgColor;
        Color fgColor;
        Color borderColor;

        switch (variant) {
          case TvButtonVariant.primary:
            bgColor = isFocused ? Colors.blue.shade600 : Colors.blue.shade50;
            fgColor = isFocused ? Colors.white : Colors.blue.shade900;
            borderColor = isFocused ? Colors.blue.shade900 : Colors.transparent;
            break;
          case TvButtonVariant.danger:
            bgColor = isFocused ? Colors.red.shade900 : Colors.red;
            fgColor = Colors.white;
            borderColor = isFocused ? Colors.black : Colors.transparent;
            break;
          case TvButtonVariant.ghost:
            bgColor = isFocused ? Colors.blue.shade50 : Colors.transparent;
            fgColor = isFocused ? Colors.blue.shade900 : Colors.black87;
            borderColor = isFocused ? Colors.blue : Colors.transparent;
            break;
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: borderColor, width: 3),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: fontSize + 4, color: fgColor),
                const SizedBox(width: 12),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.bold,
                  color: fgColor,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
