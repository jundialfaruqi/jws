import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import '../../../core/constants/api_constant.dart';
import '../../../core/providers/selected_profil_provider.dart';
import '../../../core/widgets/app_live_clock.dart';
import '../../../core/widgets/tv_scaffold.dart';
import '../../../core/widgets/app_next_prayer_bar.dart';
import '../../../core/services/video_downloader_service.dart';
import '../providers/my_masjid_provider.dart';
import '../providers/video_playback_provider.dart';

class JumbotronPemkoScreen extends ConsumerStatefulWidget {
  final String? imageUrl;
  final String? videoUrl;
  final bool hasAudio;
  final VoidCallback? onFinished;

  const JumbotronPemkoScreen({
    super.key,
    this.imageUrl,
    this.videoUrl,
    this.hasAudio = false,
    this.onFinished,
  });

  @override
  ConsumerState<JumbotronPemkoScreen> createState() => _JumbotronPemkoScreenState();
}

class _JumbotronPemkoScreenState extends ConsumerState<JumbotronPemkoScreen> {
  VideoPlayerController? _videoController;
  bool _isInitialized = false;
  bool _hasError = false;
  bool _isCompleted = false;
  VideoPlaybackNotifier? _audioNotifier;

  String _getFullUrl(String? path) {
    if (path == null || path.isEmpty) return '';

    final baseUrl = ApiConstant.baseUrl;
    final cleanBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;

    // Jika path berupa full URL yang merujuk ke localhost atau 127.0.0.1,
    // sesuaikan host dan port mengikuti baseUrl (misal 10.0.2.2 untuk emulator)
    if (path.startsWith('http://localhost') || path.startsWith('http://127.0.0.1')) {
      try {
        final uri = Uri.parse(path);
        final baseUri = Uri.parse(cleanBase);
        return uri.replace(
          scheme: baseUri.scheme,
          host: baseUri.host,
          port: baseUri.hasPort ? baseUri.port : null,
        ).toString();
      } catch (_) {}
    }

    if (path.startsWith('http')) return path;

    final cleanPath = path.startsWith('/') ? path : '/$path';

    return '$cleanBase$cleanPath';
  }

  @override
  void initState() {
    super.initState();
    if (widget.hasAudio) {
      _audioNotifier = ref.read(isVideoPlayingWithAudioProvider.notifier);
    }
    if (widget.videoUrl != null && widget.videoUrl!.isNotEmpty) {
      _initVideoPlayer();
    }
  }

  void _videoListener() {
    if (_isCompleted || _videoController == null || !_videoController!.value.isInitialized) {
      return;
    }
    final value = _videoController!.value;
    final pos = value.position;
    final dur = value.duration;

    if (dur > Duration.zero) {
      // Jika video sudah berada di akhir durasi (toleransi 300ms) atau berhenti di detik terakhir
      final reachedEnd = pos >= dur - const Duration(milliseconds: 300) ||
          (!value.isPlaying && pos >= dur - const Duration(seconds: 1));

      if (reachedEnd) {
        _isCompleted = true;
        try {
          _videoController?.setVolume(0.0);
          _videoController?.pause();
        } catch (_) {}
        if (widget.hasAudio) {
          ref.read(isVideoPlayingWithAudioProvider.notifier).setPlaying(false);
        }
        widget.onFinished?.call();
      }
    }
  }

  Future<void> _initVideoPlayer() async {
    final rawUrl = widget.videoUrl;
    if (rawUrl == null || rawUrl.isEmpty) return;

    try {
      final localPath = await ref.read(videoDownloaderProvider.notifier).getLocalVideoPath(rawUrl);
      final VideoPlayerController controller;

      if (localPath != null && File(localPath).existsSync()) {
        debugPrint('🎬 [JumbotronVideo] Memutar dari penyimpanan internal: $localPath');
        controller = VideoPlayerController.file(File(localPath));
      } else {
        final fullUrl = _getFullUrl(rawUrl);
        debugPrint('🌐 [JumbotronVideo] Berkas lokal belum tersedia, streaming jaringan: $fullUrl');
        controller = VideoPlayerController.networkUrl(Uri.parse(fullUrl));
      }

      _videoController = controller;

      await controller.initialize();
      if (!mounted) {
        controller.dispose();
        return;
      }

      final durationSec = controller.value.duration.inSeconds;
      if (durationSec > 0) {
        ref.read(detectedVideoDurationProvider.notifier).setDuration(rawUrl, durationSec);
      }

      controller.addListener(_videoListener);

      if (widget.hasAudio) {
        ref.read(isVideoPlayingWithAudioProvider.notifier).setPlaying(true);
        await controller.setVolume(1.0);
      } else {
        await controller.setVolume(0.0);
      }

      await controller.setLooping(false);
      await controller.play();

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Error saat memutar video jumbotron di Flutter: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
        });
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted && !_isCompleted) {
            _isCompleted = true;
            widget.onFinished?.call();
          }
        });
      }
    }
  }

  @override
  void dispose() {
    if (widget.hasAudio) {
      Future.microtask(() {
        _audioNotifier?.setPlaying(false);
      });
    }
    _videoController?.removeListener(_videoListener);
    try {
      _videoController?.setVolume(0.0);
      _videoController?.pause();
    } catch (_) {}
    _videoController?.dispose();
    _videoController = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final initialProfil = ref.watch(selectedProfilProvider);
    final liveData = initialProfil != null
        ? ref.watch(myMasjidProvider(initialProfil.id)).value
        : null;

    final isVideo = widget.videoUrl != null && widget.videoUrl!.isNotEmpty;

    return TvScaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Stack(
            children: [
              // Media Latar Belakang: Video Player atau Gambar
              Positioned.fill(
                child: isVideo
                    ? (_isInitialized && _videoController != null
                        ? SizedBox.expand(
                            child: FittedBox(
                              fit: BoxFit.contain,
                              child: SizedBox(
                                width: _videoController!.value.size.width,
                                height: _videoController!.value.size.height,
                                child: VideoPlayer(_videoController!),
                              ),
                            ),
                          )
                        : (_hasError
                            ? const Center(
                                child: Icon(
                                  Icons.error_outline,
                                  size: 100,
                                  color: Colors.white54,
                                ),
                              )
                            : const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.white70,
                                ),
                              )))
                    : CachedNetworkImage(
                        imageUrl: _getFullUrl(widget.imageUrl),
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.contain,
                        errorWidget: (context, url, error) => const Center(
                          child: Icon(
                            Icons.broken_image,
                            size: 100,
                            color: Colors.white54,
                          ),
                        ),
                      ),
              ),

              // Pojok Kiri Atas: Logo Statis DiskominfoTiksan
              Positioned(
                top: 0,
                left: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: const BorderRadius.only(
                      bottomRight: Radius.circular(24),
                    ),
                  ),
                  child: Image.asset(
                    'assets/logo/diskominfotiksan-logo.png',
                    height: 52,
                    fit: BoxFit.contain,
                  ),
                ),
              ),

              // Pojok Kiri Bawah: Jam Digital Melayang
              Positioned(
                bottom: 0,
                left: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(32),
                    ),
                  ),
                  child: const AppLiveClock(
                    textStyle: TextStyle(
                      fontSize: 48,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              // Pojok Kanan Bawah: Countdown Next Prayer Melayang
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(32),
                    ),
                  ),
                  child: AppNextPrayerBar(
                    countdownOnly: true,
                    fontSize: 48,
                    iconSize: 48,
                    jadwalSholatList: liveData?.jadwalSholat ?? [],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
