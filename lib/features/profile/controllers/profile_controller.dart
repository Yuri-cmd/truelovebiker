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
      Get.snackbar('Éxito', 'Estado actualizado correctamente.');
    } else {
      Get.snackbar('Error', 'Error al actualizar el estado.');
    }
  }

  Future<void> cerrarSesion() async {
    await SecureStorage.clearSession();
    Get.offAllNamed(Routes.LOGIN);
  }

  Future<void> eliminarCuenta() async {
    final response = await _authService.deleteAccount();
    if (response.statusCode == 200) {
      await cerrarSesion();
      Get.snackbar('Éxito', 'Cuenta eliminada correctamente.');
    } else {
      Get.snackbar('Error', 'Error al eliminar la cuenta.');
    }
  }
}
