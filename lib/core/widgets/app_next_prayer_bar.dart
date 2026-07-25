import 'package:flutter/material.dart';
import 'package:jws/core/constants/app_colors.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

class AppNextPrayerBar extends StatelessWidget {
  final double leftMargin;

  const AppNextPrayerBar({
    super.key,
    this.leftMargin = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bgNavy,
      padding: EdgeInsets.only(left: leftMargin + 32, right: 48, top: 16, bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Kiri: Waktu Sholat yang akan masuk
          Row(
            children: [
              const Icon(TablerIcons.bell_ringing, color: Colors.white, size: 36),
              const SizedBox(width: 16),
              const Text(
                'MENUJU ASHAR',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(width: 24),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                ),
                child: const Text(
                  '- 01:23:45',
                  style: TextStyle(
                    color: AppColors.textYellow,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'JetBrainsMono',
                  ),
                ),
              ),
            ],
          ),
          
          // Kanan: Tanggal Masehi & Hijriah
          Row(
            children: [
              const Icon(TablerIcons.calendar_event, color: Colors.white, size: 32),
              const SizedBox(width: 12),
              const Text(
                '26 Juli 2026',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(width: 24),
              Container(width: 2, height: 28, color: Colors.white54),
              const SizedBox(width: 24),
              const Icon(TablerIcons.moon_stars, color: Colors.white, size: 32),
              const SizedBox(width: 12),
              const Text(
                '12 Muharram 1448 H',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
