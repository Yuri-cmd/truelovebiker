import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:truelovebiker/core/theme/app_theme.dart';
import 'package:truelovebiker/features/splash/controllers/splash_controller.dart';

class SplashScreen extends GetView<SplashController> {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // We don't need initState because SplashController.onInit handles logic
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
              ),
            ),
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
