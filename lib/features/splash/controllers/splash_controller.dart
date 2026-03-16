import 'package:get/get.dart';
import 'package:truelovebiker/data/services/version_check_service.dart';
import 'package:truelovebiker/core/routes/app_pages.dart';

class SplashController extends GetxController {
  final VersionCheckService _versionService = VersionCheckService();

  @override
  void onInit() {
    super.onInit();
    initializeApp();
  }

  Future<void> initializeApp() async {
    await Future.delayed(const Duration(seconds: 2));

    final versionInfo = await _versionService.checkVersion();

    if (versionInfo['needsUpdate'] == true &&
        versionInfo['forceUpdate'] == true) {
      // Logic for mandatory update dialog can be handled in the UI 
      // or by emitting a state. For now, we'll keep it simple.
      // But usually we can navigate to an UpdateScreen or show a dialog from the UI.
    } else {
      goToLogin();
    }
  }

  void goToLogin() {
    Get.offNamed(Routes.LOGIN);
  }
}
