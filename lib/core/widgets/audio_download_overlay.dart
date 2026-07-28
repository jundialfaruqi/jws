import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/audio_downloader_service.dart';

class AudioDownloadOverlay extends ConsumerWidget {
  const AudioDownloadOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloadState = ref.watch(audioDownloaderProvider);

    if (downloadState.status == AudioDownloadStatus.idle) {
      return const SizedBox.shrink();
    }

    return Positioned(
      bottom: 24,
      right: 24,
      child: Material(
        color: Colors.transparent,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildIcon(downloadState.status),
              const SizedBox(width: 16),
              Text(
                downloadState.message,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(AudioDownloadStatus status) {
    switch (status) {
      case AudioDownloadStatus.downloading:
        return const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
        );
      case AudioDownloadStatus.success:
        return const Icon(
          Icons.check_circle,
          color: Colors.green,
          size: 28,
        );
      case AudioDownloadStatus.error:
        return const Icon(
          Icons.error,
          color: Colors.red,
          size: 28,
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
