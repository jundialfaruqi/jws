class AgendaModel {
  final String name;
  final String date;
  final String dateRaw;
  final String daysLabel;
  final bool aktif;

  AgendaModel({
    required this.name,
    required this.date,
    required this.dateRaw,
    required this.daysLabel,
    required this.aktif,
  });

  factory AgendaModel.fromJson(Map<String, dynamic> json) {
    return AgendaModel(
      name: json['name'] ?? '',
      date: json['date'] ?? '',
      dateRaw: json['date_raw'] ?? '',
      daysLabel: json['days_label'] ?? '',
      aktif: json['aktif'] == 1 || json['aktif'] == true,
    );
  }
}
