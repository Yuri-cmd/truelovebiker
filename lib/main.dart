import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:screen_protector/screen_protector.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:truelovebiker/core/bindings/initial_binding.dart';
import 'package:truelovebiker/core/routes/app_pages.dart';
import 'package:truelovebiker/core/theme/app_theme.dart';
import 'package:truelovebiker/core/theme/theme_notifier.dart';
import 'package:truelovebiker/data/services/firebase_api.dart';
import 'package:truelovebiker/data/services/timer_service.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler);
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } on FirebaseException catch (e) {
    if (e.code != 'duplicate-app') rethrow;
  }

  await FirebaseApi().initNotifications();

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
  @override
  void dispose() {
    ScreenProtector.preventScreenshotOff();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, mode, _) {
        return GetMaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Truelove Driver',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: mode,
          initialRoute: AppPages.INITIAL,
          initialBinding: InitialBinding(),
          getPages: AppPages.routes,
          defaultTransition: Transition.cupertino,
        );
      },
    );
  }
}
