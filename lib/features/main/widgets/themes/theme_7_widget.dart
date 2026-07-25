import 'package:flutter/material.dart';
import 'package:jws/core/widgets/app_marquee.dart';
import 'package:jws/core/widgets/app_masjid_title.dart';
import 'package:jws/core/widgets/app_jadwal_sholat.dart';
import 'package:jws/core/widgets/app_next_prayer_bar.dart';
import 'package:jws/core/widgets/app_image_slider.dart';
import 'package:jws/core/constants/app_colors.dart';
import '../../models/my_masjid_model.dart';
import '../../models/marquee_model.dart';

class Theme7Widget extends StatelessWidget {
  final MyMasjidModel data;

  const Theme7Widget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final marqueeText =
        data.marquee?.concatenatedText ?? MarqueeModel.defaultMarqueeText;
    final speedMultiplier = data.marquee?.marqueeSpeed ?? 1.0;
    final calculatedVelocity = 120.0 * speedMultiplier;

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
              textColor: AppColors.textYellow,
              addressColor: AppColors.textInverse,
              isRightAligned: true,
            ),

            // Info Bar Waktu Sholat & Tanggal
            AppNextPrayerBar(
              leftMargin: 600, // Menghindari card melayang di kiri
            ),

            // Konten Utama (Tengah) - Tema 7 (Default)
            Expanded(
              child: Container(
                color: AppColors
                    .bgNavy, // Dasar warna navy untuk mengisi kekosongan kurva
                child: const AppImageSlider(
                  leftMargin:
                      500, // Geser slider ke kanan agar tidak banyak tertutup
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

        // Jadwal Sholat Melayang di Kiri
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          child: ClipPath(
            clipper: JadwalCurveClipper(),
            child: AppJadwalSholat(
              backgroundColor: AppColors.bgNavy,
              textColor: AppColors.textYellow,
              iconColor: AppColors.textYellow,
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
