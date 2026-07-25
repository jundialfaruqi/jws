import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/selected_profil_provider.dart';
import '../providers/my_masjid_provider.dart';
import '../models/my_masjid_model.dart';
import '../../../core/widgets/app_loading_spinner.dart';
import '../../../core/services/websocket_service.dart';

// Impor 4 Tema
import 'themes/theme_4_widget.dart';
import 'themes/theme_7_widget.dart';
import 'themes/theme_10_widget.dart';
import 'themes/theme_12_widget.dart';

class MainContentWidget extends ConsumerWidget {
  const MainContentWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profil = ref.watch(selectedProfilProvider);

    if (profil == null) {
      return const Expanded(
        child: Center(child: Text('Profil tidak ditemukan')),
      );
    }

    // Inisiasi koneksi WebSocket
    ref.read(webSocketServiceProvider(profil.slug)).connect();

    final myMasjidAsync = ref.watch(myMasjidProvider(profil.slug));

    return Expanded(
      child: myMasjidAsync.when(
        loading: () => const Center(
          child: AppLoadingSpinner(message: 'Memuat data masjid...'),
        ),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 64),
              const SizedBox(height: 16),
              Text(
                'Terjadi kesalahan: $err',
                style: const TextStyle(color: Colors.red, fontSize: 24),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(myMasjidProvider(profil.slug)),
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
        data: (data) {
          final themeId = data.themeId ?? 7; // Tema Default

          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 800),
            switchInCurve: Curves.easeIn,
            switchOutCurve: Curves.easeOut,
            child: _buildThemeWidget(themeId, data),
          );
        },
      ),
    );
  }

  Widget _buildThemeWidget(int themeId, MyMasjidModel data) {
    switch (themeId) {
      case 4:
        return Theme4Widget(key: const ValueKey(4), data: data);
      case 10:
        return Theme10Widget(key: const ValueKey(10), data: data);
      case 12:
        return Theme12Widget(key: const ValueKey(12), data: data);
      case 7:
      default:
        return Theme7Widget(key: const ValueKey(7), data: data);
    }
  }
}
