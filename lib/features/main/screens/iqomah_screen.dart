import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

    final myMasjidData = profil != null ? ref.watch(myMasjidProvider(profil.slug)).value : null;
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
      slideIqomahs.add('https://images.unsplash.com/photo-1564121211835-e88c852648ab?q=80&w=1000');
    }

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

    return TvScaffold(
      backgroundColor: AppColors.bgDark, 
      body: Stack(
        children: [
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
                  'MENUNGGU WAKTU IQOMAH',
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
                    fontSize: 100,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 12,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 40),
                Text(
                  _formatCountdown(transitionState.remainingSeconds),
                  style: const TextStyle(
                    fontSize: 200,
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
                    'Mohon matikan ponsel dan luruskan shaf',
                    style: TextStyle(
                      fontSize: 32,
                      color: Colors.white,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ], // Penutup children Column
            ), // Penutup Column
          ), // Penutup Center
        ), // Penutup Expanded
        
        const SizedBox(width: 64), // Jarak tengah (margin antar 2 layout)
        
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
                )
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
