import 'dart:io';

import 'package:dio/dio.dart';
import 'package:truelovebiker/core/api/api_client.dart';

class MiscService {
  final Dio _dio = ApiClient.dio;

  Future<Response> acknowledgeNotification(
    String notificationId,
    String status,
  ) async {
    return await _dio.post(
      '/notifications/update-status',
      data: {'notification_id': notificationId, 'status': status},
    );
  }

  Future<Response> getAppVersion(String appName) async {
    String platform =
        Platform.isAndroid ? 'android' : (Platform.isIOS ? 'ios' : 'unknown');
    return await _dio.get(
      'app-version/$appName',
      queryParameters: {'platform': platform},
    );
  }
}
