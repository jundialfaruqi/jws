import 'package:dio/dio.dart';
import '../../../core/constants/api_constant.dart';
import '../models/profil_masjid_model.dart';

class ProfilMasjidService {
  final Dio _dio;

  ProfilMasjidService(this._dio);

  Future<List<ProfilMasjidModel>> getProfilMasjids({int page = 1}) async {
    try {
      final response = await _dio.get(
        ApiConstant.profilMasjid,
        queryParameters: {'page': page},
      );
      
      if (response.data['success'] == true) {
        final List data = response.data['data']['data'];
        return data.map((json) => ProfilMasjidModel.fromJson(json)).toList();
      } else {
        throw Exception(response.data['message']);
      }
    } catch (e) {
      rethrow;
    }
  }
}
