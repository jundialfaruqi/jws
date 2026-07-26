import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/api_constant.dart';
import '../../../core/providers/selected_profil_provider.dart';
import '../../../core/widgets/app_masjid_title.dart';
import '../../../core/widgets/app_live_clock.dart';
import '../../../core/widgets/app_next_prayer_bar.dart';

class JumbotronMasjidScreen extends ConsumerWidget {
  final String imageUrl;

  const JumbotronMasjidScreen({
    super.key,
    required this.imageUrl,
  });

  String _getFullUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;

    final baseUrl = ApiConstant.baseUrl;
    final cleanBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final cleanPath = path.startsWith('/') ? path : '/$path';

    return '$cleanBase$cleanPath';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profil = ref.watch(selectedProfilProvider);
    final title = profil?.name ?? 'Nama Masjid';
    final logoPemerintah = profil?.logoPemerintah;
    final logoMasjid = profil?.logoMasjid;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Gambar Full Layar (Ditarik/Gepeng tidak masalah)
          Positioned.fill(
            child: CachedNetworkImage(
              imageUrl: _getFullUrl(imageUrl),
              fit: BoxFit.fill,
              errorWidget: (context, url, error) => const Center(
                child: Icon(Icons.broken_image, size: 100, color: Colors.white54),
              ),
            ),
          ),
          
          // Atas: Logo & Nama Masjid (membentang penuh agar tidak error RenderFlex)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AppMasjidTitle(
              title: title,
              logoPemerintah: logoPemerintah,
              logoMasjid: logoMasjid,
            ),
          ),

          // Pojok Kiri Bawah: Jam Digital Melayang
          Positioned(
            bottom: 24,
            left: 24,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white24),
              ),
              child: const AppLiveClock(
                textStyle: TextStyle(fontSize: 48, color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),

          // Pojok Kanan Bawah: Countdown Next Prayer Melayang
          Positioned(
            bottom: 24,
            right: 24,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white24),
              ),
              child: const AppNextPrayerBar(countdownOnly: true),
            ),
          ),
        ],
      ),
    );
  }
}
