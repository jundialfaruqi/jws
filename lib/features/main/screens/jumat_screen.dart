import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/tv_scaffold.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/api_constant.dart';
import '../../../core/providers/selected_profil_provider.dart';

class JumatScreen extends ConsumerWidget {
  final String countdownTime;

  const JumatScreen({
    super.key,
    this.countdownTime = '10:00', // Dummy hitung mundur persiapan Jumat
  });

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
    final String logo1 = _getFullUrl(profil?.logoMasjid);
    final String logo2 = _getFullUrl(profil?.logoPemerintah);
    final bool hasLogo1 = logo1.isNotEmpty;
    final bool hasLogo2 = logo2.isNotEmpty;

    List<Widget> logoWidgets = [];
    final double logoSize = 120.0; // Diperkecil sedikit agar tidak overflow

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
                // Kolom Kiri: Informasi Jumat
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
                      const SizedBox(height: 24),
                      const Text(
                        'PERSIAPAN KHUTBAH',
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.w600,
                          color: Colors.white70,
                          letterSpacing: 8,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        "SHOLAT JUM'AT",
                        style: TextStyle(
                          fontSize: 80, // Diperkecil agar muat
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 12,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        countdownTime,
                        style: const TextStyle(
                          fontSize: 160,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textYellow,
                          fontFamily: 'JetBrainsMono',
                        ),
                      ),
                      const SizedBox(height: 48),
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
                          'Mohon segera bersiap dan masuk ke dalam masjid',
                          style: TextStyle(
                            fontSize: 28,
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
                      child: Image.network(
                        'https://images.unsplash.com/photo-1564121211835-e88c852648ab?q=80&w=1000', // URL valid
                        fit: BoxFit.cover,
                        height: double.infinity,
                        width: double.infinity,
                        errorBuilder: (c,e,s) => Container(color: Colors.grey),
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
