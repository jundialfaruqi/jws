import 'package:flutter/material.dart';
import '../../../core/widgets/tv_scaffold.dart';
import '../../../core/constants/app_colors.dart';

class AdzanScreen extends StatelessWidget {
  final String prayerName;
  final String prayerTime;

  const AdzanScreen({
    super.key,
    this.prayerName = 'MAGHRIB',
    this.prayerTime = '18:30',
  });

  @override
  Widget build(BuildContext context) {
    // ScaffoldTV akan otomatis menjaga resolusi tetap 1920x1080 (Full HD) 
    // berapapun rasio layar aslinya
    return TvScaffold(
      backgroundColor: AppColors.bgDark, // Menggunakan background gelap/hitam
      body: Stack(
        children: [
          // Konten Utama (Dummy)
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.mosque,
                  size: 150,
                  color: AppColors.textYellow,
                ),
                const SizedBox(height: 40),
                const Text(
                  'SAATNYA MENGUMANDANGKAN ADZAN',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                    letterSpacing: 8,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  prayerName,
                  style: const TextStyle(
                    fontSize: 140,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 12,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  prayerTime,
                  style: const TextStyle(
                    fontSize: 90,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textYellow,
                    fontFamily: 'JetBrainsMono',
                  ),
                ),
                const SizedBox(height: 80),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 24),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                      width: 2,
                    ),
                  ),
                  child: const Text(
                    'Mohon bersiap dan luruskan shaf',
                    style: TextStyle(
                      fontSize: 32,
                      color: Colors.white,
                      fontFamily: 'Poppins',
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
}
