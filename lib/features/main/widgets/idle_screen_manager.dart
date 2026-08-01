import '../../../core/providers/slide_start_time_provider.dart';

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/selected_profil_provider.dart';
import '../../../core/providers/connectivity_provider.dart';
import '../../../core/time/time_sync_service.dart';
import '../../../core/widgets/app_loading_spinner.dart';
import '../providers/my_masjid_provider.dart';
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
  Timer? _timer;
  final FocusNode _retryFocusNode = FocusNode();
  bool _hasRequestedFocusForRetry = false;

  @override
  void dispose() {
    _timer?.cancel();
    _retryFocusNode.dispose();
    super.dispose();
  }

  void _scheduleNextUpdate(int delayMs) {
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: delayMs), () {
      if (mounted) setState(() {});
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

    // Dengarkan perubahan jaringan secara diam-diam.
    // Jika awalnya putus (false) lalu tersambung lagi (true), otomatis refresh data utama jika sedang error.
    ref.listen<AsyncValue<bool>>(isConnectedProvider, (previous, next) {
      if (previous?.value == false && next.value == true) {
        // Hapus pengecekan hasError agar selalu refresh data saat internet kembali
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
        final pemkoSlides = data.jumbotronPemko?.isActive == true
            ? (data.jumbotronPemko?.validSlides ?? [])
            : [];
        final masjidSlides = data.jumbotronMasjid?.isActive == true
            ? (data.jumbotronMasjid?.validSlides ?? [])
            : [];

        int mainDuration = mainSlides.isNotEmpty ? mainSlides.length * 20 : 30;
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
            _scheduleNextUpdate(msUntilNextBlock);
          }
        });

        Widget currentWidget;
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
          // loopStartMs adalah waktu absolut saat siklus ini dimulai (diulang setiap totalDuration)
          final loopStartMs = nowMs - currentPosMs;
          // activeBlockStartMs adalah waktu absolut saat MainContent ini seharusnya mulai muncul
          final activeBlockStartMs = loopStartMs + accumulatedMs;
          
          currentWidget = ProviderScope(
            key: const ValueKey('main'),
            overrides: [
              slideStartTimeProvider.overrideWithValue(activeBlockStartMs),
            ],
            child: const MainContentWidget(),
          );
        }

        return Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 1000),
            switchInCurve: Curves.easeInOut,
            switchOutCurve: Curves.easeInOut,
            child: currentWidget,
          ),
        );
      },
    );
  }
}
