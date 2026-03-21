import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:truelovebiker/data/services/profile_service.dart';

class EditProfileController extends GetxController {
  final ProfileService _profileService = Get.find<ProfileService>();
  
  final Map<String, dynamic> repartidor;
  EditProfileController({required this.repartidor});

  final formKey = GlobalKey<FormState>();
  late TextEditingController celularController;
  late TextEditingController emailController;
  late TextEditingController departamentoController;
  
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    celularController = TextEditingController(text: repartidor['celular'] ?? "");
    emailController = TextEditingController(text: repartidor['email'] ?? "");
    departamentoController = TextEditingController(text: repartidor['departamento'] ?? "");
  }

  @override
  void onClose() {
    celularController.dispose();
    emailController.dispose();
    departamentoController.dispose();
    super.onClose();
  }

  Future<void> save() async {
    if (formKey.currentState!.validate()) {
      try {
        isLoading.value = true;
        final response = await _profileService.updateBikerInfo(
          id: repartidor['id'],
          cellul: celularController.text.trim(),
          email: emailController.text.trim(),
          department: departamentoController.text.trim(),
        );

        if (response.statusCode == 200) {
          final data = response.data;
          Get.back(result: data['repartidor']);
          Get.snackbar(
            'Éxito', 
            data['mensaje'] ?? "Datos actualizados.",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green,
            colorText: Colors.white,
            margin: const EdgeInsets.all(15),
            borderRadius: 10,
          );
        } else {
          isLoading.value = false;
          Get.snackbar(
            'Error', 
            'Error al actualizar datos.',
            backgroundColor: Colors.redAccent, 
            colorText: Colors.white,
            snackPosition: SnackPosition.BOTTOM,
            margin: const EdgeInsets.all(15),
            borderRadius: 10,
            icon: const Icon(Icons.error_outline, color: Colors.white),
          );
        }
      } catch (e) {
        isLoading.value = false;
        Get.snackbar(
          'Error', 
          e.toString(),
          backgroundColor: Colors.redAccent, 
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(15),
          borderRadius: 10,
          icon: const Icon(Icons.error_outline, color: Colors.white),
        );
      }
    }
  }
}
