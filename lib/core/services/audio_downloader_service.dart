import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import '../constants/api_constant.dart';
import '../../features/main/models/my_masjid_model.dart';

enum AudioDownloadStatus {
  idle,
  downloading,
  success,
  error
}

class AudioDownloadState {
  final AudioDownloadStatus status;
  final String message;

  AudioDownloadState({
    this.status = AudioDownloadStatus.idle,
    this.message = '',
  });

  AudioDownloadState copyWith({
    AudioDownloadStatus? status,
    String? message,
  }) {
    return AudioDownloadState(
      status: status ?? this.status,
      message: message ?? this.message,
    );
  }
}

final audioDownloaderProvider = NotifierProvider<AudioDownloaderNotifier, AudioDownloadState>(AudioDownloaderNotifier.new);

class AudioDownloaderNotifier extends Notifier<AudioDownloadState> {
  final Dio _dio = Dio();
  Future<void>? _currentSyncTask;

  @override
  AudioDownloadState build() {
    return AudioDownloadState();
  }

  /// Menunggu jika saat ini sedang ada proses download yang berjalan
  Future<void> waitForDownload() async {
    if (_currentSyncTask != null) {
      await _currentSyncTask;
    }
  }

  /// Sinkronisasi audio. Memastikan file lokal sinkron dengan data server.
  Future<void> syncAudios(MyMasjidModel model) async {
    if (_currentSyncTask != null) return _currentSyncTask;

    _currentSyncTask = _performSync(model);
    await _currentSyncTask;
    _currentSyncTask = null;
  }

  Future<void> _performSync(MyMasjidModel model) async {
    try {
      final List<String> requiredPaths = [];

      // Ambil semua path Adzan
      if (model.audioAdzan != null) {
        if (model.audioAdzan!.audioAdzan != null) requiredPaths.add(model.audioAdzan!.audioAdzan!);
        if (model.audioAdzan!.adzanShubuh != null) requiredPaths.add(model.audioAdzan!.adzanShubuh!);
      }

      // Ambil semua path Murotal
      if (model.audioMurotal != null) {
        if (model.audioMurotal!.audio1 != null) requiredPaths.add(model.audioMurotal!.audio1!);
        if (model.audioMurotal!.audio2 != null) requiredPaths.add(model.audioMurotal!.audio2!);
        if (model.audioMurotal!.audio3 != null) requiredPaths.add(model.audioMurotal!.audio3!);
      }

      final List<String> requiredFilenames = requiredPaths.map(_getFilenameFromPath).toList();

      final dir = await getApplicationDocumentsDirectory();
      final audioDir = Directory('${dir.path}/audios');
      if (!await audioDir.exists()) {
        await audioDir.create(recursive: true);
      }

      // 1. Garbage Collection (Hapus file lama yang tidak dipakai lagi)
      final files = audioDir.listSync();
      for (var file in files) {
        if (file is File && file.path.endsWith('.mp3')) {
          final filename = file.uri.pathSegments.last;
          if (!requiredFilenames.contains(filename)) {
            debugPrint("🗑️ [AudioDownloader] Menghapus file audio lama: $filename");
            try {
              await file.delete();
            } catch (e) {
              debugPrint("Gagal menghapus file: $e");
            }
          }
        }
      }

      // Cek apakah ada file yang perlu diunduh
      bool needsDownload = false;
      for (int i = 0; i < requiredPaths.length; i++) {
        final filename = requiredFilenames[i];
        final localFile = File('${audioDir.path}/$filename');
        if (!await localFile.exists()) {
          needsDownload = true;
          break;
        }
      }

      if (needsDownload) {
        state = state.copyWith(status: AudioDownloadStatus.downloading, message: 'Audio sedang didownload...');
      } else {
        return; // Tidak ada yang perlu diunduh
      }

      // 2. Download file baru jika belum ada
      final baseUrl = ApiConstant.baseUrl;
      final cleanBase = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
      bool hasError = false;

      for (int i = 0; i < requiredPaths.length; i++) {
        final serverPath = requiredPaths[i];
        final filename = requiredFilenames[i];
        final localFile = File('${audioDir.path}/$filename');

        if (!await localFile.exists()) {
          final fullUrl = serverPath.startsWith('http') ? serverPath : '$cleanBase$serverPath';
          debugPrint("⬇️ [AudioDownloader] Mengunduh file baru: $filename");
          try {
            await _dio.download(fullUrl, localFile.path);
            debugPrint("✅ [AudioDownloader] Sukses mengunduh: $filename");
          } catch (e) {
            debugPrint("❌ [AudioDownloader] Gagal mengunduh $filename: $e");
            hasError = true;
            if (await localFile.exists()) {
              await localFile.delete();
            }
          }
        }
      }

      if (hasError) {
        state = state.copyWith(status: AudioDownloadStatus.error, message: 'Gagal mendownload beberapa audio');
        await Future.delayed(const Duration(seconds: 3));
        state = state.copyWith(status: AudioDownloadStatus.idle);
      } else {
        state = state.copyWith(status: AudioDownloadStatus.success, message: 'Download audio selesai');
        await Future.delayed(const Duration(seconds: 3));
        state = state.copyWith(status: AudioDownloadStatus.idle);
      }

    } catch (e) {
      debugPrint("Error saat sinkronisasi audio: $e");
      state = state.copyWith(status: AudioDownloadStatus.error, message: 'Terjadi kesalahan sistem');
      await Future.delayed(const Duration(seconds: 3));
      state = state.copyWith(status: AudioDownloadStatus.idle);
    }
  }

  /// Mendapatkan absolute path lokal jika file sudah terdownload, return null jika belum
  Future<String?> getLocalAudioPath(String serverPath) async {
    try {
      final filename = _getFilenameFromPath(serverPath);
      final dir = await getApplicationDocumentsDirectory();
      final localFile = File('${dir.path}/audios/$filename');
      
      if (await localFile.exists()) {
        return localFile.path;
      }
    } catch (e) {
      debugPrint("Gagal mengecek local path: $e");
    }
    return null;
  }

  String _getFilenameFromPath(String path) {
    final segments = Uri.parse(path).pathSegments;
    if (segments.isNotEmpty) {
      return segments.last;
    }
    return path.replaceAll('/', '_').replaceAll(':', '_');
  }
}
