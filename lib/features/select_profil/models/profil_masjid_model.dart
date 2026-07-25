class ProfilMasjidModel {
  final int id;
  final String name;
  final String slug;
  final String? address;

  ProfilMasjidModel({
    required this.id,
    required this.name,
    required this.slug,
    this.address,
  });

  factory ProfilMasjidModel.fromJson(Map<String, dynamic> json) {
    return ProfilMasjidModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      address: json['address'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'address': address,
    };
  }
}
