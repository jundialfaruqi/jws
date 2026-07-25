class ProfilMasjidModel {
  final int id;
  final String name;
  final String slug;
  final String? address;
  final String? logoMasjid;
  final String? logoPemerintah;

  ProfilMasjidModel({
    required this.id,
    required this.name,
    required this.slug,
    this.address,
    this.logoMasjid,
    this.logoPemerintah,
  });

  factory ProfilMasjidModel.fromJson(Map<String, dynamic> json) {
    return ProfilMasjidModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      address: json['address'],
      logoMasjid: json['logo_masjid'],
      logoPemerintah: json['logo_pemerintah'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'address': address,
      'logo_masjid': logoMasjid,
      'logo_pemerintah': logoPemerintah,
    };
  }
}
