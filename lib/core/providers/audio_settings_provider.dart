import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AudioSettingsState {
  final bool isAdzanMuted;
  final bool isMurotalMuted;

  AudioSettingsState({
    this.isAdzanMuted = false,
    this.isMurotalMuted = false,
  });

  AudioSettingsState copyWith({
    bool? isAdzanMuted,
    bool? isMurotalMuted,
  }) {
    return AudioSettingsState(
      isAdzanMuted: isAdzanMuted ?? this.isAdzanMuted,
      isMurotalMuted: isMurotalMuted ?? this.isMurotalMuted,
    );
  }
}

final audioSettingsProvider = NotifierProvider<AudioSettingsNotifier, AudioSettingsState>(AudioSettingsNotifier.new);

class AudioSettingsNotifier extends Notifier<AudioSettingsState> {
  final _storage = const FlutterSecureStorage();
  
  @override
  AudioSettingsState build() {
    _loadSettings();
    return AudioSettingsState();
  }

  Future<void> _loadSettings() async {
    final adzanMutedStr = await _storage.read(key: 'is_adzan_muted');
    final murotalMutedStr = await _storage.read(key: 'is_murotal_muted');

    state = state.copyWith(
      isAdzanMuted: adzanMutedStr == 'true',
      isMurotalMuted: murotalMutedStr == 'true',
    );
  }

  Future<void> toggleAdzanMuted() async {
    final newValue = !state.isAdzanMuted;
    state = state.copyWith(isAdzanMuted: newValue);
    await _storage.write(key: 'is_adzan_muted', value: newValue.toString());
  }

  Future<void> toggleMurotalMuted() async {
    final newValue = !state.isMurotalMuted;
    state = state.copyWith(isMurotalMuted: newValue);
    await _storage.write(key: 'is_murotal_muted', value: newValue.toString());
  }
}
