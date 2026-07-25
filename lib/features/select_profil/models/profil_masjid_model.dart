class ProfilMasjidModel {
  final int id;
  final String name;
  final String slug;

  ProfilMasjidModel({
    required this.id,
    required this.name,
    required this.slug,
  });

  factory ProfilMasjidModel.fromJson(Map<String, dynamic> json) {
    return ProfilMasjidModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
    };
  }
}
