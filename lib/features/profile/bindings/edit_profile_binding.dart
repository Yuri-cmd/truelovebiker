import 'package:get/get.dart';
import 'package:truelovebiker/features/profile/controllers/edit_profile_controller.dart';

class EditProfileBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<EditProfileController>(() => EditProfileController(repartidor: Get.arguments));
  }
}
