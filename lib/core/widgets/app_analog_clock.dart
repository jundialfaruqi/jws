import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../time/time_sync_service.dart';

class AppAnalogClock extends ConsumerStatefulWidget {
  final double size;
  final double? numberFontSize;
  final double? digitalFontSize;
  final double borderWidth;
  final Color animationColor;
  final double? logoWidth;
  final bool showBubble;
  final String bubbleAsset;

  const AppAnalogClock({
    super.key,
    this.size = 350,
    this.numberFontSize,
    this.digitalFontSize,
    this.borderWidth = 12.0,
    this.animationColor = Colors.white,
    this.logoWidth,
    this.showBubble = true,
    this.bubbleAsset = 'assets/jam-analog/bubble.png',
  });

  @override
  ConsumerState<AppAnalogClock> createState() => _AppAnalogClockState();
}

class _AppAnalogClockState extends ConsumerState<AppAnalogClock> {
  Timer? _timer;
  late DateTime _now;

  @override
  void initState() {
    super.initState();
    _now = ref.read(timeSyncServiceProvider).now();
    _scheduleNextTick();
  }

  void _scheduleNextTick() {
    if (!mounted) return;
    final now = ref.read(timeSyncServiceProvider).now();
    final msUntilNext = 1000 - (now.millisecondsSinceEpoch % 1000);
    _timer = Timer(Duration(milliseconds: msUntilNext), () {
      if (mounted) {
        setState(() {
          _now = ref.read(timeSyncServiceProvider).now();
        });
        _scheduleNextTick();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String formattedTime =
        "${_now.hour.toString().padLeft(2, '0')}:${_now.minute.toString().padLeft(2, '0')}:${_now.second.toString().padLeft(2, '0')}";

    final double borderWidth = widget.borderWidth;
    final double outerSize = widget.size + (borderWidth * 2) + 16;

    // Perhitungan simetris presisi terhadap titik tengah jam
    final double yCenter = widget.size / 2;
    final double logoWidth = widget.logoWidth ?? (widget.size * 0.44);
    final double logoHeight = logoWidth / 5.0; // Rasio 1581:316 = 5:1
    final double gapFromCenter = widget.size * 0.085;

    return RepaintBoundary(
      child: SizedBox(
        width: outerSize,
        height: outerSize,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Komponen jam utama (ukuran dial tetap tepat widget.size tanpa terpengaruh border)
            Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                color: const Color(0xFF003366), // Warna bgNavy agar senada
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 24,
                    spreadRadius: 4,
                    offset: const Offset(8, 8),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Logo statis Diskominfotiksan di bagian tengah atas
                  // Jarak dari titik tengah ke tepi bawah logo = gapFromCenter
                  Positioned(
                    top: yCenter - gapFromCenter - logoHeight,
                    child: SizedBox(
                      width: logoWidth,
                      height: logoHeight,
                      child: Image.asset(
                        'assets/logo/diskominfotiksan-logo.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),

                  // Jam digital di bagian tengah bawah
                  // Jarak dari titik tengah ke tepi atas jam digital = gapFromCenter (SAMA PERSIS DENGAN LOGO)
                  Positioned(
                    top: yCenter + gapFromCenter,
                    child: Text(
                      formattedTime,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: widget.digitalFontSize ?? (widget.size * 0.09),
                        fontWeight: FontWeight.bold,
                        fontFamily: 'JetBrainsMono',
                        height: 1.0,
                        shadows: [
                          Shadow(
                            blurRadius: 4,
                            color: Colors.black.withValues(alpha: 0.6),
                            offset: const Offset(1, 2),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Canvas jam analog (dirender terakhir agar jarum berada di depan)
                  CustomPaint(
                    size: Size(widget.size, widget.size),
                    painter: AnalogClockPainter(
                      dateTime: _now,
                      handColor: Colors.white,
                      secondHandColor: Colors.red,
                      tickColor: Colors.white,
                      numberFontSize: widget.numberFontSize,
                    ),
                  ),

                  // Efek bubble / kaca melayang tepat di atas dial jam bulat (menggunakan BoxShape.circle tanpa ClipOval)
                  if (widget.showBubble)
                    IgnorePointer(
                      child: Container(
                        width: widget.size,
                        height: widget.size,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          image: DecorationImage(
                            image: AssetImage(widget.bubbleAsset),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Border gradasi statis di lingkar luar jam (warna gradasi dipertahankan, tanpa rotasi animasi)
            CustomPaint(
              size: Size(outerSize, outerSize),
              painter: _ClockBorderPainter(
                borderWidth: borderWidth,
                clockSize: widget.size,
                borderColor: widget.animationColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AnalogClockPainter extends CustomPainter {
  final DateTime dateTime;
  final Color handColor;
  final Color secondHandColor;
  final Color tickColor;
  final double? numberFontSize;

  AnalogClockPainter({
    required this.dateTime,
    required this.handColor,
    required this.secondHandColor,
    required this.tickColor,
    this.numberFontSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2;

    // Draw Ticks (Garis penunjuk menit & jam)
    final tickPaint = Paint()
      ..color = tickColor
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 60; i++) {
      final angle = i * 6 * pi / 180;
      final isHour = i % 5 == 0;
      final tickLength = isHour ? radius * 0.08 : radius * 0.04;
      final strokeWidth = isHour ? 4.0 : 2.0;

      tickPaint.strokeWidth = strokeWidth;
      tickPaint.color = tickColor.withValues(alpha: isHour ? 1.0 : 0.5);

      final p1 = Offset(
        center.dx + cos(angle) * (radius - tickLength - 8),
        center.dy + sin(angle) * (radius - tickLength - 8),
      );
      final p2 = Offset(
        center.dx + cos(angle) * (radius - 8),
        center.dy + sin(angle) * (radius - 8),
      );

      canvas.drawLine(p1, p2, tickPaint);
    }

    // Draw Numbers (Angka 1-12)
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    int currentHour12 = dateTime.hour % 12;
    if (currentHour12 == 0) currentHour12 = 12;

    for (int i = 1; i <= 12; i++) {
      final angle = (i * 30 - 90) * pi / 180;

      textPainter.text = TextSpan(
        text: i.toString(),
        style: TextStyle(
          color: i == currentHour12 ? Colors.red : Colors.white,
          fontSize: numberFontSize ?? (radius * 0.25),
          fontWeight: FontWeight.bold,
          fontFamily: 'Poppins',
          shadows: [
            Shadow(
              blurRadius: 4,
              color: Colors.black.withValues(alpha: 0.6),
              offset: const Offset(1, 2),
            ),
          ],
        ),
      );

      textPainter.layout();
      final offset = Offset(
        center.dx + cos(angle) * (radius * 0.72) - (textPainter.width / 2),
        center.dy + sin(angle) * (radius * 0.72) - (textPainter.height / 2),
      );

      textPainter.paint(canvas, offset);
    }

    // Helper function untuk menggambar jarum beserta shadow-nya (hardware-accelerated tanpa CPU MaskFilter)
    void drawHandWithShadow(Offset p1, Offset p2, Paint paint) {
      final shadowPaint = Paint()
        ..color = Colors.black.withValues(alpha: 0.3)
        ..strokeWidth = paint.strokeWidth
        ..strokeCap = StrokeCap.round;

      // Gambar shadow
      canvas.drawLine(
        p1 + const Offset(2, 3),
        p2 + const Offset(2, 3),
        shadowPaint,
      );
      // Gambar jarum asli
      canvas.drawLine(p1, p2, paint);
    }

    // Hitung Sudut Jarum Jam
    final hour = dateTime.hour % 12;
    final minute = dateTime.minute;
    final second = dateTime.second;
    final millisecond = dateTime.millisecond;

    // Hitungan sudut presisi hingga tingkat pecahan desimal (smooth sweep)
    final hourAngle =
        ((hour + (minute / 60) + (second / 3600)) * 30 - 90) * pi / 180;
    final minuteAngle =
        ((minute + (second / 60) + (millisecond / 60000)) * 6 - 90) * pi / 180;
    final secondAngle = ((second + (millisecond / 1000)) * 6 - 90) * pi / 180;

    // Jarum Jam (Hour Hand)
    final hourPaint = Paint()
      ..color = handColor
      ..strokeWidth = radius * 0.06
      ..strokeCap = StrokeCap.round;
    drawHandWithShadow(
      center,
      Offset(
        center.dx + cos(hourAngle) * (radius * 0.45),
        center.dy + sin(hourAngle) * (radius * 0.45),
      ),
      hourPaint,
    );

    // Jarum Menit (Minute Hand)
    final minPaint = Paint()
      ..color = handColor
      ..strokeWidth = radius * 0.04
      ..strokeCap = StrokeCap.round;
    drawHandWithShadow(
      center,
      Offset(
        center.dx + cos(minuteAngle) * (radius * 0.65),
        center.dy + sin(minuteAngle) * (radius * 0.65),
      ),
      minPaint,
    );

    // Jarum Detik (Second Hand)
    final secPaint = Paint()
      ..color = secondHandColor
      ..strokeWidth = radius * 0.02
      ..strokeCap = StrokeCap.round;

    // Ekor jarum detik
    drawHandWithShadow(
      Offset(
        center.dx - cos(secondAngle) * (radius * 0.15),
        center.dy - sin(secondAngle) * (radius * 0.15),
      ),
      Offset(
        center.dx + cos(secondAngle) * (radius * 0.75),
        center.dy + sin(secondAngle) * (radius * 0.75),
      ),
      secPaint,
    );

    // Lingkaran merah di tengah
    canvas.drawCircle(center, radius * 0.05, Paint()..color = secondHandColor);
  }

  @override
  bool shouldRepaint(covariant AnalogClockPainter oldDelegate) {
    return oldDelegate.dateTime != dateTime;
  }
}

class _ClockBorderPainter extends CustomPainter {
  final double borderWidth;
  final double clockSize;
  final Color borderColor;

  const _ClockBorderPainter({
    required this.borderWidth,
    required this.clockSize,
    this.borderColor = Colors.white,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    // Stroke radius berada tepat mengelilingi tepi luar jam
    final radius = (clockSize + borderWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // 1. Base translucent ring (lingkar dasar statis satu warna yang halus)
    final basePaint = Paint()
      ..color = borderColor.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;
    canvas.drawCircle(center, radius, basePaint);

    // 2. Statis sweep gradient - gradasi warna tetap ada, tanpa rotasi animasi
    final sweepGradient = SweepGradient(
      startAngle: 0.0,
      endAngle: 2 * pi,
      colors: [
        Colors.transparent,
        borderColor.withValues(alpha: 0.08),
        borderColor.withValues(alpha: 0.35),
        borderColor.withValues(alpha: 0.95), // Puncak cahaya terang
        borderColor.withValues(alpha: 0.35),
        borderColor.withValues(alpha: 0.08),
        Colors.transparent,
      ],
      stops: const [0.0, 0.65, 0.78, 0.88, 0.94, 0.98, 1.0],
    );

    // Outer subtle glow satu warna (hardware-accelerated tanpa CPU MaskFilter)
    final glowPaint = Paint()
      ..shader = sweepGradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth + 4;
    canvas.drawCircle(center, radius, glowPaint);

    // Crisp sweep stroke satu warna
    final sweepPaint = Paint()
      ..shader = sweepGradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, sweepPaint);
  }

  @override
  bool shouldRepaint(covariant _ClockBorderPainter oldDelegate) {
    return oldDelegate.borderWidth != borderWidth ||
        oldDelegate.clockSize != clockSize ||
        oldDelegate.borderColor != borderColor;
  }
}

