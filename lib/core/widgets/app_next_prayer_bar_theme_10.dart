import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:jws/core/constants/app_colors.dart';
import '../../features/main/models/jadwal_sholat_model.dart';
import '../time/time_sync_service.dart';
import 'package:hijri/hijri_calendar.dart';

class AppNextPrayerBarTheme10 extends ConsumerStatefulWidget {
  final double leftMargin;
  final List<JadwalSholatModel> jadwalSholatList;
  final bool countdownOnly;
  final bool dateOnly;
  final double fontSize;

  const AppNextPrayerBarTheme10({
    super.key,
    this.leftMargin = 0.0,
    this.jadwalSholatList = const [],
    this.countdownOnly = false,
    this.dateOnly = false,
    this.fontSize = 28.0,
  });

  @override
  ConsumerState<AppNextPrayerBarTheme10> createState() => _AppNextPrayerBarTheme10State();
}

class _AppNextPrayerBarTheme10State extends ConsumerState<AppNextPrayerBarTheme10> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _syncAndScheduleNext();
    });
  }

  void _syncAndScheduleNext() {
    if (!mounted) return;
    setState(() {}); // Picu rebuild layar

    final nowMs = ref.read(timeSyncServiceProvider).now().millisecondsSinceEpoch;
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

        String nextPrayer = '...';
        Duration countdown = Duration.zero;
        JadwalSholatModel? todayJadwal;
        JadwalSholatModel? tomorrowJadwal;

        if (widget.jadwalSholatList.isNotEmpty) {
          final dateStr =
              "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

          try {
            todayJadwal = widget.jadwalSholatList.firstWhere((j) => j.date == dateStr);
          } catch (_) {
            todayJadwal = widget.jadwalSholatList.first;
          }

          final tomorrow = now.add(const Duration(days: 1));
          final tomorrowStr =
              "${tomorrow.year}-${tomorrow.month.toString().padLeft(2, '0')}-${tomorrow.day.toString().padLeft(2, '0')}";
          try {
            tomorrowJadwal = widget.jadwalSholatList.firstWhere(
              (j) => j.date == tomorrowStr,
            );
          } catch (_) {
            tomorrowJadwal = todayJadwal;
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

          bool found = false;
          for (int i = 0; i < times.length; i++) {
            final t = times[i]['time'] as DateTime;
            if (t.isAfter(now)) {
              nextPrayer = times[i]['nama'] as String;
              countdown = t.difference(now);
              found = true;
              break;
            }
          }

          if (!found) {
            nextPrayer = 'IMSAK';
            // Pakai jam Imsak besok
            final tomorrowImsakTime = _parseTime(
              tomorrowJadwal.imsak,
              tomorrow,
            );
            countdown = tomorrowImsakTime.difference(now);
          }
        }

        String twoDigits(int n) => n.toString().padLeft(2, '0');
        final hours = twoDigits(countdown.inHours);
        final minutes = twoDigits(countdown.inMinutes.remainder(60));
        final seconds = twoDigits(countdown.inSeconds.remainder(60));
        final countdownStr = '- $hours:$minutes:$seconds';

        final isWarning = countdown.inSeconds > 0 && countdown.inSeconds <= 600;
        final blinkOn = now.second % 2 == 0;
        final cardColor = isWarning && blinkOn ? AppColors.bgBlue : Colors.red;
        final borderColor = Colors.transparent;
        final textColor = isWarning && blinkOn
            ? AppColors.textYellow
            : Colors.white;

        // Tanggal masehi dari jadwal
        final tanggalMasehi = (todayJadwal?.tanggal ?? '26 Juli 2026')
            .replaceAll('Minggu', 'Ahad');

        // Kalkulasi Hijriah secara mandiri (ganti tanggal setelah Maghrib)
        DateTime dateToCalculate = now;
        bool isAfterMaghrib = false;
        if (todayJadwal != null && todayJadwal.maghrib.isNotEmpty) {
          try {
            final maghribTime = _parseTime(todayJadwal.maghrib, now);
            if (!now.isBefore(maghribTime)) {
              dateToCalculate = now.add(const Duration(days: 1));
              isAfterMaghrib = true;
            }
          } catch (_) {}
        }

        String tanggalHijriah = "";
        final activeJadwal = isAfterMaghrib ? tomorrowJadwal : todayJadwal;

        if (activeJadwal != null &&
            activeJadwal.tanggalHijriah != null &&
            activeJadwal.tanggalHijriah!.isNotEmpty) {
          tanggalHijriah = activeJadwal.tanggalHijriah!;
        } else {
          // Fallback ke library, dengan koreksi -1 hari karena Umm al-Qura sering +1 hari dibanding Indonesia
          final correctedDate = dateToCalculate.subtract(
            const Duration(days: 1),
          );
          final hijriDate = HijriCalendar.fromDate(correctedDate);
          tanggalHijriah =
              "${hijriDate.hDay} ${hijriDate.longMonthName} ${hijriDate.hYear} H";
        }

        final countdownWidget = Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
          decoration: BoxDecoration(
            color: AppColors.bgDark.withValues(alpha: 0.5),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(0),
              bottomLeft: Radius.circular(60),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _RingingBellIcon(
                icon: TablerIcons.bell_ringing,
                color: Colors.white,
                size: 36,
              ),
              const SizedBox(width: 16),
              Text(
                'MENUJU $nextPrayer',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: widget.fontSize,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(width: 24),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: Text(
                  countdownStr,
                  style: TextStyle(
                    color: textColor,
                    fontSize: widget.fontSize,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'JetBrainsMono',
                  ),
                ),
              ),
            ],
          ),
        );

        if (widget.countdownOnly) {
          return countdownWidget;
        }

        final dateWidget = Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
          decoration: BoxDecoration(
            color: AppColors.bgDark.withValues(alpha: 0.6),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(0),
              bottomLeft: Radius.circular(24),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                TablerIcons.calendar_event,
                color: Colors.white,
                size: 36,
              ),
              const SizedBox(width: 12),
              Text(
                tanggalMasehi,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: widget.fontSize,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(width: 24),
              Container(width: 2, height: 28, color: Colors.white54),
              const SizedBox(width: 24),
              const Icon(TablerIcons.moon_stars, color: Colors.white, size: 36),
              const SizedBox(width: 12),
              Text(
                tanggalHijriah,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: widget.fontSize,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
        );

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            dateWidget,
            if (!widget.dateOnly) const SizedBox(height: 0),
            if (!widget.dateOnly) countdownWidget,
          ],
        );
  }
}

class _RingingBellIcon extends StatefulWidget {
  final IconData icon;
  final Color color;
  final double size;

  const _RingingBellIcon({
    required this.icon,
    required this.color,
    required this.size,
  });

  @override
  State<_RingingBellIcon> createState() => _RingingBellIconState();
}

class _RingingBellIconState extends State<_RingingBellIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    // Durasi ayunan bolak-balik yang cepat agar terlihat bergetar
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..repeat(reverse: true);

    // Sudut putar antara -15 derajat hingga 15 derajat (dalam radian)
    _animation = Tween<double>(begin: -0.25, end: 0.25).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.rotate(
          angle: _animation.value,
          alignment: Alignment.topCenter, // Poros rotasi di ujung atas lonceng
          child: child,
        );
      },
      child: Icon(widget.icon, color: widget.color, size: widget.size),
    );
  }
}
