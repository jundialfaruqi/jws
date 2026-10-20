import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/tv_scaffold.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/selected_profil_provider.dart';
import '../providers/my_masjid_provider.dart';
import '../../../core/widgets/app_image_slider.dart';

import '../../../core/services/prayer_transition_service.dart';
import '../../../core/time/time_sync_service.dart';

class IqomahScreen extends ConsumerWidget {
  const IqomahScreen({super.key});

  String _formatCountdown(int totalSeconds) {
    int minutes = totalSeconds ~/ 60;
    int seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profil = ref.watch(selectedProfilProvider);
    final transitionState = ref.watch(prayerTransitionProvider);

    final myMasjidData = profil != null
        ? ref.watch(myMasjidProvider(profil.id)).value
        : null;

    List<String> slideIqomahs = [];
    if (myMasjidData != null && myMasjidData.slideIqomah != null) {
      final s = myMasjidData.slideIqomah!;
      if (s.slide1 != null && s.slide1!.isNotEmpty) slideIqomahs.add(s.slide1!);
      if (s.slide2 != null && s.slide2!.isNotEmpty) slideIqomahs.add(s.slide2!);
      if (s.slide3 != null && s.slide3!.isNotEmpty) slideIqomahs.add(s.slide3!);
      if (s.slide4 != null && s.slide4!.isNotEmpty) slideIqomahs.add(s.slide4!);
      if (s.slide5 != null && s.slide5!.isNotEmpty) slideIqomahs.add(s.slide5!);
      if (s.slide6 != null && s.slide6!.isNotEmpty) slideIqomahs.add(s.slide6!);
    }

    // Jika tidak ada data dari backend, gunakan gambar default
    if (slideIqomahs.isEmpty) {
      slideIqomahs.add('assets/iqomah-screen/slide-iqomah-default-1.jpg');
      slideIqomahs.add('assets/iqomah-screen/slide-iqomah-default-2.jpg');
      slideIqomahs.add('assets/iqomah-screen/slide-iqomah-default-3.jpg');
    }

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

    return TvScaffold(
      backgroundColor: AppColors.bgBlack,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/iqomah-screen/bg-iqomah-jumat-screen.png',
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(64.0),
            child: Row(
              children: [
                // Kolom Kiri: Informasi Iqomah
                Expanded(
                  flex: 1,
                  child: Padding(
                    // Padding kiri & kanan untuk seluruh konten Informasi Iqomah
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/logo/diskominfotiksan-logo.png',
                            height: 80.0,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(height: 36),
                          const Text(
                            'MENUJU IQOMAH',
                            style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.w600,
                              color: Colors.white70,
                              letterSpacing: 8,
                              fontFamily: 'Poppins',
                            ),
                          ),
                          const SizedBox(height: 20),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              displayPrayerName,
                              style: const TextStyle(
                                fontSize: 130,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 12,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: TweenAnimationBuilder<double>(
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
                                      seconds: 300,
                                    ) // Simulasi lambat 5 menit
                                  : const Duration(seconds: 1),
                              curve: Curves.linear,
                              builder: (context, value, child) {
                                final remainingFloatSeconds =
                                    transitionState.totalSeconds == 0
                                    ? (1.0 - value) * 300
                                    : (1.0 - value) *
                                          transitionState.totalSeconds;

                                final currentSeconds = remainingFloatSeconds
                                    .ceil();

                                final isBlinking =
                                    currentSeconds <= 10 && currentSeconds > 0;
                                final barColor = isBlinking
                                    ? ((remainingFloatSeconds * 2).floor() %
                                                  2 ==
                                              0
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
                                        color: Colors.white.withValues(
                                          alpha: 0.2,
                                        ),
                                        child: Stack(
                                          children: [
                                            Positioned(
                                              top: 0,
                                              bottom: 0,
                                              left:
                                                  -700 *
                                                  (1 - value.clamp(0.0, 1.0)),
                                              child: Container(
                                                width: 750,
                                                decoration: BoxDecoration(
                                                  color: barColor,
                                                  borderRadius:
                                                      BorderRadius.circular(40),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        _formatCountdown(currentSeconds),
                                        style: TextStyle(
                                          fontSize: 300,
                                          fontWeight: FontWeight.bold,
                                          color: barColor,
                                          fontFamily: 'JetBrainsMono',
                                          height: 1.0,
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ], // Penutup children Column
                      ), // Penutup Column
                    ), // Penutup Center
                  ), // Penutup Padding
                ), // Penutup Expanded

                const SizedBox(
                  width: 64,
                ), // Jarak tengah (margin antar 2 layout)
                // Kolom Kanan: Gambar Rounded (Dummy)
                Expanded(
                  flex: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(48),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          blurRadius: 32,
                          offset: const Offset(8, 16),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(48),
                      child: AppImageSlider(
                        imageUrls: slideIqomahs,
                        leftMargin: 0,
                      ),
                    ),
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
