import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/connectivity_provider.dart';

class AppOfflineBanner extends ConsumerWidget {
  final VoidCallback? onRetry;

  const AppOfflineBanner({super.key, this.onRetry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Dengarkan perubahan jaringan untuk auto-recovery
    ref.listen<AsyncValue<bool>>(isConnectedProvider, (previous, next) {
      if (previous?.value == false && next.value == true) {
        if (onRetry != null) {
          onRetry!();
        }
      }
    });

    final connectivityState = ref.watch(isConnectedProvider);
    final isConnected = connectivityState.value ?? true; // Default anggap online jika belum ada data

    if (isConnected) {
      return const SizedBox.shrink(); // Sembunyikan banner jika online
    }

    return Container(
      width: double.infinity,
      color: Colors.red.shade100, // Warna latar error yang lembut
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Tidak ada internet. Tunggu koneksi terhubung, atau',
            style: TextStyle(
              color: Colors.red.shade900,
              fontSize: 16,
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: () {
              if (onRetry != null) {
                onRetry!();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }
}
