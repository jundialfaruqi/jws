import 'package:flutter/material.dart';
import 'dart:async';

class AppImageSlider extends StatefulWidget {
  final List<String> imageUrls;
  final double leftMargin;

  const AppImageSlider({
    super.key,
    this.imageUrls = const [
      'https://images.unsplash.com/photo-1572889693481-42289c894e75?q=80&w=2000', // Dummy masjid 1
      'https://images.unsplash.com/photo-1564683214965-3619addd900d?q=80&w=2000', // Dummy masjid 2
      'https://images.unsplash.com/photo-1542816417-0983c9c9ad53?q=80&w=2000', // Dummy masjid 3
    ],
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

  @override
  Widget build(BuildContext context) {
    if (widget.imageUrls.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: EdgeInsets.only(left: widget.leftMargin),
      child: PageView.builder(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(), // Biarkan timer yang scroll
        itemCount: widget.imageUrls.length,
        itemBuilder: (context, index) {
          return Image.network(
            widget.imageUrls[index],
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.blueGrey.shade900,
                child: const Center(
                  child: Icon(Icons.broken_image, color: Colors.white54, size: 64),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
