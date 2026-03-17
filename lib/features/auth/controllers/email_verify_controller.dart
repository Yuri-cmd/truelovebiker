import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:truelovebiker/core/routes/app_pages.dart';
import 'package:truelovebiker/data/services/auth_service.dart';

class EmailVerifyController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();
  
  final inputController = TextEditingController();
  final codeController = TextEditingController();

  final isLoading = false.obs;
  final errorMessage = ''.obs;
  final userId = 0.obs;
  final correctCode = ''.obs;
  final codeSent = false.obs;

  @override
  void onClose() {
    inputController.dispose();
    codeController.dispose();
    super.onClose();
  }

  Future<void> handleAction() async {
    isLoading.value = true;
    errorMessage.value = '';

    if (!codeSent.value) {
      final input = inputController.text.trim();
      if (input.isEmpty) {
        errorMessage.value = 'Este campo no puede estar vacío';
        isLoading.value = false;
        return;
      }

      try {
        final response = await _authService.sendCode(input);
        isLoading.value = false;

        if (response.statusCode == 200) {
          final data = response.data;
          userId.value = data['id'];
          correctCode.value = data['verification_code']?.toString() ?? '';
          codeSent.value = true;
          _showMessage(data['message'], true);
        } else {
          _showMessage('Error al enviar código', false);
        }
      } on DioException catch (e) {
        isLoading.value = false;
        if (e.response != null && e.response!.data != null) {
          final data = e.response!.data;
          errorMessage.value = data['message'] ?? 'Error de servidor (${e.response!.statusCode})';
        } else {
          errorMessage.value = 'Error de conexión: ${e.message}';
        }
      } catch (e) {
        isLoading.value = false;
        errorMessage.value = 'Error inesperado: $e';
      }
    } else {
      final code = codeController.text.trim();
      if (code.isEmpty) {
        errorMessage.value = 'Ingresa el código';
        isLoading.value = false;
        return;
      }

      if (code == correctCode.value) {
        isLoading.value = false;
        Get.toNamed(Routes.CHANGE_PASSWORD, arguments: userId.value);
      } else {
        errorMessage.value = 'Código incorrecto';
        isLoading.value = false;
      }
    }
  }

  void _showMessage(String message, bool success) {
    Get.dialog(
      AlertDialog(
        title: Text(success ? 'Éxito' : 'Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }
}
