import '../../../core/providers/slide_start_time_provider.dart';

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/selected_profil_provider.dart';
import '../../../core/providers/connectivity_provider.dart';
import '../../../core/widgets/app_loading_spinner.dart';
import '../providers/my_masjid_provider.dart';
import '../providers/video_playback_provider.dart';
import '../../../core/widgets/tv/tv_button.dart';
import '../screens/jumbotron_masjid_screen.dart';
import '../screens/jumbotron_pemko_screen.dart';
import 'main_content_widget.dart';

class IdleScreenManager extends ConsumerStatefulWidget {
  const IdleScreenManager({super.key});

  @override
  ConsumerState<IdleScreenManager> createState() => _IdleScreenManagerState();
}

class _IdleScreenManagerState extends ConsumerState<IdleScreenManager> {
  Timer? _phaseTimer;
  Timer? _videoWatchdogTimer;
  final FocusNode _retryFocusNode = FocusNode();
  bool _hasRequestedFocusForRetry = false;

  bool _isInMainPhase = true;
  // Index item jumbotron yang akan ditampilkan BERIKUTNYA (saat masuk dari main).
  int _jumbotronStepIndex = 0;
  int _activeBlockStartMs = 0;
  int _currentMainDuration = 30;
  List<Map<String, dynamic>> _jumbotronItems = [];
  bool _pendingItemsUpdate = false;
  List<Map<String, dynamic>>? _pendingItems;

  @override
  void dispose() {
    _phaseTimer?.cancel();
    _videoWatchdogTimer?.cancel();
    _retryFocusNode.dispose();
    ref.read(isVideoPlayingWithAudioProvider.notifier).setPlaying(false);
    super.dispose();
  }

  void _updateVideoAudioState() {
    if (!mounted) return;
    if (_isInMainPhase || _jumbotronItems.isEmpty) {
      ref.read(isVideoPlayingWithAudioProvider.notifier).setPlaying(false);
      return;
    }
    final item = _jumbotronItems[_jumbotronStepIndex % _jumbotronItems.length];
    final isVideoWithAudio = item['type'] == 'pemko_video' && (item['hasAudio'] == true);
    ref.read(isVideoPlayingWithAudioProvider.notifier).setPlaying(isVideoWithAudio);
  }

  /// Masuk ke fase jumbotron untuk menampilkan item di [_jumbotronStepIndex].
  /// Hanya menampilkan SATU item, setelah selesai kembali ke main.
  void _switchToJumbotron() {
    _phaseTimer?.cancel();
    _phaseTimer = null;
    _videoWatchdogTimer?.cancel();
    _videoWatchdogTimer = null;

    if (!mounted || _jumbotronItems.isEmpty) {
      _jumbotronStepIndex = 0;
      return;
    }

    _isInMainPhase = false;
    _activeBlockStartMs = DateTime.now().millisecondsSinceEpoch;
    _updateVideoAudioState();
    _showCurrentJumbotronItem();
  }

  void _setTimerForCurrentItem() {
    if (!mounted || _jumbotronItems.isEmpty) return;

    _activeBlockStartMs = DateTime.now().millisecondsSinceEpoch;
    final currentStep = _jumbotronStepIndex;
    final item = _jumbotronItems[_jumbotronStepIndex % _jumbotronItems.length];

    if (item['type'] == 'pemko_video') {
      final durationSec = (item['duration'] as int?) ?? 30;
      final timeoutSec = durationSec > 0 ? durationSec + 15 : 180;
      _videoWatchdogTimer = Timer(Duration(seconds: timeoutSec), () {
        debugPrint(
          '[IdleScreenManager] Safety watchdog fired for video ($timeoutSec s), advancing to next jumbotron item.',
        );
        _advanceJumbotron(fromStepIndex: currentStep);
      });
    } else {
      // Gambar statis (pemko_image atau masjid_image): tampil 20 detik
      final durationSec = (item['duration'] as int?) ?? 20;
      _phaseTimer = Timer(Duration(seconds: durationSec), () {
        if (mounted) _advanceJumbotron(fromStepIndex: currentStep);
      });
    }
  }

  void _showCurrentJumbotronItem() {
    _phaseTimer?.cancel();
    _phaseTimer = null;
    _videoWatchdogTimer?.cancel();
    _videoWatchdogTimer = null;

    if (!mounted || _jumbotronItems.isEmpty) return;

    _setTimerForCurrentItem();
    setState(() {});
  }

  /// Dipanggil saat item jumbotron saat ini selesai ditampilkan.
  /// Increment index ke item berikutnya, lalu kembali ke fase main.
  /// Fase main yang akan memanggil [_switchToJumbotron] kembali setelah durasinya habis.
  void _advanceJumbotron({int? fromStepIndex}) {
    if (!mounted) return;
    if (fromStepIndex != null && fromStepIndex != _jumbotronStepIndex) {
      debugPrint(
        '[IdleScreenManager] Ignoring stale advance from step $fromStepIndex (current is $_jumbotronStepIndex)',
      );
      return;
    }

    _phaseTimer?.cancel();
    _phaseTimer = null;
    _videoWatchdogTimer?.cancel();
    _videoWatchdogTimer = null;

    if (_jumbotronItems.isEmpty) {
      _jumbotronStepIndex = 0;
      _switchToMain();
      return;
    }

    // Maju ke item berikutnya. Jika sudah habis, wrap ke awal.
    _jumbotronStepIndex = (_jumbotronStepIndex + 1) % _jumbotronItems.length;

    // Setiap item jumbotron SELALU diselingi fase main.
    _switchToMain();
  }

  void _switchToMain() {
    _phaseTimer?.cancel();
    _phaseTimer = null;
    _videoWatchdogTimer?.cancel();
    _videoWatchdogTimer = null;

    _isInMainPhase = true;
    _activeBlockStartMs = DateTime.now().millisecondsSinceEpoch;
    _updateVideoAudioState();
    setState(() {});

    if (_jumbotronItems.isNotEmpty) {
      // Simpan step yang akan ditampilkan agar timer tidak stale.
      final nextStep = _jumbotronStepIndex;
      _phaseTimer = Timer(Duration(seconds: _currentMainDuration), () {
        if (mounted && _jumbotronStepIndex == nextStep) {
          _switchToJumbotron();
        } else if (mounted && _jumbotronStepIndex != nextStep) {
          // Step berubah karena update data; tetap jalankan switchToJumbotron
          // dengan step terkini yang sudah di-update oleh _handleItemsUpdated.
          debugPrint(
            '[IdleScreenManager] Main timer fired but step changed '
            '($nextStep -> $_jumbotronStepIndex), still switching to jumbotron.',
          );
          _switchToJumbotron();
        }
      });
    }
  }

  List<Map<String, dynamic>> _buildJumbotronItems(
    dynamic data,
    Map<String, int> detectedDurations,
  ) {
    final List<Map<String, dynamic>> items = [];

    // 1. Jumbotron Video Global
    if (data.jumbotronPemko?.isActive == true) {
      final videos = data.jumbotronPemko!.videos;
      if (videos.isNotEmpty) {
        for (final v in videos) {
          int videoDuration = v.duration;
          if (videoDuration <= 0 && detectedDurations.containsKey(v.videoUrl)) {
            videoDuration = detectedDurations[v.videoUrl]!;
          }
          if (videoDuration <= 0) {
            videoDuration = 30;
          }
          items.add({
            'type': 'pemko_video',
            'videoUrl': v.videoUrl,
            'hasAudio': v.hasAudio,
            'duration': videoDuration,
            'id': v.id,
          });
        }
      } else if (data.jumbotronPemko!.isVideo &&
          data.jumbotronPemko!.videoFile != null &&
          data.jumbotronPemko!.videoFile!.isNotEmpty) {
        final vUrl = data.jumbotronPemko!.videoFile!;
        int videoDuration = data.jumbotronPemko!.videoDuration;
        if (videoDuration <= 0 && detectedDurations.containsKey(vUrl)) {
          videoDuration = detectedDurations[vUrl]!;
        }
        if (videoDuration <= 0) {
          videoDuration = 30;
        }
        items.add({
          'type': 'pemko_video',
          'videoUrl': vUrl,
          'hasAudio': data.jumbotronPemko!.hasAudio,
          'duration': videoDuration,
          'id': data.jumbotronPemko!.id,
        });
      }

      // 2. Jumbotron Gambar Global
      final pemkoImages = data.jumbotronPemko!.validSlides;
      for (final img in pemkoImages) {
        items.add({
          'type': 'pemko_image',
          'slide': img,
          'duration': 20,
        });
      }
    }

    // 3. Jumbotron Gambar Masjid
    if (data.jumbotronMasjid?.isActive == true) {
      final masjidImages = data.jumbotronMasjid!.validSlides;
      for (final img in masjidImages) {
        items.add({
          'type': 'masjid_image',
          'slide': img,
          'duration': 20,
        });
      }
    }

    return items;
  }

  bool _itemsChanged(
    List<Map<String, dynamic>> a,
    List<Map<String, dynamic>> b,
  ) {
    if (a.length != b.length) return true;
    for (int i = 0; i < a.length; i++) {
      if (a[i]['type'] != b[i]['type']) return true;
      if (a[i]['videoUrl'] != b[i]['videoUrl']) return true;
      if (a[i]['slide'] != b[i]['slide']) return true;
      if (a[i]['hasAudio'] != b[i]['hasAudio']) return true;
      if (a[i]['duration'] != b[i]['duration']) return true;
    }
    return false;
  }

  void _handleItemsUpdated(List<Map<String, dynamic>> newItems) {
    final oldItems = _jumbotronItems;
    _jumbotronItems = newItems;

    if (newItems.isEmpty) {
      // Batalkan timer phase saat ini dan kembali ke main.
      _phaseTimer?.cancel();
      _phaseTimer = null;
      _videoWatchdogTimer?.cancel();
      _videoWatchdogTimer = null;
      _jumbotronStepIndex = 0;
      if (!_isInMainPhase) {
        _switchToMain();
      }
      return;
    }

    if (_isInMainPhase) {
      // Di fase main, _jumbotronStepIndex adalah "next item" yang akan ditampilkan.
      // Pastikan index masih valid dengan list baru. Jika tidak, wrap ke 0.
      if (_jumbotronStepIndex >= newItems.length) {
        _jumbotronStepIndex = 0;
      }
      _updateVideoAudioState();
      return;
    }

    // Sedang berada di fase Jumbotron (menampilkan satu item):
    // Cek apakah item yang saat ini sedang tayang masih ada dalam list baru.
    if (oldItems.isNotEmpty && _jumbotronStepIndex < oldItems.length) {
      final currentOldItem = oldItems[_jumbotronStepIndex];
      final newIndex = newItems.indexWhere((it) =>
          it['type'] == currentOldItem['type'] &&
          ((it['videoUrl'] != null && it['videoUrl'] == currentOldItem['videoUrl']) ||
           (it['slide'] != null && it['slide'] == currentOldItem['slide'])));

      if (newIndex != -1) {
        // Item masih ada di list baru. Pertahankan item yang sedang tayang.
        // Jika posisi index bergeser (misal item baru ditambahkan di depan list),
        // restart timer agar _advanceJumbotron tidak mengabaikan callback stale.
        final oldIndex = _jumbotronStepIndex;
        _jumbotronStepIndex = newIndex;
        _updateVideoAudioState();

        if (newIndex != oldIndex) {
          _phaseTimer?.cancel();
          _phaseTimer = null;
          _videoWatchdogTimer?.cancel();
          _videoWatchdogTimer = null;
          _setTimerForCurrentItem();
        }
        return;
      }
    }

    // Item yang saat ini ditampilkan sudah tidak ada di list baru
    // (misal item dihapus/dinonaktifkan). Hentikan jumbotron, kembali ke main
    // dengan item pertama dari list baru.
    _phaseTimer?.cancel();
    _phaseTimer = null;
    _videoWatchdogTimer?.cancel();
    _videoWatchdogTimer = null;

    _jumbotronStepIndex = 0;
    _switchToMain();
  }

  @override
  Widget build(BuildContext context) {
    final profil = ref.watch(selectedProfilProvider);
    if (profil == null) {
      return const Expanded(
        child: Center(child: Text('Profil tidak ditemukan')),
      );
    }

    final myMasjidAsync = ref.watch(myMasjidProvider(profil.id));
    final detectedDurations = ref.read(detectedVideoDurationProvider);

    // Dengarkan perubahan jaringan secara diam-diam.
    // Jika awalnya putus (false) lalu tersambung lagi (true), otomatis refresh data utama jika sedang error.
    ref.listen<AsyncValue<bool>>(isConnectedProvider, (previous, next) {
      if (previous?.value == false && next.value == true) {
        ref.invalidate(myMasjidProvider(profil.id));
      }
    });

    return myMasjidAsync.when(
      loading: () => const Expanded(
        child: Center(child: AppLoadingSpinner(message: 'Memuat data...')),
      ),
      error: (e, s) {
        if (myMasjidAsync.isLoading) {
          return const Expanded(
            child: Center(
              child: AppLoadingSpinner(
                message: 'Mencoba menghubungkan kembali...',
              ),
            ),
          );
        }

        if (!_hasRequestedFocusForRetry) {
          _hasRequestedFocusForRetry = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_retryFocusNode.canRequestFocus) {
              _retryFocusNode.requestFocus();
            }
          });
        }

        return Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  style: TextStyle(fontSize: 30),
                  'Gagal memuat data, periksa koneksi atau coba beberapa saat lagi',
                ),
                const SizedBox(height: 16),
                TvButton(
                  focusNode: _retryFocusNode,
                  onPressed: () {
                    _hasRequestedFocusForRetry = false;
                    ref.invalidate(myMasjidProvider(profil.id));
                  },
                  icon: Icons.refresh,
                  label: 'Coba lagi',
                  fontSize: 24,
                ),
              ],
            ),
          ),
        );
      },
      data: (data) {
        final mainSlides = data.slides?.validSlides ?? [];
        final int mainDuration =
            mainSlides.isNotEmpty ? mainSlides.length * 20 : 30;
        _currentMainDuration = mainDuration;

        final newItems = _buildJumbotronItems(data, detectedDurations);
        if (_itemsChanged(_jumbotronItems, newItems)) {
          _pendingItems = newItems;
          if (!_pendingItemsUpdate) {
            _pendingItemsUpdate = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && _pendingItems != null) {
                final items = _pendingItems!;
                _pendingItems = null;
                _pendingItemsUpdate = false;
                _handleItemsUpdated(items);
              } else {
                _pendingItemsUpdate = false;
              }
            });
          }
        }

        // Inisialisasi awal saat pertama kali mount
        if (_activeBlockStartMs == 0) {
          _activeBlockStartMs = DateTime.now().millisecondsSinceEpoch;
        }

        if (_isInMainPhase &&
            _phaseTimer == null &&
            _jumbotronItems.isNotEmpty) {
          _phaseTimer = Timer(Duration(seconds: mainDuration), () {
            if (mounted) _switchToJumbotron();
          });
        }

        Widget currentWidget;

        if (_isInMainPhase || _jumbotronItems.isEmpty) {
          currentWidget = ProviderScope(
            key: ValueKey('main_$_activeBlockStartMs'),
            overrides: [
              slideStartTimeProvider.overrideWithValue(_activeBlockStartMs),
            ],
            child: const MainContentWidget(),
          );
        } else {
          final currentStep = _jumbotronStepIndex;
          final item =
              _jumbotronItems[_jumbotronStepIndex % _jumbotronItems.length];
          if (item['type'] == 'pemko_video') {
            currentWidget = JumbotronPemkoScreen(
              key: ValueKey(
                'pemko_video_${item['videoUrl']}_${_jumbotronStepIndex}_$_activeBlockStartMs',
              ),
              videoUrl: item['videoUrl'],
              hasAudio: item['hasAudio'] ?? false,
              onFinished: () {
                _advanceJumbotron(fromStepIndex: currentStep);
              },
            );
          } else if (item['type'] == 'pemko_image') {
            currentWidget = JumbotronPemkoScreen(
              key: ValueKey(
                'pemko_image_${item['slide']}_${_jumbotronStepIndex}_$_activeBlockStartMs',
              ),
              imageUrl: item['slide'],
            );
          } else {
            currentWidget = JumbotronMasjidScreen(
              key: ValueKey(
                'masjid_${item['slide']}_${_jumbotronStepIndex}_$_activeBlockStartMs',
              ),
              imageUrl: item['slide'],
            );
          }
        }

        return Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 600),
            switchInCurve: Curves.easeInOut,
            switchOutCurve: Curves.easeInOut,
            child: currentWidget,
          ),
        );
      },
    );
  }
}
