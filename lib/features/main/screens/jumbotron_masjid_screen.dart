import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/api_constant.dart';
import '../../../core/providers/selected_profil_provider.dart';
import '../../../core/widgets/app_live_clock.dart';
import '../../../core/widgets/tv_scaffold.dart';
import '../../../core/widgets/app_next_prayer_bar.dart';
import '../providers/my_masjid_provider.dart';

class JumbotronMasjidScreen extends ConsumerWidget {
  final String imageUrl;

  const JumbotronMasjidScreen({super.key, required this.imageUrl});

  String _getFullUrl(String? path) {
    if (path == null || path.isEmpty) return '';

    final baseUrl = ApiConstant.baseUrl;
    final cleanBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;

    if (path.startsWith('http://localhost') || path.startsWith('http://127.0.0.1')) {
      try {
        final uri = Uri.parse(path);
        final baseUri = Uri.parse(cleanBase);
        return uri.replace(
          scheme: baseUri.scheme,
          host: baseUri.host,
          port: baseUri.hasPort ? baseUri.port : null,
        ).toString();
      } catch (_) {}
    }

    if (path.startsWith('http')) return path;

    final cleanPath = path.startsWith('/') ? path : '/$path';

    return '$cleanBase$cleanPath';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final initialProfil = ref.watch(selectedProfilProvider);
    final liveData = initialProfil != null
        ? ref.watch(myMasjidProvider(initialProfil.id)).value
        : null;

    return TvScaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Stack(
            children: [
              // Gambar Full Layar (Contain agar potret tetap utuh)
              Positioned.fill(
                child: CachedNetworkImage(
                  imageUrl: _getFullUrl(imageUrl),
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.contain,
                  memCacheWidth: 1920,
                  memCacheHeight: 1080,
                  fadeInDuration: const Duration(milliseconds: 250),
                  fadeOutDuration: const Duration(milliseconds: 100),
                  errorWidget: (context, url, error) => const Center(
                    child: Icon(
                      Icons.broken_image,
                      size: 100,
                      color: Colors.white54,
                    ),
                  ),
                ),
              ),

              // Pojok Kiri Atas: Logo Statis DiskominfoTiksan
              Positioned(
                top: 0,
                left: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: const BorderRadius.only(
                      bottomRight: Radius.circular(24),
                    ),
                  ),
                  child: Image.asset(
                    'assets/logo/diskominfotiksan-logo.png',
                    height: 52,
                    fit: BoxFit.contain,
                  ),
                ),
              ),

              // Pojok Kiri Bawah: Jam Digital Melayang
              Positioned(
                bottom: 0,
                left: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(32),
                    ),
                  ),
                  child: const AppLiveClock(
                    textStyle: TextStyle(
                      fontSize: 48,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              // Pojok Kanan Bawah: Countdown Next Prayer Melayang
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(32),
                    ),
                  ),
                  child: AppNextPrayerBar(
                    countdownOnly: true,
                    fontSize: 48,
                    iconSize: 48,
                    jadwalSholatList: liveData?.jadwalSholat ?? [],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
