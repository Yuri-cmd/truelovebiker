import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:truelovebiker/core/storage/secure_storage.dart';
import 'package:truelovebiker/data/services/auth_service.dart';
import 'package:truelovebiker/data/services/profile_service.dart';
import 'package:truelovebiker/core/routes/app_pages.dart';

class ProfileController extends GetxController {
  final ProfileService _profileService = Get.find<ProfileService>();
  final AuthService _authService = Get.find<AuthService>();

  final repartidor = Rxn<Map<String, dynamic>>();
  final usuario = Rxn<Map<String, dynamic>>();
  final cuentaBancaria = Rxn<Map<String, dynamic>>();
  final isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    cargarPerfil();
  }

  Future<void> cargarPerfil() async {
    isLoading.value = true;
    try {
      final int? idBiker = await SecureStorage.getBikerId();
      if (idBiker == null) return;

      final response = await _profileService.getBikerProfile(idBiker);
      if (response.statusCode == 200) {
        final data = response.data;
        repartidor.value = data['repartidor'];
        usuario.value = data['usuario'];
        cuentaBancaria.value = data['cuentaBancaria'];
      }
    } catch (e) {
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> cambiarEstadoRepartidor() async {
    if (repartidor.value == null) return;
    
    final nuevoEstado = repartidor.value!['activo'] == 1 ? 0 : 1;
    final int? idBiker = repartidor.value!['id'];
    if (idBiker == null) return;

    final response = await _authService.updateBikerStatus(idBiker, nuevoEstado);

    if (response.statusCode == 200) {
      repartidor.update((val) {
        val!['activo'] = nuevoEstado;
      });
      Get.snackbar(
        'Éxito', 
        'Estado actualizado correctamente.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        margin: const EdgeInsets.all(15),
        borderRadius: 10,
      );
    } else {
      Get.snackbar(
        'Error', 
        'Error al actualizar el estado.',
        backgroundColor: Colors.redAccent, 
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(15),
        borderRadius: 10,
        icon: const Icon(Icons.error_outline, color: Colors.white),
      );
    }
  }

  Future<bool> actualizarFotoPerfil(File imagen) async {
    if (repartidor.value == null) return false;
    final int? idBiker = repartidor.value!['id'];
    if (idBiker == null) return false;

    try {
      final response = await _profileService.actualizarFotoPerfil(idBiker, imagen);
      if (response.statusCode == 200) {
        final fotoUrl = response.data['foto_perfil_url'];
        repartidor.update((val) {
          val!['foto_perfil_url'] = fotoUrl;
        });
        return true;
      }
    } catch (e) {}

    Get.snackbar(
      'Error',
      'No se pudo actualizar la foto de perfil.',
      backgroundColor: Colors.redAccent,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(15),
      borderRadius: 10,
      icon: const Icon(Icons.error_outline, color: Colors.white),
    );
    return false;
  }

  Future<void> cerrarSesion() async {
    await SecureStorage.clearSession();
    Get.offAllNamed(Routes.LOGIN);
  }

  Future<void> eliminarCuenta() async {
    final response = await _authService.deleteAccount();
    if (response.statusCode == 200) {
      await cerrarSesion();
      Get.snackbar(
        'Éxito', 
        'Cuenta eliminada correctamente.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        margin: const EdgeInsets.all(15),
        borderRadius: 10,
      );
    } else {
      Get.snackbar(
        'Error', 
        'Error al eliminar la cuenta.',
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
