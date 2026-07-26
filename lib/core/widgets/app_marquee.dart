import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_colors.dart';
import '../time/time_sync_service.dart';

class AppMarquee extends ConsumerStatefulWidget {
  final String text;
  final double height;
  final Color backgroundColor;
  final TextStyle textStyle;
  final double velocity;
  final double blankSpace;

  const AppMarquee({
    super.key,
    required this.text,
    this.height = 120.0,
    this.backgroundColor = AppColors.bgDark,
    this.textStyle = const TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 64,
      color: AppColors.textYellow,
    ),
    this.velocity = 120.0,
    this.blankSpace = 300.0, // Spasi pemisah sebelum teks berulang
  });

  @override
  ConsumerState<AppMarquee> createState() => _AppMarqueeState();
}

class _AppMarqueeState extends ConsumerState<AppMarquee> with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  double _textWidth = 0.0;
  double _offsetX = 0.0;
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    _calculateTextWidth();
    
    // Ticker berjalan pada refresh rate layar (60/120 fps)
    _ticker = createTicker((elapsed) {
      if (!_isReady || _textWidth == 0.0) return;

      // Logika Sinkronisasi Jam Dunia (Keajaiban Sinkronisasi)
      final int nowMs = ref.read(timeSyncServiceProvider).now().millisecondsSinceEpoch;
      
      // Jarak = (waktu_berjalan_dalam_detik) * kecepatan
      final double distance = (nowMs / 1000.0) * widget.velocity;
      
      final double totalWidth = _textWidth + widget.blankSpace;
      
      // Hitung sisa jarak agar animasi berulang (looping) secara mulus
      final double position = distance % totalWidth;

      // Update posisi tanpa setState agar super ringan!
      setState(() {
        _offsetX = -position; // Minus karena bergerak ke kiri
      });
    });

    _ticker.start();
  }

  void _calculateTextWidth() {
    final TextPainter textPainter = TextPainter(
      text: TextSpan(text: widget.text, style: widget.textStyle),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout(minWidth: 0, maxWidth: double.infinity);

    setState(() {
      _textWidth = textPainter.size.width;
      _isReady = true;
    });
  }

  @override
  void didUpdateWidget(covariant AppMarquee oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text || oldWidget.textStyle != widget.textStyle) {
      _calculateTextWidth();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isReady) return Container(height: widget.height, color: widget.backgroundColor);

    return Container(
      height: widget.height,
      width: double.infinity,
      color: widget.backgroundColor,
      // ClipRect memastikan teks yang tergeser keluar batas layar disembunyikan
      child: ClipRect(
        child: Transform.translate(
          offset: Offset(_offsetX, 0),
          child: OverflowBox(
            maxWidth: double.infinity,
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              // Render 2 salinan agar saat salinan pertama menghilang, salinan kedua sudah muncul menyambung
              children: [
                Text(
                  widget.text,
                  style: widget.textStyle,
                  maxLines: 1,
                  softWrap: false,
                ),
                SizedBox(width: widget.blankSpace),
                Text(
                  widget.text,
                  style: widget.textStyle,
                  maxLines: 1,
                  softWrap: false,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


