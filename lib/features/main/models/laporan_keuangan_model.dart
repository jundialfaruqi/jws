class LaporanKeuanganItemModel {
  final int id;
  final String tanggal;
  final String uraian;
  final String jenis;
  final bool isOpening;
  final int saldo;
  final int groupCategoryId;
  final String groupCategoryName;

  LaporanKeuanganItemModel({
    required this.id,
    required this.tanggal,
    required this.uraian,
    required this.jenis,
    required this.isOpening,
    required this.saldo,
    required this.groupCategoryId,
    required this.groupCategoryName,
  });

  factory LaporanKeuanganItemModel.fromJson(Map<String, dynamic> json) {
    return LaporanKeuanganItemModel(
      id: json['id'] ?? 0,
      tanggal: json['tanggal'] ?? '',
      uraian: json['uraian'] ?? '',
      jenis: json['jenis'] ?? 'masuk',
      isOpening: json['is_opening'] ?? false,
      saldo: json['saldo'] ?? 0,
      groupCategoryId: json['group_category_id'] ?? 0,
      groupCategoryName: json['group_category_name'] ?? '-',
    );
  }
}

class LaporanKeuanganGroupModel {
  final int categoryId;
  final String categoryName;
  final List<LaporanKeuanganItemModel> items;
  final int itemsTotal;
  final int sumMasuk;
  final int sumKeluar;
  final int ending;
  final int saldoSebelumnya;
  final int saldoAkhir;

  LaporanKeuanganGroupModel({
    required this.categoryId,
    required this.categoryName,
    required this.items,
    required this.itemsTotal,
    required this.sumMasuk,
    required this.sumKeluar,
    required this.ending,
    required this.saldoSebelumnya,
    required this.saldoAkhir,
  });

  factory LaporanKeuanganGroupModel.fromJson(Map<String, dynamic> json) {
    return LaporanKeuanganGroupModel(
      categoryId: json['categoryId'] ?? 0,
      categoryName: json['categoryName'] ?? '-',
      items: json['items'] != null
          ? (json['items'] as List).map((i) => LaporanKeuanganItemModel.fromJson(i)).toList()
          : [],
      itemsTotal: json['items_total'] ?? 0,
      sumMasuk: json['sumMasuk'] ?? 0,
      sumKeluar: json['sumKeluar'] ?? 0,
      ending: json['ending'] ?? 0,
      saldoSebelumnya: json['saldoSebelumnya'] ?? 0,
      saldoAkhir: json['saldoAkhir'] ?? 0,
    );
  }
}

class GrandTotalsModel {
  final int sumMasuk;
  final int sumKeluar;
  final int ending;

  GrandTotalsModel({
    required this.sumMasuk,
    required this.sumKeluar,
    required this.ending,
  });

  factory GrandTotalsModel.fromJson(Map<String, dynamic> json) {
    return GrandTotalsModel(
      sumMasuk: json['sumMasuk'] ?? 0,
      sumKeluar: json['sumKeluar'] ?? 0,
      ending: json['ending'] ?? 0,
    );
  }
}

class LaporanKeuanganDataModel {
  final String periodeString;
  final List<LaporanKeuanganGroupModel> categories;
  final GrandTotalsModel grandTotals;

  LaporanKeuanganDataModel({
    required this.periodeString,
    required this.categories,
    required this.grandTotals,
  });

  factory LaporanKeuanganDataModel.fromJson(Map<String, dynamic> json) {
    return LaporanKeuanganDataModel(
      periodeString: json['periodeString'] ?? '',
      categories: json['categories'] != null
          ? (json['categories'] as List)
              .map((i) => LaporanKeuanganGroupModel.fromJson(i))
              .toList()
          : [],
      grandTotals: json['grandTotals'] != null
          ? GrandTotalsModel.fromJson(json['grandTotals'])
          : GrandTotalsModel(sumMasuk: 0, sumKeluar: 0, ending: 0),
    );
  }
}
