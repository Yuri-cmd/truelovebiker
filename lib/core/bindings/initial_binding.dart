import 'package:get/get.dart';
import 'package:truelovebiker/core/controllers/location_controller.dart';
import 'package:truelovebiker/data/services/auth_service.dart';
import 'package:truelovebiker/data/services/order_service.dart';
import 'package:truelovebiker/data/services/profile_service.dart';
import 'package:truelovebiker/data/services/rating_service.dart';
import 'package:truelovebiker/data/services/chat_service.dart';
import 'package:truelovebiker/data/services/misc_service.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(AuthService(), permanent: true);
    Get.put(OrderService(), permanent: true);
    Get.put(ProfileService(), permanent: true);
    Get.put(RatingService(), permanent: true);
    Get.put(ChatService(), permanent: true);
    Get.put(MiscService(), permanent: true);
    Get.put(LocationController(), permanent: true);
  }
}
