import 'package:flutter_riverpod/flutter_riverpod.dart';

final timeSyncServiceProvider = Provider<TimeSyncService>((ref) {
  return TimeSyncService();
});

class TimeSyncService {
  int? _serverTimestampMs;
  Stopwatch? _stopwatch;

  /// Sinkronisasi waktu menggunakan timestamp dari server.
  /// Mendukung format detik (10 digit) maupun milidetik (13 digit).
  void sync(int serverTimestamp, {int latencyMs = 0}) {
    if (serverTimestamp < 10000000000) {
      // Format detik (contoh: 1785163942)
      _serverTimestampMs = (serverTimestamp * 1000) + latencyMs;
    } else {
      // Format milidetik (contoh: 1785163942000)
      _serverTimestampMs = serverTimestamp + latencyMs;
    }
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
