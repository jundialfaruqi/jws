import 'package:flutter/material.dart';
import 'package:jws/core/widgets/app_marquee.dart';
import 'package:jws/core/widgets/app_masjid_title.dart';
import 'package:jws/core/widgets/app_jadwal_sholat.dart';
import 'package:jws/core/widgets/app_next_prayer_bar.dart';
import 'package:jws/core/widgets/app_image_slider.dart';
import 'package:jws/core/widgets/app_analog_clock.dart';
import 'package:jws/core/widgets/app_agenda_widget.dart';
import 'package:jws/core/constants/app_colors.dart';
import '../../models/my_masjid_model.dart';
import '../../models/marquee_model.dart';

class Theme4Widget extends StatelessWidget {
  final MyMasjidModel data;

  const Theme4Widget({super.key, required this.data});

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

            // Info Bar Tanggal (Tanpa Countdown)
            AppNextPrayerBar(
              leftMargin: 600, // Menghindari card melayang di kiri
              jadwalSholatList: data.jadwalSholat,
              dateOnly: true, // Hanya tampilkan tanggal
            ),

            // Konten Utama (Tengah) - Tema 4
            Expanded(
              child: Container(
                color: AppColors.bgNavy,
                child: AppImageSlider(
                  imageUrls: slideUrls,
                  leftMargin: 500,
                ),
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

        // Widget Agenda di kiri bawah (Diurutkan LEBIH DULU agar posisinya di BELAKANG card Jadwal Sholat)
        Positioned(
          left: 600, // Menjorok ke kanan dari card jadwal sholat
          bottom: 140, // Diberi jarak agar tidak menempel dengan marquee
          child: AppAgendaWidget(agendas: data.agenda, slideLeft: true), // Bergeser ke/dari kiri
        ),

        // Jadwal Sholat Melayang di Kiri (Akan menutupi agenda saat tersembunyi)
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          child: PhysicalShape(
            clipper: JadwalCurveClipper(),
            color: AppColors.bgNavy,
            elevation: 16.0,
            shadowColor: Colors.black,
            clipBehavior: Clip.antiAlias,
            child: AppJadwalSholat(
              backgroundColor: AppColors.bgNavy,
              textColor: AppColors.textYellow,
              iconColor: AppColors.textYellow,
              jadwalSholatList: data.jadwalSholat,
            ),
          ),
        ),

        // Jam Analog Melayang Tepat di Tengah Lengkungan (Peak Kurva)
        Positioned(
          left: 370,
          top: 0,
          bottom: 0,
          child: const Center(child: AppAnalogClock(size: 380)),
        ),



        // Teks menuju waktu sholat berikutnya beserta countdown melayang di kanan layar atas marquee
        Positioned(
          right: 32,
          bottom: 140, // Diberi jarak agar tidak menempel dengan marquee
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.black54, // hitam transparan
              borderRadius: BorderRadius.circular(24),
            ),
            child: AppNextPrayerBar(
              jadwalSholatList: data.jadwalSholat,
              countdownOnly: true,
              fontSize: 32,
            ),
          ),
        ),
      ],
    );
  }
}

class JadwalCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(size.width - 230, 0);
    path.quadraticBezierTo(
      size.width,
      size.height / 2,
      size.width - 230,
      size.height,
    );
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
