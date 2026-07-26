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
    // Data Dummy Jadwal Sholat 6 Waktu
    final List<Map<String, dynamic>> jadwal = [
      {
        'nama': 'SUBUH',
        'jam': '04:57',
        'icon': TablerIcons.moon_2,
        'color': Colors.white,
      },
      {
        'nama': 'DHUHA',
        'jam': '06:42',
        'icon': TablerIcons.sun,
        'color': Colors.white,
      },
      {
        'nama': 'DZUHUR',
        'jam': '12:24',
        'icon': TablerIcons.sun_high,
        'color': Colors.white,
      },
      {
        'nama': 'ASHAR',
        'jam': '15:47',
        'icon': TablerIcons.cloud,
        'color': Colors.white,
      },
      {
        'nama': 'MAGHRIB',
        'jam': '18:28',
        'icon': TablerIcons.sunset,
        'color': Colors.yellow,
      },
      {
        'nama': 'ISYA',
        'jam': '19:41',
        'icon': TablerIcons.moon_stars,
        'color': Colors.red,
      },
    ];

    return Container(
      width: 700, // Diperlebar agar lengkungan dan card terlihat jelas
      color: backgroundColor,
      padding: const EdgeInsets.only(left: 32, right: 250, top: 16, bottom: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center, // Ubah dari spaceEvenly ke center agar mengumpul
        children: jadwal.map((item) {
          final itemColor = item['color'] as Color;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8), // Jarak antar item diperkecil agar tidak overflow
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
              decoration: BoxDecoration(
                color: backgroundColor,
                border: Border(
                  bottom: BorderSide(color: Colors.white.withValues(alpha: 0.15), width: 1.0),
                ),
              ),
              child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Icon Paling Kiri
                Icon(item['icon'] as IconData, color: itemColor, size: 48),
                const SizedBox(width: 32),
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
                          color: itemColor,
                          fontFamily: 'Poppins',
                          letterSpacing: 4.0,
                        ),
                      ),
                      const SizedBox(height: 4), // Kembalikan spasi antara judul dan jam
                      Text(
                        item['jam'] as String,
                        style: TextStyle(
                          fontSize: 72, // Jam diperbesar
                          fontWeight: FontWeight.bold,
                          color: itemColor,
                          fontFamily: 'Poppins',
                          height: 1.0,
                        ),
                        textAlign: TextAlign.left,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
      ),
    );
  }
}
