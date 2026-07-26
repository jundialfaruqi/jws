import 'package:flutter_riverpod/flutter_riverpod.dart';

final timeSyncServiceProvider = Provider<TimeSyncService>((ref) {
  return TimeSyncService();
});

class TimeSyncService {
  int? _serverTimestampMs;
  Stopwatch? _stopwatch;

  /// Sinkronisasi waktu menggunakan timestamp dari server (dalam detik)
  void sync(int serverTimestampSeconds) {
    _serverTimestampMs = serverTimestampSeconds * 1000;
    _stopwatch = Stopwatch()..start();
  }

  /// Dapatkan waktu aplikasi saat ini berdasarkan server + monotonic local time
  DateTime now() {
    if (_serverTimestampMs != null && _stopwatch != null) {
      return DateTime.fromMillisecondsSinceEpoch(
        _serverTimestampMs! + _stopwatch!.elapsedMilliseconds,
      );
    }
    // Fallback jika belum tersinkronisasi
    return DateTime.now();
  }
}
