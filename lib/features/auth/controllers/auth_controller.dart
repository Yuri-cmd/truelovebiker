import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:truelovebiker/core/storage/secure_storage.dart';
import 'package:truelovebiker/data/services/auth_service.dart';
import 'package:truelovebiker/data/models/biker_model.dart';
import 'package:truelovebiker/core/routes/app_pages.dart';

class AuthController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  
  final isButtonActive = false.obs;
  final isObscure = true.obs;
  final isLoading = false.obs;
  final biker = Rxn<Biker>();

  @override
  void onInit() {
    super.onInit();
    emailController.addListener(updateButtonState);
    passwordController.addListener(updateButtonState);
    loadSavedUser();
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  void updateButtonState() {
    isButtonActive.value =
        emailController.text.isNotEmpty &&
        passwordController.text.isNotEmpty;
  }

  void togglePasswordVisibility() {
    isObscure.value = !isObscure.value;
  }

  Future<void> loadSavedUser() async {
    final userStr = await SecureStorage.getUser();
    if (userStr != null) {
      biker.value = Biker.fromJson(jsonDecode(userStr));
    }
  }

  Future<void> login() async {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) return;
    
    isLoading.value = true;
    try {
      final response = await _authService.login(
        emailController.text.trim(),
        passwordController.text.trim(),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['status'] == 'success') {
          final bikerData = data['repartidor'];
          final userData = data['user'];
          final token = data['token'];

          // Save Session
          await SecureStorage.saveToken(token);
          await SecureStorage.saveUser(jsonEncode(bikerData));
          await SecureStorage.saveUserId(userData['id']);
          await SecureStorage.saveBikerId(bikerData['id']);

          // Compatibility with SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', token);
          await prefs.setInt('usuario_id', userData['id']);
          await prefs.setInt('id_biker', bikerData['id']);
          await prefs.setString('biker', jsonEncode(bikerData));

          biker.value = Biker.fromJson(bikerData);

          // Verify Conditions
          final condResponse = await _authService.checkBikerConditions(bikerData['id']);
          if (condResponse.statusCode == 200) {
            final condiciones = condResponse.data;
            if (condiciones['puede_trabajar'] == true) {
              // Update FCM Token if exists
              String? tokenFcm = prefs.getString('token_fcm');
              if (tokenFcm == null || tokenFcm.isEmpty) {
                tokenFcm = await FirebaseMessaging.instance.getToken();
                if (tokenFcm != null) await prefs.setString('token_fcm', tokenFcm);
              }

              if (tokenFcm != null && tokenFcm.isNotEmpty) {
                await _authService.updateFcmToken(bikerData['id'], tokenFcm);
              }
              
              Get.offAllNamed(Routes.HOME);
            } else {
              await logout();
              mostrarAlerta(condiciones['mensaje'] ?? 'No autorizado');
            }
          }
        } else {
        Get.snackbar(
          'Error', 
          data['message'] ?? 'Credenciales incorrectas', 
          backgroundColor: Colors.redAccent, 
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(15),
          borderRadius: 10,
          duration: const Duration(seconds: 4),
          icon: const Icon(Icons.error_outline, color: Colors.white),
        );
        }
      } else {
        Get.snackbar(
          'Error', 
          'Error en el servidor', 
          backgroundColor: Colors.redAccent, 
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(15),
          borderRadius: 10,
          duration: const Duration(seconds: 4),
          icon: const Icon(Icons.error_outline, color: Colors.white),
        );
      }
    } catch (e) {
      String errorMessage = 'Error de conexión';
      if (e is DioException && e.response != null) {
        final data = e.response!.data;
        if (data is Map && data['message'] != null) {
          errorMessage = data['message'];
        } else if (data is Map && data['error'] != null) {
          errorMessage = data['error'];
        }
      } else {
        errorMessage = 'Error: $e';
      }
      Get.snackbar(
        'Error', 
        errorMessage, 
        backgroundColor: Colors.redAccent, 
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(15),
        borderRadius: 10,
        duration: const Duration(seconds: 4),
        icon: const Icon(Icons.error_outline, color: Colors.white),
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    await SecureStorage.clearSession();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('usuario_id');
    await prefs.remove('id_biker');
    await prefs.remove('biker');
    biker.value = null;
    Get.offAllNamed(Routes.LOGIN);
  }

  void mostrarAlerta(String mensaje) {
    Get.dialog(
      AlertDialog(
        title: const Text('Acceso denegado'),
        content: Text(mensaje),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
