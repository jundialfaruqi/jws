import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';
import '../constants/api_constant.dart';

final deviceServiceProvider = Provider<DeviceService>((ref) {
  return DeviceService();
});

class DeviceService {
  final _storage = const FlutterSecureStorage();
  final _uuid = const Uuid();
  final _dio = Dio();

  Future<String> getDeviceId() async {
    String? deviceId = await _storage.read(key: 'device_id');
    if (deviceId == null) {
      deviceId = _uuid.v4();
      await _storage.write(key: 'device_id', value: deviceId);
    }
    return deviceId;
  }

  Future<Map<String, String?>> _getDeviceInfo() async {
    final info = DeviceInfoPlugin();
    try {
      if (Platform.isAndroid) {
        final androidInfo = await info.androidInfo;
        return {
          'device_brand': androidInfo.brand,
          'device_model': androidInfo.model,
          'os_version':   'Android ${androidInfo.version.release}',
        };
      }
    } catch (_) {}
    return {
      'device_brand': null,
      'device_model': null,
      'os_version':   null,
    };
  }

  Future<Map<String, dynamic>> requestPairingCode() async {
    try {
      final deviceId = await getDeviceId();
      final deviceInfo = await _getDeviceInfo();
      final response = await _dio.post(
        '${ApiConstant.baseUrl}api/v2/device/request-code',
        data: {
          'device_id':    deviceId,
          'device_brand': deviceInfo['device_brand'],
          'device_model': deviceInfo['device_model'],
          'os_version':   deviceInfo['os_version'],
        },
      );
      
      if (response.statusCode == 200) {
        return response.data; // { status: 'pending'|'linked', pairing_code: '...', masjid_id: ... }
      }
      return {'status': 'error', 'message': 'Failed to request code'};
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }

  Future<bool> unpairDevice() async {
    try {
      final deviceId = await getDeviceId();
      final response = await _dio.post(
        '${ApiConstant.baseUrl}api/v2/device/unpair',
        data: {'device_id': deviceId},
      );
      return response.statusCode == 200 && response.data['success'] == true;
    } catch (_) {
      return false;
    }
  }

  Future<void> resetDeviceId() async {
    await _storage.delete(key: 'device_id');
  }
}
