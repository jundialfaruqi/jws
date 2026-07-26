import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../constants/api_constant.dart';
import '../providers/main_slide_index_provider.dart';

class AppImageSlider extends ConsumerStatefulWidget {
  final List<String> imageUrls;
  final double leftMargin;
  final bool externalSync; // Default false. Jika true, disetir oleh mainSlideIndexProvider.

  const AppImageSlider({
    super.key,
    this.imageUrls = const [],
    this.leftMargin = 0.0,
    this.externalSync = false,
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
    // Inisialisasi awal aman
    _pageController = PageController(initialPage: 0);
    
    if (widget.externalSync) {
      // Gunakan post-frame untuk mendapatkan initial index dari provider
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final initialIndex = ref.read(mainSlideIndexProvider);
          if (initialIndex < widget.imageUrls.length && initialIndex != 0) {
            setState(() {
              _currentPage = initialIndex;
            });
            if (_pageController.hasClients) {
              _pageController.jumpToPage(_currentPage);
            }
          }
        }
      });
    } else {
      // Internal timer fallback untuk screen seperti Iqomah/Jumat
      _startLocalTimer();
    }
  }

  void _startLocalTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (!mounted || widget.imageUrls.isEmpty) return;
      
      final nextIndex = (_currentPage + 1) % widget.imageUrls.length;
      setState(() {
        _currentPage = nextIndex;
      });
      
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
  void didUpdateWidget(AppImageSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.externalSync != oldWidget.externalSync) {
      if (widget.externalSync) {
        _timer?.cancel();
      } else {
        _startLocalTimer();
      }
    }
    
    if (widget.imageUrls.length != oldWidget.imageUrls.length) {
      if (_currentPage >= widget.imageUrls.length && widget.imageUrls.isNotEmpty) {
        _currentPage = widget.imageUrls.length - 1;
        if (_pageController.hasClients) {
          _pageController.jumpToPage(_currentPage);
        }
      }
    }
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

    if (widget.externalSync) {
      ref.listen<int>(mainSlideIndexProvider, (previous, next) {
        if (next != _currentPage && next < widget.imageUrls.length && mounted) {
          setState(() {
            _currentPage = next;
          });
          if (_pageController.hasClients) {
            if ((_pageController.page?.round() ?? 0) != _currentPage && 
                (_pageController.page?.round() ?? 0) != _currentPage - 1 && 
                (_pageController.page?.round() ?? 0) != _currentPage + 1) {
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
    return CachedNetworkImage(
      imageUrl: widget.url,
      fit: BoxFit.fill,
      errorWidget: (context, url, error) {
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
