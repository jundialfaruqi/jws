import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/api_provider.dart';
import '../services/profil_masjid_service.dart';
import '../models/profil_masjid_model.dart';

final profilMasjidServiceProvider = Provider<ProfilMasjidService>((ref) {
  final dio = ref.watch(dioProvider);
  return ProfilMasjidService(dio);
});

final profilMasjidListProvider = FutureProvider.autoDispose<List<ProfilMasjidModel>>((ref) async {
  final service = ref.watch(profilMasjidServiceProvider);
  // Untuk saat ini mengambil data halaman 1
  return await service.getProfilMasjids(page: 1);
});
