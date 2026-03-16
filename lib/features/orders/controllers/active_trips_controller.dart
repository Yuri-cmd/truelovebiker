import 'dart:async';
import 'package:get/get.dart';
import 'package:truelovebiker/core/storage/secure_storage.dart';
import 'package:truelovebiker/data/models/pedido_model.dart';
import 'package:truelovebiker/data/services/order_service.dart';
import 'package:truelovebiker/data/services/timer_service.dart';

class ActiveTripsController extends GetxController {
  final OrderService _orderService = Get.find<OrderService>();
  final TimerService _timerService = Get.find<TimerService>();
  
  final pedidos = <Pedido>[].obs;
  final isLoading = true.obs;
  final hasError = false.obs;
  final errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadActiveTrips();
  }

  Future<void> loadActiveTrips() async {
    isLoading.value = true;
    hasError.value = false;
    errorMessage.value = '';
    try {
      final int? idBiker = await SecureStorage.getBikerId();
      if (idBiker == null) return;

      final response = await _orderService.getViajesActivos(idBiker);
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        pedidos.assignAll(data.map((p) => Pedido.fromJson(p)).toList());
        _startTimers();
      }
    } catch (e) {
      hasError.value = true;
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  void _startTimers() {
    for (var pedido in pedidos) {
      if (!_timerService.isTimerRunningForPedido(pedido.id)) {
        _timerService.startTimerForPedido(
          pedido.id,
          onTick: () => update(),
        );
      }
    }
  }

  String getElapsedTime(int pedidoId) {
    final elapsed = _timerService.getElapsedTimeForPedidoSync(pedidoId);
    final minutes = elapsed.inMinutes;
    final seconds = elapsed.inSeconds % 60;
    
    if (minutes < 60) {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      final hours = minutes ~/ 60;
      final mins = minutes % 60;
      return '${hours}h ${mins.toString().padLeft(2, '0')}m';
    }
  }

  Future<void> refreshTrips() async {
    await loadActiveTrips();
  }
}
