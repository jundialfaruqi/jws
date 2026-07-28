import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constant.dart';
import '../../../core/network/api_client.dart';
import '../../../core/providers/api_provider.dart';
import '../models/my_masjid_model.dart';

import '../../../core/services/offline_cache_service.dart';

final myMasjidServiceProvider = Provider<MyMasjidService>((ref) {
  return MyMasjidService(
    ref.read(apiClientProvider),
    ref.read(offlineCacheServiceProvider),
  );
});

class MyMasjidService {
  final ApiClient _apiClient;
  final OfflineCacheService _cacheService;

  MyMasjidService(this._apiClient, this._cacheService);

  Future<({MyMasjidModel data, bool isFromCache})> getMyMasjid(int id) async {
    try {
      final response = await _apiClient.dio.get(
        ApiConstant.myMasjid,
        queryParameters: {'id': id},
      );

      final responseData = response.data;
      if (responseData['success'] == true && responseData['data'] != null) {
        // Simpan raw JSON ke cache untuk berjaga-jaga saat mati lampu
        await _cacheService.saveMyMasjid(id, responseData['data']);
        
        return (
          data: MyMasjidModel.fromJson(responseData['data']),
          isFromCache: false,
        );
      } else {
        throw Exception(responseData['message'] ?? 'Gagal mengambil data masjid');
      }
    } catch (e) {
      // Jika terjadi error (misal Timeout/Server Down), coba baca dari Offline Cache
      final cachedData = await _cacheService.loadMyMasjid(id);
      if (cachedData != null) {
        debugPrint('✅ Menggunakan Offline Cache untuk Masjid ID $id');
        return (
          data: MyMasjidModel.fromJson(cachedData),
          isFromCache: true,
        );
      }
      
      // Jika tidak ada cache, lempar ulang errornya
      rethrow;
    }
  }
}
