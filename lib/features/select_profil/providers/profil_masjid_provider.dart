import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/api_provider.dart';
import '../services/profil_masjid_service.dart';

final profilMasjidServiceProvider = Provider<ProfilMasjidService>((ref) {
  final dio = ref.watch(dioProvider);
  return ProfilMasjidService(dio);
});
