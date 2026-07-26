import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/api_constant.dart';
import '../time/time_sync_service.dart';

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
  late final PageController _pageController;
  int _currentPage = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _startTimer();
  }

  @override
  void didUpdateWidget(AppImageSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.imageUrls.length != oldWidget.imageUrls.length) {
      if (_currentPage >= widget.imageUrls.length && widget.imageUrls.isNotEmpty) {
        _currentPage = widget.imageUrls.length - 1;
        if (_pageController.hasClients) {
          _pageController.jumpToPage(_currentPage);
        }
      }
    }
  }

  void _startTimer() {
    _timer?.cancel();
    // Cek kalkulasi setiap 1 detik
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || widget.imageUrls.isEmpty) return;

      final now = ref.read(timeSyncServiceProvider).now();
      final int currentEpoch = now.millisecondsSinceEpoch ~/ 1000;
      final int slideCount = widget.imageUrls.length;
      
      // Hitung index yang seharusnya tayang berdasarkan waktu absolut (10 detik per slide)
      final int cyclePosition = currentEpoch % (slideCount * 10);
      final int targetIndex = cyclePosition ~/ 10;

      if (targetIndex != _currentPage) {
        setState(() {
          _currentPage = targetIndex;
        });
        
        if (_pageController.hasClients) {
          // Lompat langsung jika perbedaan jaraknya jauh (misal saat inisialisasi)
          if ((_pageController.page?.round() ?? 0) != _currentPage && (_pageController.page?.round() ?? 0) != _currentPage - 1 && (_pageController.page?.round() ?? 0) != _currentPage + 1) {
            _pageController.jumpToPage(_currentPage);
          } else {
            _pageController.animateToPage(
              _currentPage,
              duration: const Duration(milliseconds: 1000),
              curve: Curves.easeInOutCubic,
            );
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  String _getFullUrl(String path) {
    if (path.isEmpty) return '';
    if (path.startsWith('http')) return path;

    final baseUrl = ApiConstant.baseUrl;
    final cleanBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final cleanPath = path.startsWith('/') ? path : '/$path';

    return '$cleanBase$cleanPath';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.imageUrls.isEmpty) {
      // Tampilkan default/dummy atau biarkan kosong jika benar-benar tak ada slide
      return Container(
        color: Colors.blueGrey.shade900,
        child: const Center(
          child: Icon(Icons.image_not_supported, color: Colors.white24, size: 64),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.only(left: widget.leftMargin),
      child: PageView.builder(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(), // Biarkan timer yang scroll
        itemCount: widget.imageUrls.length,
        itemBuilder: (context, index) {
          final fullUrl = _getFullUrl(widget.imageUrls[index]);
          return _KeepAliveImage(url: fullUrl);
        },
      ),
    );
  }
}

class _KeepAliveImage extends StatefulWidget {
  final String url;
  const _KeepAliveImage({required this.url});

  @override
  State<_KeepAliveImage> createState() => _KeepAliveImageState();
}

class _KeepAliveImageState extends State<_KeepAliveImage> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // Wajib dipanggil untuk AutomaticKeepAliveClientMixin
    return Image.network(
      widget.url,
      fit: BoxFit.fill,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: Colors.blueGrey.shade900,
          child: const Center(
            child: Icon(Icons.broken_image, color: Colors.white54, size: 64),
          ),
        );
      },
    );
  }
}
