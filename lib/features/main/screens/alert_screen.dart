import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/tv_scaffold.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/prayer_transition_service.dart';
import '../../../core/time/time_sync_service.dart';
import '../../../core/providers/selected_profil_provider.dart';
import '../../main/providers/my_masjid_provider.dart';
import '../models/jadwal_sholat_model.dart';

class AlertScreen extends ConsumerWidget {
  final String? previewPrayerName;
  const AlertScreen({super.key, this.previewPrayerName});

  String _formatCountdown(int totalSeconds) {
    int minutes = totalSeconds ~/ 60;
    int seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transitionState = ref.watch(prayerTransitionProvider);
    final now = ref.watch(timeSyncServiceProvider).now();
    final selectedProfil = ref.watch(selectedProfilProvider);
    final masjidData = selectedProfil != null
        ? ref.watch(myMasjidProvider(selectedProfil.id)).value
        : null;

    final todayStr =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    JadwalSholatModel? todayJadwal;
    if (masjidData != null && masjidData.jadwalSholat.isNotEmpty) {
      try {
        todayJadwal = masjidData.jadwalSholat.firstWhere(
          (j) => j.date == todayStr,
        );
      } catch (_) {
        todayJadwal = null;
      }
    }

    final defaultPrayer = previewPrayerName ?? 'SYURUQ';
    String displayPrayerName = transitionState.prayerName.isEmpty
        ? defaultPrayer
        : transitionState.prayerName;

    if (displayPrayerName == 'DZUHUR' && now.weekday == DateTime.friday) {
      displayPrayerName = "JUM'AT";
    }

    final isSyuruq = displayPrayerName == 'SYURUQ';
    final isDhuha = displayPrayerName == 'DHUHA';
    final barWidth = isSyuruq ? 850.0 : 850.0;

    final dhuhaTime = transitionState.prayerTime.isNotEmpty
        ? transitionState.prayerTime
        : (todayJadwal != null && todayJadwal.dhuha.isNotEmpty
              ? todayJadwal.dhuha
              : '06:20');

    final dzuhurTime = (todayJadwal != null && todayJadwal.dzuhur.isNotEmpty
        ? todayJadwal.dzuhur
        : '12:02');

    String topLabel = 'WAKTU';
    if (isDhuha) {
      topLabel = 'WAKTU SHOLAT SUNAH';
    } else if (isSyuruq) {
      topLabel = 'WAKTU SYURUQ';
    }

    double progress = transitionState.totalSeconds > 0
        ? ((transitionState.totalSeconds - transitionState.remainingSeconds) /
              transitionState.totalSeconds)
        : 0.5; // 50% untuk preview

    return TvScaffold(
      backgroundColor: AppColors.bgDark,
      body: Stack(
        children: [
          // Background
          Positioned.fill(
            child: Image.asset(
              'assets/final-screen/border-final-screen.png',
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
                Text(
                  topLabel,
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                    letterSpacing: (isSyuruq || isDhuha) ? 4 : 8,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 140,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 80),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          isSyuruq
                              ? 'MENUJU SHOLAT SUNAH SYURUQ'
                              : displayPrayerName,
                          style: TextStyle(
                            fontSize: isSyuruq ? 90 : 140,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: isSyuruq ? 4 : 12,
                            fontFamily: 'Poppins',
                            height: 1.0,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 35),
                // Progress Bar
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isSyuruq ? 20.0 : (isDhuha ? 200.0 : 500.0),
                  ),
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
                              !isDhuha &&
                              currentSeconds <= 10 &&
                              currentSeconds > 0;
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
                                  width: barWidth,
                                  height: 80,
                                  color: Colors.white.withValues(alpha: 0.2),
                                  child: Stack(
                                    children: [
                                      Positioned(
                                        top: 0,
                                        bottom: 0,
                                        left:
                                            -(barWidth - 100.0) *
                                            (1 - value.clamp(0.0, 1.0)),
                                        child: Container(
                                          width: barWidth,
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
                              if (isDhuha)
                                SizedBox(
                                  height: 300,
                                  child: Center(
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        '$dhuhaTime s/d $dzuhurTime',
                                        style: const TextStyle(
                                          fontSize: 100,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          fontFamily: 'JetBrainsMono',
                                          letterSpacing: 4,
                                          height: 1.0,
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                              else
                                Text(
                                  _formatCountdown(currentSeconds),
                                  style: TextStyle(
                                    fontSize: 300,
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
