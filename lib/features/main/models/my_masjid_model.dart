import '../../select_profil/models/profil_masjid_model.dart';
import 'marquee_model.dart';
import 'jadwal_sholat_model.dart';
import 'slide_model.dart';
import 'agenda_model.dart';
import 'petugas_model.dart';
import 'durasi_model.dart';
import 'laporan_keuangan_model.dart';

class MyMasjidModel {
  final String currentTime;
  final int timestamp;
  final int? themeId;
  final ProfilMasjidModel profil;
  final MarqueeModel? marquee;
  final List<JadwalSholatModel> jadwalSholat;
  final SlideModel? slides;
  final SlideModel? slideIqomah;
  final SlideModel? slideJumat;
  final SlideModel? slideFinal;
  final List<AgendaModel> agenda;
  final String agendaMessage;
  final List<PetugasModel> petugasJumat;
  final SlideModel? jumbotronPemko;
  final SlideModel? jumbotronMasjid;
  final DurasiModel? durasi;
  final LaporanKeuanganDataModel? laporanKeuangan;

  MyMasjidModel({
    required this.currentTime,
    required this.timestamp,
    this.themeId,
    required this.profil,
    this.marquee,
    this.jadwalSholat = const [],
    this.slides,
    this.slideIqomah,
    this.slideJumat,
    this.slideFinal,
    this.agenda = const [],
    this.agendaMessage = '',
    this.petugasJumat = const [],
    this.jumbotronPemko,
    this.jumbotronMasjid,
    this.durasi,
    this.laporanKeuangan,
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
      slideIqomah: json['slide_iqomah'] != null && json['slide_iqomah']['data'] != null ? SlideModel.fromJson(json['slide_iqomah']['data']) : null,
      slideJumat: json['slide_jumat'] != null && json['slide_jumat']['data'] != null ? SlideModel.fromJson(json['slide_jumat']['data']) : null,
      slideFinal: json['slide_final'] != null && json['slide_final']['data'] != null ? SlideModel.fromJson(json['slide_final']['data']) : null,
      agenda: json['agenda'] != null && json['agenda']['data'] != null ? (json['agenda']['data'] as List).map((i) => AgendaModel.fromJson(i)).toList() : [],
      agendaMessage: json['agenda'] != null && json['agenda']['message'] != null ? json['agenda']['message'] : '',
      petugasJumat: json['petugas_jumat'] != null && json['petugas_jumat']['data'] != null ? (json['petugas_jumat']['data'] as List).map((i) => PetugasModel.fromJson(i)).toList() : [],
      jumbotronPemko: json['jumbotron_pemko'] != null && json['jumbotron_pemko']['data'] != null ? SlideModel.fromJson(json['jumbotron_pemko']['data']) : null,
      jumbotronMasjid: json['jumbotron_masjid'] != null && json['jumbotron_masjid']['data'] != null ? SlideModel.fromJson(json['jumbotron_masjid']['data']) : null,
      durasi: json['durasi'] != null && json['durasi']['data'] != null ? DurasiModel.fromJson(json['durasi']['data']) : DurasiModel(),
      laporanKeuangan: json['laporan_keuangan'] != null && json['laporan_keuangan']['data'] != null ? LaporanKeuanganDataModel.fromJson(json['laporan_keuangan']['data']) : null,
    );
  }
}
