import 'package:get/get.dart';
import 'package:truelovebiker/features/orders/controllers/order_detail_controller.dart';

class OrderDetailBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<OrderDetailController>(() => OrderDetailController(pedidoMap: Get.arguments));
  }
}
