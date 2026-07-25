import 'package:flutter/material.dart';
import 'package:jws/core/widgets/app_marquee.dart';
import 'package:jws/core/widgets/app_live_clock.dart';
import 'package:jws/core/widgets/app_masjid_title.dart';
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

    return Column(
      children: [
        // Judul Masjid di atas
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

        // Konten Utama (Tengah) - Tema 7 (Default)
        Expanded(
          child: Container(
            color: Colors.blue.shade50, // Tambahkan background terang
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.mosque, size: 150, color: Colors.blue),
                  const SizedBox(height: 16),
                  AppLiveClock(
                    prefix: 'Tema 7',
                    textStyle: const TextStyle(
                      fontFamily: 'JetBrainsMono',
                      fontSize: 24,
                      color: Colors.blueGrey, // Perjelas warna jam
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
          textStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            fontSize: 64,
            color: AppColors.textYellow,
          ),
        ),
      ],
    );
  }
}
