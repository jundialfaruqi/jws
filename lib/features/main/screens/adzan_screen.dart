import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/tv_scaffold.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/prayer_transition_service.dart';
import '../../../core/time/time_sync_service.dart';

class AdzanScreen extends ConsumerWidget {
  const AdzanScreen({super.key});

  String _formatCountdown(int totalSeconds) {
    int minutes = totalSeconds ~/ 60;
    int seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transitionState = ref.watch(prayerTransitionProvider);
    final now = ref.watch(timeSyncServiceProvider).now();

    String displayPrayerName = transitionState.prayerName.isEmpty
        ? 'MAGHRIB'
        : transitionState.prayerName;

    if (displayPrayerName == 'DZUHUR' && now.weekday == DateTime.friday) {
      displayPrayerName = "JUM'AT";
    }

    double progress = transitionState.totalSeconds > 0
        ? ((transitionState.totalSeconds - transitionState.remainingSeconds) /
            transitionState.totalSeconds)
        : 0.5; // 50% untuk preview

    // ScaffoldTV akan otomatis menjaga resolusi tetap 1920x1080 (Full HD)
    // berapapun rasio layar aslinya
    return TvScaffold(
      backgroundColor: AppColors.bgDark, // Menggunakan background gelap/hitam
      body: Stack(
        children: [
          // Background
          Positioned.fill(
            child: Image.asset(
              'assets/adzan/bg-adzan-screen.png',
              fit: BoxFit.cover,
            ),
          ),
          // Konten Utama
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/logo/diskominfotiksan-logo.png',
                  height: 95.0,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 36),
                const Text(
                  'WAKTUNYA ADZAN',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                    letterSpacing: 8,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  displayPrayerName,
                  style: const TextStyle(
                    fontSize: 140,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 12,
                    fontFamily: 'Poppins',
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 35),
                // Progress Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 500),
                  child: Column(
                    children: [
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(
                          begin: transitionState.totalSeconds == 0
                              ? 0.0
                              : progress,
                          end: transitionState.totalSeconds == 0
                              ? 1.0
                              : progress,
                        ),
                        duration: transitionState.totalSeconds == 0
                            ? const Duration(
                                seconds: 90,
                              ) // Simulasi lambat 1.5 menit
                            : const Duration(seconds: 1),
                        curve: Curves.linear,
                        builder: (context, value, child) {
                          final remainingFloatSeconds =
                              transitionState.totalSeconds == 0
                              ? (1.0 - value) * 90
                              : (1.0 - value) * transitionState.totalSeconds;

                          final currentSeconds = remainingFloatSeconds.ceil();

                          final isBlinking =
                              currentSeconds <= 10 && currentSeconds > 0;
                          final barColor = isBlinking
                              ? ((remainingFloatSeconds * 2).floor() % 2 == 0
                                    ? Colors.red
                                    : AppColors.textYellow)
                              : AppColors.textYellow;

                          return Column(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(40),
                                child: Container(
                                  width: 750,
                                  height: 80,
                                  color: Colors.white.withValues(alpha: 0.2),
                                  child: Stack(
                                    children: [
                                      Positioned(
                                        top: 0,
                                        bottom: 0,
                                        left:
                                            -750 * (1 - value.clamp(0.0, 1.0)),
                                        child: Container(
                                          width: 750,
                                          decoration: BoxDecoration(
                                            color: barColor,
                                            borderRadius: BorderRadius.circular(
                                              40,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                _formatCountdown(currentSeconds),
                                style: TextStyle(
                                  fontSize: 260,
                                  fontWeight: FontWeight.bold,
                                  color: isBlinking ? barColor : Colors.white,
                                  fontFamily: 'JetBrainsMono',
                                  height: 1.0,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
