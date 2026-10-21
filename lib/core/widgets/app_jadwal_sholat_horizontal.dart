import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import '../../features/main/models/jadwal_sholat_model.dart';
import '../time/time_sync_service.dart';
import '../constants/app_colors.dart';

class AppJadwalSholatHorizontal extends ConsumerStatefulWidget {
  final List<JadwalSholatModel> jadwalSholatList;

  const AppJadwalSholatHorizontal({
    super.key,
    this.jadwalSholatList = const [],
  });

  @override
  ConsumerState<AppJadwalSholatHorizontal> createState() =>
      _AppJadwalSholatHorizontalState();
}

class _AppJadwalSholatHorizontalState
    extends ConsumerState<AppJadwalSholatHorizontal> {
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

      // Tentukan waktu sholat aktif dan selanjutnya
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

      if (activePrayer.isEmpty) {
        activePrayer = 'ISYA';
        nextPrayer = 'IMSAK';
      }
    }

    final List<Map<String, dynamic>> prayersToDisplay = [];
    if (todayJadwal != null) {
      if (_showImsak) {
        prayersToDisplay.add({
          'label': 'IMSAK',
          'time': todayJadwal.imsak,
          'icon': TablerIcons.moon_2,
        });
      } else {
        prayersToDisplay.add({
          'label': 'SUBUH',
          'time': todayJadwal.subuh,
          'icon': TablerIcons.sun_low,
        });
      }

      if (_showSyuruq) {
        prayersToDisplay.add({
          'label': 'SYURUQ',
          'time': todayJadwal.terbit,
          'icon': TablerIcons.sunrise,
        });
      } else {
        prayersToDisplay.add({
          'label': 'DHUHA',
          'time': todayJadwal.dhuha,
          'icon': TablerIcons.sun,
        });
      }

      prayersToDisplay.addAll([
        {
          'label': now.weekday == DateTime.friday ? "JUM'AT" : 'DZUHUR',
          'time': todayJadwal.dzuhur,
          'icon': TablerIcons.sun_high,
        },
        {
          'label': 'ASHAR',
          'time': todayJadwal.ashar,
          'icon': TablerIcons.sun_low,
        },
        {
          'label': 'MAGHRIB',
          'time': todayJadwal.maghrib,
          'icon': TablerIcons.sunset,
        },
        {'label': 'ISYA', 'time': todayJadwal.isya, 'icon': TablerIcons.moon},
      ]);
    }

    return Container(
      width: double.infinity,
      color: Colors.transparent,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: prayersToDisplay.map((prayer) {
          final isHighlight = activePrayer == prayer['label'];
          final isNext = nextPrayer == prayer['label'];
          // Khusus Terbit/Syuruq, jika IMSAK adalah active/next, maka mereka bisa terbawa jika labelnya tidak muncul,
          // tapi logika di atas aman karena nama label sudah persis.
          return _buildPrayerItem(
            label: prayer['label'] as String,
            time: prayer['time'] as String,
            iconData: prayer['icon'] as IconData,
            isHighlight: isHighlight,
            isNext: isNext,
          );
        }).toList(),
      ),
    );
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

  Widget _buildPrayerItem({
    required String label,
    required String time,
    required IconData iconData,
    required bool isHighlight,
    required bool isNext,
  }) {
    Color getBgColor() {
      if (isHighlight) return Colors.red;
      if (isNext) return Colors.yellow;
      return AppColors.bgBlue; // default
    }

    Color getTextColor() {
      if (isHighlight) {
        return Colors.white;
      }
      if (isNext) {
        return AppColors.bgNavy; // Teks hitam agar kontras dengan latar kuning
      }
      return Colors.white; // default
    }

    final bgColor = getBgColor();
    final textColor = getTextColor();

    return Expanded(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 700),
        switchInCurve: Curves.linear,
        switchOutCurve: Curves.linear,
        layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
          return Stack(
            alignment: Alignment.center,
            children: [
              ...previousChildren,
              if (currentChild != null) currentChild,
            ],
          );
        },
        transitionBuilder: _buildFlipTransition,
        child: Container(
          key: ValueKey(label),
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(iconData, color: textColor, size: 48),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.bold,
                      fontSize: 27,
                      color: textColor,
                    ),
                  ),
                  Text(
                    time,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.bold,
                      fontSize: 37,
                      letterSpacing: 2.0,
                      color: textColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
