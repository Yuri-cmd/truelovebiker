import 'package:get/get.dart';
import 'package:truelovebiker/features/profile/controllers/change_password_controller.dart';

class ChangePasswordBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ChangePasswordController>(() => ChangePasswordController(userId: Get.arguments));
  }
}
