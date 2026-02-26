// ignore_for_file: library_private_types_in_public_api

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:truelovebiker/theme/app_theme.dart';
import 'package:truelovebiker/services/version_check_service.dart';
import 'package:url_launcher/url_launcher.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final VersionCheckService _versionService = VersionCheckService();

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Pequeña espera para que la animación se vea
    await Future.delayed(const Duration(seconds: 2));

    final versionInfo = await _versionService.checkVersion();

    if (versionInfo['needsUpdate'] == true &&
        versionInfo['forceUpdate'] == true) {
      _showUpdateDialog(versionInfo['updateUrl'], true);
    } else if (versionInfo['hasNewerVersion'] == true) {
      // Si hay una nueva versión pero no es obligatoria, simplemente seguir adelante.
      _goToLogin();
    } else {
      _goToLogin();
    }
  }

  void _goToLogin() {
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  void _showUpdateDialog(String url, bool isMandatory) {
    showDialog(
      context: context,
      barrierDismissible: !isMandatory,
      builder:
          (context) => AlertDialog(
            title: const Text('Actualización Necesaria'),
            content: const Text(
              'Hay una nueva versión obligatoria disponible. Por favor, actualiza la aplicación para continuar.',
            ),
            actions: [
              if (!isMandatory)
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Más tarde'),
                ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                ),
                onPressed: () async {
                  if (await canLaunchUrl(Uri.parse(url))) {
                    await launchUrl(
                      Uri.parse(url),
                      mode: LaunchMode.externalApplication,
                    );
                  }
                },
                child: const Text(
                  'Actualizar ahora',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );
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
