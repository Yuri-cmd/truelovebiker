import 'package:get/get.dart';
import 'package:truelovebiker/features/profile/controllers/profile_controller.dart';
import 'package:truelovebiker/features/profile/controllers/ratings_controller.dart';

class ProfileBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ProfileController>(() => ProfileController());
    Get.lazyPut<RatingsController>(() => RatingsController());
  }
}
