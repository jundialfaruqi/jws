import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import '../../features/main/models/jadwal_sholat_model.dart';
import '../time/time_sync_service.dart';

class AppJadwalSholat extends ConsumerStatefulWidget {
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
  ConsumerState<AppJadwalSholat> createState() => _AppJadwalSholatState();
}

class _AppJadwalSholatState extends ConsumerState<AppJadwalSholat> {
  bool _showPrimary = true;
  Timer? _timer;
  int _tickCount = 0;

  @override
  void initState() {
    super.initState();
    // Berdetak setiap 1 detik agar warna sholat akurat,
    // tetapi toggle Imsak/Subuh hanya berjalan setiap 7 detik
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _tickCount++;
          if (_tickCount % 7 == 0) {
            _showPrimary = !_showPrimary;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  DateTime _parseTime(String timeStr, DateTime now) {
    if (timeStr == '--:--' || timeStr.isEmpty) return now;
    final parts = timeStr.split(':');
    if (parts.length != 2) return now;
    return DateTime(
      now.year,
      now.month,
      now.day,
      int.tryParse(parts[0]) ?? 0,
      int.tryParse(parts[1]) ?? 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Ambil waktu paling mutakhir dari server (secara monotonic)
    final now = ref.read(timeSyncServiceProvider).now();

    String activePrayer = '';
    String nextPrayer = '';

    if (widget.jadwalSholat != null) {
      final times = [
        {'nama': 'IMSAK', 'time': _parseTime(widget.jadwalSholat!.imsak, now)},
        {'nama': 'SUBUH', 'time': _parseTime(widget.jadwalSholat!.subuh, now)},
        {
          'nama': 'TERBIT',
          'time': _parseTime(widget.jadwalSholat!.terbit, now),
        },
        {'nama': 'DHUHA', 'time': _parseTime(widget.jadwalSholat!.dhuha, now)},
        {
          'nama': now.weekday == DateTime.friday ? "JUM'AT" : 'DZUHUR',
          'time': _parseTime(widget.jadwalSholat!.dzuhur, now),
        },
        {'nama': 'ASHAR', 'time': _parseTime(widget.jadwalSholat!.ashar, now)},
        {
          'nama': 'MAGHRIB',
          'time': _parseTime(widget.jadwalSholat!.maghrib, now),
        },
        {'nama': 'ISYA', 'time': _parseTime(widget.jadwalSholat!.isya, now)},
      ];

      for (int i = times.length - 1; i >= 0; i--) {
        final t = times[i]['time'] as DateTime;
        if (now.isAfter(t) || now.isAtSameMomentAs(t)) {
          activePrayer = times[i]['nama'] as String;
          if (i < times.length - 1) {
            nextPrayer = times[i + 1]['nama'] as String;
          } else {
            nextPrayer = times[0]['nama'] as String; // Besok Imsak
          }
          break;
        }
      }

      // Jika waktu sekarang masih sebelum Imsak hari ini
      if (activePrayer.isEmpty) {
        activePrayer = 'ISYA';
        nextPrayer = 'IMSAK';
      }
    }

    Color getColor(String nama) {
      if (nama == activePrayer) return Colors.red;
      if (nama == nextPrayer) return Colors.yellow;
      return Colors.white; // default color
    }

    // Data Jadwal Sholat Dinamis
    final List<Map<String, dynamic>> jadwal = [
      _showPrimary
          ? {
              'nama': 'IMSAK',
              'jam': widget.jadwalSholat?.imsak ?? '--:--',
              'icon': TablerIcons.moon_2,
              'color': getColor('IMSAK'),
            }
          : {
              'nama': 'SUBUH',
              'jam': widget.jadwalSholat?.subuh ?? '--:--',
              'icon': TablerIcons.sun_low,
              'color': getColor('SUBUH'),
            },
      _showPrimary
          ? {
              'nama': 'TERBIT',
              'jam': widget.jadwalSholat?.terbit ?? '--:--',
              'icon': TablerIcons.sunrise,
              'color': getColor('TERBIT'),
            }
          : {
              'nama': 'DHUHA',
              'jam': widget.jadwalSholat?.dhuha ?? '--:--',
              'icon': TablerIcons.sun,
              'color': getColor('DHUHA'),
            },
      {
        'nama': now.weekday == DateTime.friday ? "JUM'AT" : 'DZUHUR',
        'jam': widget.jadwalSholat?.dzuhur ?? '--:--',
        'icon': TablerIcons.sun_high,
        'color': getColor(now.weekday == DateTime.friday ? "JUM'AT" : 'DZUHUR'),
      },
      {
        'nama': 'ASHAR',
        'jam': widget.jadwalSholat?.ashar ?? '--:--',
        'icon': TablerIcons.cloud,
        'color': getColor('ASHAR'),
      },
      {
        'nama': 'MAGHRIB',
        'jam': widget.jadwalSholat?.maghrib ?? '--:--',
        'icon': TablerIcons.sunset,
        'color': getColor('MAGHRIB'),
      },
      {
        'nama': 'ISYA',
        'jam': widget.jadwalSholat?.isya ?? '--:--',
        'icon': TablerIcons.moon_stars,
        'color': getColor('ISYA'),
      },
    ];

    return Container(
      width: 700, // Diperlebar agar lengkungan dan card terlihat jelas
      color: widget.backgroundColor,
      padding: const EdgeInsets.only(left: 32, right: 250, top: 16, bottom: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment
            .center, // Ubah dari spaceEvenly ke center agar mengumpul
        children: jadwal.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final isLast = index == jadwal.length - 1;

          final itemColor = item['color'] as Color;
          final uniqueKey = ValueKey(
            item['nama'],
          ); // Kunci unik untuk AnimatedSwitcher

          return Padding(
            padding: EdgeInsets.only(
              bottom: isLast ? 0 : 8,
            ), // Hilangkan padding bawah jika item terakhir
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
              decoration: BoxDecoration(
                color: widget.backgroundColor,
                border: isLast
                    ? null
                    : Border(
                        bottom: BorderSide(
                          color: Colors.white.withValues(alpha: 0.15),
                          width: 1.0,
                        ),
                      ),
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 800),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (Widget child, Animation<double> animation) {
                  final offsetAnimation = Tween<Offset>(
                    begin: const Offset(
                      -0.3,
                      0.0,
                    ), // Muncul dari agak kiri (horizontal)
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
                  key:
                      uniqueKey, // Kunci unik ditempatkan pada Row agar merender ulang sekalian
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
                          const SizedBox(
                            height: 4,
                          ), // Kembalikan spasi antara judul dan jam
                          Text(
                            item['jam'] as String,
                            style: TextStyle(
                              fontSize: 72, // Jam diperbesar
                              fontWeight: FontWeight.bold,
                              color: itemColor,
                              fontFamily: 'Poppins',
                              height: 1.0,
                              letterSpacing:
                                  5.0, // Memberikan sedikit spasi antar karakter
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
