import 'package:get/get.dart';
import 'package:truelovebiker/features/orders/controllers/pedidos_controller.dart';
import 'package:truelovebiker/features/orders/controllers/active_trips_controller.dart';
import 'package:truelovebiker/features/orders/controllers/order_history_controller.dart';

class OrdersBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PedidosController>(() => PedidosController());
    Get.lazyPut<ActiveTripsController>(() => ActiveTripsController());
    Get.lazyPut<OrderHistoryController>(() => OrderHistoryController());
  }
}
