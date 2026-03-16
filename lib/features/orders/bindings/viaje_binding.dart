import 'package:get/get.dart';
import 'package:truelovebiker/features/orders/controllers/viaje_controller.dart';

class ViajeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ViajeController>(() => ViajeController(pedido: Get.arguments));
  }
}
