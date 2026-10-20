import 'package:flutter/material.dart';
import 'package:jws/core/widgets/app_marquee.dart';
import 'package:jws/core/widgets/app_masjid_title_theme_10.dart';
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
            'assets/slide-default/slide-main-default.jpg',
            'assets/slide-default/slide-main-default-2.jpg',
          ];

    return Stack(
      children: [
        Column(
          children: [
            // Konten Utama (Tengah) - Tema 10 dengan Floating Bar
            Expanded(
              child: Stack(
                children: [
                  // Dasar (Widget Keuangan & Image Slider + Jadwal)
                  Container(
                    color: AppColors.bgNavy,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          width: 500,
                          child: AppKeuanganWidget(
                            laporanData: data.laporanKeuangan,
                            scrollSpeed: data.durasi?.financeScrollSpeed ?? 0,
                            margin: const EdgeInsets.only(
                              top: 148,
                              bottom: 0,
                              left: 0,
                              right: 0,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: RepaintBoundary(
                                  child: AppImageSlider(
                                    imageUrls: slideUrls,
                                    leftMargin:
                                        0, // Dihapus karena sudah berada di sebelah kolom Keuangan (500px)
                                  ),
                                ),
                              ),
                              Container(
                                height: 150,
                                padding: const EdgeInsets.only(
                                  left: 6,
                                  right: 6,
                                  top: 12,
                                  bottom: 12,
                                ),
                                child: AppJadwalSholatHorizontal(
                                  jadwalSholatList: data.jadwalSholat,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Floating Next Prayer Bar (Melayang di atas slider)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: AppNextPrayerBarTheme10(
                      dateCardWidth: 880,
                      countdownCardWidth: 560,
                      jadwalSholatList: data.jadwalSholat,
                    ),
                  ),
                ],
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
              child: const AppAnalogClock(size: 300),
            ),
          ),
        ),

        // Widget Agenda (Kanan Bawah di atas Marquee dan Jadwal Sholat)
        Positioned(
          right: 32,
          bottom:
              300, // BAGIAN INI: Mengatur jarak / menaikkan kotak agenda dari bawah layar
          child: AppAgendaWidget(
            agendas: data.agenda,
            backgroundColor: AppColors.bgBlue.withValues(alpha: 0.40),
          ),
        ),

        // Judul Masjid (Melayang di atas)
        Positioned(
          top: 0,
          left: 0,
          child: AppMasjidTitleTheme10(
            width: 1000,
            title: data.profil.name,
            address: data.profil.address,
            logoMasjid: data.profil.logoMasjid,
            logoPemerintah: data.profil.logoPemerintah,
            backgroundColor: AppColors
                .bgNavy, // Transparansi gradient sudah diatur di dalam widget AppMasjidTitleTheme10
            textColor: AppColors.textYellow,
            addressColor: AppColors.textInverse,
            isLeftAligned: true,
          ),
        ),
      ],
    );
  }
}


