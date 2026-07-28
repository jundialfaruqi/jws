import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class AppLoadingSpinner extends StatelessWidget {
  final double size;
  final String? message;
  final double fontSize;

  const AppLoadingSpinner({
    super.key,
    this.size = 80.0,
    this.message,
    this.fontSize = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              width: size,
              height: size,
              child: const CircularProgressIndicator(
                strokeWidth: 6,
                strokeCap: StrokeCap.round, // Ujung garis loading melengkung elegan
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                backgroundColor: AppColors.ghost,
              ),
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: fontSize,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
