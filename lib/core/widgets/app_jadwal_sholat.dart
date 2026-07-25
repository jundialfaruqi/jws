import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

class AppJadwalSholat extends StatelessWidget {
  final Color backgroundColor;
  final Color textColor;
  final Color iconColor;

  const AppJadwalSholat({
    super.key,
    required this.backgroundColor,
    required this.textColor,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    // Data Dummy Jadwal Sholat 5 Waktu
    final List<Map<String, dynamic>> jadwal = [
      {'nama': 'Subuh', 'jam': '04:45', 'icon': TablerIcons.moon},
      {'nama': 'Dzuhur', 'jam': '12:15', 'icon': TablerIcons.sun},
      {'nama': 'Ashar', 'jam': '15:30', 'icon': TablerIcons.cloud},
      {'nama': 'Maghrib', 'jam': '18:20', 'icon': TablerIcons.sunset},
      {'nama': 'Isya', 'jam': '19:35', 'icon': TablerIcons.moon_stars},
    ];

    return Container(
      width: 320,
      color: backgroundColor,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: jadwal.map((item) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Icon Paling Kiri
              Icon(item['icon'] as IconData, color: iconColor, size: 64),
              const SizedBox(width: 24),
              // Column Nama dan Jam di Kanannya
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['nama'] as String,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item['jam'] as String,
                      style: TextStyle(
                        fontSize: 56, // Jam lebih besar
                        fontWeight: FontWeight.bold,
                        color: textColor,
                        fontFamily: 'JetBrainsMono',
                        height: 1.0,
                      ),
                      textAlign: TextAlign.left,
                    ),
                  ],
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
