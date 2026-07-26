import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import '../../features/main/models/agenda_model.dart';
import '../constants/app_colors.dart';
import '../time/time_sync_service.dart';

class AppAgendaWidget extends ConsumerStatefulWidget {
  final List<AgendaModel> agendas;
  final bool slideLeft;

  const AppAgendaWidget({super.key, required this.agendas, this.slideLeft = false});

  @override
  ConsumerState<AppAgendaWidget> createState() => _AppAgendaWidgetState();
}

class _AppAgendaWidgetState extends ConsumerState<AppAgendaWidget> {
  Timer? _timer;
  int _currentIndex = 0;
  bool _isResting = false;
  List<AgendaModel> _activeAgendas = [];

  @override
  void initState() {
    super.initState();
    _activeAgendas = widget.agendas.where((a) => a.aktif).toList();
    _startSyncTimer();
  }

  @override
  void didUpdateWidget(AppAgendaWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.agendas != widget.agendas) {
      setState(() {
        _activeAgendas = widget.agendas.where((a) => a.aktif).toList();
      });
    }
  }

  void _startSyncTimer() {
    _timer?.cancel();
    // Gunakan periodic timer (1 detik) hanya untuk men-trigger build ulang UI.
    // Kalkulasi index mutlak akan dilakukan di dalam build() berdasarkan waktu server.
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _truncateText(String text) {
    if (text.length > 23) {
      return '${text.substring(0, 23)}...';
    }
    return text;
  }

  @override
  Widget build(BuildContext context) {
    // Kalkulasi waktu server
    final now = ref.read(timeSyncServiceProvider).now();
    final today = DateTime(now.year, now.month, now.day);

    // Filter agenda: hanya yang aktif & belum lewat hari ini
    final List<AgendaModel> validAgendas = _activeAgendas.where((agenda) {
      if (agenda.dateRaw.isEmpty) return true;
      try {
        final dateParts = agenda.dateRaw.split('-');
        final agendaDate = DateTime(
          int.parse(dateParts[0]),
          int.parse(dateParts[1]),
          int.parse(dateParts[2]),
        );
        return !agendaDate.isBefore(today); // true jika >= hari ini
      } catch (_) {
        return true;
      }
    }).toList();

    if (validAgendas.isEmpty) {
      return const SizedBox.shrink();
    }

    // Kalkulasi index sinkron berdasarkan waktu server absolut
    final int currentEpoch = now.millisecondsSinceEpoch ~/ 1000;

    final int activeCount = validAgendas.length;
    final int cycleTime =
        (activeCount * 10) + 5; // 10s tiap item + 5s istirahat
    final int cyclePosition = currentEpoch % cycleTime;

    if (cyclePosition >= activeCount * 10) {
      _isResting = true;
      // Tetap pertahankan index terakhir yang valid
      _currentIndex = activeCount - 1;
      if (_currentIndex < 0) _currentIndex = 0;
    } else {
      _isResting = false;
      _currentIndex = cyclePosition ~/ 10;
    }

    final agenda = validAgendas[_currentIndex];

    // Kalkulasi days_label secara dinamis berdasarkan now()
    String dynamicDaysLabel = agenda.daysLabel;
    if (agenda.dateRaw.isNotEmpty) {
      try {
        final dateParts = agenda.dateRaw.split('-');
        final agendaDate = DateTime(
          int.parse(dateParts[0]),
          int.parse(dateParts[1]),
          int.parse(dateParts[2]),
        );
        
        if (agendaDate.isAtSameMomentAs(today)) {
          dynamicDaysLabel = 'Hari ini';
        } else {
          final diff = agendaDate.difference(today).inDays;
          if (diff == 1) {
            dynamicDaysLabel = 'Besok';
          } else if (diff > 1) {
            dynamicDaysLabel = '$diff Hari Lagi';
          }
        }
      } catch (_) {}
    }

    String dateStr = agenda.date;

    return AnimatedSlide(
      offset: _isResting ? Offset(widget.slideLeft ? -1.5 : 1.5, 0) : Offset.zero,
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInOutCubic,
      child: Container(
        width: 440,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.bgBlue,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 16,
              offset: const Offset(4, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(
                  TablerIcons.calendar_event,
                  color: Colors.white,
                  size: 32,
                ),
                const SizedBox(width: 16),
                const Text(
                  'Agenda Masjid',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              _truncateText(agenda.name),
              style: const TextStyle(
                color: AppColors.textYellow,
                fontSize: 32,
                fontWeight: FontWeight.w900,
                fontFamily: 'Poppins',
              ),
              maxLines: 1,
              overflow: TextOverflow.visible,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  dateStr,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: dynamicDaysLabel.toLowerCase() == 'hari ini'
                        ? Colors.red.shade400
                        : Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    dynamicDaysLabel,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
