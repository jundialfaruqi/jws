class SlideModel {
  final int id;
  final String? slide1;
  final String? slide2;
  final String? slide3;
  final String? slide4;
  final String? slide5;
  final String? slide6;

  SlideModel({
    required this.id,
    this.slide1,
    this.slide2,
    this.slide3,
    this.slide4,
    this.slide5,
    this.slide6,
  });

  factory SlideModel.fromJson(Map<String, dynamic> json) {
    return SlideModel(
      id: json['id'] ?? 0,
      slide1: json['slide1'],
      slide2: json['slide2'],
      slide3: json['slide3'],
      slide4: json['slide4'],
      slide5: json['slide5'],
      slide6: json['slide6'],
    );
  }

  // Helper untuk mendapatkan list url gambar yang tidak null
  List<String> get validSlides {
    final slides = [slide1, slide2, slide3, slide4, slide5, slide6];
    return slides.whereType<String>().toList();
  }
}
