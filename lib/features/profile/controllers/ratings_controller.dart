import 'package:get/get.dart';
import 'package:truelovebiker/core/storage/secure_storage.dart';
import 'package:truelovebiker/data/models/rating_model.dart';
import 'package:truelovebiker/data/services/rating_service.dart';

class RatingsController extends GetxController {
  final RatingService _ratingService = Get.find<RatingService>();
  
  final calificaciones = <RatingModel>[].obs;
  final isLoading = true.obs;
  final hasError = false.obs;
  final errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadRatings();
  }

  Future<void> loadRatings() async {
    isLoading.value = true;
    hasError.value = false;
    errorMessage.value = '';
    try {
      final int? idBiker = await SecureStorage.getBikerId();
      if (idBiker == null) return;

      final response = await _ratingService.getBikerRatings(idBiker);
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        calificaciones.assignAll(data.map((r) => RatingModel.fromJson(r)).toList());
      }
    } catch (e) {
      hasError.value = true;
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }
}
