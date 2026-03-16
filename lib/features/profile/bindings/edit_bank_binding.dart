import 'package:get/get.dart';
import 'package:truelovebiker/features/profile/controllers/edit_bank_controller.dart';

class EditBankBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<EditBankController>(() => EditBankController(cuentaBancaria: Get.arguments));
  }
}
