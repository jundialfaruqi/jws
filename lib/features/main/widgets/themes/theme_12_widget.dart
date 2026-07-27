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
            'https://images.unsplash.com/photo-1519817650390-64a93db51149?q=80&w=2000',
            'https://images.unsplash.com/photo-1564121211835-e88c852648ab?q=80&w=2000',
            'https://images.unsplash.com/photo-1584551246679-0daf3d275d05?q=80&w=2000',
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
                  color: AppColors.bgNavy,
                  padding: const EdgeInsets.symmetric(vertical: 36),
                  alignment: Alignment.center,
                  child: AppLiveClock(
                    showSeconds: false,
                    showDate: false,
                    textStyle: const TextStyle(
                      fontFamily: 'JetBrainsMono',
                      fontSize: 84,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textYellow,
                    ),
                  ),
                ),
                // Pembatas Tipis
                Container(height: 2, color: Colors.white12),
                // 3. App Jadwal Sholat
                Expanded(
                  child: Container(
                    color: AppColors.bgNavy,
                    child: AppJadwalSholat(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      iconSize: 36,
                      titleFontSize: 24,
                      timeFontSize: 56,
                      backgroundColor: AppColors.bgNavy,
                      textColor: Colors.white,
                      iconColor: AppColors.textYellow,
                      jadwalSholatList: data.jadwalSholat,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Pembatas Vertikal Utama
          Container(width: 4, color: Colors.white12),

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
                  textColor: AppColors.textInverse,
                  addressColor: AppColors.textInverse,
                  isRightAligned: true,
                ),

                // Pembatas Horisontal
                Container(height: 2, color: Colors.white12),

                // 4. App Tanggal (Rata Kanan)
                Container(
                  color: AppColors.bgDark.withValues(alpha: 0.8),
                  alignment: Alignment.centerRight,
                  child: AppNextPrayerBar(
                    jadwalSholatList: data.jadwalSholat,
                    dateOnly: true,
                  ),
                ),

                // Pembatas Horisontal
                Container(height: 2, color: Colors.white12),

                // Baris Tengah (Slide & Keuangan)
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // KOLOM TENGAH KIRI (Slide & Next Prayer)
                      Expanded(
                        flex: 5,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // 5. App Slide
                            Expanded(
                              child: AppImageSlider(
                                imageUrls: slideUrls,
                                externalSync: true,
                                leftMargin: 0,
                              ),
                            ),
                            // Pembatas Horisontal
                            Container(height: 4, color: Colors.white12),
                            // 7. App Next Prayer (Countdown)
                            Container(
                              color: AppColors.bgNavy,
                              alignment: Alignment.centerLeft,
                              child: AppNextPrayerBar(
                                jadwalSholatList: data.jadwalSholat,
                                countdownOnly: true,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Pembatas Vertikal Tengah
                      Container(width: 4, color: Colors.white12),

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
                              ),
                            ),
                            // Pembatas Horisontal
                            Container(height: 4, color: Colors.white12),
                            // 8. App Agenda
                            Container(
                              height: 300, // Tinggi fix proporsional untuk agenda
                              color: AppColors.bgDark,
                              child: AppAgendaWidget(agendas: data.agenda),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Pembatas Horisontal Bawah
                Container(height: 4, color: Colors.white12),

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
