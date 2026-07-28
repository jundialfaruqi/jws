import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/my_masjid_model.dart';
import '../services/my_masjid_service.dart';
import '../../../core/time/time_sync_service.dart';
import '../../../core/services/audio_downloader_service.dart';

final myMasjidProvider = FutureProvider.family<MyMasjidModel, int>((ref, id) async {
  final service = ref.read(myMasjidServiceProvider);
  final data = await service.getMyMasjid(id);
  
  // Sinkronisasi waktu menggunakan timestamp dari server
  ref.read(timeSyncServiceProvider).sync(data.timestamp);
  
  // Sinkronisasi audio secara background
  ref.read(audioDownloaderProvider.notifier).syncAudios(data);
  
  return data;
});
