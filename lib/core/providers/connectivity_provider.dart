import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'dart:io';

// Provider ini memonitor status koneksi secara real-time
final connectivityProvider = StreamProvider<List<ConnectivityResult>>((ref) async* {
  // 1. Ambil status saat ini (agar loading state langsung terganti)
  yield await Connectivity().checkConnectivity();
  // 2. Dengarkan perubahan selanjutnya secara real-time
  yield* Connectivity().onConnectivityChanged;
});

// Provider tambahan yang mengecek AKTUAL akses internet
final isConnectedProvider = FutureProvider<bool>((ref) async {
  // Pantau perubahan antarmuka jaringan
  final connectivity = await ref.watch(connectivityProvider.future);
  
  // Jika secara fisik tidak ada jaringan yang terdeteksi
  if (connectivity.contains(ConnectivityResult.none) || connectivity.isEmpty) {
    return false;
  }
  
  // Karena emulator TV kadang menipu (Ethernet seolah nyala padahal internet Mac mati),
  // kita lakukan tes PING ke server global.
  try {
    final result = await InternetAddress.lookup('google.com');
    if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
      return true;
    }
  } on SocketException catch (_) {
    return false;
  }
  
  return false;
});
