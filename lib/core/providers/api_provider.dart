import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/api_client.dart';

/// Provider global untuk mengakses class ApiClient.
/// Ini dibuat sekali dan akan bertahan selama aplikasi berjalan.
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

/// Provider pembantu (opsional) untuk mempermudah akses
/// jika Anda hanya butuh memanggil instance 'Dio'-nya saja di tempat lain.
final dioProvider = Provider((ref) {
  return ref.watch(apiClientProvider).dio;
});
