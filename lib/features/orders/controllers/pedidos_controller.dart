import 'dart:async';
import 'package:get/get.dart';
import 'package:truelovebiker/core/storage/secure_storage.dart';
import 'package:truelovebiker/data/models/pedido_model.dart';
import 'package:truelovebiker/data/services/order_service.dart';

class PedidosController extends GetxController {
  final OrderService _orderService = Get.find<OrderService>();
  
  final pedidos = <Pedido>[].obs;
  final isLoading = true.obs;
  final hasError = false.obs;
  final errorMessage = ''.obs;
  Timer? _timer;

  @override
  void onInit() {
    super.onInit();
    loadPedidos();
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      loadPedidos();
    });
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }

  Future<void> loadPedidos() async {
    isLoading.value = true;
    hasError.value = false;
    errorMessage.value = '';
    try {
      final int? idBiker = await SecureStorage.getBikerId();
      if (idBiker == null) return;

      final response = await _orderService.getPedidos(idBiker);
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        pedidos.assignAll(data.map((p) => Pedido.fromJson(p)).toList());
      }
    } catch (e) {
      hasError.value = true;
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshPedidos() async {
    await loadPedidos();
  }
}
