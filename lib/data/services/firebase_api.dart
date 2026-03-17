// ignore_for_file: avoid_print

import 'dart:developer';
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:truelovebiker/data/services/auth_service.dart';
import 'package:truelovebiker/data/services/misc_service.dart';

String _getValidTitle(RemoteMessage message, String defaultTitle) {
  if (message.notification?.title != null && message.notification!.title!.isNotEmpty) {
    return message.notification!.title!;
  }
  final dataTitle = message.data['title']?.toString();
  if (dataTitle != null && dataTitle.isNotEmpty) {
    return dataTitle;
  }
  return defaultTitle;
}

String _getValidBody(RemoteMessage message, String defaultBody) {
  if (message.notification?.body != null && message.notification!.body!.isNotEmpty) {
    return message.notification!.body!;
  }
  final dataBody = message.data['body']?.toString();
  if (dataBody != null && dataBody.isNotEmpty) {
    return dataBody;
  }
  return defaultBody;
}

@pragma('vm:entry-point')
Future<void> firebaseBackgroundHandler(RemoteMessage message) async {
  final notificationId = message.data['notification_id'];
  if (notificationId != null && notificationId.isNotEmpty) {
    await MiscService().acknowledgeNotification(notificationId, 'received');
  }

  if (Platform.isIOS && message.notification != null) {
    return;
  }

  final plugin = FlutterLocalNotificationsPlugin();
  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const iosSettings = DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );
  await plugin.initialize(const InitializationSettings(android: androidSettings, iOS: iosSettings));

  final androidPlugin = plugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
  await androidPlugin?.createNotificationChannel(
    const AndroidNotificationChannel(
      'pedidos_v7',
      'Nuevos Pedidos',
      importance: Importance.max,
      sound: RawResourceAndroidNotificationSound('nuevo_pedido'),
      enableVibration: true,
    ),
  );

  final title = _getValidTitle(message, 'Nuevo Pedido');
  final body = _getValidBody(message, 'Tienes un nuevo pedido');
  final soundFile = message.data['sound'] ?? 'nuevo_pedido';
  final channelId = message.data['channel_id'] ?? 'pedidos_v7';

  await plugin.show(
    DateTime.now().millisecondsSinceEpoch.remainder(100000),
    title,
    body,
    NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        'Nuevos Pedidos',
        importance: Importance.max,
        priority: Priority.max,
        sound: RawResourceAndroidNotificationSound(soundFile),
        playSound: true,
        enableVibration: true,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        presentBanner: true,
        presentList: true,
        sound: soundFile.endsWith('.wav') ? soundFile : '$soundFile.wav',
      ),
    ),
  );
}

class FirebaseApi {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initNotifications() async {
    try {
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
        criticalAlert: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        log("Permisos de notificación concedidos");
      }

      String? token = await _firebaseMessaging.getToken();
      log(
        token != null
            ? "✅ Token FCM obtenido: $token"
            : "❌ No se pudo obtener el token FCM",
      );
      SharedPreferences prefs = await SharedPreferences.getInstance();
      if (token != null) {
        await prefs.setString('token_fcm', token);
        final idUser = prefs.getInt('id_biker');
        if (idUser != null) {
          await AuthService().updateFcmToken(idUser, token);
        }
      }

      if (Platform.isIOS) {
        await _firebaseMessaging.setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
      }

      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
          
      const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
        requestCriticalPermission: true,
      );

      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _flutterLocalNotificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (details) {
          log("Notificación clickeada: ${details.payload}");
        },
      );

      await _createNotificationChannels();

      RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        final notificationId = initialMessage.data['notification_id'];
        if (notificationId != null) {
          MiscService().acknowledgeNotification(notificationId, 'received');
          MiscService().acknowledgeNotification(notificationId, 'opened');
        }
        log('App abierta desde notificación cerrada: ${initialMessage.notification?.title}');
      }

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        log('Notificación recibida. Notification: ${message.notification?.title}, Data: ${message.data}');
        final notificationId = message.data['notification_id'];
        if (notificationId != null) {
          MiscService().acknowledgeNotification(notificationId, 'received');
        }
        
        if (Platform.isAndroid || message.notification == null) {
          _showNotification(message);
        }
      });

      _firebaseMessaging.onTokenRefresh.listen((newToken) async {
        log("🔄 Token FCM refrescado: $newToken");
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('token_fcm', newToken);
        final idUser = prefs.getInt('id_biker');
        if (idUser != null) {
          await AuthService().updateFcmToken(idUser, newToken);
        }
      });

      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        log('Notificación abierta: ${message.notification?.title}');
        final notificationId = message.data['notification_id'];
        if (notificationId != null) {
          MiscService().acknowledgeNotification(notificationId, 'opened');
        }
      });
    } catch (e) {
      log('❌ Error inicializando notificaciones: $e');
    }
  }

  Future<void> testNotification(RemoteMessage message) async {
    await _showNotification(message);
  }

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
      const String channelId = 'pedidos_v7';
      const String altChannelId = 'pedidos_alt_v3';

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

      const AndroidNotificationChannel generalChannel =
          AndroidNotificationChannel(
            'general_channel',
            'Notificaciones Generales',
            description: 'Notificaciones generales del sistema',
            importance: Importance.high,
            enableVibration: true,
            enableLights: true,
          );

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

      await androidPlugin?.createNotificationChannel(pedidosChannelWithSound);
      await androidPlugin?.createNotificationChannel(pedidosChannelAlternative);
      await androidPlugin?.createNotificationChannel(generalChannel);
      await androidPlugin?.createNotificationChannel(basicChannel);
    } catch (e) {
      print('❌ Error general creando canales: $e');
    }
  }

  Future<void> _showNotification(RemoteMessage message) async {
    try {
      String? soundFile = message.data['sound'];
      if (soundFile != null && soundFile == 'nuevo_pedido') {
        await _showPedidoNotification(message);
      } else {
        await _showGeneralNotification(message);
      }
    } catch (e) {
      await _showFallbackNotification(message);
    }
  }

  Future<void> _showPedidoNotification(RemoteMessage message) async {
    const String channelId = 'pedidos_v7';
    const String altChannelId = 'pedidos_alt_v3';

    bool success = await _tryShowPedidoWithCustomSound(
      message,
      channelId,
      'nuevo_pedido',
    );

    if (!success) {
      success = await _tryShowPedidoWithCustomSound(
        message,
        altChannelId,
        'pedido_sound',
      );
    }

    if (!success) {
      await _showPedidoNotificationFallback(message);
    }
  }

  Future<bool> _tryShowPedidoWithCustomSound(
    RemoteMessage message,
    String channelId,
    String soundFile,
  ) async {
    try {
      final vibrationPattern = Int64List.fromList([0, 200, 100, 200, 100, 200, 100, 400, 200, 400, 200, 400]);

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
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          presentBanner: true,
          presentList: true,
          sound: soundFile.endsWith('.wav') ? soundFile : '$soundFile.wav',
        ),
      );

      await _flutterLocalNotificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch.remainder(100000),
        _getValidTitle(message, '🛒 Nuevo Pedido'),
        _getValidBody(message, 'Tienes un nuevo pedido'),
        details,
      );

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> _showPedidoNotificationFallback(RemoteMessage message) async {
    try {
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
            vibrationPattern: vibrationPattern,
            enableLights: true,
            ledColor: Colors.orange,
            ledOnMs: 1000,
            ledOffMs: 500,
            ongoing: false,
            autoCancel: true,
            showWhen: true,
            largeIcon: const DrawableResourceAndroidBitmap(
              '@mipmap/ic_launcher',
            ),
          );

      NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          presentBanner: true,
          presentList: true,
          sound: 'default',
        ),
      );

      await _flutterLocalNotificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch.remainder(100000),
        _getValidTitle(message, '🛒 Nuevo Pedido 🔔'),
        _getValidBody(message, 'Tienes un nuevo pedido'),
        details,
      );
    } catch (e) {
      print('❌ Error con notificación de pedido fallback: $e');
    }
  }

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
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          presentBanner: true,
          presentList: true,
          sound: 'default',
        ),
      );

      await _flutterLocalNotificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch.remainder(100000),
        _getValidTitle(message, 'Nueva notificación'),
        _getValidBody(message, 'Tienes una nueva notificación'),
        details,
      );
    } catch (e) {
      print('Error mostrando notificación general: $e');
    }
  }

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
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          presentBanner: true,
          presentList: true,
          sound: 'default',
        ),
      );

      await _flutterLocalNotificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch.remainder(100000),
        _getValidTitle(message, 'Nueva notificación'),
        _getValidBody(message, 'Tienes una nueva notificación'),
        details,
      );
    } catch (e) {
      print('Error mostrando notificación de respaldo: $e');
    }
  }
}
