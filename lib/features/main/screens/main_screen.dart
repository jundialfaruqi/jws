import 'package:flutter/material.dart';
import '../../select_profil/models/profil_masjid_model.dart';

class MainScreen extends StatelessWidget {
  final ProfilMasjidModel profil;

  const MainScreen({super.key, required this.profil});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Jadwal Waktu Sholat'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.mosque, size: 100, color: Colors.blue),
            const SizedBox(height: 16),
            Text(
              profil.name,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Slug: ${profil.slug}',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            const Text(
              'Halaman Utama (Dashboard) sedang dalam tahap pengembangan.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
