import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:truelovebiker/screen/login_screen.dart';
import 'package:truelovebiker/screen/splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:truelovebiker/services/api.dart';
import 'package:truelovebiker/services/firebase_api.dart';
import 'firebase_options.dart';
import 'package:screen_protector/screen_protector.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 1. ValueNotifier global para el ThemeMode
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.system);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    name: 'app dev',
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await FirebaseApi().initNotifications();

  // 🔐 Previene capturas de pantalla al iniciar
  await ScreenProtector.preventScreenshotOn();

  if (Platform.isIOS) {
    await ScreenProtector.protectDataLeakageWithBlur();
  }

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

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    _startLocationTracking();
  }

  @override
  void dispose() {
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
          title: 'Delivery True Love',
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

  //Funcction to track location periodically
  Future<void> _startLocationTracking() async {
    Timer.periodic(const Duration(seconds: 10), (Timer timer) async {
      Position position = await _getCurrentLocation();
      await _sendLocationToServer(position);
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
    return await Geolocator.getCurrentPosition();
  }

  // Send the location data to the server
  Future<void> _sendLocationToServer(Position position) async {
    await ApiService.sendLocationData(position.latitude, position.longitude);
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