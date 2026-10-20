import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../constants/api_constant.dart';
import '../time/time_sync_service.dart';
import '../providers/slide_start_time_provider.dart';

class AppImageSlider extends ConsumerStatefulWidget {
  final List<String> imageUrls;
  final double leftMargin;

  const AppImageSlider({
    super.key,
    this.imageUrls = const [],
    this.leftMargin = 0.0,
  });

  @override
  ConsumerState<AppImageSlider> createState() => _AppImageSliderState();
}

class _AppImageSliderState extends ConsumerState<AppImageSlider> {
  int _currentPage = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    // Gunakan post-frame untuk mengatur initial index secara presisi absolut
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.imageUrls.isNotEmpty) {
        _syncAndScheduleNext(initial: true);
      }
    });
  }

  void _syncAndScheduleNext({bool initial = false}) {
    if (!mounted || widget.imageUrls.isEmpty) return;

    final nowMs = ref
        .read(timeSyncServiceProvider)
        .now()
        .millisecondsSinceEpoch;
    final blockStartTimeMs = ref.read(slideStartTimeProvider);

    // Jika provider berisi waktu mulai, gunakan waktu relatif dari waktu mulai blok.
    // Jika null (misal Iqomah/Jumat), gunakan waktu absolut epoch.
    final relativeMs = blockStartTimeMs != null
        ? (nowMs - blockStartTimeMs)
        : nowMs;

    // Indeks dihitung secara presisi berdasarkan kelipatan 20.000 ms (20 detik)
    final int nextIndex = (relativeMs ~/ 20000) % widget.imageUrls.length;

    if (_currentPage != nextIndex || initial) {
      setState(() {
        _currentPage = nextIndex;
      });
    }

    // Jadwalkan eksekusi timer meledak persis di kelipatan 20.000 ms berikutnya
    int msUntilNext = 20000 - (relativeMs % 20000);
    _timer?.cancel();
    _timer = Timer(
      Duration(milliseconds: msUntilNext),
      () => _syncAndScheduleNext(),
    );
  }

  @override
  void didUpdateWidget(AppImageSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.imageUrls.length != oldWidget.imageUrls.length) {
      _syncAndScheduleNext(initial: true);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _getFullUrl(String path) {
    if (path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    if (path.startsWith('assets/')) return path;

    final baseUrl = ApiConstant.baseUrl;
    final cleanBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final cleanPath = path.startsWith('/') ? path : '/$path';

    return '$cleanBase$cleanPath';
  }

  @override
  Widget build(BuildContext context) {
    // Sinkronkan pergantian slot main phase tanpa perlu merusak widget tree
    ref.listen<int?>(slideStartTimeProvider, (previous, next) {
      if (previous != next) {
        _syncAndScheduleNext(initial: true);
      }
    });

    if (widget.imageUrls.isEmpty) {
      return Container(
        color: Colors.blueGrey.shade900,
        child: const Center(
          child: Icon(
            Icons.image_not_supported,
            color: Colors.white24,
            size: 64,
          ),
        ),
      );
    }

    final safeIndex = _currentPage % widget.imageUrls.length;
    final fullUrl = _getFullUrl(widget.imageUrls[safeIndex]);

    return Padding(
      padding: EdgeInsets.only(left: widget.leftMargin),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 1000),
        switchInCurve: Curves.easeInOut,
        switchOutCurve: Curves.easeInOut,
        layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
          return Stack(
            fit: StackFit.expand,
            alignment: Alignment.center,
            children: <Widget>[
              ...previousChildren,
              if (currentChild != null) currentChild,
            ],
          );
        },
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        child: _SliderImageItem(
          key: ValueKey('slide_${safeIndex}_$fullUrl'),
          url: fullUrl,
        ),
      ),
    );
  }
}

class _SliderImageItem extends StatelessWidget {
  final String url;
  const _SliderImageItem({super.key, required this.url});

  @override
  Widget build(BuildContext context) {
    if (!url.startsWith('http')) {
      return SizedBox.expand(
        child: Image.asset(
          url,
          fit: BoxFit.fill,
          cacheWidth: 1280,
          cacheHeight: 720,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.blueGrey.shade900,
              child: const Center(
                child: Icon(Icons.broken_image, color: Colors.white54, size: 64),
              ),
            );
          },
        ),
      );
    }

    return SizedBox.expand(
      child: CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.fill,
        memCacheWidth: 1280,
        memCacheHeight: 720,
        fadeInDuration: const Duration(milliseconds: 250),
        fadeOutDuration: const Duration(milliseconds: 100),
        errorWidget: (context, url, error) {
          return Container(
            color: Colors.blueGrey.shade900,
            child: const Center(
              child: Icon(Icons.broken_image, color: Colors.white54, size: 64),
            ),
          );
        },
      ),
    );
  }
}
