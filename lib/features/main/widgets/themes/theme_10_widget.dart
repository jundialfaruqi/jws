import 'package:flutter/material.dart';
import 'package:jws/core/widgets/app_marquee.dart';
import 'package:jws/core/widgets/app_masjid_title.dart';
import 'package:jws/core/widgets/app_jadwal_sholat_horizontal.dart';
import 'package:jws/core/widgets/app_next_prayer_bar.dart';
import 'package:jws/core/widgets/app_image_slider.dart';
import 'package:jws/core/widgets/app_analog_clock.dart';
import 'package:jws/core/widgets/app_agenda_widget.dart';
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
              isRightAligned: true,
            ),

            // Info Bar Waktu Sholat & Tanggal
            AppNextPrayerBar(
              leftMargin: 600, // Menghindari card melayang di kiri
              jadwalSholatList: data.jadwalSholat,
            ),

            // Konten Utama (Tengah) - Tema 10 (Default)
            Expanded(
              child: Container(
                color: AppColors
                    .bgNavy, // Dasar warna navy untuk mengisi kekosongan kurva
                child: AppImageSlider(
                  imageUrls: slideUrls,
                  externalSync: true,
                  leftMargin:
                      500, // Geser slider ke kanan agar tidak banyak tertutup
                ),
              ),
            ),

            // Baris Horizontal Jadwal Sholat
            Container(
              height: 90,
              color: AppColors.bgNavy.withValues(alpha: 0.9),
              padding: const EdgeInsets.only(
                left: 500,
                right: 6,
                top: 4,
                bottom: 4,
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

        // Jam Analog Melayang Tepat di Tengah Lengkungan (Peak Kurva)
        Positioned(
          left:
              370, // Digeser lebih jauh ke kiri (merasuk lebih dalam ke card jadwal sholat)
          top: 0,
          bottom: 0,
          child: const Center(child: AppAnalogClock(size: 380)),
        ),

        // Widget Agenda (Kanan Bawah di atas Marquee)
        Positioned(
          right: 32,
          bottom: 160, // Dinaikkan agar tidak terlalu mepet dengan marquee
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
