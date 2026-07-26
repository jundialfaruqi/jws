import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:go_router/go_router.dart';
import '../routes/app_router.dart';
import '../../../core/providers/selected_profil_provider.dart';
import '../../features/main/providers/my_masjid_provider.dart';
import '../time/time_sync_service.dart';
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
  bool _hasPlayedIqomahBeep = false;

  @override
  PrayerTransitionState build() {
    // Start timer on build
    _timer = Timer.periodic(const Duration(seconds: 1), _tick);
    
    ref.onDispose(() {
      _timer?.cancel();
      _audioPlayer.dispose();
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
    final data = ref.read(myMasjidProvider(profil.slug)).value;
    if (data == null) return;

    final todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    JadwalSholatModel? todayJadwal;
    try {
      todayJadwal = data.jadwalSholat.firstWhere((j) => j.date == todayStr);
    } catch (_) {
      return;
    }

    final currentHm = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
    // Trigger hanya di detik 0 agar tidak berulang
    if (now.second != 0) return;

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
      if (entry.value == currentHm) {
        // Masuk waktu!
        _startTransition(entry.key, entry.value, data.durasi ?? DurasiModel(), now.weekday == DateTime.friday);
        break;
      }
    }
  }

  void _startTransition(String name, String time, DurasiModel durasi, bool isFriday) {
    _playSound();
    
    // Tentukan status awal
    PrayerState initialStatus = PrayerState.adzan;
    if (name == 'IMSAK' || name == 'SYURUQ' || name == 'DHUHA') {
      initialStatus = PrayerState.alert;
    }
    
    int durationMinutes = _getDurationForState(initialStatus, name, durasi);
    
    state = PrayerTransitionState(
      status: initialStatus,
      prayerName: name,
      prayerTime: time,
      totalSeconds: durationMinutes * 60,
      remainingSeconds: durationMinutes * 60,
    );
    
    _navigateToCurrentState();
  }

  void _nextState() {
    final name = state.prayerName;
    final profil = ref.read(selectedProfilProvider);
    final durasi = (profil != null) ? (ref.read(myMasjidProvider(profil.slug)).value?.durasi ?? DurasiModel()) : DurasiModel();
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
