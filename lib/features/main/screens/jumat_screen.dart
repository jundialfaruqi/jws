import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:hijri/hijri_calendar.dart';
import '../../../core/widgets/tv_scaffold.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/api_constant.dart';
import '../../../core/providers/selected_profil_provider.dart';
import '../providers/my_masjid_provider.dart';
import '../../../core/widgets/app_image_slider.dart';
import '../../../core/time/time_sync_service.dart';
import '../../../core/widgets/app_live_clock.dart';
import '../models/petugas_model.dart';

class JumatScreen extends ConsumerWidget {
  const JumatScreen({super.key});

  String _getFullUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;

    final baseUrl = ApiConstant.baseUrl;
    final cleanBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final cleanPath = path.startsWith('/') ? path : '/$path';

    return '$cleanBase$cleanPath';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profil = ref.watch(selectedProfilProvider);
    
    final String logo1 = _getFullUrl(profil?.logoMasjid);
    final String logo2 = _getFullUrl(profil?.logoPemerintah);
    final bool hasLogo1 = logo1.isNotEmpty;
    final bool hasLogo2 = logo2.isNotEmpty;

    final myMasjidData = profil != null ? ref.watch(myMasjidProvider(profil.slug)).value : null;
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
      slideJumats.add('https://images.unsplash.com/photo-1564121211835-e88c852648ab?q=80&w=1000');
    }

    List<Widget> logoWidgets = [];
    final double logoSize = 120.0; // Diperkecil sedikit agar tidak overflow

    if (!hasLogo1 && !hasLogo2) {
      logoWidgets.add(Image.asset('assets/logo/logo-masjid-default.png', height: logoSize, fit: BoxFit.contain));
      logoWidgets.add(const SizedBox(width: 24));
      logoWidgets.add(Image.asset('assets/logo/logo-pemko-default.png', height: logoSize, fit: BoxFit.contain));
    } else {
      if (hasLogo1) {
        logoWidgets.add(CachedNetworkImage(imageUrl: logo1, height: logoSize, fit: BoxFit.contain, errorWidget: (c,url,e) => Icon(Icons.mosque, size: logoSize, color: Colors.white)));
      }
      if (hasLogo2) {
        if (hasLogo1) logoWidgets.add(const SizedBox(width: 24));
        logoWidgets.add(CachedNetworkImage(imageUrl: logo2, height: logoSize, fit: BoxFit.contain, errorWidget: (c,url,e) => Icon(Icons.account_balance, size: logoSize, color: Colors.white)));
      }
    }

    final now = ref.watch(timeSyncServiceProvider).now();
    final dateStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    
    DateTime dateToCalculate = now;
    if (myMasjidData != null && myMasjidData.jadwalSholat.isNotEmpty) {
      try {
        final todayJadwal = myMasjidData.jadwalSholat.firstWhere((j) => j.date == dateStr);
        if (todayJadwal.maghrib.isNotEmpty) {
          final parts = todayJadwal.maghrib.split(':');
          if (parts.length >= 2) {
             final maghribTime = DateTime(now.year, now.month, now.day, int.tryParse(parts[0]) ?? 0, int.tryParse(parts[1]) ?? 0);
             if (now.isBefore(maghribTime)) {
                dateToCalculate = now.subtract(const Duration(days: 1));
             }
          }
        }
      } catch (_) {}
    }

    final hijriDate = HijriCalendar.fromDate(dateToCalculate);
    String tanggalMasehi = DateFormat('EEEE, dd MMMM yyyy', 'id').format(now);
    tanggalMasehi = tanggalMasehi.replaceAll('Minggu', 'Ahad');
    final tanggalHijriah = "${hijriDate.hDay} ${hijriDate.longMonthName} ${hijriDate.hYear} H";
    final tanggalLengkap = "$tanggalHijriah\n$tanggalMasehi";

    PetugasModel? petugasHariIni;
    if (myMasjidData != null && myMasjidData.petugasJumat.isNotEmpty) {
      try {
        petugasHariIni = myMasjidData.petugasJumat.firstWhere((p) => p.hari == dateStr);
      } catch (_) {
        // Tidak ada petugas hari ini
      }
    }

    return TvScaffold(
      backgroundColor: AppColors.bgDark, 
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(64.0),
            child: Row(
              children: [
                // Kolom Kiri: Informasi Jumat
              Expanded(
                flex: 1,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: logoWidgets,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        tanggalLengkap,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.w600,
                          color: Colors.white70,
                          letterSpacing: 4,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 32),
                      // List Petugas Jumat
                      SizedBox(
                        width: 750,
                        child: Column(
                          children: [
                              const Text(
                                'PETUGAS JUMAT HARI INI',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textYellow,
                                  letterSpacing: 4,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                              const SizedBox(height: 24),
                              _buildPetugasRow('Khatib', petugasHariIni?.khatib ?? '-'),
                              const SizedBox(height: 16),
                              _buildPetugasRow('Imam', petugasHariIni?.imam ?? '-'),
                              const SizedBox(height: 16),
                                _buildPetugasRow('Muadzin', petugasHariIni?.muadzin ?? '-'),
                                const SizedBox(height: 64),
                                // Jam Digital di bawah petugas
                                const AppLiveClock(
                                  showDate: false,
                                  textStyle: TextStyle(
                                    fontSize: 80,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontFamily: 'JetBrainsMono',
                                    letterSpacing: 8,
                                  ),
                                ),
                              ],
                            ),
                      ),
                    ], // Penutup children Column
                  ), // Penutup Column
                ), // Penutup Center
              ), // Penutup Expanded
              
              const SizedBox(width: 64), // Jarak tengah (margin antar 2 layout)
              
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
                        )
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
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 180,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 32,
                color: Colors.white70,
                fontFamily: 'Poppins',
              ),
            ),
          ),
          const Text(
            ': ',
            style: TextStyle(
              fontSize: 32,
              color: Colors.white70,
              fontFamily: 'Poppins',
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
