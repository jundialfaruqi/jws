import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import '../../features/main/models/jadwal_sholat_model.dart';
import '../time/time_sync_service.dart';

class AppJadwalSholat extends ConsumerStatefulWidget {
  final Color backgroundColor;
  final Color textColor;
  final Color iconColor;
  final List<JadwalSholatModel> jadwalSholatList;
  final double? width;
  final EdgeInsetsGeometry? padding;
  final double? iconSize;
  final double? titleFontSize;
  final double? timeFontSize;
  final bool useCardVariant;
  final Color? cardColor;
  final Color? nextTextColor;
  final Color? nextCardColor;
  final bool highlightFadingGradient;

  const AppJadwalSholat({
    super.key,
    required this.backgroundColor,
    required this.textColor,
    required this.iconColor,
    this.jadwalSholatList = const [],
    this.width,
    this.padding,
    this.iconSize,
    this.titleFontSize,
    this.timeFontSize,
    this.useCardVariant = false,
    this.cardColor,
    this.nextTextColor,
    this.nextCardColor,
    this.highlightFadingGradient = false,
  });

  @override
  ConsumerState<AppJadwalSholat> createState() => _AppJadwalSholatState();
}

class _AppJadwalSholatState extends ConsumerState<AppJadwalSholat> {
  Timer? _timer;
  bool _showImsak = true;
  bool _showSyuruq = true;

  @override
  void initState() {
    super.initState();
    final now = ref.read(timeSyncServiceProvider).now();
    final int epochSeconds = now.millisecondsSinceEpoch ~/ 1000;
    final int cyclePosition = epochSeconds % 14;
    _showImsak = cyclePosition >= 7;
    _showSyuruq = cyclePosition >= 8 || cyclePosition == 0;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _syncAndScheduleNext();
    });
  }

  void _syncAndScheduleNext() {
    if (!mounted) return;

    final now = ref.read(timeSyncServiceProvider).now();
    final int nowMs = now.millisecondsSinceEpoch;
    final int epochSeconds = nowMs ~/ 1000;

    // 1 Siklus total = 14 detik (masing-masing fase berdurasi tepat 7 detik)
    // Slot 1 (Imsak/Subuh) berganti di detik 0 dan detik 7
    // Slot 2 (Syuruq/Dhuha) berganti di detik 1 dan detik 8 (berurutan dengan jeda 1 detik)
    final int cyclePosition = epochSeconds % 14;

    setState(() {
      // Detik 0..6: Subuh, Detik 7..13: Imsak (durasi tepat 7 detik)
      _showImsak = cyclePosition >= 7;

      // Detik 1..7: Dhuha, Detik 8..13 & 0: Syuruq (durasi tepat 7 detik)
      _showSyuruq = cyclePosition >= 8 || cyclePosition == 0;
    });

    final int msUntilNext = 1000 - (nowMs % 1000);
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: msUntilNext), _syncAndScheduleNext);
  }

  Widget _buildFlipTransition(Widget child, Animation<double> animation) {
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, childWidget) {
        final isIncoming = animation.status != AnimationStatus.reverse;
        final value = animation.value;

        if (isIncoming) {
          if (value < 0.5) {
            return const SizedBox.shrink();
          }
          final rawProgress = (value - 0.5) * 2.0;
          final progress = Curves.easeOutCubic.transform(rawProgress);
          final angle = -math.pi / 2 * (1.0 - progress);

          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0015)
              ..rotateX(angle),
            child: childWidget,
          );
        } else {
          if (value < 0.5) {
            return const SizedBox.shrink();
          }
          final rawProgress = (1.0 - value) * 2.0;
          final progress = Curves.easeInCubic.transform(rawProgress);
          final angle = math.pi / 2 * progress;

          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0015)
              ..rotateX(angle),
            child: childWidget,
          );
        }
      },
    );
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
    JadwalSholatModel? todayJadwal;

    if (widget.jadwalSholatList.isNotEmpty) {
      final dateStr =
          "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
      try {
        todayJadwal = widget.jadwalSholatList.firstWhere(
          (j) => j.date == dateStr,
        );
      } catch (_) {
        todayJadwal = widget.jadwalSholatList.first;
      }

      final times = [
        {'nama': 'IMSAK', 'time': _parseTime(todayJadwal.imsak, now)},
        {'nama': 'SUBUH', 'time': _parseTime(todayJadwal.subuh, now)},
        {'nama': 'SYURUQ', 'time': _parseTime(todayJadwal.terbit, now)},
        {'nama': 'DHUHA', 'time': _parseTime(todayJadwal.dhuha, now)},
        {
          'nama': now.weekday == DateTime.friday ? "JUM'AT" : 'DZUHUR',
          'time': _parseTime(todayJadwal.dzuhur, now),
        },
        {'nama': 'ASHAR', 'time': _parseTime(todayJadwal.ashar, now)},
        {'nama': 'MAGHRIB', 'time': _parseTime(todayJadwal.maghrib, now)},
        {'nama': 'ISYA', 'time': _parseTime(todayJadwal.isya, now)},
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
      if (widget.useCardVariant) {
        if (nama == nextPrayer) return widget.nextTextColor ?? Colors.white;
        return Colors.white; // Pada mode card, teks dan icon aktif/lainnya putih
      }
      if (nama == activePrayer) return Colors.red;
      if (nama == nextPrayer) return Colors.yellow;
      return Colors.white; // default color
    }

    Color getBgColor(String nama) {
      if (widget.useCardVariant) {
        if (nama == activePrayer) return Colors.red;
        if (nama == nextPrayer) return widget.nextCardColor ?? Colors.orange.shade500;
        return widget.cardColor ?? Colors.white.withValues(alpha: 0.05);
      }
      return Colors.transparent;
    }

    final List<Map<String, dynamic>> jadwal = [
      _showImsak
          ? {
              'nama': 'IMSAK',
              'jam': todayJadwal?.imsak ?? '--:--',
              'icon': TablerIcons.moon_2,
              'color': getColor('IMSAK'),
              'bgColor': getBgColor('IMSAK'),
            }
          : {
              'nama': 'SUBUH',
              'jam': todayJadwal?.subuh ?? '--:--',
              'icon': TablerIcons.sun_low,
              'color': getColor('SUBUH'),
              'bgColor': getBgColor('SUBUH'),
            },
      _showSyuruq
          ? {
              'nama': 'SYURUQ',
              'jam': todayJadwal?.terbit ?? '--:--',
              'icon': TablerIcons.sunrise,
              'color': getColor('SYURUQ'),
              'bgColor': getBgColor('SYURUQ'),
            }
          : {
              'nama': 'DHUHA',
              'jam': todayJadwal?.dhuha ?? '--:--',
              'icon': TablerIcons.sun,
              'color': getColor('DHUHA'),
              'bgColor': getBgColor('DHUHA'),
            },
      {
        'nama': now.weekday == DateTime.friday ? "JUM'AT" : 'DZUHUR',
        'jam': todayJadwal?.dzuhur ?? '--:--',
        'icon': TablerIcons.sun_high,
        'color': getColor(now.weekday == DateTime.friday ? "JUM'AT" : 'DZUHUR'),
        'bgColor': getBgColor(
          now.weekday == DateTime.friday ? "JUM'AT" : 'DZUHUR',
        ),
      },
      {
        'nama': 'ASHAR',
        'jam': todayJadwal?.ashar ?? '--:--',
        'icon': TablerIcons.cloud,
        'color': getColor('ASHAR'),
        'bgColor': getBgColor('ASHAR'),
      },
      {
        'nama': 'MAGHRIB',
        'jam': todayJadwal?.maghrib ?? '--:--',
        'icon': TablerIcons.sunset,
        'color': getColor('MAGHRIB'),
        'bgColor': getBgColor('MAGHRIB'),
      },
      {
        'nama': 'ISYA',
        'jam': todayJadwal?.isya ?? '--:--',
        'icon': TablerIcons.moon_stars,
        'color': getColor('ISYA'),
        'bgColor': getBgColor('ISYA'),
      },
    ];

    return Container(
      width: widget.width ?? 700, // Default 700, bisa dioverride
      color: widget.backgroundColor,
      padding:
          widget.padding ??
          const EdgeInsets.only(left: 32, right: 250, top: 16, bottom: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment
            .center, // Ubah dari spaceEvenly ke center agar mengumpul
        children: jadwal.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final isLast = index == jadwal.length - 1;

          final itemColor = item['color'] as Color;
          final itemBgColor = item['bgColor'] as Color;
          final uniqueKey = ValueKey(
            item['nama'],
          ); // Kunci unik untuk AnimatedSwitcher

          return Padding(
            padding: widget.useCardVariant
                ? EdgeInsets.only(bottom: isLast ? 0 : 16)
                : EdgeInsets.only(bottom: isLast ? 0 : 8),
            child: Builder(
              builder: (context) {
                BoxDecoration decoration;
                if (widget.useCardVariant) {
                  decoration = BoxDecoration(
                    color: itemBgColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  );
                } else if (widget.highlightFadingGradient) {
                  final double startAlpha;
                  if (item['nama'] == activePrayer) {
                    startAlpha = 0.28; // Solat aktif: lebih tebal
                  } else if (item['nama'] == nextPrayer) {
                    startAlpha = 0.18; // Akan masuk: agak kurang tebal
                  } else {
                    startAlpha = 0.07; // Lainnya: lebih tipis lagi
                  }

                  decoration = BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.white.withValues(alpha: startAlpha),
                        Colors.white.withValues(alpha: 0.0),
                      ],
                      stops: const [0.0, 1.0],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  );
                } else {
                  decoration = BoxDecoration(
                    color: widget.backgroundColor,
                    border: isLast
                        ? null
                        : Border(
                            bottom: BorderSide(
                              color: Colors.white.withValues(alpha: 0.15),
                              width: 1.0,
                            ),
                          ),
                  );
                }

                return Container(
                  padding: EdgeInsets.symmetric(
                    vertical: widget.useCardVariant ? 19 : 20,
                    horizontal: 24,
                  ),
                  decoration: decoration,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 700),
                    switchInCurve: Curves.linear,
                    switchOutCurve: Curves.linear,
                    layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
                      return Stack(
                        alignment: Alignment.centerLeft,
                        children: [
                          ...previousChildren,
                          if (currentChild != null) currentChild,
                        ],
                      );
                    },
                    transitionBuilder: _buildFlipTransition,
                    child: Row(
                      key:
                          uniqueKey, // Kunci unik ditempatkan pada Row agar merender ulang sekalian
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Icon Paling Kiri
                    Icon(
                      item['icon'] as IconData,
                      color: itemColor,
                      size: widget.iconSize ?? 48,
                    ),
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
                              fontSize: widget.titleFontSize ?? 32,
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
                              fontSize:
                                  widget.timeFontSize ?? 72, // Jam diperbesar
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
            );
          },
        ),
      );
    }).toList(),
      ),
    );
  }
}
