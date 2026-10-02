import 'package:flutter_riverpod/flutter_riverpod.dart';

class VideoPlaybackNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void setPlaying(bool value) {
    if (state != value) {
      state = value;
    }
  }
}

final isVideoPlayingWithAudioProvider = NotifierProvider<VideoPlaybackNotifier, bool>(
  VideoPlaybackNotifier.new,
);

class VideoDurationNotifier extends Notifier<Map<String, int>> {
  @override
  Map<String, int> build() => {};

  void setDuration(String url, int durationInSeconds) {
    if (durationInSeconds > 0 && state[url] != durationInSeconds) {
      state = {...state, url: durationInSeconds};
    }
  }
}

final detectedVideoDurationProvider =
    NotifierProvider<VideoDurationNotifier, Map<String, int>>(
  VideoDurationNotifier.new,
);

