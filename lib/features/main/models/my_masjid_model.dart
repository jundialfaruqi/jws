import '../../select_profil/models/profil_masjid_model.dart';
import 'marquee_model.dart';

class MyMasjidModel {
  final String currentTime;
  final int timestamp;
  final int? themeId;
  final ProfilMasjidModel profil;
  final MarqueeModel? marquee;

  MyMasjidModel({
    required this.currentTime,
    required this.timestamp,
    this.themeId,
    required this.profil,
    this.marquee,
  });

  factory MyMasjidModel.fromJson(Map<String, dynamic> json) {
    return MyMasjidModel(
      currentTime: json['current_time'] ?? '',
      timestamp: json['timestamp'] ?? 0,
      themeId: json['theme_id'],
      profil: ProfilMasjidModel.fromJson(json['profil'] ?? {}),
      marquee: json['marquee'] != null ? MarqueeModel.fromJson(json['marquee']) : null,
    );
  }
}
