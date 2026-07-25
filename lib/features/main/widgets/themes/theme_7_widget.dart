import 'package:flutter/material.dart';
import 'package:jws/core/widgets/app_marquee.dart';
import '../../models/my_masjid_model.dart';
import '../../models/marquee_model.dart';

class Theme7Widget extends StatelessWidget {
  final MyMasjidModel data;

  const Theme7Widget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final marqueeText = data.marquee?.concatenatedText ?? MarqueeModel.defaultMarqueeText;
    final speedMultiplier = data.marquee?.marqueeSpeed ?? 1.0;
    final calculatedVelocity = 120.0 * speedMultiplier;

    return Column(
      children: [
        // Konten Utama (Tengah) - Tema 7 (Default)
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.mosque, size: 150, color: Colors.blue),
                const SizedBox(height: 24),
                Text(
                  data.profil.name,
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Waktu Server: ${data.currentTime}',
                  style: const TextStyle(
                    fontFamily: 'JetBrainsMono',
                    fontSize: 28,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Widget Marquee (Bawah)
        // Widget Marquee (Bawah)
        AppMarquee(text: marqueeText, velocity: calculatedVelocity),
      ],
    );
  }
}
