import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_colors.dart';
import '../providers/toast_notification_provider.dart';

class AppToastOverlay extends ConsumerWidget {
  const AppToastOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toastState = ref.watch(toastNotificationProvider);

    return Positioned(
      top: 36,
      left: 0,
      right: 0,
      child: Center(
        child: IgnorePointer(
          ignoring: !toastState.isVisible,
          child: AnimatedSlide(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutBack,
            offset: toastState.isVisible ? Offset.zero : const Offset(0, -1.6),
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: toastState.isVisible ? 1.0 : 0.0,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 18,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.bgDark.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(
                      color: toastState.accentColor.withValues(alpha: 0.7),
                      width: 2.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.6),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                      BoxShadow(
                        color: toastState.accentColor.withValues(alpha: 0.25),
                        blurRadius: 18,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: toastState.accentColor.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          toastState.icon,
                          color: toastState.accentColor,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            toastState.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Poppins',
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            toastState.message,
                            style: const TextStyle(
                              color: AppColors.textYellow,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
