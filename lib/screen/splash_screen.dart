// ignore_for_file: library_private_types_in_public_api

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:truelovebiker/theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Navega a la pantalla de login después de 3 segundos
    Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacementNamed(context, '/login');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SizedBox(
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            BounceInDown(
                duration: const Duration(seconds: 2),
                child: const Column(
                  children: [
                    Image(
                      image: AssetImage("images/logo.png"),
                    ),
                    SizedBox(
                      height: 10,
                    ),
                  ],
                )),
            const SizedBox(height: 50),
            const SpinKitFadingCube(
              color: AppTheme.primary,
              size: 50.0,
            )
          ],
        ),
      ),
    );
  }
}
