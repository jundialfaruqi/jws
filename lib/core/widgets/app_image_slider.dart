import 'package:flutter/material.dart';
import 'dart:async';
import '../constants/api_constant.dart';

class AppImageSlider extends StatefulWidget {
  final List<String> imageUrls;
  final double leftMargin;

  const AppImageSlider({
    super.key,
    this.imageUrls = const [],
    this.leftMargin = 0.0,
  });

  @override
  State<AppImageSlider> createState() => _AppImageSliderState();
}

class _AppImageSliderState extends State<AppImageSlider> {
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
    _timer = Timer.periodic(const Duration(seconds: 8), (timer) {
      if (widget.imageUrls.isEmpty) return;
      
      if (_currentPage < widget.imageUrls.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }
      
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 1000),
          curve: Curves.easeInOutCubic,
        );
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
