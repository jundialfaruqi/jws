import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/tv_scaffold.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/api_constant.dart';
import '../../../core/providers/selected_profil_provider.dart';
import '../../../core/services/prayer_transition_service.dart';

class AdzanScreen extends ConsumerWidget {
  const AdzanScreen({super.key});

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

    List<Widget> logoWidgets = [];
    final double logoSize = 150.0;

    if (!hasLogo1 && !hasLogo2) {
      logoWidgets.add(Image.asset('assets/logo/logo-masjid-default.png', height: logoSize, fit: BoxFit.contain));
      logoWidgets.add(const SizedBox(width: 24));
      logoWidgets.add(Image.asset('assets/logo/logo-pemko-default.png', height: logoSize, fit: BoxFit.contain));
    } else {
      if (hasLogo1) {
        logoWidgets.add(Image.network(logo1, height: logoSize, fit: BoxFit.contain, errorBuilder: (c,e,s) => Icon(Icons.mosque, size: logoSize, color: Colors.white)));
      }
      if (hasLogo2) {
        if (hasLogo1) logoWidgets.add(const SizedBox(width: 24));
        logoWidgets.add(Image.network(logo2, height: logoSize, fit: BoxFit.contain, errorBuilder: (c,e,s) => Icon(Icons.account_balance, size: logoSize, color: Colors.white)));
      }
    }
    
    double progress = transitionState.totalSeconds > 0 
        ? transitionState.remainingSeconds / transitionState.totalSeconds 
        : 0;

    // ScaffoldTV akan otomatis menjaga resolusi tetap 1920x1080 (Full HD) 
    // berapapun rasio layar aslinya
    return TvScaffold(
      backgroundColor: AppColors.bgDark, // Menggunakan background gelap/hitam
      body: Stack(
        children: [
          // Konten Utama (Dummy)
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
                  'SAATNYA MENGUMANDANGKAN ADZAN',
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
                  transitionState.prayerName,
                  style: const TextStyle(
                    fontSize: 140,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 12,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  transitionState.prayerTime,
                  style: const TextStyle(
                    fontSize: 90,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textYellow,
                    fontFamily: 'JetBrainsMono',
                  ),
                ),
                const SizedBox(height: 80),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 24),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                      width: 2,
                    ),
                  ),
                  child: const Text(
                    'Mohon bersiap dan luruskan shaf',
                    style: TextStyle(
                      fontSize: 32,
                      color: Colors.white,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                // Progress Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 200),
                  child: Column(
                    children: [
                      LinearProgressIndicator(
                        value: progress,
                        minHeight: 12,
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        color: AppColors.textYellow,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _formatCountdown(transitionState.remainingSeconds),
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'JetBrainsMono',
                        ),
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
