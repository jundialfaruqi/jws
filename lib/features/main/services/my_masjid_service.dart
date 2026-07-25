import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constant.dart';
import '../../../core/network/api_client.dart';
import '../../../core/providers/api_provider.dart';
import '../models/my_masjid_model.dart';

final myMasjidServiceProvider = Provider<MyMasjidService>((ref) {
  return MyMasjidService(ref.read(apiClientProvider));
});

class MyMasjidService {
  final ApiClient _apiClient;

  MyMasjidService(this._apiClient);

  Future<MyMasjidModel> getMyMasjid(String slug) async {
    final response = await _apiClient.dio.get(
      ApiConstant.myMasjid,
      queryParameters: {'slug': slug},
    );

    final responseData = response.data;
    if (responseData['success'] == true && responseData['data'] != null) {
      return MyMasjidModel.fromJson(responseData['data']);
    } else {
      throw Exception(responseData['message'] ?? 'Gagal mengambil data masjid');
    }
  }
}
