import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/selected_profil_provider.dart';
import '../../../core/providers/main_slide_index_provider.dart';
import '../../../core/time/time_sync_service.dart';
import '../../../core/widgets/app_loading_spinner.dart';
import '../providers/my_masjid_provider.dart';
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

  @override
  void initState() {
    super.initState();
    // Berdetak tiap detik untuk sinkronisasi perpindahan playlist jumbotron
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profil = ref.watch(selectedProfilProvider);
    if (profil == null) {
      return const Expanded(child: Center(child: Text('Profil tidak ditemukan')));
    }

    final myMasjidAsync = ref.watch(myMasjidProvider(profil.id));

    return myMasjidAsync.when(
      loading: () => const Expanded(
        child: Center(child: AppLoadingSpinner(message: 'Memuat data...')),
      ),
      error: (e, s) => const Expanded(
        child: Center(child: Text('Gagal memuat siklus Jumbotron')),
      ),
      data: (data) {
        final mainSlides = data.slides?.validSlides ?? [];
        final pemkoSlides = data.jumbotronPemko?.isActive == true
            ? (data.jumbotronPemko?.validSlides ?? [])
            : [];
        final masjidSlides = data.jumbotronMasjid?.isActive == true
            ? (data.jumbotronMasjid?.validSlides ?? [])
            : [];

        // Hitung durasi Main Screen (10s per slide, minimal 30s)
        int mainDuration = mainSlides.isNotEmpty ? mainSlides.length * 10 : 30;

        List<Map<String, dynamic>> blocks = [];

        // Selalu mulai dengan Main Screen
        blocks.add({'type': 'main', 'duration': mainDuration});

        // Susun daftar siklus selang-seling (Main -> Pemko -> Main -> Masjid)
        int maxJumbo = pemkoSlides.length > masjidSlides.length
            ? pemkoSlides.length
            : masjidSlides.length;

        for (int i = 0; i < maxJumbo; i++) {
          if (i < pemkoSlides.length) {
            blocks.add({
              'type': 'pemko',
              'slide': pemkoSlides[i],
              'duration': 15, // 15 detik tetap sesuai permintaan
            });
            blocks.add({'type': 'main', 'duration': mainDuration});
          }
          if (i < masjidSlides.length) {
            blocks.add({
              'type': 'masjid',
              'slide': masjidSlides[i],
              'duration': 15,
            });
            blocks.add({'type': 'main', 'duration': mainDuration});
          }
        }

        // Hapus blok Main di akhir jika itu berlebihan (hanya jika ada jumbotron)
        if (blocks.length > 1 && blocks.last['type'] == 'main') {
          blocks.removeLast();
        }

        int totalDuration =
            blocks.fold(0, (sum, b) => sum + (b['duration'] as int));

        if (totalDuration == 0) totalDuration = 1;

        final now = ref.read(timeSyncServiceProvider).now();
        final epochSeconds = now.millisecondsSinceEpoch ~/ 1000;
        final currentPos = epochSeconds % totalDuration;

        int accumulated = 0;
        int activeBlockStart = 0;
        Map<String, dynamic>? activeBlock;
        for (final b in blocks) {
          int duration = b['duration'] as int;
          if (currentPos >= accumulated && currentPos < accumulated + duration) {
            activeBlock = b;
            activeBlockStart = accumulated;
            break;
          }
          accumulated += duration;
        }
        activeBlock ??= blocks.first;
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
          int relativeTime = currentPos - activeBlockStart;
          int mainSlideIndex = relativeTime ~/ 10;
          
          currentWidget = ProviderScope(
            key: const ValueKey('main'),
            overrides: [
              mainSlideIndexProvider.overrideWithValue(mainSlideIndex),
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
