import '../../select_profil/models/profil_masjid_model.dart';
import 'marquee_model.dart';
import 'jadwal_sholat_model.dart';
import 'slide_model.dart';
import 'agenda_model.dart';

class MyMasjidModel {
  final String currentTime;
  final int timestamp;
  final int? themeId;
  final ProfilMasjidModel profil;
  final MarqueeModel? marquee;
  final List<JadwalSholatModel> jadwalSholat;
  final SlideModel? slides;
  final List<AgendaModel> agenda;

  MyMasjidModel({
    required this.currentTime,
    required this.timestamp,
    this.themeId,
    required this.profil,
    this.marquee,
    this.jadwalSholat = const [],
    this.slides,
    this.agenda = const [],
  });

  factory MyMasjidModel.fromJson(Map<String, dynamic> json) {
    return MyMasjidModel(
      currentTime: json['current_time'] ?? '',
      timestamp: json['timestamp'] ?? 0,
      themeId: json['theme_id'],
      profil: ProfilMasjidModel.fromJson(json['profil'] ?? {}),
      marquee: json['marquee'] != null ? MarqueeModel.fromJson(json['marquee']) : null,
      jadwalSholat: json['jadwal_sholat'] != null ? (json['jadwal_sholat'] as List).map((i) => JadwalSholatModel.fromJson(i)).toList() : [],
      slides: json['slides'] != null ? SlideModel.fromJson(json['slides']) : null,
      agenda: json['agenda'] != null ? (json['agenda'] as List).map((i) => AgendaModel.fromJson(i)).toList() : [],
    );
  }
}
