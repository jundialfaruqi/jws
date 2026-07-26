import 'package:flutter/material.dart';
import 'package:jws/core/widgets/app_marquee.dart';
import 'package:jws/core/widgets/app_live_clock.dart';
import 'package:jws/core/widgets/app_masjid_title.dart';
import 'package:jws/core/widgets/app_jadwal_sholat.dart';
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
              backgroundColor: Colors.teal.shade900,
              textColor: Colors.white,
            ),

            // Konten Utama (Tengah) - Tema 10
            Expanded(
              child: Container(
                color: Colors.teal.shade50,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.mosque, size: 150, color: Colors.teal),
                      const SizedBox(height: 16),
                      AppLiveClock(
                        prefix: 'Tema 10',
                        textStyle: const TextStyle(
                          fontFamily: 'JetBrainsMono',
                          fontSize: 28,
                          color: Colors.teal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Widget Marquee (Bawah)
            AppMarquee(
              text: marqueeText,
              velocity: calculatedVelocity,
              backgroundColor: Colors.teal,
              textStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 64,
                color: Colors.white,
              ),
            ),
          ],
        ),

        // Jadwal Sholat Melayang di Kiri
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          child: AppJadwalSholat(
            backgroundColor: Colors.teal.shade800,
            textColor: Colors.white,
            iconColor: Colors.tealAccent,
            jadwalSholatList: data.jadwalSholat,
          ),
        ),
      ],
    );
  }
}
