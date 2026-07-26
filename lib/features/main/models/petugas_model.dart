class PetugasModel {
  final int id;
  final String hari;
  final String tanggalFormat;
  final String khatib;
  final String imam;
  final String muadzin;

  PetugasModel({
    required this.id,
    required this.hari,
    required this.tanggalFormat,
    required this.khatib,
    required this.imam,
    required this.muadzin,
  });

  factory PetugasModel.fromJson(Map<String, dynamic> json) {
    return PetugasModel(
      id: json['id'] ?? 0,
      hari: json['hari'] ?? '',
      tanggalFormat: json['tanggal_format'] ?? '',
      khatib: json['khatib'] ?? '',
      imam: json['imam'] ?? '',
      muadzin: json['muadzin'] ?? '',
    );
  }
}
