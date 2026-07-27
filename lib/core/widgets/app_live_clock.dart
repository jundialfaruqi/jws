import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../time/time_sync_service.dart';
import 'package:intl/intl.dart';

class AppLiveClock extends ConsumerWidget {
  final TextStyle textStyle;
  final String prefix;
  final bool showDate;
  final bool showSeconds;

  const AppLiveClock({
    super.key,
    required this.textStyle,
    this.prefix = '',
    this.showDate = true,
    this.showSeconds = true,
  });

  String _formatNumber(int number) => number.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder(
      // Berdetak setiap 1 detik
      stream: Stream.periodic(const Duration(seconds: 1)),
      builder: (context, snapshot) {
        final now = ref.read(timeSyncServiceProvider).now();
        var dateStr = DateFormat('EEEE, dd MMMM yyyy', 'id').format(now);
        dateStr = dateStr.replaceAll('Minggu', 'Ahad');
        final timeStr = showSeconds
            ? "${_formatNumber(now.hour)}:${_formatNumber(now.minute)}:${_formatNumber(now.second)}"
            : "${_formatNumber(now.hour)}:${_formatNumber(now.minute)}";
        
        String baseText = showDate ? '$dateStr $timeStr' : timeStr;
        final displayText = prefix.isNotEmpty 
            ? '$prefix • $baseText' 
            : baseText;

        return Text(
          displayText,
          style: textStyle,
        );
      },
    );
  }
}
