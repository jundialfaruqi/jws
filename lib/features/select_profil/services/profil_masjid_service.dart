import 'package:dio/dio.dart';
import '../../../core/constants/api_constant.dart';
import '../models/paginated_profil_model.dart';

class ProfilMasjidService {
  final Dio _dio;

  ProfilMasjidService(this._dio);

  Future<PaginatedProfilModel> getProfilMasjids({int page = 1, String? searchQuery}) async {
    try {
      final queryParams = <String, dynamic>{'page': page};
      if (searchQuery != null && searchQuery.isNotEmpty) {
        queryParams['search'] = searchQuery;
      }

      final response = await _dio.get(
        ApiConstant.profilMasjid,
        queryParameters: queryParams,
      );
      
      if (response.data['success'] == true) {
        return PaginatedProfilModel.fromJson(response.data['data']);
      } else {
        throw Exception(response.data['message']);
      }
    } catch (e) {
      rethrow;
    }
  }
}
