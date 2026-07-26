import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:jws/core/constants/app_colors.dart';
import '../../features/main/models/jadwal_sholat_model.dart';
import '../time/time_sync_service.dart';

class AppNextPrayerBar extends ConsumerWidget {
  final double leftMargin;
  final JadwalSholatModel? jadwalSholat;

  const AppNextPrayerBar({super.key, this.leftMargin = 0.0, this.jadwalSholat});

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
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder(
      stream: Stream.periodic(const Duration(seconds: 1)),
      builder: (context, snapshot) {
        final now = ref.read(timeSyncServiceProvider).now();

        String nextPrayer = '...';
        Duration countdown = Duration.zero;

        if (jadwalSholat != null) {
          final times = [
            {'nama': 'IMSAK', 'time': _parseTime(jadwalSholat!.imsak, now)},
            {'nama': 'SUBUH', 'time': _parseTime(jadwalSholat!.subuh, now)},
            {'nama': 'TERBIT', 'time': _parseTime(jadwalSholat!.terbit, now)},
            {'nama': 'DHUHA', 'time': _parseTime(jadwalSholat!.dhuha, now)},
            {'nama': now.weekday == DateTime.friday ? "JUM'AT" : 'DZUHUR', 'time': _parseTime(jadwalSholat!.dzuhur, now)},
            {'nama': 'ASHAR', 'time': _parseTime(jadwalSholat!.ashar, now)},
            {'nama': 'MAGHRIB', 'time': _parseTime(jadwalSholat!.maghrib, now)},
            {'nama': 'ISYA', 'time': _parseTime(jadwalSholat!.isya, now)},
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
            final t = times[0]['time'] as DateTime;
            final tomorrowImsak = t.add(const Duration(days: 1));
            countdown = tomorrowImsak.difference(now);
          }
        }

        String twoDigits(int n) => n.toString().padLeft(2, '0');
        final hours = twoDigits(countdown.inHours);
        final minutes = twoDigits(countdown.inMinutes.remainder(60));
        final seconds = twoDigits(countdown.inSeconds.remainder(60));
        final countdownStr = '- $hours:$minutes:$seconds';

        // Tanggal masehi dari jadwal, jika ada
        final tanggalMasehi = (jadwalSholat?.tanggal ?? '26 Juli 2026').replaceAll('Minggu', 'Ahad');

        return Container(
          color: AppColors.bgNavy,
          padding: EdgeInsets.only(
            left: leftMargin + 32,
            right: 48,
            top: 16,
            bottom: 16,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Kiri: Waktu Sholat yang akan masuk
              Row(
                children: [
                  const _RingingBellIcon(
                    icon: TablerIcons.bell_ringing,
                    color: Colors.white,
                    size: 36,
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'MENUJU $nextPrayer',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
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
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Text(
                      countdownStr,
                      style: const TextStyle(
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
                  const Icon(
                    TablerIcons.calendar_event,
                    color: Colors.white,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    tanggalMasehi,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(width: 24),
                  Container(width: 2, height: 28, color: Colors.white54),
                  const SizedBox(width: 24),
                  const Icon(
                    TablerIcons.moon_stars,
                    color: Colors.white,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    jadwalSholat?.tanggalHijriah ?? '',
                    style: const TextStyle(
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
      },
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
