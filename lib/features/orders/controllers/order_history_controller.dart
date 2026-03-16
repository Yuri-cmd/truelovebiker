import 'package:get/get.dart';
import 'package:truelovebiker/core/storage/secure_storage.dart';
import 'package:truelovebiker/data/models/pedido_historico_model.dart';
import 'package:truelovebiker/data/services/order_service.dart';

class OrderHistoryController extends GetxController {
  final OrderService _orderService = Get.find<OrderService>();
  
  final pedidos = <PedidoHistorico>[].obs;
  final isLoading = true.obs;
  final hasError = false.obs;
  final errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadHistory();
  }

  Future<void> loadHistory() async {
    isLoading.value = true;
    hasError.value = false;
    errorMessage.value = '';
    try {
      final int? idBiker = await SecureStorage.getBikerId();
      if (idBiker == null) return;

      final response = await _orderService.getOrderHistory(idBiker);
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        pedidos.assignAll(data.map((p) => PedidoHistorico.fromJson(p)).toList());
      }
    } catch (e) {
      hasError.value = true;
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }
}
