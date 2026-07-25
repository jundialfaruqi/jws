import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class AppLoadingSpinner extends StatelessWidget {
  final double size;
  final String? message;

  const AppLoadingSpinner({
    super.key,
    this.size = 40.0,
    this.message,
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
                strokeWidth: 4,
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
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
