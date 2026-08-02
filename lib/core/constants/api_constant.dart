import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstant {
  /// Base URL diambil dari file .env.
  /// Pastikan memanggil dotenv.load() di main.dart sebelum menggunakan variabel ini.
  static String get baseUrl {
    String url = dotenv.env['BASE_URL'] ?? 'http://127.0.0.1:8000/';
    return url.endsWith('/') ? url : '$url/';
  }

  /// Endpoint untuk mengambil profil masjid
  static const String profilMasjid = 'api/v2/profil-masjid';
  
  /// Endpoint untuk mengambil data halaman utama masjid (Waktu & Marquee)
  static const String myMasjid = 'api/v2/my-masjid';
}
