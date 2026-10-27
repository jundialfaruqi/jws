import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final timeSyncServiceProvider = Provider<TimeSyncService>((ref) {
  return TimeSyncService();
});

class TimeSyncService extends ChangeNotifier {
  int? _serverTimestampMs;
  Stopwatch? _stopwatch;
  Duration _simulationOffset = Duration.zero;

  bool get isSimulated => _simulationOffset != Duration.zero;
  Duration get simulationOffset => _simulationOffset;

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
    notifyListeners();
  }

  /// Dapatkan waktu nyata saat ini (tanpa offset simulasi)
  DateTime realNow() {
    if (_serverTimestampMs != null && _stopwatch != null) {
      return DateTime.fromMillisecondsSinceEpoch(
        _serverTimestampMs! + _stopwatch!.elapsedMilliseconds,
      );
    }
    return DateTime.now();
  }

  /// Dapatkan waktu aplikasi saat ini berdasarkan server + monotonic local time + offset simulasi
  DateTime now() {
    return realNow().add(_simulationOffset);
  }

  /// Tambah atau kurangi offset simulasi (misal +1 menit, -10 menit, +1 hari)
  void addOffset(Duration offset) {
    _simulationOffset += offset;
    notifyListeners();
  }

  /// Langsung setel waktu aplikasi ke tanggal & jam target tertentu
  void setTargetDateTime(DateTime target) {
    final real = realNow();
    _simulationOffset = target.difference(real);
    notifyListeners();
  }

  /// Reset kembali ke waktu nyata (tanpa offset)
  void reset() {
    _simulationOffset = Duration.zero;
    notifyListeners();
  }
}
