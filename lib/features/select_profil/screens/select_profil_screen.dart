import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/profil_masjid_provider.dart';
import '../widgets/profil_card_widget.dart';

class SelectProfilScreen extends ConsumerWidget {
  const SelectProfilScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profilAsyncValue = ref.watch(profilMasjidListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pilih Masjid'),
        centerTitle: true,
      ),
      body: profilAsyncValue.when(
        data: (profils) {
          if (profils.isEmpty) {
            return const Center(child: Text('Data profil masjid belum tersedia.'));
          }
          return ListView.builder(
            itemCount: profils.length,
            itemBuilder: (context, index) {
              final profil = profils[index];
              return ProfilCardWidget(
                profil: profil,
                onTap: () {
                  // Aksi ketika masjid dipilih (misal: navigasi/simpan state)
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Anda memilih: ${profil.name}')),
                  );
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Terjadi kesalahan:\n$error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ),
      ),
    );
  }
}
