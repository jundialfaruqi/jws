import 'profil_masjid_model.dart';

class PaginatedProfilModel {
  final List<ProfilMasjidModel> data;
  final int currentPage;
  final int lastPage;
  final int total;

  PaginatedProfilModel({
    required this.data,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  factory PaginatedProfilModel.fromJson(Map<String, dynamic> json) {
    var list = json['data'] as List? ?? [];
    List<ProfilMasjidModel> dataList = list.map((i) => ProfilMasjidModel.fromJson(i)).toList();

    return PaginatedProfilModel(
      data: dataList,
      currentPage: json['current_page'] ?? 1,
      lastPage: json['last_page'] ?? 1,
      total: json['total'] ?? 0,
    );
  }
}
