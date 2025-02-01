import 'package:flutter/material.dart';
import 'package:truelovebiker/screen/login_screen.dart';
import 'package:truelovebiker/screen/splash_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Delivery True Love',
      // theme: ThemeData(
      //   primarySwatch: Colors.red,
      // ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) =>
            const LoginScreen(),
      },
    );
  }
}
