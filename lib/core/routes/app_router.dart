import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/select_profil/screens/select_profil_screen.dart';
import '../../features/main/screens/main_screen.dart';
import '../providers/selected_profil_provider.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final selectedProfil = ref.read(selectedProfilProvider);

  return GoRouter(
    initialLocation: selectedProfil != null ? '/main' : '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'select_profil',
        builder: (context, state) => const SelectProfilScreen(),
      ),
      GoRoute(
        path: '/main',
        name: 'main',
        builder: (context, state) => const MainScreen(),
      ),
    ],
  );
});
