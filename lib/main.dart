import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/routes/app_router.dart';
import 'core/services/secure_storage_service.dart';
import 'core/providers/selected_profil_provider.dart';
import 'core/providers/view_mode_provider.dart';
import 'features/select_profil/models/profil_masjid_model.dart';

// Class untuk mengabaikan verifikasi SSL secara global
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = MyHttpOverrides(); // Pasang HttpOverrides di sini
  await dotenv.load(fileName: ".env");

  // Membaca storage untuk cek profil terakhir
  final storage = SecureStorageService();
  final savedProfilJson = await storage.read('selected_profil');
  final savedViewMode = await storage.read('view_mode');
  
  ProfilMasjidModel? initialProfil;
  if (savedProfilJson != null) {
    try {
      initialProfil = ProfilMasjidModel.fromJson(jsonDecode(savedProfilJson));
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
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig: router,
    );
  }
}
