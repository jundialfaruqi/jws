import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/services.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage;
  final Map<String, String> _memoryFallback = {};

  SecureStorageService()
      : _storage = const FlutterSecureStorage(
          aOptions: AndroidOptions(),
        );

  Future<void> write(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } on PlatformException catch (_) {
      // Fallback untuk macOS lokal jika tidak ada izin Keychain
      _memoryFallback[key] = value;
    }
  }

  Future<String?> read(String key) async {
    try {
      final value = await _storage.read(key: key);
      if (value != null) return value;
      return _memoryFallback[key];
    } on PlatformException catch (_) {
      return _memoryFallback[key];
    }
  }

  Future<void> delete(String key) async {
    try {
      await _storage.delete(key: key);
    } on PlatformException catch (_) {
      // Abaikan jika error, cukup hapus dari memori
    }
    _memoryFallback.remove(key);
  }

  Future<void> deleteAll() async {
    try {
      await _storage.deleteAll();
    } on PlatformException catch (_) {
      // Abaikan
    }
    _memoryFallback.clear();
  }
}
