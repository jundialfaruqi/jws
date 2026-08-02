import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  Future<Map<String, dynamic>> requestPairingCode() async {
    try {
      final deviceId = await getDeviceId();
      final response = await _dio.post(
        '${ApiConstant.baseUrl}api/v2/device/request-code',
        data: {'device_id': deviceId},
      );
      
      if (response.statusCode == 200) {
        return response.data; // { status: 'pending'|'linked', pairing_code: '...', masjid_id: ... }
      }
      return {'status': 'error', 'message': 'Failed to request code'};
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }
}
