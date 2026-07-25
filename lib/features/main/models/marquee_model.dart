class MarqueeModel {
  final int? id;
  final int? userId;
  final String? marquee1;
  final String? marquee2;
  final String? marquee3;
  final String? marquee4;
  final String? marquee5;
  final String? marquee6;
  final double? marqueeSpeed;

  MarqueeModel({
    this.id,
    this.userId,
    this.marquee1,
    this.marquee2,
    this.marquee3,
    this.marquee4,
    this.marquee5,
    this.marquee6,
    this.marqueeSpeed,
  });

  factory MarqueeModel.fromJson(Map<String, dynamic> json) {
    return MarqueeModel(
      id: json['id'],
      userId: json['user_id'],
      marquee1: json['marquee1'],
      marquee2: json['marquee2'],
      marquee3: json['marquee3'],
      marquee4: json['marquee4'],
      marquee5: json['marquee5'],
      marquee6: json['marquee6'],
      marqueeSpeed: json['marquee_speed'] != null ? double.tryParse(json['marquee_speed'].toString()) : null,
    );
  }

  static String get defaultMarqueeText {
    return [
      "Matikan ponsel atau gunakan mode senyap saat berada di dalam masjid",
      "Mohon menjaga kebersihan di dalam masjid",
      "Berdoalah untuk umat Islam",
      "Shalatlah berjamaah untuk mendapatkan lebih banyak pahala",
      "Ingatlah untuk berdonasi demi pemeliharaan masjid",
      "Harap gunakan rak sepatu yang telah disediakan"
    ].join("   •   ");
  }

  // Helper method untuk menggabungkan semua teks marquee menjadi satu kalimat panjang
  String get concatenatedText {
    final List<String> parts = [];
    if (marquee1 != null && marquee1!.trim().isNotEmpty) parts.add(marquee1!.trim());
    if (marquee2 != null && marquee2!.trim().isNotEmpty) parts.add(marquee2!.trim());
    if (marquee3 != null && marquee3!.trim().isNotEmpty) parts.add(marquee3!.trim());
    if (marquee4 != null && marquee4!.trim().isNotEmpty) parts.add(marquee4!.trim());
    if (marquee5 != null && marquee5!.trim().isNotEmpty) parts.add(marquee5!.trim());
    if (marquee6 != null && marquee6!.trim().isNotEmpty) parts.add(marquee6!.trim());
    
    if (parts.isEmpty) return defaultMarqueeText;
    return parts.join("   •   ");
  }
}
