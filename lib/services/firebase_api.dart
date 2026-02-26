// ignore_for_file: avoid_print

import 'dart:developer';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:truelovebiker/services/api.dart';

class FirebaseApi {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initNotifications() async {
    try {
      // Solicitar permisos
      NotificationSettings settings = await _firebaseMessaging
          .requestPermission(alert: true, badge: true, sound: true);

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        log("Permisos de notificación concedidos");
      }

      // Obtener el token de FCM
      String? token = await _firebaseMessaging.getToken();
      log(
        token != null
            ? "✅ Token FCM obtenido: $token"
            : "❌ No se pudo obtener el token FCM",
      );
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('token_fcm', token!);
      final idUser = await ApiService.getUsuarioId();
      if (idUser != null) {
        ApiService.updateFcmToken(idUser, token);
      }

      // Configurar flutter_local_notifications
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
      );

      await _flutterLocalNotificationsPlugin.initialize(initSettings);

      // Crear canales de notificación
      await _createNotificationChannels();

      // Manejo de notificaciones recibidas
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        log('Notificación recibida: ${message.notification?.title}');
        final notificationId = message.data['notification_id'];
        ApiService.acknowledgeNotification(notificationId, 'received');
        _showNotification(message);
      });

      // Manejar el refresco del token
      _firebaseMessaging.onTokenRefresh.listen((newToken) async {
        log("🔄 Token FCM refrescado: $newToken");
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('token_fcm', newToken);
        final idUser = await ApiService.getUsuarioId();
        if (idUser != null) {
          ApiService.updateFcmToken(idUser, newToken);
        }
      });

      // Manejar notificaciones cuando la app está en segundo plano pero abierta
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        log('Notificación abierta: ${message.notification?.title}');
        final notificationId = message.data['notification_id'];
        ApiService.acknowledgeNotification(notificationId, 'opened');
      });
    } catch (e) {
      log('❌ Error inicializando notificaciones: $e');
    }
  }

  // Método público para testing
  Future<void> testNotification(RemoteMessage message) async {
    await _showNotification(message);
  }

  // Método para probar inmediatamente las notificaciones de pedidos
  Future<void> testPedidoNotification() async {
    final testMessage = RemoteMessage(
      notification: const RemoteNotification(
        title: '🛒 Test Nuevo Pedido',
        body: 'Esta es una notificación de prueba',
      ),
      data: {'sound': 'nuevo_pedido', 'type': 'test'},
    );

    await _showPedidoNotification(testMessage);
  }

  Future<void> _createNotificationChannels() async {
    try {
      // Usar IDs únicos para forzar recreación (v7) - IMPORTANTE: actualizar en backend también
      const String channelId = 'pedidos_v7';
      const String altChannelId = 'pedidos_alt_v7';

      final AndroidNotificationChannel pedidosChannelWithSound =
          AndroidNotificationChannel(
            channelId,
            'Nuevos Pedidos',
            description:
                'Notificaciones de nuevos pedidos con sonido personalizado',
            importance: Importance.max,
            sound: const RawResourceAndroidNotificationSound('nuevo_pedido'),
            enableVibration: true,
            enableLights: true,
            ledColor: const Color(0xFF00FF00),
          );

      final AndroidNotificationChannel pedidosChannelAlternative =
          AndroidNotificationChannel(
            altChannelId,
            'Nuevos Pedidos Alt',
            description: 'Canal alternativo para pedidos',
            importance: Importance.max,
            sound: const RawResourceAndroidNotificationSound('pedido_sound'),
            enableVibration: true,
            enableLights: true,
          );

      // Canal para notificaciones generales sin sonido personalizado
      const AndroidNotificationChannel generalChannel =
          AndroidNotificationChannel(
            'general_channel',
            'Notificaciones Generales',
            description: 'Notificaciones generales del sistema',
            importance: Importance.high,
            enableVibration: true,
            enableLights: true,
          );

      // Canal básico de respaldo
      const AndroidNotificationChannel basicChannel =
          AndroidNotificationChannel(
            'basic_channel',
            'Notificaciones Básicas',
            description: 'Canal básico de notificaciones',
            importance: Importance.high,
            enableVibration: true,
            enableLights: true,
          );

      final androidPlugin =
          _flutterLocalNotificationsPlugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();

      // Forzar eliminación de canales anteriores
      const bool forceRecreateChannels = true;
      if (forceRecreateChannels) {
        try {
          // Eliminar canales anteriores para asegurar que se apliquen los nuevos ajustes (v1, v2)
          await androidPlugin?.deleteNotificationChannel('pedidos_channel');
          await androidPlugin?.deleteNotificationChannel('pedidos_channel_v2');
          await androidPlugin?.deleteNotificationChannel('pedidos_debug_v1');
          await androidPlugin?.deleteNotificationChannel('pedidos_release_v1');
          await androidPlugin?.deleteNotificationChannel(
            'pedidos_alt_debug_v1',
          );
          await androidPlugin?.deleteNotificationChannel(
            'pedidos_alt_release_v1',
          );
          await androidPlugin?.deleteNotificationChannel(
            'pedidos_channel_alt_v2',
          );
        } catch (delErr) {
          print('⚠️ Error al eliminar canales anteriores: $delErr');
        }
      }

      // Intentar crear el canal principal con sonido personalizado
      try {
        await androidPlugin?.createNotificationChannel(pedidosChannelWithSound);
      } catch (e) {
        // Intentar canal alternativo
        try {
          await androidPlugin?.createNotificationChannel(
            pedidosChannelAlternative,
          );
        } catch (e2) {
          print('❌ Error con canal alternativo: $e2');
        }
      }

      // Crear canales de respaldo
      await androidPlugin?.createNotificationChannel(generalChannel);
      await androidPlugin?.createNotificationChannel(basicChannel);
    } catch (e) {
      print('❌ Error general creando canales: $e');
    }
  }

  Future<void> _showNotification(RemoteMessage message) async {
    try {
      // Logging detallado para debug
      String? soundFile = message.data['sound'];
      // Determinar qué tipo de notificación mostrar
      if (soundFile != null && soundFile == 'nuevo_pedido') {
        await _showPedidoNotification(message);
      } else {
        await _showGeneralNotification(message);
      }
    } catch (e) {
      await _showFallbackNotification(message);
    }
  }

  // Notificación para nuevos pedidos con sonido personalizado
  Future<void> _showPedidoNotification(RemoteMessage message) async {
    const String channelId = 'pedidos_v7';
    const String altChannelId = 'pedidos_alt_v7';

    // Primero intentar con el canal principal
    bool success = await _tryShowPedidoWithCustomSound(
      message,
      channelId,
      'nuevo_pedido',
    );

    if (!success) {
      // Intentar con canal alternativo
      success = await _tryShowPedidoWithCustomSound(
        message,
        altChannelId,
        'pedido_sound',
      );
    }

    if (!success) {
      // Fallback final
      await _showPedidoNotificationFallback(message);
    }
  }

  Future<bool> _tryShowPedidoWithCustomSound(
    RemoteMessage message,
    String channelId,
    String soundFile,
  ) async {
    try {
      final vibrationPattern = Int64List.fromList([
        0,
        200,
        100,
        200,
        100,
        200,
        100,
        400,
        200,
        400,
        200,
        400,
      ]);

      final AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            channelId,
            'Nuevos Pedidos',
            channelDescription:
                'Notificaciones de nuevos pedidos con sonido personalizado',
            importance: Importance.max,
            priority: Priority.max,
            sound: RawResourceAndroidNotificationSound(soundFile),
            playSound: true,
            enableVibration: true,
            vibrationPattern: vibrationPattern,
            enableLights: true,
            ledColor: Colors.green,
            ledOnMs: 1000,
            ledOffMs: 500,
            ongoing: false,
            autoCancel: true,
            showWhen: true,
            when: DateTime.now().millisecondsSinceEpoch,
            largeIcon: const DrawableResourceAndroidBitmap(
              '@mipmap/ic_launcher',
            ),
            category: AndroidNotificationCategory.call,
          );

      NotificationDetails details = NotificationDetails(
        android: androidDetails,
      );

      await _flutterLocalNotificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch.remainder(100000),
        message.notification?.title ?? "🛒 Nuevo Pedido",
        "${message.notification?.body ?? 'Tienes un nuevo pedido'}${channelId.contains('v3') ? '' : ' (Old)'}",
        details,
      );

      return true;
    } catch (e) {
      return false;
    }
  }

  // Notificación de pedido sin sonido personalizado (fallback)
  Future<void> _showPedidoNotificationFallback(RemoteMessage message) async {
    try {
      // Patrón de vibración personalizado para diferenciar pedidos
      final vibrationPattern = Int64List.fromList([0, 500, 200, 500, 200, 500]);

      final AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            'general_channel',
            'Notificaciones Generales',
            channelDescription:
                'Notificaciones de pedidos sin sonido personalizado',
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
            vibrationPattern: vibrationPattern, // Patrón único para pedidos
            enableLights: true,
            ledColor: Colors.orange,
            ledOnMs: 1000,
            ledOffMs: 500,
            // Hacer más visible para dispositivos físicos
            ongoing: false,
            autoCancel: true,
            showWhen: true,
            largeIcon: const DrawableResourceAndroidBitmap(
              '@mipmap/ic_launcher',
            ),
          );

      NotificationDetails details = NotificationDetails(
        android: androidDetails,
      );

      await _flutterLocalNotificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch.remainder(100000),
        "🛒 ${message.notification?.title ?? 'Nuevo Pedido'} 🔔",
        "${message.notification?.body ?? 'Tienes un nuevo pedido'} - Dispositivo físico",
        details,
      );
    } catch (e) {
      print('❌ Error con notificación de pedido fallback: $e');
    }
  }

  // Notificación general sin sonido personalizado
  Future<void> _showGeneralNotification(RemoteMessage message) async {
    try {
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            'general_channel',
            'Notificaciones Generales',
            channelDescription: 'Notificaciones generales del sistema',
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
            enableLights: true,
          );

      const NotificationDetails details = NotificationDetails(
        android: androidDetails,
      );

      await _flutterLocalNotificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch.remainder(100000),
        message.notification?.title ?? "Nueva notificación",
        message.notification?.body ?? "Tienes una nueva notificación",
        details,
      );
    } catch (e) {
      print('Error mostrando notificación general: $e');
    }
  }

  // Notificación de respaldo básica
  Future<void> _showFallbackNotification(RemoteMessage message) async {
    try {
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            'basic_channel',
            'Notificaciones Básicas',
            channelDescription: 'Canal básico de notificaciones',
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
            enableLights: true,
          );

      const NotificationDetails details = NotificationDetails(
        android: androidDetails,
      );

      await _flutterLocalNotificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch.remainder(100000),
        message.notification?.title ?? "Nueva notificación",
        message.notification?.body ?? "Tienes una nueva notificación",
        details,
      );
    } catch (e) {
      print('Error mostrando notificación de respaldo: $e');
    }
  }
}
