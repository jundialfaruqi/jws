import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider ini digunakan untuk mensinkronkan AppImageSlider yang berada di dalam MainContent
/// agar slide-nya bisa mereset ke gambar pertama saat kembali dari tayangan Jumbotron.
/// Jika nilainya null, slider akan menggunakan jam absolut dunia (untuk Iqomah dan Jumat).
final slideStartTimeProvider = Provider<int?>((ref) => null);
