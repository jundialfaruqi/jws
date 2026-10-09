import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../time/time_sync_service.dart';

/// Widget teks berjalan (marquee) yang otomatis aktif jika panjang teks
/// melebihi lebar area yang tersedia, dan tersinkronisasi antar perangkat
/// menggunakan detak milidetik dari [timeSyncServiceProvider].
class AppSyncMarqueeText extends ConsumerStatefulWidget {
  final String text;
  final TextStyle style;
  final TextAlign textAlign;
  final double velocity;
  final double blankSpace;
  final double? maxWidth;

  const AppSyncMarqueeText({
    super.key,
    required this.text,
    required this.style,
    this.textAlign = TextAlign.left,
    this.velocity = 60.0,
    this.blankSpace = 80.0,
    this.maxWidth,
  });

  @override
  ConsumerState<AppSyncMarqueeText> createState() => _AppSyncMarqueeTextState();
}

class _AppSyncMarqueeTextState extends ConsumerState<AppSyncMarqueeText>
    with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  double _textWidth = 0.0;
  double _textHeight = 0.0;
  final ValueNotifier<double> _offsetNotifier = ValueNotifier<double>(0.0);
  bool _isOverflowing = false;

  @override
  void initState() {
    super.initState();
    _calculateTextDimensions();

    _ticker = createTicker((elapsed) {
      if (!_isOverflowing || _textWidth <= 0) return;

      final int nowMs =
          ref.read(timeSyncServiceProvider).now().millisecondsSinceEpoch;
      final double totalWidth = _textWidth + widget.blankSpace;
      final double distance = (nowMs / 1000.0) * widget.velocity;
      final double position = distance % totalWidth;

      _offsetNotifier.value = -position;
    });
  }

  void _calculateTextDimensions() {
    if (widget.text.isEmpty) {
      _textWidth = 0.0;
      _textHeight = 0.0;
      return;
    }
    final textPainter = TextPainter(
      text: TextSpan(text: widget.text, style: widget.style),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout(minWidth: 0, maxWidth: double.infinity);

    _textWidth = textPainter.size.width;
    _textHeight = textPainter.size.height;
  }

  @override
  void didUpdateWidget(covariant AppSyncMarqueeText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text || oldWidget.style != widget.style) {
      _calculateTextDimensions();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _offsetNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.text.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = widget.maxWidth ?? constraints.maxWidth;
        final bool shouldScroll =
            availableWidth.isFinite &&
            availableWidth > 0 &&
            _textWidth > availableWidth;

        if (shouldScroll != _isOverflowing) {
          _isOverflowing = shouldScroll;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            if (_isOverflowing) {
              if (!_ticker.isActive) _ticker.start();
            } else {
              if (_ticker.isActive) _ticker.stop();
            }
          });
        }

        if (!shouldScroll) {
          return Text(
            widget.text,
            style: widget.style,
            textAlign: widget.textAlign,
            maxLines: 1,
            overflow: TextOverflow.clip,
          );
        }

        const double vPadding = 6.0;
        final double boxHeight = _textHeight + (vPadding * 2);

        return SizedBox(
          width: availableWidth,
          height: boxHeight,
          child: ClipRect(
            child: ValueListenableBuilder<double>(
              valueListenable: _offsetNotifier,
              builder: (context, offset, child) {
                return Transform.translate(
                  offset: Offset(offset, 0),
                  child: child,
                );
              },
              child: OverflowBox(
                minWidth: 0,
                maxWidth: double.infinity,
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: vPadding),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        widget.text,
                        style: widget.style,
                        maxLines: 1,
                        softWrap: false,
                      ),
                      SizedBox(width: widget.blankSpace),
                      Text(
                        widget.text,
                        style: widget.style,
                        maxLines: 1,
                        softWrap: false,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
