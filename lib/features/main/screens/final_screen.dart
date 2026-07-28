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
    final myMasjidData = profil != null ? ref.watch(myMasjidProvider(profil.id)).value : null;
    
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
        ],
      ),
    );
  }
}
