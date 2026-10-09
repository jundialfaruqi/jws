import 'package:flutter/material.dart';
import 'package:jws/core/widgets/app_marquee.dart';
import 'package:jws/core/widgets/app_live_clock.dart';
import 'package:jws/core/widgets/app_masjid_title.dart';
import 'package:jws/core/widgets/app_jadwal_sholat.dart';
import 'package:jws/core/widgets/app_next_prayer_bar.dart';
import 'package:jws/core/widgets/app_image_slider.dart';
import 'package:jws/core/widgets/app_agenda_widget.dart';
import 'package:jws/core/widgets/app_keuangan_widget.dart';
import 'package:jws/core/constants/app_colors.dart';
import '../../models/my_masjid_model.dart';
import '../../models/marquee_model.dart';

class Theme12Widget extends StatelessWidget {
  final MyMasjidModel data;

  const Theme12Widget({super.key, required this.data});

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

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ===============================
          // 1 & 3: KOLOM KIRI (Lebar Tetap)
          // ===============================
          SizedBox(
            width: 380,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. App Jam Digital
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  decoration: BoxDecoration(
                    color: AppColors.bgNavy,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        blurRadius: 12,
                        offset: const Offset(4, 6),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  alignment: Alignment.center,
                  child: AppLiveClock(
                    builder: (context, now) {
                      final hour = now.hour.toString().padLeft(2, '0');
                      final minute = now.minute.toString().padLeft(2, '0');
                      final second = now.second.toString().padLeft(2, '0');

                      String timeZone = 'WIB';
                      if (now.timeZoneOffset.inHours == 8) timeZone = 'WITA';
                      if (now.timeZoneOffset.inHours == 9) timeZone = 'WIT';

                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            hour,
                            style: const TextStyle(
                              fontSize: 84,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textYellow,
                              fontFamily: 'Poppins',
                            ),
                          ),
                          Container(
                            height: 56,
                            width: 3,
                            margin: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.grey.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          Text(
                            minute,
                            style: const TextStyle(
                              fontSize: 84,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textYellow,
                              fontFamily: 'Poppins',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                second,
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textYellow,
                                  fontFamily: 'Poppins',
                                  height: 1.0,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                timeZone,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white70,
                                  fontFamily: 'Poppins',
                                  letterSpacing: 1,
                                  height: 1.0,
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ),
                // Pembatas Tipis Dihapus
                // 3. App Jadwal Sholat
                Expanded(
                  child: Container(
                    color: AppColors.bgDark,
                    child: AppJadwalSholat(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      iconSize: 56,
                      titleFontSize: 24,
                      timeFontSize: 56,
                      backgroundColor: AppColors.bgDark,
                      textColor: Colors.white,
                      iconColor: AppColors.textYellow,
                      jadwalSholatList: data.jadwalSholat,
                      useCardVariant: true,
                      cardColor: AppColors.bgBlue,
                      nextTextColor: AppColors.textYellow,
                      nextCardColor: AppColors.bgNavy,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Pembatas Vertikal Utama Dihapus

          // ===============================
          // 2, 4, 5, 6, 7, 8, 9: KOLOM KANAN (Expanded)
          // ===============================
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 2. App Title (Rata Kanan)
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

                // Pembatas Horisontal Dihapus

                // 4. App Tanggal (Rata Kanan)
                Container(
                  color: AppColors.bgDark.withValues(alpha: 0.8),
                  alignment: Alignment.centerRight,
                  child: AppNextPrayerBar(
                    jadwalSholatList: data.jadwalSholat,
                    dateOnly: true,
                  ),
                ),

                // Pembatas Horisontal Dihapus

                // Baris Tengah (Slide & Keuangan)
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // KOLOM TENGAH KIRI (Slide & Next Prayer)
                      Expanded(
                        flex: 7,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // 5. App Slide
                            Expanded(
                              child: AppImageSlider(
                                imageUrls: slideUrls,
                                leftMargin: 0,
                              ),
                            ),
                            // Pembatas Horisontal Dihapus
                            // 7. App Next Prayer (Countdown) & Logo Diskominfo
                            Container(
                              color: AppColors.bgNavy,
                              padding: const EdgeInsets.symmetric(
                                vertical: 18,
                                horizontal: 32,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  AppNextPrayerBar(
                                    jadwalSholatList: data.jadwalSholat,
                                    countdownOnly: true,
                                  ),
                                  Image.asset(
                                    'assets/logo/diskominfotiksan-logo.png',
                                    height: 48,
                                    fit: BoxFit.contain,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Pembatas Vertikal Tengah Dihapus

                      // KOLOM TENGAH KANAN (Keuangan & Agenda)
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // 6. App Keuangan
                            Expanded(
                              child: AppKeuanganWidget(
                                laporanData: data.laporanKeuangan,
                                scrollSpeed:
                                    data.durasi?.financeScrollSpeed ?? 0,
                                margin: EdgeInsets.zero,
                                showRightBorder: false,
                              ),
                            ),
                            // Pembatas Horisontal Dihapus
                            // 8. App Agenda
                            Container(
                              color: AppColors.bgDark,
                              child: AppAgendaWidget(
                                agendas: data.agenda,
                                continuous: true,
                                borderRadius: 0.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Pembatas Horisontal Bawah Dihapus

                // 9. App Marquee
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
          ),
        ],
      ),
    );
  }
}
