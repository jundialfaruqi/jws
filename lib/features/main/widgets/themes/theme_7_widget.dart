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
              leftMargin: 550, // Menghindari card melayang di kiri
              jadwalSholatList: data.jadwalSholat,
              nextPrayerFontSize: 24.0,
              dateFontSize: 24.0,
            ),

            // Konten Utama (Tengah) - Tema 7 (Default)
            Expanded(
              child: Container(
                color: AppColors
                    .bgNavy, // Dasar warna navy untuk mengisi kekosongan kurva
                child: AppImageSlider(
                  imageUrls: slideUrls,
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
          child: CustomPaint(
            foregroundPainter: const JadwalCurveBorderPainter(
              color: Color(0xFF707070),
              width: 6.0,
            ),
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
            child: AppAnalogClock(
              size: 380,
              numberFontSize: 38,
              digitalFontSize: 28,
            ),
          ),
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

class JadwalCurveBorderPainter extends CustomPainter {
  final Color color;
  final double width;

  const JadwalCurveBorderPainter({
    this.color = const Color(0xFF707070),
    this.width = 6.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = width
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(size.width - 230, 0);
    path.quadraticBezierTo(
      size.width,
      size.height / 2,
      size.width - 230,
      size.height,
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant JadwalCurveBorderPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.width != width;
}
