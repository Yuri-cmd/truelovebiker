import 'package:get/get.dart';
import 'package:truelovebiker/features/orders/controllers/rating_controller.dart';

class RatingBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<OrderRatingController>(() => OrderRatingController());
  }
}
