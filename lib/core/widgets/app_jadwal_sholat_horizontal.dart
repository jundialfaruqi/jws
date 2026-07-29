import 'dart:async';
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
  bool _showPrimary = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _syncAndScheduleNext();
    });
  }

  void _syncAndScheduleNext() {
    if (!mounted) return;

    final now = ref.read(timeSyncServiceProvider).now();
    final int nowMs = now.millisecondsSinceEpoch;
    final int epochSeconds = nowMs ~/ 1000;

    // 1 Siklus total = 14 detik (7 detik Imsak/Terbit, 7 detik Subuh/Dhuha)
    final int cyclePosition = epochSeconds % 14;

    setState(() {
      _showPrimary = cyclePosition < 7;
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
      if (_showPrimary) {
        prayersToDisplay.add({
          'label': 'IMSAK',
          'time': todayJadwal.imsak,
          'icon': TablerIcons.moon_2,
        });
        prayersToDisplay.add({
          'label': 'SYURUQ',
          'time': todayJadwal.terbit,
          'icon': TablerIcons.sunrise,
        });
      } else {
        prayersToDisplay.add({
          'label': 'SUBUH',
          'time': todayJadwal.subuh,
          'icon': TablerIcons.sun_low,
        });
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
        return Colors.black; // Teks hitam agar kontras dengan latar kuning
      }
      return Colors.white; // default
    }

    final bgColor = getBgColor();
    final textColor = getTextColor();

    return Expanded(
      child: Container(
        // Margin horizontal digunakan untuk mengatur jarak renggang antar kotak jadwal
        margin: const EdgeInsets.symmetric(horizontal: 8),
        // Padding digunakan untuk mengatur spasi ke dalam (menjauhkan teks & icon dari tepi kotak)
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 800),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (Widget child, Animation<double> animation) {
            final offsetAnimation = Tween<Offset>(
              begin: const Offset(-0.3, 0.0),
              end: Offset.zero,
            ).animate(animation);
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(position: offsetAnimation, child: child),
            );
          },
          child: Row(
            key: ValueKey(label),
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
