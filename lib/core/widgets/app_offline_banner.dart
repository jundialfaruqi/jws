import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/connectivity_provider.dart';

class AppOfflineBanner extends ConsumerStatefulWidget {
  final VoidCallback? onRetry;
  final bool isDot;

  const AppOfflineBanner({super.key, this.onRetry, this.isDot = false});

  @override
  ConsumerState<AppOfflineBanner> createState() => _AppOfflineBannerState();
}

class _AppOfflineBannerState extends ConsumerState<AppOfflineBanner> {
  bool _isVisible = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (mounted) {
        setState(() {
          _isVisible = !_isVisible;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Dengarkan perubahan jaringan untuk auto-recovery
    ref.listen<AsyncValue<bool>>(isConnectedProvider, (previous, next) {
      if (previous?.value == false && next.value == true) {
        if (widget.onRetry != null) {
          widget.onRetry!();
        }
      }
    });

    final connectivityState = ref.watch(isConnectedProvider);
    final isConnected =
        connectivityState.value ??
        true; // Default anggap online jika belum ada data

    if (isConnected) {
      return const SizedBox.shrink(); // Sembunyikan banner jika online
    }

    if (widget.isDot) {
      return Align(
        alignment: Alignment.topRight,
        child: Padding(
          padding: const EdgeInsets.only(top: 10, right: 10),
          child: Opacity(
            opacity: _isVisible ? 1.0 : 0.0,
            child: Container(
              width: 16,
              height: 16,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.redAccent,
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      color: Colors.red.shade100, // Warna latar error yang lembut
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Tidak ada internet. Menunggu koneksi...',
            style: TextStyle(color: Colors.red.shade900, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
