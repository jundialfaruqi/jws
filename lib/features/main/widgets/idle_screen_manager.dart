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

// ---------------------------------------------------------------------------
// Model internal untuk satu slot di dalam siklus tampilan.
//
// Siklus lengkap (jika ada N item jumbotron):
//   [main_0, item_0, main_1, item_1, ..., main_N-1, item_N-1]  → repeat
// ---------------------------------------------------------------------------
class _CycleSlot {
  final bool isMain;
  final int startOffsetMs;
  final int durationMs;
  final Map<String, dynamic>? item;
  final int itemIndex;

  const _CycleSlot({
    required this.isMain,
    required this.startOffsetMs,
    required this.durationMs,
    this.item,
    this.itemIndex = -1,
  });
}

// ---------------------------------------------------------------------------
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

  List<Map<String, dynamic>> _jumbotronItems = [];
  List<_CycleSlot> _cycleSlots = [];
  int _totalCycleMs = 0;
  int _currentSlotIndex = -1;
  int _currentSlotAbsoluteStartMs = 0;
  int _mainDurationMs = 30000;

  bool _pendingItemsUpdate = false;
  List<Map<String, dynamic>>? _pendingNewItems;
  int _pendingMainDurationMs = 30000;

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
    if (_cycleSlots.isEmpty ||
        _currentSlotIndex < 0 ||
        _currentSlotIndex >= _cycleSlots.length) {
      ref.read(isVideoPlayingWithAudioProvider.notifier).setPlaying(false);
      return;
    }
    final slot = _cycleSlots[_currentSlotIndex];
    if (slot.isMain) {
      ref.read(isVideoPlayingWithAudioProvider.notifier).setPlaying(false);
      return;
    }
    final item = slot.item!;
    final isVideoWithAudio =
        item['type'] == 'pemko_video' && (item['hasAudio'] == true);
    ref.read(isVideoPlayingWithAudioProvider.notifier).setPlaying(isVideoWithAudio);
  }

  // ---------------------------------------------------------------------------
  // Cycle building
  // ---------------------------------------------------------------------------

  List<_CycleSlot> _buildCycleSlots(
    List<Map<String, dynamic>> items,
    int mainDurationMs,
  ) {
    if (items.isEmpty) return [];

    final List<_CycleSlot> slots = [];
    int offset = 0;

    for (int i = 0; i < items.length; i++) {
      slots.add(_CycleSlot(
        isMain: true,
        startOffsetMs: offset,
        durationMs: mainDurationMs,
        itemIndex: -1,
      ));
      offset += mainDurationMs;

      // Bug 1 fix: preferensikan durasi dari server, fallback detected/30s
      final int itemDurationMs = ((items[i]['duration'] as int?) ?? 20) * 1000;
      slots.add(_CycleSlot(
        isMain: false,
        startOffsetMs: offset,
        durationMs: itemDurationMs,
        item: items[i],
        itemIndex: i,
      ));
      offset += itemDurationMs;
    }

    return slots;
  }

  int _calcTotalCycleMs(List<_CycleSlot> slots) {
    if (slots.isEmpty) return 0;
    final last = slots.last;
    return last.startOffsetMs + last.durationMs;
  }

  // ---------------------------------------------------------------------------
  // Epoch-based slot calculation
  // ---------------------------------------------------------------------------

  ({int slotIndex, int slotAbsoluteStartMs}) _calcCurrentSlot(int nowEpochMs) {
    if (_cycleSlots.isEmpty || _totalCycleMs <= 0) {
      return (slotIndex: -1, slotAbsoluteStartMs: nowEpochMs);
    }

    final int posInCycle = nowEpochMs % _totalCycleMs;
    final int cycleStartEpoch = nowEpochMs - posInCycle;

    for (int i = 0; i < _cycleSlots.length; i++) {
      final slot = _cycleSlots[i];
      if (posInCycle < slot.startOffsetMs + slot.durationMs) {
        return (
          slotIndex: i,
          slotAbsoluteStartMs: cycleStartEpoch + slot.startOffsetMs,
        );
      }
    }

    return (slotIndex: 0, slotAbsoluteStartMs: cycleStartEpoch);
  }

  // ---------------------------------------------------------------------------
  // Core: recalculate + self-correcting timer
  // ---------------------------------------------------------------------------

  void _recalculate({bool forceRebuild = false}) {
    // Bug 5 fix: cancel timer lama, jadwalkan baru berbasis epoch
    _phaseTimer?.cancel();
    _phaseTimer = null;
    _videoWatchdogTimer?.cancel();
    _videoWatchdogTimer = null;

    if (!mounted) return;

    if (_cycleSlots.isEmpty) {
      if (_currentSlotIndex != -1 || forceRebuild) {
        _currentSlotIndex = -1;
        _updateVideoAudioState();
        setState(() {});
      }
      return;
    }

    final nowMs = ref.read(timeSyncServiceProvider).now().millisecondsSinceEpoch;
    final result = _calcCurrentSlot(nowMs);

    final bool slotChanged = result.slotIndex != _currentSlotIndex;
    _currentSlotIndex = result.slotIndex;
    _currentSlotAbsoluteStartMs = result.slotAbsoluteStartMs;

    _updateVideoAudioState();

    if (slotChanged || forceRebuild) {
      setState(() {});
    }

    _scheduleNextTick(nowMs);
  }

  /// Bug 5 fix: timer self-correcting — meledak persis di batas akhir slot.
  void _scheduleNextTick(int nowMs) {
    if (_cycleSlots.isEmpty || _totalCycleMs <= 0) return;

    final int slotIdx =
        (_currentSlotIndex >= 0 && _currentSlotIndex < _cycleSlots.length)
            ? _currentSlotIndex
            : 0;
    final slot = _cycleSlots[slotIdx];

    final int posInCycle = nowMs % _totalCycleMs;
    final int slotEndOffset = slot.startOffsetMs + slot.durationMs;
    int msUntilNext = slotEndOffset - posInCycle;

    if (msUntilNext <= 0) msUntilNext = _totalCycleMs - posInCycle;
    if (msUntilNext <= 0) msUntilNext = 100;

    debugPrint(
      '[IdleScreenManager] Slot $slotIdx (${slot.isMain ? "main" : slot.item?["type"]}) '
      'next tick in ${msUntilNext}ms',
    );

    _phaseTimer = Timer(Duration(milliseconds: msUntilNext), () {
      if (mounted) _recalculate();
    });

    // Watchdog ekstra untuk slot video
    if (!slot.isMain && slot.item?['type'] == 'pemko_video') {
      final watchdogMs = msUntilNext + 15000;
      _videoWatchdogTimer = Timer(Duration(milliseconds: watchdogMs), () {
        debugPrint('[IdleScreenManager] Video watchdog triggered.');
        if (mounted) _recalculate();
      });
    }
  }

  // ---------------------------------------------------------------------------
  // Data update handler
  // ---------------------------------------------------------------------------

  List<Map<String, dynamic>> _buildJumbotronItems(
    dynamic data,
    Map<String, int> detectedDurations,
  ) {
    final List<Map<String, dynamic>> items = [];

    if (data.jumbotronPemko?.isActive == true) {
      final videos = data.jumbotronPemko!.videos;
      if (videos.isNotEmpty) {
        for (final v in videos) {
          // Bug 1 fix: server → detected → fallback 30s
          int videoDuration = v.duration;
          if (videoDuration <= 0 && detectedDurations.containsKey(v.videoUrl)) {
            videoDuration = detectedDurations[v.videoUrl]!;
          }
          if (videoDuration <= 0) videoDuration = 30;
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
        if (videoDuration <= 0) videoDuration = 30;
        items.add({
          'type': 'pemko_video',
          'videoUrl': vUrl,
          'hasAudio': data.jumbotronPemko!.hasAudio,
          'duration': videoDuration,
          'id': data.jumbotronPemko!.id,
        });
      }

      final pemkoImages = data.jumbotronPemko!.validSlides;
      for (final img in pemkoImages) {
        items.add({'type': 'pemko_image', 'slide': img, 'duration': 20});
      }
    }

    if (data.jumbotronMasjid?.isActive == true) {
      final masjidImages = data.jumbotronMasjid!.validSlides;
      for (final img in masjidImages) {
        items.add({'type': 'masjid_image', 'slide': img, 'duration': 20});
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

  /// Bug 2 fix: hanya dipanggil setelah data tersedia (via postFrameCallback).
  /// Bug 4 fix: setiap device rebuild cycle dari epoch yang sama → otomatis sync.
  void _handleItemsUpdated(
    List<Map<String, dynamic>> newItems,
    int mainDurationMs,
  ) {
    _jumbotronItems = newItems;
    _mainDurationMs = mainDurationMs;
    _cycleSlots = _buildCycleSlots(newItems, mainDurationMs);
    _totalCycleMs = _calcTotalCycleMs(_cycleSlots);

    debugPrint(
      '[IdleScreenManager] Cycle rebuilt: ${newItems.length} items, '
      'totalCycle=${_totalCycleMs}ms (${(_totalCycleMs / 1000).toStringAsFixed(1)}s)',
    );

    _recalculate(forceRebuild: true);
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final profil = ref.watch(selectedProfilProvider);
    if (profil == null) {
      return const Expanded(
        child: Center(child: Text('Profil tidak ditemukan')),
      );
    }

    final myMasjidAsync = ref.watch(myMasjidProvider(profil.id));

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
        // Bug 2 fix: mainDurationMs dihitung dari data yang sudah siap.
        final int mainDurationMs =
            (mainSlides.isNotEmpty ? mainSlides.length * 20 : 30) * 1000;

        final detectedDurations = ref.read(detectedVideoDurationProvider);
        final newItems = _buildJumbotronItems(data, detectedDurations);

        final bool needRebuild = _itemsChanged(_jumbotronItems, newItems) ||
            mainDurationMs != _mainDurationMs;

        if (needRebuild && !_pendingItemsUpdate) {
          _pendingNewItems = newItems;
          _pendingMainDurationMs = mainDurationMs;
          _pendingItemsUpdate = true;
          // Bug 2 fix: terapkan update setelah frame selesai
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _pendingNewItems != null) {
              final items = _pendingNewItems!;
              final dur = _pendingMainDurationMs;
              _pendingNewItems = null;
              _pendingItemsUpdate = false;
              _handleItemsUpdated(items, dur);
            } else {
              _pendingItemsUpdate = false;
            }
          });
        }

        // Inisialisasi epoch start untuk main widget key saat pertama kali
        if (_currentSlotAbsoluteStartMs == 0) {
          _currentSlotAbsoluteStartMs =
              ref.read(timeSyncServiceProvider).now().millisecondsSinceEpoch;
        }

        // Recovery: cycle ada tapi timer hilang (hot reload, dll)
        if (_cycleSlots.isNotEmpty &&
            _phaseTimer == null &&
            !_pendingItemsUpdate) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _phaseTimer == null && _cycleSlots.isNotEmpty) {
              _recalculate();
            }
          });
        }

        final bool isMainPhase = _cycleSlots.isEmpty ||
            _currentSlotIndex < 0 ||
            _currentSlotIndex >= _cycleSlots.length ||
            _cycleSlots[_currentSlotIndex].isMain;

        Widget currentWidget;

        if (isMainPhase) {
          // Bug 6 fix: key deterministik dari epoch slot start (sama di semua device)
          currentWidget = ProviderScope(
            key: ValueKey('main_$_currentSlotAbsoluteStartMs'),
            overrides: [
              slideStartTimeProvider
                  .overrideWithValue(_currentSlotAbsoluteStartMs),
            ],
            child: const MainContentWidget(),
          );
        } else {
          final slot = _cycleSlots[_currentSlotIndex];
          final item = slot.item!;

          // Bug 6 fix: key hanya dari data server + epoch slot start
          // (tidak menggunakan timestamp lokal device)
          final String baseKey =
              '${item['type']}_${item['videoUrl'] ?? item['slide']}'
              '_$_currentSlotAbsoluteStartMs';

          if (item['type'] == 'pemko_video') {
            currentWidget = JumbotronPemkoScreen(
              key: ValueKey('pemko_video_$baseKey'),
              videoUrl: item['videoUrl'],
              hasAudio: item['hasAudio'] ?? false,
              // Bug 3 fix: onFinished hanya trigger recalculate.
              // Jika epoch masih di dalam slot ini, widget tetap tampil
              // dalam state paused hingga timer epoch meledak sendiri.
              onFinished: () {
                if (mounted) _recalculate();
              },
            );
          } else if (item['type'] == 'pemko_image') {
            currentWidget = JumbotronPemkoScreen(
              key: ValueKey('pemko_image_$baseKey'),
              imageUrl: item['slide'],
            );
          } else {
            currentWidget = JumbotronMasjidScreen(
              key: ValueKey('masjid_$baseKey'),
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
