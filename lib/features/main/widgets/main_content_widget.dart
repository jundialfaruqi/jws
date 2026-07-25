import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/selected_profil_provider.dart';
import '../../../core/widgets/ganti_profil_button.dart';

class MainContentWidget extends ConsumerWidget {
  const MainContentWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profil = ref.watch(selectedProfilProvider);

    if (profil == null) {
      return const Expanded(
        child: Center(
          child: Text('Profil tidak ditemukan'),
        ),
      );
    }

    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.mosque,
              size: 150,
              color: Colors.blue,
            ),
            const SizedBox(height: 24),
            Text(
              profil.name,
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Slug: ${profil.slug}',
              style: const TextStyle(
                fontSize: 28,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 48),
            const Text(
              'Halaman Utama (Dashboard) sedang dalam tahap pengembangan.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 32),
            ),
            const SizedBox(height: 64),
            const GantiProfilButton(),
          ],
        ),
      ),
    );
  }
}
