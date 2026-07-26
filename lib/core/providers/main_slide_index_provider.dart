import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider untuk mendistribusikan index slide dari IdleScreenManager ke AppImageSlider
final mainSlideIndexProvider = Provider<int>((ref) => 0);
