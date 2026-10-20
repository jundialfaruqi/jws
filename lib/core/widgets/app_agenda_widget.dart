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
  final bool continuous;
  final double borderRadius;
  final Color? backgroundColor;

  const AppAgendaWidget({
    super.key,
    required this.agendas,
    this.slideLeft = false,
    this.continuous = false,
    this.borderRadius = 24.0,
    this.backgroundColor,
  });

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
    if (!mounted) return;
    setState(() {}); // Picu rebuild UI pada kelipatan detik yang tepat

    final nowMs = ref
        .read(timeSyncServiceProvider)
        .now()
        .millisecondsSinceEpoch;
    final int msUntilNext = 1000 - (nowMs % 1000);

    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: msUntilNext), _startSyncTimer);
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
    final int cycleTime = widget.continuous
        ? (activeCount * 10)
        : (activeCount * 10) +
              5; // 10s tiap item + 5s istirahat (jika tidak continuous)
    final int cyclePosition = currentEpoch % cycleTime;

    if (widget.continuous) {
      _isResting = false;
      _currentIndex = cyclePosition ~/ 10;
    } else if (cyclePosition >= activeCount * 10) {
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
      offset: _isResting
          ? Offset(widget.slideLeft ? -1.5 : 1.5, 0)
          : Offset.zero,
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInOutCubic,
      child: Container(
        width: 440,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: widget.backgroundColor ?? AppColors.bgBlue,
          borderRadius: BorderRadius.circular(widget.borderRadius),
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
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Padding(
                  padding: EdgeInsets.only(
                    bottom: 0,
                    left: 0,
                  ), // Angkat sedikit ikonnya
                  child: Icon(
                    TablerIcons.calendar_event,
                    color: Colors.white,
                    size: 42,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  dynamicDaysLabel,
                  style: TextStyle(
                    fontSize: 36,
                    height:
                        1.0, // Rapatkan tinggi font agar tidak ada ruang kosong di bawah
                    fontWeight: FontWeight.bold,
                    color: dynamicDaysLabel.toLowerCase() == 'hari ini'
                        ? Colors.yellow
                        : Colors.white,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              _truncateText(agenda.name),
              style: const TextStyle(
                color: AppColors.textInverse,
                fontSize: 28,
                fontWeight: FontWeight.w900,
                fontFamily: 'Poppins',
              ),
              maxLines: 1,
              overflow: TextOverflow.visible,
            ),
            const SizedBox(height: 12),
            Text(
              dateStr,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
