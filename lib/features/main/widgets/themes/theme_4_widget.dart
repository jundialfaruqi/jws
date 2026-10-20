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
            'assets/slide-default/slide-main-default.jpg',
            'assets/slide-default/slide-main-default-2.jpg',
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
              textColor: AppColors.textYellow,
              addressColor: AppColors.textInverse,
              isRightAligned: true,
            ),

            // Info Bar Tanggal (Tanpa Countdown)
            AppNextPrayerBar(
              leftMargin: 600, // Menghindari card melayang di kiri
              jadwalSholatList: data.jadwalSholat,
              dateOnly: true, // Hanya tampilkan tanggal
              dateFontSize: 36.0,
              hijriFontSize: 32.0,
              iconSize: 38.0,
            ),

            // Konten Utama (Tengah) - Tema 4
            Expanded(
              child: Container(
                color: AppColors.bgNavy,
                child: RepaintBoundary(
                  child: AppImageSlider(imageUrls: slideUrls, leftMargin: 500),
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
          child: RepaintBoundary(
            child: AppAgendaWidget(
              agendas: data.agenda,
              slideLeft: true,
              backgroundColor: AppColors.bgBlue.withValues(alpha: 0.40),
            ),
          ), // Bergeser ke/dari kiri
        ),

        // Jadwal Sholat Melayang di Kiri (Bebas Stencil & Bebas Memory Leak)
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          child: RepaintBoundary(
            child: CustomPaint(
              painter: const JadwalCurveBackgroundPainter(),
              child: AppJadwalSholat(
                backgroundColor: Colors.transparent,
                textColor: AppColors.textYellow,
                iconColor: AppColors.textYellow,
                jadwalSholatList: data.jadwalSholat,
                highlightFadingGradient: true,
              ),
            ),
          ),
        ),

        // Jam Analog Melayang Tepat di Tengah Lengkungan (Peak Kurva)
        Positioned(
          left: 350,
          top: 0,
          bottom: 0,
          child: const Center(
            child: RepaintBoundary(
              child: AppAnalogClock(
                size: 380,
                numberFontSize: 38,
                digitalFontSize: 36,
              ),
            ),
          ),
        ),

        // Teks menuju waktu sholat berikutnya beserta countdown melayang di kanan layar atas marquee
        Positioned(
          right: 32,
          bottom: 140, // Diberi jarak agar tidak menempel dengan marquee
          child: RepaintBoundary(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.black.withValues(
                  alpha: 0.40,
                ), // Transparansi dikurangi agar lebih solid & jelas terbaca
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: AppNextPrayerBar(
                jadwalSholatList: data.jadwalSholat,
                countdownOnly: true,
                nextPrayerFontSize: 34.0,
                countdownFontSize: 40.0,
                iconSize: 42.0,
                countdownCardColor: AppColors.textYellow.withValues(
                  alpha: 0.15,
                ),
                countdownTextColor: AppColors.textYellow,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Painter background, bayangan, dan garis kurva menyatu tanpa membutuhkan Stencil Buffer / Skia Clip Mask.
/// Mencegah malloc error dan thread allocation crash pada Android TV 1 GB RAM.
class JadwalCurveBackgroundPainter extends CustomPainter {
  final Color color;
  final Color borderColor;
  final double borderWidth;

  const JadwalCurveBackgroundPainter({
    this.color = AppColors.bgNavy,
    this.borderColor = const Color(0xFF707070),
    this.borderWidth = 6.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
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

    // 1. Gambar bayangan halus
    canvas.drawShadow(path, Colors.black.withValues(alpha: 0.5), 12.0, false);

    // 2. Gambar isi solid Navy
    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    // 3. Gambar garis border kurva
    final borderPaint = Paint()
      ..color = borderColor
      ..strokeWidth = borderWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final borderPath = Path();
    borderPath.moveTo(size.width - 230, 0);
    borderPath.quadraticBezierTo(
      size.width,
      size.height / 2,
      size.width - 230,
      size.height,
    );

    canvas.drawPath(borderPath, borderPaint);
  }

  @override
  bool shouldRepaint(covariant JadwalCurveBackgroundPainter oldDelegate) =>
      false;
}
