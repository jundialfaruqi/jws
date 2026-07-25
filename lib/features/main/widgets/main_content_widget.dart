import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/selected_profil_provider.dart';
import '../../../core/widgets/app_marquee.dart';
import '../providers/my_masjid_provider.dart';
import '../../../core/widgets/app_loading_spinner.dart';

class MainContentWidget extends ConsumerWidget {
  const MainContentWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profil = ref.watch(selectedProfilProvider);

    if (profil == null) {
      return const Expanded(
        child: Center(
          child: Text('Profil tidak ditemukan'),
        ),
      );
    }

    final myMasjidAsync = ref.watch(myMasjidProvider(profil.slug));

    return Expanded(
      child: myMasjidAsync.when(
        loading: () => const Center(child: AppLoadingSpinner(message: 'Memuat data masjid...')),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 64),
              const SizedBox(height: 16),
              Text('Terjadi kesalahan: $err', style: const TextStyle(color: Colors.red, fontSize: 24)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(myMasjidProvider(profil.slug)),
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
        data: (data) {
          final marqueeText = data.marquee?.concatenatedText ?? 'Selamat Datang di Sistem Informasi Masjid';
          
          // Kecepatan dasar dinaikkan menjadi 120.0 agar sesuai dengan rasa di web, dikalikan dengan pengali dari API (marqueeSpeed)
          final speedMultiplier = data.marquee?.marqueeSpeed ?? 1.0;
          final calculatedVelocity = 120.0 * speedMultiplier;

          return Column(
            children: [
              // Konten Utama (Tengah)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.mosque,
                        size: 150,
                        color: Colors.blue,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        data.profil.name,
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Waktu Server: ${data.currentTime}',
                        style: const TextStyle(
                          fontFamily: 'JetBrainsMono',
                          fontSize: 28,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Widget Marquee (Bawah)
              AppMarquee(
                text: marqueeText,
                velocity: calculatedVelocity,
              ),
            ],
          );
        },
      ),
    );
  }
}
