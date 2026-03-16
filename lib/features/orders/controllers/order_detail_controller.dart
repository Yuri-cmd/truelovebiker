import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:truelovebiker/core/routes/app_pages.dart';
import 'package:truelovebiker/core/storage/secure_storage.dart';
import 'package:truelovebiker/data/services/order_service.dart';

class OrderDetailController extends GetxController {
  final Map<String, dynamic> pedido;
  OrderDetailController({required this.pedido});

  final OrderService _orderService = Get.find<OrderService>();
  
  late LatLng localPosition;
  late LatLng customerPosition;
  late LatLngBounds bounds;

  @override
  void onInit() {
    super.onInit();
    localPosition = LatLng(
      double.tryParse(pedido['lat_local'].toString()) ?? 0.0,
      double.tryParse(pedido['lon_local'].toString()) ?? 0.0,
    );

    customerPosition = LatLng(
      double.tryParse(pedido['latitud'].toString()) ?? 0.0,
      double.tryParse(pedido['longitud'].toString()) ?? 0.0,
    );

    bounds = _calculateBounds(localPosition, customerPosition);
  }

  LatLngBounds _calculateBounds(LatLng point1, LatLng point2) {
    final latitudes = [point1.latitude, point2.latitude];
    final longitudes = [point1.longitude, point2.longitude];
    return LatLngBounds(
      LatLng(
        latitudes.reduce((a, b) => a < b ? a : b),
        longitudes.reduce((a, b) => a < b ? a : b),
      ),
      LatLng(
        latitudes.reduce((a, b) => a > b ? a : b),
        longitudes.reduce((a, b) => a > b ? a : b),
      ),
    );
  }

  Future<void> confirmStartTrip() async {
    final int? idBiker = await SecureStorage.getBikerId();

    if (idBiker == null) {
      Get.snackbar('Error', 'ID de repartidor no encontrado');
      return;
    }

    Get.dialog(
      AlertDialog(
        title: const Text('¿Iniciar viaje?'),
        content: const Text('¿Estás seguro de que deseas iniciar el viaje?'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancelar')),
          TextButton(
            onPressed: () async {
              Get.back();
              await _startTrip(idBiker, pedido['id']);
            },
            child: const Text('Iniciar viaje'),
          ),
        ],
      ),
    );
  }

  Future<void> _startTrip(int idBiker, int idPedido) async {
    try {
      final response = await _orderService.startTrip(idBiker, idPedido);
      if (response.statusCode == 200) {
        Get.snackbar('Éxito', 'Viaje iniciado');
        // Navigate to tracking screen
        Get.offNamed(Routes.ACTIVE_ORDER, arguments: pedido);
      } else {
        String errorMessage = 'Error al iniciar el viaje';
        final data = response.data;
        if (data is Map && data['message'] != null) errorMessage = data['message'];
        
        Get.snackbar('Error', errorMessage, backgroundColor: Colors.red, colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar('Error', 'Error de conexión: $e', backgroundColor: Colors.red, colorText: Colors.white);
    }
  }
}
