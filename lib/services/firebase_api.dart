import 'dart:developer';

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
    try{
      // Solicitar permisos
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        log("Permisos de notificación concedidos");
      }

      // Obtener el token de FCM
      String? token = await _firebaseMessaging.getToken();
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('token_fcm', token!);
      final idUser = await ApiService.getUsuarioId();
      if (idUser != null) {
        ApiService.updateFcmToken(idUser, token);
      }
    
      // Configurar flutter_local_notifications
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const InitializationSettings initSettings =
          InitializationSettings(android: androidSettings);

      await _flutterLocalNotificationsPlugin.initialize(initSettings);

      // Crear canales de notificación
      await _createNotificationChannels();

      // Manejar notificaciones en primer plano
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        _showNotification(message);
      });

      // Manejar notificaciones cuando la app está en segundo plano pero abierta
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        log('Notificación abierta: ${message.notification?.title}');
      });
    } catch (e) {
      log('Error inicializando notificaciones: $e');
    }
  }

  Future<void> _createNotificationChannels() async {
    try {
      // Canal para pedidos con sonido personalizado
      const AndroidNotificationChannel pedidosChannelWithSound = AndroidNotificationChannel(
        'pedidos_channel',
        'Nuevos Pedidos',
        description: 'Notificaciones de nuevos pedidos con sonido personalizado',
        importance: Importance.max,
        sound: RawResourceAndroidNotificationSound('nuevo_pedido'),
        enableVibration: true,
        enableLights: true,
        ledColor: Colors.red,
        showBadge: true,
      );

      // Canal para notificaciones generales sin sonido personalizado
      const AndroidNotificationChannel generalChannel = AndroidNotificationChannel(
        'general_channel',
        'Notificaciones Generales',
        description: 'Notificaciones generales del sistema',
        importance: Importance.high,
        enableVibration: true,
        enableLights: true,
        showBadge: true,
      );

      // Canal básico de respaldo
      const AndroidNotificationChannel basicChannel = AndroidNotificationChannel(
        'basic_channel',
        'Notificaciones Básicas',
        description: 'Canal básico de notificaciones',
        importance: Importance.high,
        enableVibration: true,
        showBadge: true,
      );

      final androidImplementation = _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        // Intentar crear el canal con sonido personalizado
        try {
          await androidImplementation.createNotificationChannel(pedidosChannelWithSound);
        } catch (e) {
          log('❌ Error creando canal con sonido personalizado: $e');
        }

        // Crear canales de respaldo
        try {
          await androidImplementation.createNotificationChannel(generalChannel);
        } catch (e) {
          log('❌ Error creando canal general: $e');
        }

        try {
          await androidImplementation.createNotificationChannel(basicChannel);
        } catch (e) {
          log('❌ Error creando canal básico: $e');
        }
      } else {
        log('❌ No se pudo obtener la implementación de Android');
      }
    } catch (e) {
      log('❌ Error general creando canales: $e');
      log('Stack trace: ${e.toString()}');
    }
  }

  Future<void> _showNotification(RemoteMessage message) async {
    try {
      // Obtener el sonido del data payload, notification.android, o data click_action
      String? soundFile = message.data['sound'] ?? 
                         message.notification?.android?.sound;
      
      // También verificar si viene en el click_action como indicador
      bool isNewOrder = message.data['click_action'] == 'FLUTTER_NOTIFICATION_CLICK' &&
                       (soundFile == 'nuevo_pedido' || message.data.containsKey('sound'));
      
      // Determinar qué tipo de notificación mostrar
      if ((soundFile != null && soundFile == 'nuevo_pedido') || isNewOrder) {
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
    try {
      
      final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'pedidos_channel',
        'Nuevos Pedidos',
        channelDescription: 'Notificaciones de nuevos pedidos con sonido personalizado',
        importance: Importance.max,
        priority: Priority.max,
        sound: const RawResourceAndroidNotificationSound('nuevo_pedido'),
        playSound: true,
        enableVibration: true,
        enableLights: true,
        ledColor: Colors.red,
        ledOnMs: 1000,
        ledOffMs: 500,
        autoCancel: false,
        ongoing: false,
        showWhen: true,
        when: DateTime.now().millisecondsSinceEpoch,
      );

      final NotificationDetails details = NotificationDetails(android: androidDetails);

      int notificationId = DateTime.now().millisecondsSinceEpoch.remainder(100000);

      await _flutterLocalNotificationsPlugin.show(
        notificationId,
        message.notification?.title ?? "🛒 Nuevo Pedido",
        message.notification?.body ?? "Tienes un nuevo pedido disponible",
        details,
      );
    } catch (e) {
      // Fallback a notificación de pedido sin sonido personalizado
      await _showPedidoNotificationFallback(message);
    }
  }

  // Notificación de pedido sin sonido personalizado (fallback)
  Future<void> _showPedidoNotificationFallback(RemoteMessage message) async {
    try {
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'general_channel',
        'Notificaciones Generales',
        channelDescription: 'Notificaciones de pedidos sin sonido personalizado',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        enableLights: true,
        ledColor: Colors.orange,
        ledOnMs: 1000,
        ledOffMs: 500,
      );

      const NotificationDetails details = NotificationDetails(android: androidDetails);

      await _flutterLocalNotificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch.remainder(100000),
        message.notification?.title ?? "🛒 Nuevo Pedido",
        message.notification?.body ?? "Tienes un nuevo pedido",
        details,
      );
    } catch (e) {
      log('Error con notificación de pedido fallback: $e');
    }
  }

  // Notificación general sin sonido personalizado
  Future<void> _showGeneralNotification(RemoteMessage message) async {
    try {
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'general_channel',
        'Notificaciones Generales',
        channelDescription: 'Notificaciones generales del sistema',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        enableLights: true,
      );

      const NotificationDetails details = NotificationDetails(android: androidDetails);

      await _flutterLocalNotificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch.remainder(100000),
        message.notification?.title ?? "Nueva notificación",
        message.notification?.body ?? "Tienes una nueva notificación",
        details,
      );
      
    } catch (e) {
      log('Error mostrando notificación general: $e');
    }
  }

  // Notificación de respaldo básica
  Future<void> _showFallbackNotification(RemoteMessage message) async {
    try {
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'basic_channel',
        'Notificaciones Básicas',
        channelDescription: 'Canal básico de notificaciones',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        enableLights: true,
      );

      const NotificationDetails details = NotificationDetails(android: androidDetails);

      await _flutterLocalNotificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch.remainder(100000),
        message.notification?.title ?? "Nueva notificación",
        message.notification?.body ?? "Tienes una nueva notificación",
        details,
      );
    } catch (e) {
      log('Error mostrando notificación de respaldo: $e');
    }
  }

  // Función para probar notificaciones con sonido personalizado
  Future<void> testCustomSoundNotification() async {
    try {
      
      final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'pedidos_channel',
        'Nuevos Pedidos',
        channelDescription: 'Prueba de sonido personalizado',
        importance: Importance.max,
        priority: Priority.max,
        sound: const RawResourceAndroidNotificationSound('nuevo_pedido'),
        playSound: true,
        enableVibration: true,
        enableLights: true,
        ledColor: Colors.red,
        ledOnMs: 1000,
        ledOffMs: 500,
      );

      final NotificationDetails details = NotificationDetails(android: androidDetails);

      await _flutterLocalNotificationsPlugin.show(
        999,
        "🧪 Prueba de Sonido",
        "Esta es una prueba del sonido personalizado",
        details,
      );
      
    } catch (e) {
      log('Error en notificación de prueba: $e');
    }
  }
}