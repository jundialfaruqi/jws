import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../time/time_sync_service.dart';
import 'package:intl/intl.dart';

class AppLiveClock extends ConsumerStatefulWidget {
  final TextStyle textStyle;
  final String prefix;
  final bool showDate;
  final bool showSeconds;
  final bool blinkSeparator;

  final Widget Function(BuildContext context, DateTime now)? builder;

  const AppLiveClock({
    super.key,
    this.textStyle = const TextStyle(),
    this.prefix = '',
    this.showDate = true,
    this.showSeconds = true,
    this.blinkSeparator = false,
    this.builder,
  });

  @override
  ConsumerState<AppLiveClock> createState() => _AppLiveClockState();
}

class _AppLiveClockState extends ConsumerState<AppLiveClock> {
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
    // Hitung sisa waktu hingga menyentuh detik (kelipatan 1000 ms) berikutnya secara presisi
    final int msUntilNext = 1000 - (nowMs % 1000);
    
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: msUntilNext), _syncAndScheduleNext);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatNumber(int number) => number.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final now = ref.read(timeSyncServiceProvider).now();

    if (widget.builder != null) {
      return widget.builder!(context, now);
    }

    var dateStr = DateFormat('EEEE, dd MMM yyyy', 'id').format(now);
    dateStr = dateStr.replaceAll('Minggu', 'Ahad');
    
    final separator = (widget.blinkSeparator && now.second % 2 != 0) ? " " : ":";
    
    final timeStr = widget.showSeconds
        ? "${_formatNumber(now.hour)}$separator${_formatNumber(now.minute)}$separator${_formatNumber(now.second)}"
        : "${_formatNumber(now.hour)}$separator${_formatNumber(now.minute)}";
    
    String baseText = widget.showDate ? '$dateStr $timeStr' : timeStr;
    final displayText = widget.prefix.isNotEmpty 
        ? '${widget.prefix} • $baseText' 
        : baseText;

    return Text(
      displayText,
      style: widget.textStyle,
    );
  }
}
