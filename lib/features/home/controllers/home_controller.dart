import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:truelovebiker/core/storage/secure_storage.dart';
import 'package:truelovebiker/data/services/order_service.dart';
import 'package:truelovebiker/core/controllers/location_controller.dart';

class HomeController extends GetxController with WidgetsBindingObserver {
  final OrderService _orderService = Get.find<OrderService>();
  
  final selectedIndex = 0.obs;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    checkViajeActivo();
    
    // Iniciamos el rastreo de ubicación cuando el usuario ya está en el Home
    try {
      if (Get.isRegistered<LocationController>()) {
        Get.find<LocationController>().startLocationTracking();
      }
    } catch (e) {
    }
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      checkViajeActivo();
    }
  }

  Future<void> checkViajeActivo() async {
    try {
      final int? idBiker = await SecureStorage.getBikerId();
      if (idBiker == null) return;

      final response = await _orderService.getViajesActivos(idBiker);
      if (response.statusCode == 200) {
        final List<dynamic> viajesActivos = response.data;
        if (viajesActivos.isNotEmpty) {
          if (viajesActivos.length == 1) {
            selectedIndex.value = 0; // Or whatever default is best
          } else if (viajesActivos.length > 1) {
            selectedIndex.value = 1; // Index for active trips
          }
        }
      }
    } catch (e) {
    }
  }

  void onItemTapped(int index) {
    selectedIndex.value = index;
  }
}
