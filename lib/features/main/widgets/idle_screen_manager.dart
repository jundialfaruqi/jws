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
  int _jumbotronStepIndex = 0;
  int _activeBlockStartMs = 0;
  int _currentMainDuration = 30;

  @override
  void dispose() {
    _phaseTimer?.cancel();
    _videoWatchdogTimer?.cancel();
    _retryFocusNode.dispose();
    super.dispose();
  }

  void _switchToJumbotron(List<Map<String, dynamic>> jumbotronItems) {
    _phaseTimer?.cancel();
    _phaseTimer = null;
    _videoWatchdogTimer?.cancel();
    _videoWatchdogTimer = null;

    if (!mounted || jumbotronItems.isEmpty) return;

    _isInMainPhase = false;
    _jumbotronStepIndex = 0;
    _showCurrentJumbotronItem(jumbotronItems);
  }

  void _showCurrentJumbotronItem(List<Map<String, dynamic>> jumbotronItems) {
    _phaseTimer?.cancel();
    _phaseTimer = null;
    _videoWatchdogTimer?.cancel();
    _videoWatchdogTimer = null;

    if (!mounted || jumbotronItems.isEmpty) return;

    _activeBlockStartMs = DateTime.now().millisecondsSinceEpoch;
    final item = jumbotronItems[_jumbotronStepIndex % jumbotronItems.length];

    if (item['type'] == 'pemko_video') {
      final durationSec = (item['duration'] as int?) ?? 30;
      final timeoutSec = durationSec > 0 ? durationSec + 15 : 180;
      _videoWatchdogTimer = Timer(Duration(seconds: timeoutSec), () {
        debugPrint(
          '[IdleScreenManager] Safety watchdog fired for video ($timeoutSec s), advancing to next jumbotron item.',
        );
        _advanceJumbotron(jumbotronItems);
      });
    } else {
      // Gambar statis (pemko_image atau masjid_image): tampil 20 detik
      final durationSec = (item['duration'] as int?) ?? 20;
      _phaseTimer = Timer(Duration(seconds: durationSec), () {
        if (mounted) _advanceJumbotron(jumbotronItems);
      });
    }

    setState(() {});
  }

  void _advanceJumbotron(List<Map<String, dynamic>> jumbotronItems) {
    if (!mounted) return;
    _phaseTimer?.cancel();
    _phaseTimer = null;
    _videoWatchdogTimer?.cancel();
    _videoWatchdogTimer = null;

    _jumbotronStepIndex++;
    if (_jumbotronStepIndex >= jumbotronItems.length) {
      // Seluruh siklus jumbotron (video -> gambar global -> gambar masjid) telah selesai!
      // Kembali ke siklus slide utama
      _jumbotronStepIndex = 0;
      _switchToMain(jumbotronItems);
    } else {
      _showCurrentJumbotronItem(jumbotronItems);
    }
  }

  void _switchToMain(List<Map<String, dynamic>> jumbotronItems) {
    _phaseTimer?.cancel();
    _phaseTimer = null;
    _videoWatchdogTimer?.cancel();
    _videoWatchdogTimer = null;

    _isInMainPhase = true;
    _activeBlockStartMs = DateTime.now().millisecondsSinceEpoch;
    setState(() {});

    if (jumbotronItems.isNotEmpty) {
      _phaseTimer = Timer(Duration(seconds: _currentMainDuration), () {
        if (mounted) _switchToJumbotron(jumbotronItems);
      });
    }
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

        // Kumpulkan semua item jumbotron aktif sesuai urutan siklus:
        // 1. Jumbotron Video Global (semua video aktif)
        // 2. Jumbotron Gambar Global (semua gambar global aktif)
        // 3. Jumbotron Gambar Masjid (semua gambar masjid aktif)
        final List<Map<String, dynamic>> jumbotronItems = [];

        // 1. Jumbotron Video Global
        if (data.jumbotronPemko?.isActive == true) {
          final videos = data.jumbotronPemko!.videos;
          if (videos.isNotEmpty) {
            for (final v in videos) {
              int videoDuration = v.duration;
              if (videoDuration <= 0 &&
                  detectedDurations.containsKey(v.videoUrl)) {
                videoDuration = detectedDurations[v.videoUrl]!;
              }
              if (videoDuration <= 0) {
                videoDuration = 30;
              }
              jumbotronItems.add({
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
            jumbotronItems.add({
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
            jumbotronItems.add({
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
            jumbotronItems.add({
              'type': 'masjid_image',
              'slide': img,
              'duration': 20,
            });
          }
        }

        if (jumbotronItems.isEmpty) {
          if (!_isInMainPhase) {
            _phaseTimer?.cancel();
            _phaseTimer = null;
            _videoWatchdogTimer?.cancel();
            _videoWatchdogTimer = null;
            _isInMainPhase = true;
            _jumbotronStepIndex = 0;
          }
        }

        // Inisialisasi awal saat pertama kali mount
        if (_activeBlockStartMs == 0) {
          _activeBlockStartMs = DateTime.now().millisecondsSinceEpoch;
        }

        if (_isInMainPhase &&
            _phaseTimer == null &&
            jumbotronItems.isNotEmpty) {
          _phaseTimer = Timer(Duration(seconds: mainDuration), () {
            if (mounted) _switchToJumbotron(jumbotronItems);
          });
        }

        Widget currentWidget;

        if (_isInMainPhase || jumbotronItems.isEmpty) {
          currentWidget = ProviderScope(
            key: ValueKey('main_$_activeBlockStartMs'),
            overrides: [
              slideStartTimeProvider.overrideWithValue(_activeBlockStartMs),
            ],
            child: const MainContentWidget(),
          );
        } else {
          final item =
              jumbotronItems[_jumbotronStepIndex % jumbotronItems.length];
          if (item['type'] == 'pemko_video') {
            currentWidget = JumbotronPemkoScreen(
              key: ValueKey(
                'pemko_video_${item['videoUrl']}_${_jumbotronStepIndex}_$_activeBlockStartMs',
              ),
              videoUrl: item['videoUrl'],
              hasAudio: item['hasAudio'] ?? false,
              onFinished: () {
                _advanceJumbotron(jumbotronItems);
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
