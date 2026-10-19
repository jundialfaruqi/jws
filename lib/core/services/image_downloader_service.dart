import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import '../../features/main/models/my_masjid_model.dart';
import '../../features/main/models/slide_model.dart';
import '../constants/api_constant.dart';

final imageDownloaderProvider = Provider<ImageDownloaderService>((ref) {
  return ImageDownloaderService();
});

class ImageDownloaderService {
  String _getFullUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;

    final baseUrl = ApiConstant.baseUrl;
    final cleanBase = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    final cleanPath = path.startsWith('/') ? path : '/$path';

    return '$cleanBase$cleanPath';
  }

  void _addSlideUrls(SlideModel? slide, List<String> urls) {
    if (slide == null) return;
    if (slide.slide1 != null && slide.slide1!.isNotEmpty) urls.add(_getFullUrl(slide.slide1));
    if (slide.slide2 != null && slide.slide2!.isNotEmpty) urls.add(_getFullUrl(slide.slide2));
    if (slide.slide3 != null && slide.slide3!.isNotEmpty) urls.add(_getFullUrl(slide.slide3));
    if (slide.slide4 != null && slide.slide4!.isNotEmpty) urls.add(_getFullUrl(slide.slide4));
    if (slide.slide5 != null && slide.slide5!.isNotEmpty) urls.add(_getFullUrl(slide.slide5));
    if (slide.slide6 != null && slide.slide6!.isNotEmpty) urls.add(_getFullUrl(slide.slide6));
  }

  /// Secara asinkron mengunduh (pre-cache) semua gambar agar siap digunakan saat offline
  Future<void> preCacheAllImages(MyMasjidModel data) async {
    final List<String> urls = [];

    // 1. Logo
    if (data.profil.logoMasjid != null && data.profil.logoMasjid!.isNotEmpty) {
      urls.add(_getFullUrl(data.profil.logoMasjid));
    }
    if (data.profil.logoPemerintah != null && data.profil.logoPemerintah!.isNotEmpty) {
      urls.add(_getFullUrl(data.profil.logoPemerintah));
    }

    // 2. Jumbotron
    _addSlideUrls(data.jumbotronPemko, urls);
    _addSlideUrls(data.jumbotronMasjid, urls);

    // 3. Slides (Main, Iqomah, Jumat, Final)
    _addSlideUrls(data.slides, urls);
    _addSlideUrls(data.slideIqomah, urls);
    _addSlideUrls(data.slideJumat, urls);
    _addSlideUrls(data.slideFinal, urls);

    // Proses download di latar belakang dengan jeda throttling agar tidak membebani I/O TV RAM 1 GB
    for (var url in urls) {
      if (url.isNotEmpty) {
        try {
          // DefaultCacheManager akan otomatis mendownload dan menyimpannya.
          // Jika sudah ada di cache, ini akan meresolve dengan cepat.
          await DefaultCacheManager().downloadFile(url);
          debugPrint("✅ [ImageCache] Berhasil pre-cache: $url");
          // Jeda singkat antar-file agar thread I/O dan CPU TV tetap responsif
          await Future.delayed(const Duration(milliseconds: 300));
        } catch (e) {
          debugPrint("❌ [ImageCache] Gagal pre-cache: $url | Error: $e");
        }
      }
    }
  }
}
