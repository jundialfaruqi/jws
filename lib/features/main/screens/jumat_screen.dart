import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:intl/intl.dart';
import 'package:hijri/hijri_calendar.dart';
import '../../../core/widgets/tv_scaffold.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/selected_profil_provider.dart';

import '../models/petugas_model.dart';
import '../models/jadwal_sholat_model.dart';
import '../providers/my_masjid_provider.dart';
import '../../../core/widgets/app_image_slider.dart';
import '../../../core/time/time_sync_service.dart';
import '../../../core/time/hijri_localization.dart';
import '../../../core/widgets/app_live_clock.dart';

class JumatScreen extends ConsumerWidget {
  const JumatScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profil = ref.watch(selectedProfilProvider);

    final myMasjidData = profil != null
        ? ref.watch(myMasjidProvider(profil.id)).value
        : null;

    List<String> slideJumats = [];
    if (myMasjidData != null && myMasjidData.slideJumat != null) {
      final s = myMasjidData.slideJumat!;
      if (s.slide1 != null && s.slide1!.isNotEmpty) slideJumats.add(s.slide1!);
      if (s.slide2 != null && s.slide2!.isNotEmpty) slideJumats.add(s.slide2!);
      if (s.slide3 != null && s.slide3!.isNotEmpty) slideJumats.add(s.slide3!);
      if (s.slide4 != null && s.slide4!.isNotEmpty) slideJumats.add(s.slide4!);
      if (s.slide5 != null && s.slide5!.isNotEmpty) slideJumats.add(s.slide5!);
      if (s.slide6 != null && s.slide6!.isNotEmpty) slideJumats.add(s.slide6!);
    }

    // Jika tidak ada data dari backend, gunakan gambar default
    if (slideJumats.isEmpty) {
      slideJumats.add('assets/jumat-screen/slide-jumat-default-1.jpg');
      slideJumats.add('assets/jumat-screen/slide-jumat-default-2.jpg');
      slideJumats.add('assets/jumat-screen/slide-jumat-default-3.jpg');
      slideJumats.add('assets/jumat-screen/slide-jumat-default-4.jpg');
    }

    final now = ref.watch(timeSyncServiceProvider).now();
    final dateStr =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    DateTime dateToCalculate = now;
    bool isAfterMaghrib = false;
    JadwalSholatModel? todayJadwal;
    JadwalSholatModel? tomorrowJadwal;

    if (myMasjidData != null && myMasjidData.jadwalSholat.isNotEmpty) {
      try {
        todayJadwal = myMasjidData.jadwalSholat.firstWhere(
          (j) => j.date == dateStr,
        );

        final tomorrow = now.add(const Duration(days: 1));
        final tomorrowStr =
            "${tomorrow.year}-${tomorrow.month.toString().padLeft(2, '0')}-${tomorrow.day.toString().padLeft(2, '0')}";
        try {
          tomorrowJadwal = myMasjidData.jadwalSholat.firstWhere(
            (j) => j.date == tomorrowStr,
          );
        } catch (_) {}

        if (todayJadwal.maghrib.isNotEmpty) {
          final parts = todayJadwal.maghrib.split(':');
          if (parts.length >= 2) {
            final maghribTime = DateTime(
              now.year,
              now.month,
              now.day,
              int.tryParse(parts[0]) ?? 0,
              int.tryParse(parts[1]) ?? 0,
            );
            if (!now.isBefore(maghribTime)) {
              dateToCalculate = now.add(const Duration(days: 1));
              isAfterMaghrib = true;
            }
          }
        }
      } catch (_) {}
    }

    String tanggalMasehi = DateFormat('EEEE, dd MMM yyyy', 'id').format(now);
    tanggalMasehi = tanggalMasehi.replaceAll('Minggu', 'Ahad');

    String tanggalHijriah = "";
    final activeJadwal = isAfterMaghrib ? tomorrowJadwal : todayJadwal;

    if (activeJadwal != null &&
        activeJadwal.tanggalHijriah != null &&
        activeJadwal.tanggalHijriah!.isNotEmpty) {
      tanggalHijriah = activeJadwal.tanggalHijriah!;
    } else {
      // Fallback ke library, dengan koreksi -1 hari
      final correctedDate = dateToCalculate.subtract(const Duration(days: 1));
      initializeHijriLocale();
      final hijriDate = HijriCalendar.fromDate(correctedDate);
      tanggalHijriah =
          "${hijriDate.hDay} ${hijriDate.longMonthName} ${hijriDate.hYear} H";
    }

    PetugasModel? petugasHariIni;
    if (myMasjidData != null && myMasjidData.petugasJumat.isNotEmpty) {
      try {
        petugasHariIni = myMasjidData.petugasJumat.firstWhere(
          (p) => p.hari == dateStr,
        );
      } catch (_) {
        // Tidak ada petugas hari ini
      }
    }

    return TvScaffold(
      backgroundColor: AppColors.bgBlack,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/iqomah-screen/bg-iqomah-jumat-screen.png',
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(64.0),
            child: Row(
              children: [
                // Kolom Kiri: Informasi Jumat
                Expanded(
                  flex: 1,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Kelompok Atas: Logo dan Tanggal
                      Column(
                        children: [
                          Image.asset(
                            'assets/logo/diskominfotiksan-logo.png',
                            height: 75.0,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                TablerIcons.moon_stars,
                                color: Colors.white,
                                size: 40,
                              ),
                              const SizedBox(width: 16),
                              Text(
                                tanggalHijriah,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  letterSpacing: 4,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                TablerIcons.calendar_event,
                                color: Colors.white,
                                size: 40,
                              ),
                              const SizedBox(width: 16),
                              Text(
                                tanggalMasehi,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  letterSpacing: 4,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      // Kelompok Tengah: List Petugas Jumat
                      SizedBox(
                        width: 750,
                        child: Column(
                          children: [
                            _buildPetugasRow(
                              'Khatib',
                              petugasHariIni?.khatib ?? '-',
                            ),
                            _buildPetugasRow(
                              'Imam',
                              petugasHariIni?.imam ?? '-',
                            ),
                            _buildPetugasRow(
                              'Muadzin',
                              petugasHariIni?.muadzin ?? '-',
                            ),
                          ],
                        ),
                      ),
                      // Kelompok Bawah: Jam Digital
                      SizedBox(
                        width: 750,
                        child: Center(
                          child: AppLiveClock(
                            builder: (context, now) {
                              final hour = now.hour.toString().padLeft(2, '0');
                              final minute = now.minute.toString().padLeft(
                                2,
                                '0',
                              );
                              final second = now.second.toString().padLeft(
                                2,
                                '0',
                              );

                              String timeZone = 'WIB';
                              if (now.timeZoneOffset.inHours == 8) {
                                timeZone = 'WITA';
                              }
                              if (now.timeZoneOffset.inHours == 9) {
                                timeZone = 'WIT';
                              }

                              return Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                Text(
                                  hour,
                                  style: const TextStyle(
                                    fontSize: 120,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontFamily: 'Poppins',
                                    height: 1.0,
                                  ),
                                ),
                                Container(
                                  height: 80,
                                  width: 4,
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                Text(
                                  minute,
                                  style: const TextStyle(
                                    fontSize: 120,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontFamily: 'Poppins',
                                    height: 1.0,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      second,
                                      style: const TextStyle(
                                        fontSize: 48,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textYellow,
                                        fontFamily: 'Poppins',
                                        height: 1.0,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      timeZone,
                                      style: const TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white70,
                                        fontFamily: 'Poppins',
                                        letterSpacing: 2,
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
                    ),
                    ], // Penutup children Column
                  ), // Penutup Column
                ), // Penutup Expanded

                const SizedBox(
                  width: 64,
                ), // Jarak tengah (margin antar 2 layout)
                // Kolom Kanan: Gambar Rounded (Dummy)
                Expanded(
                  flex: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(48),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          blurRadius: 32,
                          offset: const Offset(8, 16),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(48),
                      child: AppImageSlider(
                        imageUrls: slideJumats,
                        leftMargin: 0,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPetugasRow(String label, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w500,
              color: Colors.white70,
              fontFamily: 'Poppins',
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 50,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'Poppins',
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
