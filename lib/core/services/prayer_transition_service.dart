import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:go_router/go_router.dart';
import 'package:jws/core/constants/api_constant.dart';
import '../routes/app_router.dart';
import '../../../core/providers/selected_profil_provider.dart';
import '../../features/main/providers/my_masjid_provider.dart';
import '../time/time_sync_service.dart';
import '../providers/audio_settings_provider.dart';
import '../../features/main/models/jadwal_sholat_model.dart';
import '../../features/main/models/durasi_model.dart';

enum PrayerState {
  idle,
  alert,
  adzan,
  iqomah,
  jumat,
  finalScreen,
}

class PrayerTransitionState {
  final PrayerState status;
  final String prayerName;
  final String prayerTime;
  final int totalSeconds;
  final int remainingSeconds;

  PrayerTransitionState({
    this.status = PrayerState.idle,
    this.prayerName = '',
    this.prayerTime = '',
    this.totalSeconds = 0,
    this.remainingSeconds = 0,
  });

  PrayerTransitionState copyWith({
    PrayerState? status,
    String? prayerName,
    String? prayerTime,
    int? totalSeconds,
    int? remainingSeconds,
  }) {
    return PrayerTransitionState(
      status: status ?? this.status,
      prayerName: prayerName ?? this.prayerName,
      prayerTime: prayerTime ?? this.prayerTime,
      totalSeconds: totalSeconds ?? this.totalSeconds,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
    );
  }
}

final prayerTransitionProvider = NotifierProvider<PrayerTransitionNotifier, PrayerTransitionState>(PrayerTransitionNotifier.new);

class PrayerTransitionNotifier extends Notifier<PrayerTransitionState> {
  Timer? _timer;
  final AudioPlayer _audioPlayer = AudioPlayer();
  final AudioPlayer _adzanPlayer = AudioPlayer();
  bool _hasPlayedIqomahBeep = false;

  @override
  PrayerTransitionState build() {
    // Start timer on build
    _timer = Timer.periodic(const Duration(seconds: 1), _tick);
    
    // Listen to beep complete to start Adzan
    _audioPlayer.onPlayerComplete.listen((_) {
      if (state.status == PrayerState.adzan) {
        _playAdzanAudio(state.prayerName);
      }
    });

    ref.onDispose(() {
      _timer?.cancel();
      _audioPlayer.dispose();
      _adzanPlayer.dispose();
    });
    
    return PrayerTransitionState();
  }

  void _playSound() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/beep.mp3'));
    } catch (e) {
      debugPrint('Error playing sound: $e');
    }
  }

  void _playAdzanAudio(String prayerName) async {
    final audioSettings = ref.read(audioSettingsProvider);
    if (audioSettings.isAdzanMuted) return;

    final profil = ref.read(selectedProfilProvider);
    if (profil == null) return;
    
    final data = ref.read(myMasjidProvider(profil.id)).value;
    if (data == null || data.audioAdzan == null || !data.audioAdzan!.status) return;

    final adzanData = data.audioAdzan!;
    String? path = prayerName == 'SHUBUH' ? adzanData.adzanShubuh : adzanData.audioAdzan;

    if (path == null || path.isEmpty) return;

    final baseUrl = ApiConstant.baseUrl;
    final cleanBase = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    final fullUrl = path.startsWith('http') ? path : '$cleanBase$path';

    try {
      await _adzanPlayer.play(UrlSource(fullUrl));
    } catch (e) {
      debugPrint("Gagal memutar adzan: $e");
    }
  }

  void _tick(Timer timer) {
    if (state.status != PrayerState.idle) {
      // Sedang dalam transisi (Adzan/Iqomah/dll)
      if (state.remainingSeconds > 0) {
        // Countdown
        final newRemaining = state.remainingSeconds - 1;
        
        // Cek beep 5 detik terakhir di iqomah
        if (state.status == PrayerState.iqomah && newRemaining == 5 && !_hasPlayedIqomahBeep) {
          _hasPlayedIqomahBeep = true;
          _playSound();
        }

        state = state.copyWith(remainingSeconds: newRemaining);
      } else {
        // Waktu habis, pindah ke state berikutnya
        _adzanPlayer.stop(); // Pastikan adzan berhenti saat berpindah fase
        _nextState();
      }
    } else {
      // Idle, cek apakah sudah masuk waktu sholat
      _checkPrayerTime();
    }
  }

  void _checkPrayerTime() {
    final now = ref.read(timeSyncServiceProvider).now();
    final profil = ref.read(selectedProfilProvider);
    if (profil == null) return;
    final data = ref.read(myMasjidProvider(profil.id)).value;
    if (data == null) return;

    final todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    JadwalSholatModel? todayJadwal;
    try {
      todayJadwal = data.jadwalSholat.firstWhere((j) => j.date == todayStr);
    } catch (_) {
      return;
    }

    final isFriday = now.weekday == DateTime.friday;
    final durasi = data.durasi ?? DurasiModel();

    final times = {
      'IMSAK': todayJadwal.imsak,
      'SYURUQ': todayJadwal.terbit,
      'DHUHA': todayJadwal.dhuha,
      'SHUBUH': todayJadwal.subuh,
      'DZUHUR': todayJadwal.dzuhur,
      'ASHAR': todayJadwal.ashar,
      'MAGHRIB': todayJadwal.maghrib,
      'ISYA': todayJadwal.isya,
    };

    for (var entry in times.entries) {
      final name = entry.key;
      final timeStr = entry.value;
      if (timeStr.length != 5) continue; // Pastikan format HH:mm

      final parts = timeStr.split(':');
      final hour = int.tryParse(parts[0]) ?? 0;
      final minute = int.tryParse(parts[1]) ?? 0;

      // Titik awal waktu sholat
      DateTime phaseStart = DateTime(now.year, now.month, now.day, hour, minute, 0);
      
      // Fase 1: Alert / Adzan
      PrayerState phase1State = (name == 'IMSAK' || name == 'SYURUQ' || name == 'DHUHA') ? PrayerState.alert : PrayerState.adzan;
      int phase1Mins = _getDurationForState(phase1State, name, durasi);
      DateTime phase1End = phaseStart.add(Duration(minutes: phase1Mins));

      if (now.compareTo(phaseStart) >= 0 && now.isBefore(phase1End)) {
        // Sedang berada di Fase 1
        _jumpToState(phase1State, name, timeStr, phase1Mins * 60, phase1End.difference(now).inSeconds);
        return;
      }

      // Lanjut ke Fase 2 & 3 jika ini bukan sholat sunnah (bukan alert)
      if (phase1State == PrayerState.adzan) {
        if (name == 'DZUHUR' && isFriday) {
          // Fase Jumat (khusus dzuhur di hari jumat)
          int jumatMins = _getDurationForState(PrayerState.jumat, name, durasi);
          DateTime jumatEnd = phase1End.add(Duration(minutes: jumatMins));
          
          if (now.compareTo(phase1End) >= 0 && now.isBefore(jumatEnd)) {
             _jumpToState(PrayerState.jumat, name, timeStr, jumatMins * 60, jumatEnd.difference(now).inSeconds);
             return;
          }
        } else {
          // Fase Iqomah
          int iqomahMins = _getDurationForState(PrayerState.iqomah, name, durasi);
          DateTime iqomahEnd = phase1End.add(Duration(minutes: iqomahMins));
          
          if (now.compareTo(phase1End) >= 0 && now.isBefore(iqomahEnd)) {
             _jumpToState(PrayerState.iqomah, name, timeStr, iqomahMins * 60, iqomahEnd.difference(now).inSeconds);
             return;
          }

          // Fase Final Screen
          int finalMins = _getDurationForState(PrayerState.finalScreen, name, durasi);
          DateTime finalEnd = iqomahEnd.add(Duration(minutes: finalMins));
          
          if (now.compareTo(iqomahEnd) >= 0 && now.isBefore(finalEnd)) {
             _jumpToState(PrayerState.finalScreen, name, timeStr, finalMins * 60, finalEnd.difference(now).inSeconds);
             return;
          }
        }
      }
    }
  }

  void _jumpToState(PrayerState status, String name, String time, int totalSeconds, int remainingSeconds) {
    if (remainingSeconds <= 0) return;
    
    // Reset status bunyi beep khusus iqomah
    _hasPlayedIqomahBeep = false;
    
    // Bunyikan beep HANYA JIKA baru mulai (selisih <= 2 detik dari awal fase)
    if (totalSeconds - remainingSeconds <= 2) {
       _playSound();
    }
    
    state = PrayerTransitionState(
      status: status,
      prayerName: name,
      prayerTime: time,
      totalSeconds: totalSeconds,
      remainingSeconds: remainingSeconds,
    );
    
    _navigateToCurrentState();
  }

  void _nextState() {
    final name = state.prayerName;
    final profil = ref.read(selectedProfilProvider);
    final durasi = (profil != null) ? (ref.read(myMasjidProvider(profil.id)).value?.durasi ?? DurasiModel()) : DurasiModel();
    final now = ref.read(timeSyncServiceProvider).now();
    final isFriday = now.weekday == DateTime.friday;

    PrayerState nextStatus = PrayerState.idle;

    if (state.status == PrayerState.alert) {
      nextStatus = PrayerState.idle;
    } else if (state.status == PrayerState.adzan) {
      if (name == 'DZUHUR' && isFriday) {
        nextStatus = PrayerState.jumat;
      } else {
        nextStatus = PrayerState.iqomah;
      }
    } else if (state.status == PrayerState.iqomah) {
      nextStatus = PrayerState.finalScreen;
    } else if (state.status == PrayerState.jumat || state.status == PrayerState.finalScreen) {
      nextStatus = PrayerState.idle;
    }

    if (nextStatus == PrayerState.idle) {
      state = PrayerTransitionState(); // Reset
      _navigateToMain();
    } else {
      _hasPlayedIqomahBeep = false;
      int durationMinutes = _getDurationForState(nextStatus, name, durasi);
      state = state.copyWith(
        status: nextStatus,
        totalSeconds: durationMinutes * 60,
        remainingSeconds: durationMinutes * 60,
      );
      _navigateToCurrentState();
    }
  }

  int _getDurationForState(PrayerState status, String name, DurasiModel durasi) {
    if (status == PrayerState.alert || status == PrayerState.adzan) {
      switch (name) {
        case 'IMSAK': return durasi.adzanImsak;
        case 'SYURUQ': return durasi.adzanShuruq;
        case 'DHUHA': return durasi.adzanDhuha;
        case 'SHUBUH': return durasi.adzanShubuh;
        case 'DZUHUR': return durasi.adzanDzuhur;
        case 'ASHAR': return durasi.adzanAshar;
        case 'MAGHRIB': return durasi.adzanMaghrib;
        case 'ISYA': return durasi.adzanIsya;
      }
    } else if (status == PrayerState.iqomah) {
      switch (name) {
        case 'SHUBUH': return durasi.iqomahShubuh;
        case 'DZUHUR': return durasi.iqomahDzuhur;
        case 'ASHAR': return durasi.iqomahAshar;
        case 'MAGHRIB': return durasi.iqomahMaghrib;
        case 'ISYA': return durasi.iqomahIsya;
      }
    } else if (status == PrayerState.finalScreen) {
      switch (name) {
        case 'SHUBUH': return durasi.finalShubuh;
        case 'DZUHUR': return durasi.finalDzuhur;
        case 'ASHAR': return durasi.finalAshar;
        case 'MAGHRIB': return durasi.finalMaghrib;
        case 'ISYA': return durasi.finalIsya;
      }
    } else if (status == PrayerState.jumat) {
      return durasi.jumatSlide;
    }
    return 2; // Fallback
  }

  void _navigateToCurrentState() {
    final context = rootNavigatorKey.currentContext;
    if (context == null) return;

    switch (state.status) {
      case PrayerState.alert:
        context.goNamed('alert');
        break;
      case PrayerState.adzan:
        context.goNamed('adzan');
        break;
      case PrayerState.iqomah:
        context.goNamed('iqomah');
        break;
      case PrayerState.finalScreen:
        context.goNamed('final');
        break;
      case PrayerState.jumat:
        context.goNamed('jumat');
        break;
      default:
        _navigateToMain();
    }
  }

  void _navigateToMain() {
    final context = rootNavigatorKey.currentContext;
    if (context == null) return;
    context.go('/main');
  }
}
