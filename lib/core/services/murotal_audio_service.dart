import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:jws/core/constants/api_constant.dart';

import 'prayer_transition_service.dart';
import '../providers/audio_settings_provider.dart';
import '../providers/selected_profil_provider.dart';
import '../../features/main/providers/my_masjid_provider.dart';
import '../time/time_sync_service.dart';

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

  MurotalAudioService(this._ref) {
    _timer = Timer.periodic(const Duration(seconds: 1), _tick);
    
    _audioPlayer.onPlayerComplete.listen((_) {
      _isPlaying = false;
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
    // 1. Cek Setting Mute
    final audioSettings = _ref.read(audioSettingsProvider);
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
          if (diff > 0 && diff <= 60) {
            return false;
          }
        }
      }
    } catch (_) {
      // Data jadwal belum ada, fallback allow play
    }

    return true; // Semua syarat terpenuhi, Murotal boleh berputar
  }

  void _startOrResume() async {
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
      if (path == null) return; // Mencegah infinite loop kalau semua null (sudah dihandle di atas)
    }

    final baseUrl = ApiConstant.baseUrl;
    final cleanBase = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    final fullUrl = path.startsWith('http') ? path : '$cleanBase$path';

    try {
      if (_currentUrl == fullUrl) {
        // Resume if it's the same URL
        await _audioPlayer.resume();
      } else {
        // Play new URL
        _currentUrl = fullUrl;
        await _audioPlayer.play(UrlSource(fullUrl));
      }
      _isPlaying = true;
    } catch (e) {
      debugPrint("Gagal memutar murotal: $e");
    }
  }

  void _pause() async {
    if (!_isPlaying) return;
    try {
      await _audioPlayer.pause();
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
