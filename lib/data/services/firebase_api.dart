// ignore_for_file: avoid_print

import 'dart:developer';
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/services.dart';
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
  log('📩 [DIAG][BG] id=${message.messageId} notification=${message.notification?.title} data=${message.data}');
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

  /// Guarda el token en local y lo envía al backend. Un fallo del envío se registra
  /// aparte (antes se confundía con un fallo de getToken()).
  Future<void> _guardarYEnviarToken(String token, String origen) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token_fcm', token);
    final idUser = prefs.getInt('id_biker');
    if (idUser == null) {
      log('⚠️ [DIAG][$origen] token guardado en local pero NO enviado al back: no hay id_biker (sin sesión iniciada). Se enviará al iniciar sesión.');
      return;
    }
    try {
      final r = await AuthService().updateFcmToken(idUser, token);
      log('📤 [DIAG][$origen] token enviado al back id_biker=$idUser http=${r.statusCode} respuesta=${r.data}');
    } catch (e) {
      log('❌ [DIAG][$origen] error enviando token al back id_biker=$idUser: $e');
    }
  }

  /// iOS a veces tarda más de 10 s en entregar el token APNs. Si falló al arrancar,
  /// se sigue intentando en segundo plano (hasta ~2 min) sin bloquear la app.
  Future<void> _reintentarTokenIOS() async {
    for (var i = 0; i < 40; i++) {
      await Future.delayed(const Duration(seconds: 3));
      try {
        final r = await const MethodChannel('app.channel.apns').invokeMethod('reaplicarApnsToken');
        if (r != 'OK') continue;
        final token = await _firebaseMessaging.getToken();
        if (token == null) continue;
        log('✅ [DIAG] Token FCM obtenido en reintento #${i + 1}: $token');
        await _guardarYEnviarToken(token, 'reintento');
        return;
      } catch (e) {
        log('⚠️ [DIAG] fallo en reintento #${i + 1}: $e');
      }
    }
    log('❌ [DIAG] No se obtuvo el token APNs/FCM tras reintentar ~2 min');
  }

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
      log('🔔 [DIAG] permiso=${settings.authorizationStatus} alert=${settings.alert} '
          'sound=${settings.sound} badge=${settings.badge} lockScreen=${settings.lockScreen} '
          'center=${settings.notificationCenter} timeSensitive=${settings.timeSensitive}');

      // iOS entrega el token APNs al arrancar, antes de que Firebase esté listo,
      // y Firebase lo descarta: se vuelve a aplicar desde el AppDelegate.
      // El token puede tardar unos segundos en llegar: se reintenta hasta 10 s.
      if (Platform.isIOS) {
        var ultimo = '?';
        for (var i = 0; i < 20; i++) {
          try {
            ultimo = '${await const MethodChannel('app.channel.apns').invokeMethod('reaplicarApnsToken')}';
            if (ultimo == 'OK') break;
          } catch (e) {
            log('No se pudo reaplicar el token APNs: $e');
            break;
          }
          await Future.delayed(const Duration(milliseconds: 500));
        }
        log('🔁 [DIAG] reaplicar token APNs tras esperar: $ultimo');
        try {
          final apns = await _firebaseMessaging.getAPNSToken();
          log('🍎 [DIAG] APNs token (hex, para probar directo en la consola de Apple): $apns');
        } catch (_) {}
      }

      // Si falla (p. ej. APNs aún no disponible en iOS) no se aborta el resto
      // de la inicialización.
      SharedPreferences prefs = await SharedPreferences.getInstance();
      try {
        String? token = await _firebaseMessaging.getToken();
        log(
          token != null
              ? "✅ Token FCM obtenido: $token"
              : "❌ No se pudo obtener el token FCM",
        );
        if (token != null) {
          await _guardarYEnviarToken(token, 'arranque');
        }
      } catch (e) {
        log('⚠️ getToken() falló, onTokenRefresh entregará el token: $e');
        if (Platform.isIOS) _reintentarTokenIOS();
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
        log('📩 [DIAG][FG] id=${message.messageId} notification=${message.notification?.title} sound=${message.notification?.apple?.sound?.name} data=${message.data}');
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
        await _guardarYEnviarToken(newToken, 'onTokenRefresh');
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
            // largeIcon: const DrawableResourceAndroidBitmap(
            //   '@mipmap/ic_launcher',
            // ),
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
            // largeIcon: const DrawableResourceAndroidBitmap(
            //   '@mipmap/ic_launcher',
            // ),
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
