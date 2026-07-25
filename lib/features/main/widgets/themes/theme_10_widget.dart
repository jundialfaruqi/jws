import 'package:flutter/material.dart';
import 'package:jws/core/widgets/app_marquee.dart';
import 'package:jws/core/constants/app_colors.dart';
import '../../models/my_masjid_model.dart';
import '../../models/marquee_model.dart';

class Theme10Widget extends StatelessWidget {
  final MyMasjidModel data;

  const Theme10Widget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final marqueeText = data.marquee?.concatenatedText ?? MarqueeModel.defaultMarqueeText;
    final speedMultiplier = data.marquee?.marqueeSpeed ?? 1.0;
    final calculatedVelocity = 120.0 * speedMultiplier;

    return Column(
      children: [
        // Konten Utama (Tengah) - Tema 10
        Expanded(
          child: Container(
            color: Colors.teal.shade50,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.mosque, size: 150, color: Colors.teal),
                  const SizedBox(height: 24),
                  Text(
                    data.profil.name,
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Tema 10 • ${data.currentTime}',
                    style: const TextStyle(
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
          backgroundColor: AppColors.bgGreen,
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 48,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
