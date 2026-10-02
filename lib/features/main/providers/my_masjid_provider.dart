import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/my_masjid_model.dart';
import '../services/my_masjid_service.dart';
import '../../../core/time/time_sync_service.dart';
import '../../../core/services/audio_downloader_service.dart';
import '../../../core/services/image_downloader_service.dart';
import '../../../core/services/video_downloader_service.dart';

import 'dart:async';

final myMasjidProvider = FutureProvider.family<MyMasjidModel, int>((ref, id) async {
  final service = ref.read(myMasjidServiceProvider);
  final result = await service.getMyMasjid(id);
  
  if (!result.isFromCache) {
    // Sinkronisasi waktu menggunakan timestamp dari server (HANYA JIKA DARI SERVER)
    ref.read(timeSyncServiceProvider).sync(result.data.timestamp);
  } else {
    // JIKA DARI CACHE: Jangan sinkronisasi waktu agar tidak terjadi Time Travel.
    // Lakukan Auto-Retry rahasia (Stale-While-Revalidate) setiap 5 menit.
    final timer = Timer(const Duration(minutes: 5), () {
      ref.invalidateSelf();
    });
    ref.onDispose(timer.cancel);
  }
  
  // Sinkronisasi audio secara background
  ref.read(audioDownloaderProvider.notifier).syncAudios(result.data);
  
  // Sinkronisasi gambar secara background (Pre-cache semua gambar Iqomah, Jumat, Slide)
  ref.read(imageDownloaderProvider).preCacheAllImages(result.data);

  // Sinkronisasi video jumbotron secara background (unduh ke internal & hapus cache lama jika diganti)
  ref.read(videoDownloaderProvider.notifier).syncVideo(result.data);
  
  return result.data;
});
