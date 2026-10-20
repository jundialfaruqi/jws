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

class Theme7Widget extends StatelessWidget {
  final MyMasjidModel data;

  const Theme7Widget({super.key, required this.data});

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

            // Info Bar Waktu Sholat & Tanggal
            AppNextPrayerBar(
              leftMargin: 550, // Menghindari tertimpa curva lengkung jadwal sholat di kiri
              jadwalSholatList: data.jadwalSholat,
              nextPrayerFontSize: 24.0,
              countdownFontSize: 26.0,
              dateFontSize: 30.0,
              hijriFontSize: 26.0,
              iconSize: 34.0,
            ),

            // Konten Utama (Tengah) - Tema 7 (Default)
            Expanded(
              child: Container(
                color: AppColors
                    .bgNavy, // Dasar warna navy untuk mengisi kekosongan kurva
                child: RepaintBoundary(
                  child: AppImageSlider(
                    imageUrls: slideUrls,
                    leftMargin:
                        500, // Geser slider ke kanan agar tidak banyak tertutup
                  ),
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
          left:
              350, // Digeser lebih jauh ke kiri (merasuk lebih dalam ke card jadwal sholat)
          top: 0,
          bottom: 0,
          child: const Center(
            child: RepaintBoundary(
              child: AppAnalogClock(
                size: 380,
                numberFontSize: 38,
                digitalFontSize: 28,
              ),
            ),
          ),
        ),

        // Widget Agenda (Kanan Bawah di atas Marquee)
        Positioned(
          right: 32,
          bottom: 160, // Dinaikkan agar tidak terlalu mepet dengan marquee
          child: RepaintBoundary(
            child: AppAgendaWidget(agendas: data.agenda),
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
  bool shouldRepaint(covariant JadwalCurveBackgroundPainter oldDelegate) => false;
}
