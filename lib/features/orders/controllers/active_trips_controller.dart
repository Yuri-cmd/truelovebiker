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
  final expandedCards = <int>{}.obs;
  Timer? _refreshTimer;
  Timer? _uiUpdateTimer;

  void _onTimerTick() => update();

  void toggleExpanded(int id) {
    if (expandedCards.contains(id)) {
      expandedCards.remove(id);
    } else {
      expandedCards.add(id);
    }
  }

  @override
  void onInit() {
    super.onInit();
    loadActiveTrips();
    _startAutoRefresh();
    _startUIUpdateTimer();
  }

  @override
  void onClose() {
    _refreshTimer?.cancel();
    _uiUpdateTimer?.cancel();
    super.onClose();
  }

  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      loadActiveTrips();
    });
  }

  void _startUIUpdateTimer() {
    _uiUpdateTimer?.cancel();
    _uiUpdateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      update(); // Updates GetBuilder listeners
    });
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
      // Intentar obtener la fecha de inicio del servidor
      DateTime? startTime;
      final String? fInicio = pedido.fechaHoraInicio ?? pedido.fechaInicio;
      if (fInicio != null) {
        try {
          startTime = DateTime.parse(fInicio);
        } catch (e) {}
      }

      // Siempre llamamos a startTimer para sincronizar el tiempo
      _timerService.startTimerForPedido(
        pedido.id,
        startTime: startTime,
        onTick: _onTimerTick,
      );
    }
  }

  String getElapsedTime(int pedidoId) {
    final elapsed = _timerService.getElapsedTimeForPedidoSync(pedidoId);
    if (elapsed.inSeconds == 0) return '00:00';

    // Buscar el pedido para obtener su tiempo asignado
    final pedido = pedidos.firstWhereOrNull((p) => p.id == pedidoId);
    
    // Obtenemos el tiempo total para el pedido (en minutos)
    final int tiempoTotalMinutos = (pedido != null && pedido.tiempo > 0) ? pedido.tiempo : 30;
    final int tiempoTotalSegundos = tiempoTotalMinutos * 60;
    
    // Calculamos el tiempo restante
    final int restanteSegundos = tiempoTotalSegundos - elapsed.inSeconds;

    if (restanteSegundos <= 0) return 'Vencido';

    final minutes = restanteSegundos ~/ 60;
    final seconds = restanteSegundos % 60;

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
