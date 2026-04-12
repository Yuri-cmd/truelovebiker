import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:truelovebiker/core/api/api_client.dart';

class ErrorLogService {
  static final ErrorLogService _instance = ErrorLogService._internal();
  factory ErrorLogService() => _instance;
  ErrorLogService._internal();

  final Dio _dio = ApiClient.dio;

  Future<void> logError(dynamic error, dynamic stackTrace) async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final prefs = await SharedPreferences.getInstance();
      
      final userId = prefs.getInt('user_id') ?? prefs.getInt('id'); 

      final deviceInfo = {
        'platform': Platform.operatingSystem,
        'os_version': Platform.operatingSystemVersion,
        'app_version': packageInfo.version,
        'build_number': packageInfo.buildNumber,
        'package_name': packageInfo.packageName,
      };

      await _dio.post('error-logs', data: {
        'app_name': 'Biker App',
        'error_message': error.toString(),
        'stack_trace': stackTrace.toString(),
        'user_id': userId,
        'device_info': deviceInfo,
      });

      debugPrint('Error reportado exitosamente al backend');
    } catch (e) {
      debugPrint('Error al reportar log: $e');
    }
  }

  static void initialize() {
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      ErrorLogService().logError(details.exception, details.stack);
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      ErrorLogService().logError(error, stack);
      return true;
    };
  }
}
