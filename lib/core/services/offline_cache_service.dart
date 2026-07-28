import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

final offlineCacheServiceProvider = Provider<OfflineCacheService>((ref) {
  return OfflineCacheService();
});

class OfflineCacheService {
  Future<File> _getCacheFile(int id) async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/my_masjid_cache_$id.json');
  }

  Future<void> saveMyMasjid(int id, Map<String, dynamic> data) async {
    try {
      final file = await _getCacheFile(id);
      await file.writeAsString(jsonEncode(data));
    } catch (e) {
      // Abaikan jika gagal simpan, jangan sampai crash
      debugPrint('Gagal menyimpan cache offline: $e');
    }
  }

  Future<Map<String, dynamic>?> loadMyMasjid(int id) async {
    try {
      final file = await _getCacheFile(id);
      if (await file.exists()) {
        final content = await file.readAsString();
        return jsonDecode(content) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('Gagal membaca cache offline: $e');
    }
    return null;
  }
}
