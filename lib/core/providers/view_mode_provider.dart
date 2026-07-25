import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'storage_provider.dart';

// Provider untuk menampung nilai awal dari storage
final initialViewModeProvider = Provider<String?>((ref) => null);

class ViewModeNotifier extends Notifier<String?> {
  @override
  String? build() {
    return ref.read(initialViewModeProvider);
  }

  Future<void> setViewMode(String mode) async {
    state = mode;
    final storage = ref.read(secureStorageProvider);
    await storage.write('view_mode', mode);
  }
}

final viewModeProvider = NotifierProvider<ViewModeNotifier, String?>(ViewModeNotifier.new);
