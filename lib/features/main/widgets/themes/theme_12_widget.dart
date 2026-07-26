import 'package:flutter/material.dart';
import 'package:jws/core/widgets/app_marquee.dart';
import 'package:jws/core/widgets/app_live_clock.dart';
import 'package:jws/core/widgets/app_masjid_title.dart';
import 'package:jws/core/widgets/app_jadwal_sholat.dart';
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
              backgroundColor: Colors.deepPurple.shade900,
              textColor: Colors.white,
            ),

            // Konten Utama (Tengah) - Tema 12
            Expanded(
              child: Container(
                color: Colors.deepPurple.shade50,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.mosque,
                        size: 150,
                        color: Colors.deepPurple,
                      ),
                      const SizedBox(height: 16),
                      AppLiveClock(
                        prefix: 'Tema 12',
                        textStyle: const TextStyle(
                          fontFamily: 'JetBrainsMono',
                          fontSize: 28,
                          color: Colors.deepPurple,
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
              backgroundColor: Colors.deepPurple,
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
            backgroundColor: Colors.deepPurple.shade800,
            textColor: Colors.white,
            iconColor: Colors.deepPurpleAccent,
            jadwalSholatList: data.jadwalSholat,
          ),
        ),
      ],
    );
  }
}
