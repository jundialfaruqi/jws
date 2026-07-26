import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/tv_scaffold.dart';
import '../../../core/providers/selected_profil_provider.dart';
import '../providers/my_masjid_provider.dart';
import '../../../core/widgets/app_image_slider.dart';

class FinalScreen extends ConsumerWidget {
  const FinalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profil = ref.watch(selectedProfilProvider);
    final myMasjidData = profil != null ? ref.watch(myMasjidProvider(profil.slug)).value : null;
    
    List<String> slideFinals = [];
    if (myMasjidData != null && myMasjidData.slideFinal != null) {
      final s = myMasjidData.slideFinal!;
      if (s.slide1 != null && s.slide1!.isNotEmpty) slideFinals.add(s.slide1!);
    }
    
    // Jika tidak ada data dari backend, gunakan gambar default
    if (slideFinals.isEmpty) {
      slideFinals.add('https://images.unsplash.com/photo-1564121211835-e88c852648ab?q=80&w=1920');
    }

    return TvScaffold(
      backgroundColor: Colors.black, // Fallback color
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Full Gambar (Slide Slider)
          Positioned.fill(
            child: AppImageSlider(
              imageUrls: slideFinals,
              leftMargin: 0,
            ),
          ),
          
          // Overlay Gelap agar teks mudah dibaca
          Container(
            color: Colors.black.withValues(alpha: 0.6),
          ),
          
          // Konten Utama
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.do_not_disturb_on,
                  size: 200,
                  color: Colors.redAccent,
                ),
                const SizedBox(height: 48),
                const Text(
                  'HARAP TENANG',
                  style: TextStyle(
                    fontSize: 120,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 16,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'SEDANG MELAKSANAKAN SHOLAT',
                  style: TextStyle(
                    fontSize: 64,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                    letterSpacing: 8,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 80),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 64, vertical: 32),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                      width: 2,
                    ),
                  ),
                  child: const Text(
                    'Mohon pastikan ponsel Anda dalam keadaan senyap',
                    style: TextStyle(
                      fontSize: 36,
                      color: Colors.white,
                      fontFamily: 'Poppins',
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
