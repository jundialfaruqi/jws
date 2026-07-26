import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import '../../features/main/models/jadwal_sholat_model.dart';

class AppJadwalSholat extends StatefulWidget {
  final Color backgroundColor;
  final Color textColor;
  final Color iconColor;
  final JadwalSholatModel? jadwalSholat;

  const AppJadwalSholat({
    super.key,
    required this.backgroundColor,
    required this.textColor,
    required this.iconColor,
    this.jadwalSholat,
  });

  @override
  State<AppJadwalSholat> createState() => _AppJadwalSholatState();
}

class _AppJadwalSholatState extends State<AppJadwalSholat> {
  bool _showPrimary = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 7), (timer) {
      if (mounted) {
        setState(() {
          _showPrimary = !_showPrimary;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Data Jadwal Sholat Dinamis
    final List<Map<String, dynamic>> jadwal = [
      _showPrimary
          ? {
              'nama': 'IMSAK',
              'jam': widget.jadwalSholat?.imsak ?? '--:--',
              'icon': TablerIcons.moon_2,
              'color': Colors.white,
            }
          : {
              'nama': 'SUBUH',
              'jam': widget.jadwalSholat?.subuh ?? '--:--',
              'icon': TablerIcons.sun_low,
              'color': Colors.white,
            },
      _showPrimary
          ? {
              'nama': 'TERBIT',
              'jam': widget.jadwalSholat?.terbit ?? '--:--',
              'icon': TablerIcons.sunrise,
              'color': Colors.white,
            }
          : {
              'nama': 'DHUHA',
              'jam': widget.jadwalSholat?.dhuha ?? '--:--',
              'icon': TablerIcons.sun,
              'color': Colors.white,
            },
      {
        'nama': 'DZUHUR',
        'jam': widget.jadwalSholat?.dzuhur ?? '--:--',
        'icon': TablerIcons.sun_high,
        'color': Colors.white,
      },
      {
        'nama': 'ASHAR',
        'jam': widget.jadwalSholat?.ashar ?? '--:--',
        'icon': TablerIcons.cloud,
        'color': Colors.white,
      },
      {
        'nama': 'MAGHRIB',
        'jam': widget.jadwalSholat?.maghrib ?? '--:--',
        'icon': TablerIcons.sunset,
        'color': Colors.yellow,
      },
      {
        'nama': 'ISYA',
        'jam': widget.jadwalSholat?.isya ?? '--:--',
        'icon': TablerIcons.moon_stars,
        'color': Colors.red,
      },
    ];

    return Container(
      width: 700, // Diperlebar agar lengkungan dan card terlihat jelas
      color: widget.backgroundColor,
      padding: const EdgeInsets.only(left: 32, right: 250, top: 16, bottom: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center, // Ubah dari spaceEvenly ke center agar mengumpul
        children: jadwal.map((item) {
          final itemColor = item['color'] as Color;
          final uniqueKey = ValueKey(item['nama']); // Kunci unik untuk AnimatedSwitcher

          return Padding(
            padding: const EdgeInsets.only(bottom: 8), // Jarak antar item diperkecil agar tidak overflow
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
              decoration: BoxDecoration(
                color: widget.backgroundColor,
                border: Border(
                  bottom: BorderSide(color: Colors.white.withValues(alpha: 0.15), width: 1.0),
                ),
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 800),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (Widget child, Animation<double> animation) {
                  final offsetAnimation = Tween<Offset>(
                    begin: const Offset(-0.3, 0.0), // Muncul dari agak kiri (horizontal)
                    end: Offset.zero,
                  ).animate(animation);
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: offsetAnimation,
                      child: child,
                    ),
                  );
                },
                child: Row(
                  key: uniqueKey, // Kunci unik ditempatkan pada Row agar merender ulang sekalian
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
            ),
          );
        }).toList(),
      ),
    );
  }
}
