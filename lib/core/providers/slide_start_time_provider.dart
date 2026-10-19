import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider ini digunakan untuk mensinkronkan AppImageSlider yang berada di dalam MainContent
/// agar slide-nya bisa mereset ke gambar pertama saat kembali dari tayangan Jumbotron.
/// Menggunakan Notifier agar state dapat diupdate tanpa perlu merecreate ProviderScope.
class SlideStartTimeNotifier extends Notifier<int?> {
  @override
  int? build() => null;

  void setStartTime(int? time) {
    state = time;
  }
}

final slideStartTimeProvider =
    NotifierProvider<SlideStartTimeNotifier, int?>(SlideStartTimeNotifier.new);
