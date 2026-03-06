import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:truelovebiker/screen/login_screen.dart';
import 'package:truelovebiker/screen/splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:truelovebiker/services/api.dart';
import 'package:truelovebiker/services/firebase_api.dart';
import 'package:truelovebiker/services/timer_service.dart';
import 'firebase_options.dart';
import 'package:screen_protector/screen_protector.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 1. ValueNotifier global para el ThemeMode
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.system);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // IMPORTANTE: registrar el background handler ANTES de initializeApp
  FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler);
  // try-catch es más robusto que Firebase.apps.isEmpty para evitar duplicate-app
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } on FirebaseException catch (e) {
    if (e.code != 'duplicate-app') rethrow;
    // Si ya existe, Firebase está listo — no es un error real
  }

  await FirebaseApi().initNotifications();

  // 2. Cargar preferencia del tema antes de runApp
  final prefs = await SharedPreferences.getInstance();
  String? themePref = prefs.getString('themeMode');
  if (themePref == 'light') {
    themeNotifier.value = ThemeMode.light;
  } else if (themePref == 'dark') {
    themeNotifier.value = ThemeMode.dark;
  } else {
    themeNotifier.value = ThemeMode.system;
  }

  // ✨ Inicializar TimerService al arrancar la app
  final timerService = TimerService();
  await timerService.initializeOnAppStart();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Timer? _locationTimer;
  bool _isTrackingLocation = false;

  @override
  void initState() {
    super.initState();
    _startLocationTracking();
  }

  @override
  void dispose() {
    // Cancelar el timer de ubicación
    _locationTimer?.cancel();
    // Opcional: desactiva la protección si quieres limpiar al salir
    ScreenProtector.preventScreenshotOff();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, mode, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Truelove Driver',
          theme: ThemeData.light(useMaterial3: true),
          darkTheme: ThemeData.dark(useMaterial3: true),
          themeMode: mode,
          initialRoute: '/',
          routes: {
            '/': (context) => const SplashScreen(),
            '/login': (context) => const LoginScreen(),
          },
        );
      },
    );
  }

  //Function to track location periodically
  Future<void> _startLocationTracking() async {
    _locationTimer = Timer.periodic(const Duration(seconds: 10), (Timer timer) async {
      // Verificar si el widget aún está montado y no hay una operación en progreso
      if (!mounted || _isTrackingLocation) {
        return;
      }
      
      _isTrackingLocation = true;
      
      try {
        Position position = await _getCurrentLocation();
        await _sendLocationToServer(position);
        print('Location sent successfully: ${position.latitude}, ${position.longitude}');
      } catch (e) {
        print('Error tracking location: $e');
        // Opcional: podrías mostrar un snackbar o log más específico
      } finally {
        if (mounted) {
          _isTrackingLocation = false;
        }
      }
    });
  }

  // Get the current location
  Future<Position> _getCurrentLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        throw Exception('Location permissions are denied');
      }
    }
    
    // Verificar si los servicios de ubicación están habilitados
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled');
    }
    
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: const Duration(seconds: 10),
    );
  }

  // Send the location data to the server
  Future<void> _sendLocationToServer(Position position) async {
    try {
      await ApiService.sendLocationData(position.latitude, position.longitude);
    } catch (e) {
      print('Error sending location to server: $e');
      // Re-lanzar la excepción para que sea manejada en el nivel superior
      rethrow;
    }
  }
}

// 4. Función para cambiar y persistir el theme
Future<void> setThemeMode(ThemeMode mode) async {
  final prefs = await SharedPreferences.getInstance();
  themeNotifier.value = mode;
  String modeString = 'system';
  if (mode == ThemeMode.light) {
    modeString = 'light';
  } else if (mode == ThemeMode.dark) {
    modeString = 'dark';
  }
  await prefs.setString('themeMode', modeString);
}
