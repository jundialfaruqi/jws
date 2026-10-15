import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/routes/app_router.dart';
import 'core/services/secure_storage_service.dart';
import 'core/providers/selected_profil_provider.dart';
import 'core/providers/view_mode_provider.dart';
import 'core/services/prayer_transition_service.dart';
import 'core/services/murotal_audio_service.dart';
import 'features/select_profil/models/profil_masjid_model.dart';
import 'package:intl/date_symbol_data_local.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Optimasi Image Cache di RAM untuk Android TV (RAM 1 GB)
  // Membatasi akumulasi bitmap uncompressed agar tidak memicu LowMemoryKiller (LMK)
  PaintingBinding.instance.imageCache.maximumSize = 25;
  PaintingBinding.instance.imageCache.maximumSizeBytes = 40 * 1024 * 1024; // 40 MB
  
  // Mengaktifkan Fullscreen (Menyembunyikan Status Bar & Nav Bar)
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  
  await dotenv.load(fileName: ".env");
  await initializeDateFormatting('id', null);

  // Membaca storage untuk cek profil terakhir
  final storage = SecureStorageService();
  final savedProfilJson = await storage.read('selected_profil');
  final savedViewMode = await storage.read('view_mode');
  
  ProfilMasjidModel? initialProfil;
  if (savedProfilJson != null) {
    try {
      initialProfil = ProfilMasjidModel.fromJson(jsonDecode(savedProfilJson));
      if (initialProfil.id == 0) {
        initialProfil = null;
      }
    } catch (_) {}
  }

  runApp(ProviderScope(
    overrides: [
      initialProfilProvider.overrideWithValue(initialProfil),
      initialViewModeProvider.overrideWithValue(savedViewMode),
    ],
    child: const MainApp(),
  ));
}

class MainApp extends ConsumerWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Injeksi transition service agar mulai berdetak
    ref.watch(prayerTransitionProvider);
    ref.watch(murotalAudioServiceProvider);
    
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig: router,
    );
  }
}
