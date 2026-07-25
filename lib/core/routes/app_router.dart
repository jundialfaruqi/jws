import 'package:go_router/go_router.dart';
import '../../features/select_profil/screens/select_profil_screen.dart';
import '../../features/main/screens/main_screen.dart';
import '../../features/select_profil/models/profil_masjid_model.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'select_profil',
      builder: (context, state) => const SelectProfilScreen(),
    ),
    GoRoute(
      path: '/main',
      name: 'main',
      builder: (context, state) {
        final profil = state.extra as ProfilMasjidModel;
        return MainScreen(profil: profil);
      },
    ),
  ],
);
