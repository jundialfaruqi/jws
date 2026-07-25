import '../../select_profil/models/profil_masjid_model.dart';
import 'marquee_model.dart';

class MyMasjidModel {
  final String currentTime;
  final int timestamp;
  final ProfilMasjidModel profil;
  final MarqueeModel? marquee;

  MyMasjidModel({
    required this.currentTime,
    required this.timestamp,
    required this.profil,
    this.marquee,
  });

  factory MyMasjidModel.fromJson(Map<String, dynamic> json) {
    return MyMasjidModel(
      currentTime: json['current_time'] ?? '',
      timestamp: json['timestamp'] ?? 0,
      profil: ProfilMasjidModel.fromJson(json['profil'] ?? {}),
      marquee: json['marquee'] != null ? MarqueeModel.fromJson(json['marquee']) : null,
    );
  }
}
