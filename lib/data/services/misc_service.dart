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

  /// Qué sabe el servidor de las notificaciones de este repartidor (token, avisos confirmados).
  Future<Response> diagnosticoNotificaciones(int idMotorizado, String? token) async {
    return await _dio.post(
      '/notifications/diagnostico/motorizado/$idMotorizado',
      data: {'token': token},
    );
  }

  /// Manda un aviso de prueba a este repartidor.
  Future<Response> probarNotificacion(int idMotorizado) async {
    return await _dio.post('/notifications/diagnostico/motorizado/$idMotorizado/probar');
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
