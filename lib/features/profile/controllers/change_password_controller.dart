import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:truelovebiker/core/routes/app_pages.dart';
import 'package:truelovebiker/data/services/auth_service.dart';

class ChangePasswordController extends GetxController {
  final int userId;
  ChangePasswordController({required this.userId});

  final AuthService _authService = Get.find<AuthService>();
  final passwordController = TextEditingController();
  final isLoading = false.obs;
  final errorMessage = ''.obs;

  @override
  void onClose() {
    passwordController.dispose();
    super.onClose();
  }

  Future<void> changePassword() async {
    final newPassword = passwordController.text.trim();

    if (newPassword.isEmpty) {
      errorMessage.value = 'La contraseña no puede estar vacía';
      return;
    }

    isLoading.value = true;
    errorMessage.value = '';

    try {
      final response = await _authService.updatePassword(userId, newPassword);
      isLoading.value = false;
      
      final data = response.data;
      final success = response.statusCode == 200;
      _showAlert(data['message'] ?? (success ? "Éxito" : "Error"), success);
    } catch (e) {
      isLoading.value = false;
      Get.snackbar(
        'Error', 
        'Error de conexión: $e',
        backgroundColor: Colors.redAccent, 
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(15),
        borderRadius: 10,
        icon: const Icon(Icons.error_outline, color: Colors.white),
      );
    }
  }

  void _showAlert(String message, bool success) {
    Get.dialog(
      AlertDialog(
        title: Text(success ? "Éxito" : "Error"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
              if (success) {
                Get.offAllNamed(Routes.LOGIN);
              }
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }
}
