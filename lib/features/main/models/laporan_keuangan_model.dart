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
  final int groupCategoryId;
  final String groupCategoryName;
  final List<LaporanKeuanganItemModel> items;
  final int itemsTotal;
  final int sumMasukMonth;
  final int sumKeluarMonth;
  final int totalSaldoAll;

  LaporanKeuanganGroupModel({
    required this.groupCategoryId,
    required this.groupCategoryName,
    required this.items,
    required this.itemsTotal,
    required this.sumMasukMonth,
    required this.sumKeluarMonth,
    required this.totalSaldoAll,
  });

  factory LaporanKeuanganGroupModel.fromJson(Map<String, dynamic> json) {
    return LaporanKeuanganGroupModel(
      groupCategoryId: json['group_category_id'] ?? 0,
      groupCategoryName: json['group_category_name'] ?? '-',
      items: json['items'] != null
          ? (json['items'] as List).map((i) => LaporanKeuanganItemModel.fromJson(i)).toList()
          : [],
      itemsTotal: json['items_total'] ?? 0,
      sumMasukMonth: json['sum_masuk_month'] ?? 0,
      sumKeluarMonth: json['sum_keluar_month'] ?? 0,
      totalSaldoAll: json['total_saldo_all'] ?? 0,
    );
  }
}
