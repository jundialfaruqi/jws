import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../time/time_sync_service.dart';

class AppLiveClock extends ConsumerWidget {
  final TextStyle textStyle;
  final String prefix;

  const AppLiveClock({
    super.key,
    required this.textStyle,
    this.prefix = '',
  });

  String _formatNumber(int number) => number.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder(
      // Berdetak setiap 1 detik
      stream: Stream.periodic(const Duration(seconds: 1)),
      builder: (context, snapshot) {
        final now = ref.read(timeSyncServiceProvider).now();
        final dateStr = "${now.year}-${_formatNumber(now.month)}-${_formatNumber(now.day)}";
        final timeStr = "${_formatNumber(now.hour)}:${_formatNumber(now.minute)}:${_formatNumber(now.second)}";
        
        final displayText = prefix.isNotEmpty 
            ? '$prefix • $dateStr $timeStr' 
            : '$dateStr $timeStr';

        return Text(
          displayText,
          style: textStyle,
        );
      },
    );
  }
}
