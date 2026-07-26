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
  final String agendaMessage;

  MyMasjidModel({
    required this.currentTime,
    required this.timestamp,
    this.themeId,
    required this.profil,
    this.marquee,
    this.jadwalSholat = const [],
    this.slides,
    this.agenda = const [],
    this.agendaMessage = '',
  });

  factory MyMasjidModel.fromJson(Map<String, dynamic> json) {
    return MyMasjidModel(
      currentTime: json['current_time'] != null ? json['current_time']['data'] ?? '' : '',
      timestamp: json['timestamp'] != null ? json['timestamp']['data'] ?? 0 : 0,
      themeId: json['theme_id'] != null ? json['theme_id']['data'] : null,
      profil: ProfilMasjidModel.fromJson(json['profil'] != null && json['profil']['data'] != null ? json['profil']['data'] : {}),
      marquee: json['marquee'] != null && json['marquee']['data'] != null ? MarqueeModel.fromJson(json['marquee']['data']) : null,
      jadwalSholat: json['jadwal_sholat'] != null && json['jadwal_sholat']['data'] != null ? (json['jadwal_sholat']['data'] as List).map((i) => JadwalSholatModel.fromJson(i)).toList() : [],
      slides: json['slides'] != null && json['slides']['data'] != null ? SlideModel.fromJson(json['slides']['data']) : null,
      agenda: json['agenda'] != null && json['agenda']['data'] != null ? (json['agenda']['data'] as List).map((i) => AgendaModel.fromJson(i)).toList() : [],
      agendaMessage: json['agenda'] != null && json['agenda']['message'] != null ? json['agenda']['message'] : '',
    );
  }
}
