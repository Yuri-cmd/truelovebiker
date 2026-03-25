import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:truelovebiker/data/services/version_check_service.dart';
import 'package:truelovebiker/core/routes/app_pages.dart';
import 'package:truelovebiker/core/storage/secure_storage.dart';
import 'package:url_launcher/url_launcher.dart';

class SplashController extends GetxController {
  final VersionCheckService _versionService = VersionCheckService();

  @override
  void onInit() {
    super.onInit();
    initializeApp();
  }

  Future<void> initializeApp() async {
    try {
      await Future.delayed(const Duration(seconds: 2));
      // Añadimos un timeout de 10 segundos para no bloquear la app si el servidor no responde
      final versionInfo = await _versionService.checkVersion().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          return {'needsUpdate': false};
        },
      );

      if (versionInfo['needsUpdate'] == true &&
          versionInfo['forceUpdate'] == true) {
        final String updateUrl = versionInfo['updateUrl'] ?? '';
        Get.defaultDialog(
          title: "Actualización Obligatoria",
          middleText: "Debes actualizar la aplicación para continuar.",
          barrierDismissible: false,
          textConfirm: "Actualizar ahora",
          confirmTextColor: Colors.white,
          onConfirm: () async {
            if (updateUrl.isNotEmpty) {
              final Uri uri = Uri.parse(updateUrl);
              if (await canLaunchUrl(uri)) {
                await launchUrl(
                  uri,
                  mode: LaunchMode.externalApplication,
                );
              }
            }
          },
        );
      } else {
        await checkSession();
      }
    } catch (e) {
      await checkSession();
    }
  }

  Future<void> checkSession() async {
    final token = await SecureStorage.getToken();
    final user = await SecureStorage.getUser();
    
    if (token != null && token.isNotEmpty && user != null) {
      Get.offAllNamed(Routes.HOME);
    } else {
      Get.offAllNamed(Routes.LOGIN);
    }
  }

  void goToLogin() {
    // Usamos offAllNamed para asegurar que limpiamos el stack de navegación
    Get.offAllNamed(Routes.LOGIN);
  }
}
