import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/select_profil/screens/pairing_screen.dart';
import '../../features/main/screens/main_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/main/screens/adzan_screen.dart';
import '../../features/main/screens/iqomah_screen.dart';
import '../../features/main/screens/final_screen.dart';
import '../../features/main/screens/jumat_screen.dart';
import '../../features/main/screens/jumbotron_masjid_screen.dart';
import '../../features/main/screens/jumbotron_pemko_screen.dart';
import '../../features/webview/screens/webview_screen.dart';
import '../../features/main/screens/alert_screen.dart';
import '../providers/selected_profil_provider.dart';
import '../providers/view_mode_provider.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final routerProvider = Provider<GoRouter>((ref) {
  final selectedProfil = ref.read(selectedProfilProvider);
  final viewMode = ref.read(viewModeProvider);

  String initial = '/';
  if (selectedProfil != null) {
    if (viewMode == 'web') {
      initial = '/webview/${selectedProfil.slug}';
    } else {
      initial = '/main';
    }
  }

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: initial,
    routes: [
      GoRoute(
        path: '/',
        name: 'pairing',
        builder: (context, state) => const PairingScreen(),
      ),
      GoRoute(
        path: '/main',
        name: 'main',
        builder: (context, state) => const MainScreen(),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/webview/:slug',
        name: 'webview',
        builder: (context, state) {
          final slug = state.pathParameters['slug']!;
          return WebViewScreen(slug: slug);
        },
      ),
      GoRoute(
        path: '/alert',
        name: 'alert',
        builder: (context, state) {
          final preview = state.uri.queryParameters['preview'] ?? (state.extra as String?);
          return AlertScreen(previewPrayerName: preview);
        },
      ),
      GoRoute(
        path: '/adzan',
        name: 'adzan',
        builder: (context, state) => const AdzanScreen(),
      ),
      GoRoute(
        path: '/iqomah',
        name: 'iqomah',
        builder: (context, state) => const IqomahScreen(),
      ),
      GoRoute(
        path: '/final',
        name: 'final',
        builder: (context, state) => const FinalScreen(),
      ),
      GoRoute(
        path: '/jumat',
        name: 'jumat',
        builder: (context, state) => const JumatScreen(),
      ),
      GoRoute(
        path: '/jumbotron-masjid',
        name: 'jumbotron-masjid',
        builder: (context, state) => const JumbotronMasjidScreen(imageUrl: 'https://picsum.photos/1920/1080'),
      ),
      GoRoute(
        path: '/jumbotron-pemko',
        name: 'jumbotron-pemko',
        builder: (context, state) => const JumbotronPemkoScreen(imageUrl: 'https://picsum.photos/1920/1080'),
      ),
    ],
  );
});
