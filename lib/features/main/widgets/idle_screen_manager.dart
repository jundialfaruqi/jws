import '../../../core/providers/slide_start_time_provider.dart';

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/selected_profil_provider.dart';
import '../../../core/providers/connectivity_provider.dart';
import '../../../core/time/time_sync_service.dart';
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
  Timer? _staticTimer;
  Timer? _videoPhaseTimer;
  Timer? _videoWatchdogTimer;
  final FocusNode _retryFocusNode = FocusNode();
  bool _hasRequestedFocusForRetry = false;

  // State rotasi event-driven khusus ketika ada video jumbotron
  bool _isVideoPlaying = false;
  bool _isInMainPhase = true;
  int _jumbotronStepIndex = 0;
  int _activeBlockStartMs = 0;
  int _currentMainDuration = 30;

  @override
  void dispose() {
    _staticTimer?.cancel();
    _videoPhaseTimer?.cancel();
    _videoWatchdogTimer?.cancel();
    _retryFocusNode.dispose();
    super.dispose();
  }

  void _scheduleStaticUpdate(int delayMs) {
    _staticTimer?.cancel();
    _staticTimer = Timer(Duration(milliseconds: delayMs), () {
      if (mounted) setState(() {});
    });
  }

  void _switchToJumbotron(List<Map<String, dynamic>> jumbotronItems) {
    _videoPhaseTimer?.cancel();
    _videoPhaseTimer = null;
    _videoWatchdogTimer?.cancel();
    _videoWatchdogTimer = null;

    if (!mounted || jumbotronItems.isEmpty) return;

    final item = jumbotronItems[_jumbotronStepIndex % jumbotronItems.length];
    _isInMainPhase = false;
    _activeBlockStartMs = DateTime.now().millisecondsSinceEpoch;

    if (item['type'] == 'pemko_video') {
      _isVideoPlaying = true;
      setState(() {});

      final durationSec = (item['duration'] as int?) ?? 30;
      final timeoutSec = durationSec > 0 ? durationSec + 15 : 180;
      _videoWatchdogTimer = Timer(Duration(seconds: timeoutSec), () {
        debugPrint('[IdleScreenManager] Safety watchdog fired for video ($timeoutSec s), transitioning to main.');
        _handleVideoCompletion(jumbotronItems);
      });
    } else {
      // Masjid image slide
      _isVideoPlaying = false;
      setState(() {});

      final durationSec = (item['duration'] as int?) ?? 20;
      _videoPhaseTimer = Timer(Duration(seconds: durationSec), () {
        if (!mounted) return;
        _handleImageSlideCompletion(jumbotronItems);
      });
    }
  }

  void _handleVideoCompletion(List<Map<String, dynamic>> jumbotronItems) {
    if (!mounted) return;
    _videoWatchdogTimer?.cancel();
    _videoWatchdogTimer = null;

    _jumbotronStepIndex = (_jumbotronStepIndex + 1) % jumbotronItems.length;
    _switchToMain(jumbotronItems);
  }

  void _handleImageSlideCompletion(List<Map<String, dynamic>> jumbotronItems) {
    if (!mounted) return;
    _videoPhaseTimer?.cancel();
    _videoPhaseTimer = null;

    _jumbotronStepIndex = (_jumbotronStepIndex + 1) % jumbotronItems.length;
    _switchToMain(jumbotronItems);
  }

  void _switchToMain(List<Map<String, dynamic>> jumbotronItems) {
    _videoPhaseTimer?.cancel();
    _videoWatchdogTimer?.cancel();

    _isInMainPhase = true;
    _isVideoPlaying = false;
    _activeBlockStartMs = DateTime.now().millisecondsSinceEpoch;

    setState(() {});

    _videoPhaseTimer = Timer(Duration(seconds: _currentMainDuration), () {
      if (!mounted) return;
      _switchToJumbotron(jumbotronItems);
    });
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
        final isPemkoActive = data.jumbotronPemko?.isActive == true;
        final isPemkoVideo = isPemkoActive && (data.jumbotronPemko?.isVideo ?? false);
        final pemkoSlides = (isPemkoActive && !isPemkoVideo)
            ? (data.jumbotronPemko?.validSlides ?? [])
            : [];
        final masjidSlides = data.jumbotronMasjid?.isActive == true
            ? (data.jumbotronMasjid?.validSlides ?? [])
            : [];

        int mainDuration = mainSlides.isNotEmpty ? mainSlides.length * 20 : 30;
        _currentMainDuration = mainDuration;

        Widget currentWidget;

        if (isPemkoVideo) {
          // Bersihkan timer static image jika sebelumnya berjalan
          _staticTimer?.cancel();

          final videoUrl = data.jumbotronPemko!.videoFile;
          int videoDuration = data.jumbotronPemko!.videoDuration;
          if (videoDuration <= 0 && videoUrl != null && detectedDurations.containsKey(videoUrl)) {
            videoDuration = detectedDurations[videoUrl]!;
          }
          if (videoDuration <= 0) {
            videoDuration = 30;
          }

          List<Map<String, dynamic>> jumbotronItems = [];
          if (videoUrl != null && videoUrl.isNotEmpty) {
            jumbotronItems.add({
              'type': 'pemko_video',
              'videoUrl': videoUrl,
              'hasAudio': data.jumbotronPemko!.hasAudio,
              'duration': videoDuration,
            });
          }

          for (final slide in masjidSlides) {
            jumbotronItems.add({
              'type': 'masjid',
              'slide': slide,
              'duration': 20,
            });
          }

          if (jumbotronItems.isEmpty) {
            currentWidget = const MainContentWidget();
          } else {
            // Inisialisasi awal saat pertama kali mount
            if (_activeBlockStartMs == 0) {
              _activeBlockStartMs = DateTime.now().millisecondsSinceEpoch;
            }
            if (_videoPhaseTimer == null && !_isVideoPlaying && _isInMainPhase) {
              _videoPhaseTimer = Timer(Duration(seconds: mainDuration), () {
                if (mounted) _switchToJumbotron(jumbotronItems);
              });
            }

            if (_isInMainPhase) {
              currentWidget = ProviderScope(
                key: const ValueKey('main'),
                overrides: [
                  slideStartTimeProvider.overrideWithValue(_activeBlockStartMs),
                ],
                child: const MainContentWidget(),
              );
            } else {
              final item = jumbotronItems[_jumbotronStepIndex % jumbotronItems.length];
              if (item['type'] == 'pemko_video') {
                currentWidget = JumbotronPemkoScreen(
                  key: ValueKey('pemko_video_${item['videoUrl']}_$_activeBlockStartMs'),
                  videoUrl: item['videoUrl'],
                  hasAudio: item['hasAudio'] ?? false,
                  onFinished: () {
                    _handleVideoCompletion(jumbotronItems);
                  },
                );
              } else {
                currentWidget = JumbotronMasjidScreen(
                  key: ValueKey('masjid_${item['slide']}_$_activeBlockStartMs'),
                  imageUrl: item['slide'],
                );
              }
            }
          }
        } else {
          // BUKAN VIDEO: Gunakan rotasi sinkronisasi jam absolut untuk gambar statis
          _videoPhaseTimer?.cancel();
          _videoPhaseTimer = null;
          _videoWatchdogTimer?.cancel();
          _videoWatchdogTimer = null;
          _isVideoPlaying = false;
          _isInMainPhase = true;
          _activeBlockStartMs = 0;

          List<Map<String, dynamic>> blocks = [];
          blocks.add({'type': 'main', 'duration': mainDuration});

          int maxJumbo = pemkoSlides.length > masjidSlides.length
              ? pemkoSlides.length
              : masjidSlides.length;

          for (int i = 0; i < maxJumbo; i++) {
            if (i < pemkoSlides.length) {
              blocks.add({
                'type': 'pemko',
                'slide': pemkoSlides[i],
                'duration': 20,
              });
              blocks.add({'type': 'main', 'duration': mainDuration});
            }
            if (i < masjidSlides.length) {
              blocks.add({
                'type': 'masjid',
                'slide': masjidSlides[i],
                'duration': 20,
              });
              blocks.add({'type': 'main', 'duration': mainDuration});
            }
          }

          if (blocks.length > 1 && blocks.last['type'] == 'main') {
            blocks.removeLast();
          }

          int totalDuration = blocks.fold(
            0,
            (sum, b) => sum + (b['duration'] as int),
          );

          if (totalDuration == 0) totalDuration = 1;

          final nowMs = ref.read(timeSyncServiceProvider).now().millisecondsSinceEpoch;
          final totalDurationMs = totalDuration * 1000;
          final currentPosMs = nowMs % totalDurationMs;

          int accumulatedMs = 0;
          Map<String, dynamic>? activeBlock;
          int msUntilNextBlock = 1000; // fallback

          for (final b in blocks) {
            int durationMs = (b['duration'] as int) * 1000;
            if (currentPosMs >= accumulatedMs && currentPosMs < accumulatedMs + durationMs) {
              activeBlock = b;
              msUntilNextBlock = (accumulatedMs + durationMs) - currentPosMs;
              break;
            }
            accumulatedMs += durationMs;
          }
          activeBlock ??= blocks.first;

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _scheduleStaticUpdate(msUntilNextBlock);
            }
          });

          if (activeBlock['type'] == 'pemko') {
            currentWidget = JumbotronPemkoScreen(
              key: ValueKey('pemko_${activeBlock['slide']}'),
              imageUrl: activeBlock['slide'],
            );
          } else if (activeBlock['type'] == 'masjid') {
            currentWidget = JumbotronMasjidScreen(
              key: ValueKey('masjid_${activeBlock['slide']}'),
              imageUrl: activeBlock['slide'],
            );
          } else {
            final loopStartMs = nowMs - currentPosMs;
            final activeBlockStartMs = loopStartMs + accumulatedMs;

            currentWidget = ProviderScope(
              key: const ValueKey('main'),
              overrides: [
                slideStartTimeProvider.overrideWithValue(activeBlockStartMs),
              ],
              child: const MainContentWidget(),
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
