import 'package:get/get.dart';
import 'package:truelovebiker/features/orders/controllers/pedidos_controller.dart';
import 'package:truelovebiker/features/orders/controllers/active_trips_controller.dart';
import 'package:truelovebiker/features/orders/controllers/order_history_controller.dart';

class OrdersBinding extends Bindings {
  @override
  void dependencies() {
    // fenix: true recrea el controlador si GetX lo borró. Sin esto, al abrir Inicio otra vez
    // (offAllNamed estando ya en Inicio) la ruta vieja se elimina después de crear la nueva y le
    // borra los controladores: la pantalla nueva fallaba con '"ActiveTripsController" not found'.
    Get.lazyPut<PedidosController>(() => PedidosController(), fenix: true);
    Get.lazyPut<ActiveTripsController>(() => ActiveTripsController(), fenix: true);
    Get.lazyPut<OrderHistoryController>(() => OrderHistoryController(), fenix: true);
  }
}
