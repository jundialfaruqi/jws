import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audioplayers/audioplayers.dart';

import 'prayer_transition_service.dart';
import '../providers/audio_settings_provider.dart';
import '../providers/selected_profil_provider.dart';
import '../../features/main/providers/my_masjid_provider.dart';
import '../../features/main/providers/video_playback_provider.dart';
import '../time/time_sync_service.dart';
import 'audio_downloader_service.dart';

final murotalAudioServiceProvider = Provider<MurotalAudioService>((ref) {
  final service = MurotalAudioService(ref);
  ref.onDispose(() => service.dispose());
  return service;
});

class MurotalAudioService {
  final Ref _ref;
  final AudioPlayer _audioPlayer = AudioPlayer();
  Timer? _timer;
  
  int _currentSlot = 1;
  bool _isPlaying = false;
  String? _currentUrl;

  DateTime? _lastPlayTime;

  MurotalAudioService(this._ref) {
    _timer = Timer.periodic(const Duration(seconds: 1), _tick);
    
    _audioPlayer.onPlayerComplete.listen((_) async {
      _isPlaying = false;
      
      // Jeda Keselamatan (Circuit Breaker):
      // Jika lagu baru diputar lalu mati dalam waktu < 2 detik, artinya file rusak.
      // Kita beri jeda 10 detik agar tidak terjadi perulangan instan ratusan kali per detik.
      if (_lastPlayTime != null) {
        final diff = DateTime.now().difference(_lastPlayTime!).inSeconds;
        if (diff < 2) {
          debugPrint("⚠️ [Murotal] File kemungkinan rusak, menunda 10 detik...");
          await Future.delayed(const Duration(seconds: 10));
        }
      }

      _moveToNextSlotAndPlay();
    });
  }

  void dispose() {
    _timer?.cancel();
    _audioPlayer.dispose();
  }

  void _tick(Timer timer) {
    final shouldPlay = _checkShouldPlay();
    
    if (shouldPlay && !_isPlaying) {
      _startOrResume();
    } else if (!shouldPlay && _isPlaying) {
      _pause();
    }
  }

  bool _checkShouldPlay() {
    // 0. Cek Video Jumbotron Bersuara (Murottal wajib jeda jika video punya audio)
    final isVideoAudioPlaying = _ref.read(isVideoPlayingWithAudioProvider);
    if (isVideoAudioPlaying) return false;

    // 1. Cek Setting Mute
    final audioSettings = _ref.read(audioSettingsProvider);
    if (audioSettings.isLoading) return false;
    if (audioSettings.isMurotalMuted) return false;

    // 2. Cek Transisi (Hanya main di Idle)
    final transitionState = _ref.read(prayerTransitionProvider);
    if (transitionState.status != PrayerState.idle) return false;

    // 3. Cek Profil dan Data Masjid
    final profil = _ref.read(selectedProfilProvider);
    if (profil == null) return false;
    
    final data = _ref.read(myMasjidProvider(profil.id)).value;
    if (data == null) return false;

    // 4. Cek Murotal Data & Status
    final murotal = data.audioMurotal;
    if (murotal == null || !murotal.status) return false;

    // 5. Cek apakah ada audio yang tersedia di setidaknya 1 slot
    if (murotal.audio1 == null && murotal.audio2 == null && murotal.audio3 == null) {
      return false;
    }

    // 6. Cek Waktu (Matikan 1 Menit sebelum waktu sholat apapun)
    final now = _ref.read(timeSyncServiceProvider).now();
    final todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    
    try {
      final todayJadwal = data.jadwalSholat.firstWhere((j) => j.date == todayStr);
      final times = [
        todayJadwal.imsak, todayJadwal.terbit, todayJadwal.dhuha,
        todayJadwal.subuh, todayJadwal.dzuhur, todayJadwal.ashar,
        todayJadwal.maghrib, todayJadwal.isya
      ];

      for (var timeStr in times) {
        if (timeStr.length == 5) {
          final parts = timeStr.split(':');
          final hour = int.tryParse(parts[0]) ?? 0;
          final minute = int.tryParse(parts[1]) ?? 0;
          final prayerTime = DateTime(now.year, now.month, now.day, hour, minute, 0);
          
          final diff = prayerTime.difference(now).inSeconds;
          // Jika waktu sekarang berada dalam range 0 hingga 60 detik sebelum waktu sholat
          // (Termasuk tepat pada detik 0 agar tidak terjadi kebocoran suara karena race condition)
          if (diff >= 0 && diff <= 60) {
            return false;
          }
        }
      }
    } catch (_) {
      // Data jadwal belum ada, fallback allow play
    }

    return true; // Semua syarat terpenuhi, Murotal boleh berputar
  }

  bool _isStarting = false;

  void _startOrResume() async {
    if (_isStarting) return; // Cegah pemanggilan berulang jika sebelumnya masih loading/hang
    _isStarting = true;

    try {
      final profil = _ref.read(selectedProfilProvider);
      if (profil == null) return;
      final data = _ref.read(myMasjidProvider(profil.id)).value;
      if (data == null || data.audioMurotal == null) return;

      final murotal = data.audioMurotal!;
      
      // Coba ambil url dari slot sekarang, kalau null pindah ke next
      String? path = _getPathForSlot(_currentSlot, murotal);
      if (path == null) {
        _moveToNextSlot(murotal);
        path = _getPathForSlot(_currentSlot, murotal);
        if (path == null) return; // Mencegah infinite loop kalau semua null
      }

      // 1. Cek File Lokal
      final downloader = _ref.read(audioDownloaderProvider.notifier);
      String? localPath = await downloader.getLocalAudioPath(path);

      if (localPath == null) {
        // 2. Jika belum ada, tunggu sampai proses download selesai
        debugPrint("⏳ [Murotal] File belum tersedia, menunggu download selesai...");
        await downloader.waitForDownload();
        
        // 3. Cek ulang setelah download selesai
        localPath = await downloader.getLocalAudioPath(path);
        if (localPath == null) {
           debugPrint("❌ [Murotal] Gagal memutar, file masih tidak ditemukan setelah download.");
           return; 
        }
      }

      // 4. Mainkan dari Lokal (100% Offline)
      final source = DeviceFileSource(localPath);
      final trackId = 'local_$localPath';
      debugPrint("🎵 [Murotal] Memutar dari memori lokal: $localPath");

      if (_currentUrl == trackId) {
        // Resume if it's the same track
        await _audioPlayer.resume().timeout(const Duration(seconds: 5));
      } else {
        // Play new track
        _currentUrl = trackId;
        await _audioPlayer.play(source).timeout(const Duration(seconds: 5));
      }
      
      _lastPlayTime = DateTime.now();
      _isPlaying = true;
    } catch (e) {
      debugPrint("Gagal memutar murotal: $e");
      // Reset _currentUrl agar next tick mau mencoba play ulang dari awal
      _currentUrl = null;
    } finally {
      _isStarting = false;
    }
  }

  void _pause() async {
    if (!_isPlaying) return;
    try {
      await _audioPlayer.pause().timeout(const Duration(seconds: 3));
      _isPlaying = false;
    } catch (e) {
      debugPrint("Gagal pause murotal: $e");
    }
  }

  void _moveToNextSlotAndPlay() {
    final profil = _ref.read(selectedProfilProvider);
    if (profil == null) return;
    final data = _ref.read(myMasjidProvider(profil.id)).value;
    if (data == null || data.audioMurotal == null) return;

    _moveToNextSlot(data.audioMurotal!);
    _currentUrl = null; // Memaksa untuk load url slot baru
    // startOrResume akan dipanggil oleh timer _tick otomatis
  }

  void _moveToNextSlot(dynamic murotal) {
    int attempts = 0;
    while (attempts < 3) {
      _currentSlot++;
      if (_currentSlot > 3) _currentSlot = 1;
      
      if (_getPathForSlot(_currentSlot, murotal) != null) {
        break;
      }
      attempts++;
    }
  }

  String? _getPathForSlot(int slot, dynamic murotal) {
    switch (slot) {
      case 1: return murotal.audio1;
      case 2: return murotal.audio2;
      case 3: return murotal.audio3;
      default: return null;
    }
  }
}
