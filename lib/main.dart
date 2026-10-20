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
import 'core/time/hijri_localization.dart';
import 'features/select_profil/models/profil_masjid_model.dart';
import 'package:intl/date_symbol_data_local.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Optimasi Image Cache di RAM untuk Android TV (RAM 1 GB)
  // Membatasi akumulasi bitmap uncompressed agar tidak memicu LowMemoryKiller (LMK) / malloc bad_alloc
  PaintingBinding.instance.imageCache.maximumSize = 8;
  PaintingBinding.instance.imageCache.maximumSizeBytes = 15 * 1024 * 1024; // 15 MB
  
  // Mengaktifkan Fullscreen (Menyembunyikan Status Bar & Nav Bar)
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  
  await dotenv.load(fileName: ".env");
  await initializeDateFormatting('id', null);
  initializeHijriLocale();

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

class MainApp extends ConsumerStatefulWidget {
  const MainApp({super.key});

  @override
  ConsumerState<MainApp> createState() => _MainAppState();
}

class _MainAppState extends ConsumerState<MainApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didHaveMemoryPressure() {
    super.didHaveMemoryPressure();
    // Bebaskan cache native bitmap saat OS TV mengirim sinyal low memory
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  }

  @override
  Widget build(BuildContext context) {
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
