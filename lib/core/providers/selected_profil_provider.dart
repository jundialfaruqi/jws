import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/select_profil/models/profil_masjid_model.dart';

// Provider untuk menampung nilai awal dari storage
final initialProfilProvider = Provider<ProfilMasjidModel?>((ref) => null);

class SelectedProfilNotifier extends Notifier<ProfilMasjidModel?> {
  @override
  ProfilMasjidModel? build() {
    return ref.read(initialProfilProvider);
  }

  void setProfil(ProfilMasjidModel? profil) {
    state = profil;
  }
}

// Provider utama untuk status masjid
final selectedProfilProvider = NotifierProvider<SelectedProfilNotifier, ProfilMasjidModel?>(SelectedProfilNotifier.new);
