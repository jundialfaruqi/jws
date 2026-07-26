import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../constants/api_constant.dart';

class ApiClient {
  late final Dio dio;

  ApiClient() {
    dio = Dio(
      BaseOptions(
        baseUrl: ApiConstant.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    // Pasang interceptor log hanya ketika aplikasi berjalan di kDebugMode
    // agar log tidak bocor saat aplikasi di rilis (production)
    if (kDebugMode) {
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            debugPrint('============================================');
            debugPrint('🚀 [REQUEST] ${options.method} ${options.uri}');
            if (options.data != null) {
              try {
                debugPrint('Body:\n${const JsonEncoder.withIndent('  ').convert(options.data)}');
              } catch (_) {
                debugPrint('Body: ${options.data}');
              }
            }
            return handler.next(options);
          },
          onResponse: (response, handler) {
            debugPrint('✅ [RESPONSE] ${response.statusCode} ${response.requestOptions.uri}');
            if (response.data != null) {
              try {
                // Formatting JSON agar rapi
                final prettyJson = const JsonEncoder.withIndent('  ').convert(response.data);
                debugPrint('Data:\n$prettyJson');
              } catch (_) {
                debugPrint('Data: ${response.data}');
              }
            }
            debugPrint('============================================');
            return handler.next(response);
          },
          onError: (DioException e, handler) {
            debugPrint('❌ [ERROR] ${e.response?.statusCode} ${e.requestOptions.uri}');
            debugPrint('Message: ${e.message}');
            if (e.response?.data != null) {
              try {
                final prettyJson = const JsonEncoder.withIndent('  ').convert(e.response?.data);
                debugPrint('Error Data:\n$prettyJson');
              } catch (_) {
                debugPrint('Error Data: ${e.response?.data}');
              }
            }
            debugPrint('============================================');
            return handler.next(e);
          },
        ),
      );
    }
  }
}
