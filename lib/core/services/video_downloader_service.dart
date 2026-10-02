import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../constants/api_constant.dart';
import '../../features/main/models/my_masjid_model.dart';

enum VideoDownloadStatus {
  idle,
  downloading,
  success,
  error,
}

class VideoDownloadState {
  final VideoDownloadStatus status;
  final String message;
  final double progress;

  VideoDownloadState({
    this.status = VideoDownloadStatus.idle,
    this.message = '',
    this.progress = 0.0,
  });

  VideoDownloadState copyWith({
    VideoDownloadStatus? status,
    String? message,
    double? progress,
  }) {
    return VideoDownloadState(
      status: status ?? this.status,
      message: message ?? this.message,
      progress: progress ?? this.progress,
    );
  }
}

final videoDownloaderProvider =
    NotifierProvider<VideoDownloaderNotifier, VideoDownloadState>(
  VideoDownloaderNotifier.new,
);

class VideoDownloaderNotifier extends Notifier<VideoDownloadState> {
  final Dio _dio = Dio();
  Future<void>? _currentSyncTask;

  @override
  VideoDownloadState build() {
    return VideoDownloadState();
  }

  /// Memperoleh nama file yang unik dan aman dari path atau URL video
  String _getFilenameFromPath(String path) {
    try {
      final uri = Uri.parse(path);
      if (uri.pathSegments.isNotEmpty) {
        final last = uri.pathSegments.last;
        if (last.contains('.')) return last;
      }
    } catch (_) {}

    return path.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
  }

  /// Menghasilkan URL lengkap ke server jika path berupa path relatif
  String _getFullUrl(String path) {
    if (path.startsWith('http')) return path;

    final baseUrl = ApiConstant.baseUrl;
    final cleanBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final cleanPath = path.startsWith('/') ? path : '/$path';

    return '$cleanBase$cleanPath';
  }

  /// Mendapatkan direktori penyimpanan internal untuk video jumbotron
  Future<Directory> _getVideoDir() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final videoDir = Directory('${docsDir.path}/videos');
    if (!await videoDir.exists()) {
      await videoDir.create(recursive: true);
    }
    return videoDir;
  }

  /// Sinkronisasi file video jumbotron:
  /// 1. Bersihkan video lama dari memori internal jika video diganti di admin.
  /// 2. Unduh video baru ke memori internal di background.
  Future<void> syncVideo(MyMasjidModel model) async {
    if (_currentSyncTask != null) return _currentSyncTask;

    _currentSyncTask = _performSync(model);
    try {
      await _currentSyncTask;
    } finally {
      _currentSyncTask = null;
    }
  }

  Future<void> _performSync(MyMasjidModel model) async {
    try {
      final isVideoActive = model.jumbotronPemko?.isActive == true &&
          (model.jumbotronPemko?.isVideo ?? false);
      final rawVideoPath = isVideoActive ? model.jumbotronPemko?.videoFile : null;

      final videoDir = await _getVideoDir();
      final activeFilename = (rawVideoPath != null && rawVideoPath.isNotEmpty)
          ? _getFilenameFromPath(rawVideoPath)
          : null;

      // 1. PEMBERSIHAN SAMPAH (Garbage Collection):
      // Hapus file video lama atau file temp yang tidak sesuai dengan video aktif saat ini
      if (await videoDir.exists()) {
        final existingFiles = videoDir.listSync();
        for (var entity in existingFiles) {
          if (entity is File) {
            final filename = entity.uri.pathSegments.last;
            // Jika video jumbotron tidak aktif, atau file ini bukan file aktif saat ini
            if (activeFilename == null || filename != activeFilename) {
              debugPrint(
                '🗑️ [VideoDownloader] Menghapus video lama dari internal storage: $filename',
              );
              try {
                await entity.delete();
              } catch (e) {
                debugPrint('Gagal menghapus cache video: $e');
              }
            }
          }
        }
      }

      // Jika tidak ada video aktif, selesai
      if (rawVideoPath == null || rawVideoPath.isEmpty || activeFilename == null) {
        state = VideoDownloadState();
        return;
      }

      final localTargetFile = File('${videoDir.path}/$activeFilename');

      // 2. CEK APAKAH SUDAH ADA DI INTERNAL STORAGE:
      if (await localTargetFile.exists() && await localTargetFile.length() > 0) {
        debugPrint(
          '✅ [VideoDownloader] Video aktif sudah tersimpan di internal storage: $activeFilename',
        );
        state = state.copyWith(
          status: VideoDownloadStatus.success,
          message: 'Video jumbotron siap (offline)',
        );
        return;
      }

      // 3. UNDUH VIDEO BARU KE INTERNAL STORAGE:
      final fullUrl = _getFullUrl(rawVideoPath);
      final tempFile = File('${localTargetFile.path}.tmp');

      debugPrint(
        '⬇️ [VideoDownloader] Mengunduh video jumbotron baru ke internal: $fullUrl',
      );
      state = state.copyWith(
        status: VideoDownloadStatus.downloading,
        message: 'Mengunduh video jumbotron...',
        progress: 0.0,
      );

      try {
        if (await tempFile.exists()) {
          await tempFile.delete();
        }

        await _dio.download(
          fullUrl,
          tempFile.path,
          onReceiveProgress: (received, total) {
            if (total > 0) {
              final progress = received / total;
              state = state.copyWith(progress: progress);
            }
          },
        );

        // Setelah download selesai utuh tanpa error, rename dari .tmp ke target asli
        if (await tempFile.exists()) {
          await tempFile.rename(localTargetFile.path);
          debugPrint(
            '✅ [VideoDownloader] Video berhasil diunduh dan tersimpan di: ${localTargetFile.path}',
          );
          state = state.copyWith(
            status: VideoDownloadStatus.success,
            message: 'Video berhasil disimpan ke internal storage',
            progress: 1.0,
          );
        }
      } catch (e) {
        debugPrint('❌ [VideoDownloader] Gagal mengunduh video: $e');
        if (await tempFile.exists()) {
          await tempFile.delete();
        }
        state = state.copyWith(
          status: VideoDownloadStatus.error,
          message: 'Gagal mengunduh video',
        );
      }
    } catch (e) {
      debugPrint('Error pada sinkronisasi video: $e');
    }
  }

  /// Mendapatkan path file video lokal jika sudah selesai diunduh ke internal storage.
  /// Mengembalikan null jika belum diunduh (sehingga pemutar bisa fallback ke streaming jaringan).
  Future<String?> getLocalVideoPath(String rawPath) async {
    try {
      final filename = _getFilenameFromPath(rawPath);
      final videoDir = await _getVideoDir();
      final localFile = File('${videoDir.path}/$filename');

      if (await localFile.exists() && await localFile.length() > 0) {
        return localFile.path;
      }
    } catch (e) {
      debugPrint('Gagal mengecek local video path: $e');
    }
    return null;
  }
}
