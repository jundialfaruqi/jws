import 'package:dio/dio.dart';

class ErrorHandler {
  static String getErrorMessage(Object e) {
    if (e is DioException) {
      switch (e.type) {
        case DioExceptionType.cancel:
          return "Permintaan ke server dibatalkan.";
        case DioExceptionType.connectionTimeout:
          return "Koneksi lambat atau terputus. Silakan periksa jaringan internet Anda.";
        case DioExceptionType.receiveTimeout:
          return "Server terlalu lama merespons. Silakan coba lagi nanti.";
        case DioExceptionType.sendTimeout:
          return "Gagal mengirim data. Silakan periksa koneksi internet Anda.";
        case DioExceptionType.connectionError:
          return "Tidak ada koneksi internet atau server sedang offline.";
        case DioExceptionType.badCertificate:
          return "Koneksi diblokir karena sertifikat keamanan server tidak valid.";
        case DioExceptionType.badResponse:
          final statusCode = e.response?.statusCode;
          if (statusCode == 401) return "Sesi Anda telah habis. Silakan muat ulang.";
          if (statusCode == 403) return "Anda tidak memiliki akses.";
          if (statusCode == 404) return "Data tidak ditemukan di server.";
          if (statusCode == 500) return "Terjadi gangguan sistem pada server pusat.";
          if (statusCode == 502 || statusCode == 503) return "Layanan server sedang tidak tersedia (Bad Gateway/Maintenance).";
          return "Terjadi kesalahan respons dari server (Kode: $statusCode).";
        case DioExceptionType.unknown:
        default:
          return "Terjadi kesalahan sistem yang tidak diketahui.";
      }
    }
    
    // Tangani exception standar
    final message = e.toString();
    if (message.startsWith('Exception: ')) {
      return message.substring(11);
    }
    return message;
  }
}
