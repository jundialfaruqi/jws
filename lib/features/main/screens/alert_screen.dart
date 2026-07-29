import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/widgets/tv_scaffold.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/api_constant.dart';
import '../../../core/providers/selected_profil_provider.dart';
import '../../../core/services/prayer_transition_service.dart';

class AlertScreen extends ConsumerWidget {
  const AlertScreen({super.key});

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

  String _formatCountdown(int totalSeconds) {
    int minutes = totalSeconds ~/ 60;
    int seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profil = ref.watch(selectedProfilProvider);
    final transitionState = ref.watch(prayerTransitionProvider);

    final String logo1 = _getFullUrl(profil?.logoMasjid);
    final String logo2 = _getFullUrl(profil?.logoPemerintah);
    final bool hasLogo1 = logo1.isNotEmpty;
    final bool hasLogo2 = logo2.isNotEmpty;

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
        ? 'SYURUQ'
        : transitionState.prayerName;

    double progress = transitionState.totalSeconds > 0
        ? (transitionState.remainingSeconds / transitionState.totalSeconds)
        : 0.5; // 50% untuk preview

    return TvScaffold(
      backgroundColor: AppColors.bgDark,
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: logoWidgets,
                ),
                const SizedBox(height: 40),
                const Text(
                  'WAKTU',
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
                              ? 1.0
                              : progress,
                          end: transitionState.totalSeconds == 0
                              ? 0.0
                              : progress,
                        ),
                        duration: transitionState.totalSeconds == 0
                            ? const Duration(
                                seconds: 90,
                              ) // Simulasi lambat 1.5 menit
                            : const Duration(seconds: 1),
                        curve: Curves.linear,
                        builder: (context, value, child) {
                          final floatSeconds = transitionState.totalSeconds == 0
                              ? value * 90
                              : value * transitionState.totalSeconds;

                          final currentSeconds = floatSeconds.ceil();

                          final isBlinking =
                              currentSeconds <= 10 && currentSeconds > 0;
                          final barColor = isBlinking
                              ? ((floatSeconds * 2).floor() % 2 == 0
                                    ? Colors.redAccent
                                    : AppColors.textYellow)
                              : AppColors.textYellow;

                          return Column(
                            children: [
                              SizedBox(
                                width: 750,
                                child: LinearProgressIndicator(
                                  value: value,
                                  minHeight: 80,
                                  backgroundColor: Colors.white.withValues(
                                    alpha: 0.2,
                                  ),
                                  color: barColor,
                                  borderRadius: BorderRadius.circular(40),
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
