import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:truelovebiker/data/services/profile_service.dart';

class EditBankController extends GetxController {
  final ProfileService _profileService = Get.find<ProfileService>();
  
  final Map<String, dynamic> cuentaBancaria;
  EditBankController({required this.cuentaBancaria});

  final formKey = GlobalKey<FormState>();
  late TextEditingController titularController;
  late TextEditingController dniController;
  late TextEditingController numeroCuentaController;

  final bancos = <Map<String, dynamic>>[].obs;
  final tiposCuenta = <Map<String, dynamic>>[].obs;
  final selectedBancoId = Rxn<int>();
  final selectedTipoCuentaId = Rxn<int>();
  final isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    titularController = TextEditingController(text: cuentaBancaria['titular'] ?? "");
    dniController = TextEditingController(text: cuentaBancaria['dni'] ?? "");
    numeroCuentaController = TextEditingController(text: cuentaBancaria['numero_cuenta'] ?? "");
    selectedBancoId.value = cuentaBancaria['banco']?['id'];
    selectedTipoCuentaId.value = cuentaBancaria['tipo_cuenta']?['id'];
    loadData();
  }

  Future<void> loadData() async {
    try {
      final responseBancos = await _profileService.getBancos();
      final responseTipos = await _profileService.getTiposCuenta();
      
      if (responseBancos.statusCode == 200 && responseTipos.statusCode == 200) {
        final List<dynamic> bancosList = responseBancos.data;
        final List<dynamic> tiposCuentaList = responseTipos.data;
        bancos.assignAll(bancosList.cast<Map<String, dynamic>>());
        tiposCuenta.assignAll(tiposCuentaList.cast<Map<String, dynamic>>());
      }
    } catch (e) {
      Get.snackbar(
        'Error', 
        'Error al cargar bancos y tipos de cuenta',
        backgroundColor: Colors.redAccent, 
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(15),
        borderRadius: 10,
        icon: const Icon(Icons.error_outline, color: Colors.white),
      );
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    titularController.dispose();
    dniController.dispose();
    numeroCuentaController.dispose();
    super.onClose();
  }

  Future<void> save() async {
    if (formKey.currentState!.validate()) {
      try {
        isLoading.value = true;
        final response = await _profileService.updateBankAccount(
          id: cuentaBancaria['id'],
          titular: titularController.text.trim(),
          dni: dniController.text.trim(),
          bancoId: selectedBancoId.value!,
          tipoCuentaId: selectedTipoCuentaId.value!,
          numeroCuenta: numeroCuentaController.text.trim(),
        );

        if (response.statusCode == 200) {
          final data = response.data;
          Get.back(result: data['cuenta_bancaria']);
          Get.snackbar(
            'Éxito', 
            data['mensaje'] ?? "Datos bancarios actualizados.",
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
            'Error al actualizar datos bancarios.',
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
