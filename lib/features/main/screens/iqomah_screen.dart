import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/widgets/tv_scaffold.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/api_constant.dart';
import '../../../core/providers/selected_profil_provider.dart';
import '../providers/my_masjid_provider.dart';
import '../../../core/widgets/app_image_slider.dart';

import '../../../core/services/prayer_transition_service.dart';

class IqomahScreen extends ConsumerWidget {
  const IqomahScreen({super.key});

  String _formatCountdown(int totalSeconds) {
    int minutes = totalSeconds ~/ 60;
    int seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String _getFullUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;

    final baseUrl = ApiConstant.baseUrl;
    final cleanBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final cleanPath = path.startsWith('/') ? path : '/$path';

    return '$cleanBase$cleanPath';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profil = ref.watch(selectedProfilProvider);
    final transitionState = ref.watch(prayerTransitionProvider);

    final String logo1 = _getFullUrl(profil?.logoMasjid);
    final String logo2 = _getFullUrl(profil?.logoPemerintah);
    final bool hasLogo1 = logo1.isNotEmpty;
    final bool hasLogo2 = logo2.isNotEmpty;

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

    List<Widget> logoWidgets = [];
    final double logoSize = 150.0;

    if (!hasLogo1 && !hasLogo2) {
      logoWidgets.add(
        Image.asset(
          'assets/logo/logo-masjid-default.png',
          height: logoSize,
          fit: BoxFit.contain,
        ),
      );
      logoWidgets.add(const SizedBox(width: 24));
      logoWidgets.add(
        Image.asset(
          'assets/logo/logo-pemko-default.png',
          height: logoSize,
          fit: BoxFit.contain,
        ),
      );
    } else {
      if (hasLogo1) {
        logoWidgets.add(
          CachedNetworkImage(
            imageUrl: logo1,
            height: logoSize,
            fit: BoxFit.contain,
            errorWidget: (c, url, e) =>
                Icon(Icons.mosque, size: logoSize, color: Colors.white),
          ),
        );
      }
      if (hasLogo2) {
        if (hasLogo1) logoWidgets.add(const SizedBox(width: 24));
        logoWidgets.add(
          CachedNetworkImage(
            imageUrl: logo2,
            height: logoSize,
            fit: BoxFit.contain,
            errorWidget: (c, url, e) => Icon(
              Icons.account_balance,
              size: logoSize,
              color: Colors.white,
            ),
          ),
        );
      }
    }

    final String displayPrayerName = transitionState.prayerName.isEmpty
        ? 'MAGHRIB'
        : transitionState.prayerName;

    double progress = transitionState.totalSeconds > 0
        ? (transitionState.remainingSeconds / transitionState.totalSeconds)
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
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: logoWidgets,
                        ),
                        const SizedBox(height: 40),
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
                        Text(
                          displayPrayerName,
                          style: const TextStyle(
                            fontSize: 130,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 12,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 64),
                          child: TweenAnimationBuilder<double>(
                            tween: Tween<double>(
                              begin: transitionState.totalSeconds == 0
                                  ? 1.0
                                  : progress,
                              end: transitionState.totalSeconds == 0
                                  ? 0.0
                                  : progress,
                            ),
                            duration: transitionState.totalSeconds == 0
                                ? const Duration(
                                    seconds: 300,
                                  ) // Simulasi lambat 5 menit
                                : const Duration(seconds: 1),
                            curve: Curves.linear,
                            builder: (context, value, child) {
                              final floatSeconds =
                                  transitionState.totalSeconds == 0
                                  ? value * 300
                                  : value * transitionState.totalSeconds;

                              final currentSeconds = floatSeconds.ceil();

                              final isBlinking =
                                  currentSeconds <= 10 && currentSeconds > 0;
                              final barColor = isBlinking
                                  ? ((floatSeconds * 2).floor() % 2 == 0
                                        ? Colors.red
                                        : AppColors.textYellow)
                                  : AppColors.textYellow;

                              return Column(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(40),
                                    child: Container(
                                      width: 700,
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
                                              width: 700,
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
                                  Text(
                                    _formatCountdown(currentSeconds),
                                    style: TextStyle(
                                      fontSize: 240,
                                      fontWeight: FontWeight.bold,
                                      color: barColor,
                                      fontFamily: 'JetBrainsMono',
                                      height: 1.0,
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
