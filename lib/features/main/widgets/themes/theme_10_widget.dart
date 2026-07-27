import 'package:flutter/material.dart';
import 'package:jws/core/widgets/app_marquee.dart';
import 'package:jws/core/widgets/app_masjid_title.dart';
import 'package:jws/core/widgets/app_jadwal_sholat_horizontal.dart';
import 'package:jws/core/widgets/app_next_prayer_bar_theme_10.dart';
import 'package:jws/core/widgets/app_image_slider.dart';
import 'package:jws/core/widgets/app_analog_clock.dart';
import 'package:jws/core/widgets/app_agenda_widget.dart';
import 'package:jws/core/widgets/app_keuangan_widget.dart';
import 'package:jws/core/constants/app_colors.dart';
import '../../models/my_masjid_model.dart';
import '../../models/marquee_model.dart';

class Theme10Widget extends StatelessWidget {
  final MyMasjidModel data;

  const Theme10Widget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final marqueeText =
        data.marquee?.concatenatedText ?? MarqueeModel.defaultMarqueeText;
    final speedMultiplier = data.marquee?.marqueeSpeed ?? 1.0;
    final calculatedVelocity = 120.0 * speedMultiplier;

    final slideUrls = (data.slides?.validSlides.isNotEmpty == true)
        ? data.slides!.validSlides
        : [
            'https://images.unsplash.com/photo-1519817650390-64a93db51149?q=80&w=2000',
            'https://images.unsplash.com/photo-1564121211835-e88c852648ab?q=80&w=2000',
            'https://images.unsplash.com/photo-1584551246679-0daf3d275d05?q=80&w=2000',
          ];

    return Stack(
      children: [
        Column(
          children: [
            // Judul Masjid
            AppMasjidTitle(
              title: data.profil.name,
              address: data.profil.address,
              logoMasjid: data.profil.logoMasjid,
              logoPemerintah: data.profil.logoPemerintah,
              backgroundColor: AppColors.bgBlue,
              textColor: AppColors.textInverse,
              addressColor: AppColors.textInverse,
              isLeftAligned: true,
            ),

            // Info Bar Waktu Sholat & Tanggal
            AppNextPrayerBarTheme10(
              leftMargin: 600, // Menghindari card melayang di kiri
              jadwalSholatList: data.jadwalSholat,
            ),

            // Konten Utama (Tengah) - Tema 10 (Default)
            Expanded(
              child: Container(
                color: AppColors.bgNavy, // Dasar warna navy
                child: Row(
                  children: [
                    // Sisi Kiri: Widget Laporan Keuangan (500px)
                    SizedBox(
                      width: 500,
                      child: AppKeuanganWidget(
                        laporanData: data.laporanKeuangan,
                        scrollSpeed: data.durasi?.financeScrollSpeed ?? 0,
                      ),
                    ),
                    // Sisi Kanan: Gambar Slide
                    Expanded(
                      child: AppImageSlider(
                        imageUrls: slideUrls,
                        externalSync: true,
                        // leftMargin dihapus karena ukurannya sudah ditahan oleh SizedBox 500px di kiri
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Baris Horizontal Jadwal Sholat
            Container(
              height: 120,
              color: AppColors.bgNavy,
              padding: const EdgeInsets.only(
                left: 500,
                right: 6,
                top: 12,
                bottom: 12,
              ),
              child: AppJadwalSholatHorizontal(
                jadwalSholatList: data.jadwalSholat,
              ),
            ),

            // Widget Marquee (Bawah)
            AppMarquee(
              text: marqueeText,
              velocity: calculatedVelocity,
              backgroundColor: AppColors.bgDark,
              textStyle: const TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
                fontSize: 64,
                color: AppColors.textYellow,
              ),
            ),
          ],
        ),

        // Jam Analog Melayang di Kiri Bawah
        Positioned(
          left: 0,
          bottom: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.only(
                left: 20,
                top: 12,
                bottom: 12,
                right: 12, // Melebarkan sisi kanan pembungkus jam
              ),
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.zero,
                  topRight: Radius.circular(400),
                  bottomRight: Radius.circular(400),
                  bottomLeft: Radius.zero,
                ),
                color: AppColors.bgNavy,
              ),
              child: const AppAnalogClock(size: 240),
            ),
          ),
        ),

        // Widget Agenda (Kanan Bawah di atas Marquee dan Jadwal Sholat)
        Positioned(
          right: 32,
          bottom:
              270, // BAGIAN INI: Mengatur jarak / menaikkan kotak agenda dari bawah layar
          child: AppAgendaWidget(agendas: data.agenda),
        ),
      ],
    );
  }
}

class JadwalCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    // Tarik garis dari kiri atas ke kanan atas (mundur 150px untuk memberi ruang kurva)
    path.lineTo(size.width - 230, 0);
    // Buat kurva melengkung ke kanan tengah maksimal menyentuh batas container, lalu kembali ke kiri bawah
    path.quadraticBezierTo(
      size.width,
      size.height / 2, // Titik kontrol menyentuh ujung kanan
      size.width - 230,
      size.height, // Titik akhir kurva di bawah
    );
    // Tarik garis kembali ke kiri bawah
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
