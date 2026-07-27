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
                  margin: const EdgeInsets.all(16),
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
                    showSeconds: false,
                    showDate: false,
                    blinkSeparator: true,
                    textStyle: const TextStyle(
                      fontFamily: 'JetBrainsMono',
                      fontSize: 84,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textYellow,
                    ),
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
                        horizontal: 24,
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
                      cardColor: AppColors.bgNavy,
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
                  textColor: AppColors.textInverse,
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
                                externalSync: true,
                                leftMargin: 0,
                              ),
                            ),
                            // Pembatas Horisontal Dihapus
                            // 7. App Next Prayer (Countdown)
                            Container(
                              color: AppColors.bgNavy,
                              alignment: Alignment.centerLeft,
                              padding: const EdgeInsets.symmetric(
                                vertical: 24,
                                horizontal: 32,
                              ),
                              child: AppNextPrayerBar(
                                jadwalSholatList: data.jadwalSholat,
                                countdownOnly: true,
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
