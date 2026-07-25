import 'package:flutter/material.dart';
import 'package:jws/core/widgets/app_marquee.dart';
import 'package:jws/core/widgets/app_live_clock.dart';
import 'package:jws/core/widgets/app_masjid_title.dart';
import 'package:jws/core/constants/app_colors.dart';
import '../../models/my_masjid_model.dart';
import '../../models/marquee_model.dart';

class Theme4Widget extends StatelessWidget {
  final MyMasjidModel data;

  const Theme4Widget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final marqueeText = data.marquee?.concatenatedText ?? MarqueeModel.defaultMarqueeText;
    final speedMultiplier = data.marquee?.marqueeSpeed ?? 1.0;
    final calculatedVelocity = 120.0 * speedMultiplier;

    return Column(
      children: [
        // Judul Masjid
        AppMasjidTitle(
          title: data.profil.name,
          address: data.profil.address,
          logoMasjid: data.profil.logoMasjid,
          logoPemerintah: data.profil.logoPemerintah,
          backgroundColor: Colors.black87,
          textColor: Colors.white,
        ),
        
        // Konten Utama (Tengah) - Tema 4 (Misalnya warna ikon dan layout sedikit berbeda)
        Expanded(
          child: Container(
            color: Colors
                .blueGrey
                .shade50, // Latar belakang abu-abu kebiruan khusus Tema 4
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.mosque,
                    size: 150,
                    color: Colors.orange, // Beda warna untuk membedakan
                  ),
                  const SizedBox(height: 16),
                  AppLiveClock(
                    prefix: 'Tema 4',
                    textStyle: const TextStyle(
                      fontFamily: 'JetBrainsMono',
                      fontSize: 28,
                      color: Colors.blueGrey,
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
          backgroundColor: AppColors.bgBlue,
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 64,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
