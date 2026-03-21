import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:truelovebiker/data/services/rating_service.dart';
import 'package:truelovebiker/core/routes/app_pages.dart';

class OrderRatingController extends GetxController {
  final RatingService _ratingService = Get.find<RatingService>();
  
  final int idPedido = Get.arguments as int;
  
  final restaurantRating = 0.obs;
  final clientRating = 0.obs;
  
  final restaurantCommentController = TextEditingController();
  final clientCommentController = TextEditingController();
  
  final isLoading = false.obs;

  final Map<int, String> defaultComments = {
    1: "Muy malo. No lo recomiendo.",
    2: "Podría mejorar bastante.",
    3: "Aceptable, pero no excelente.",
    4: "Muy bueno, quedé satisfecho.",
    5: "¡Excelente servicio! Totalmente recomendado.",
  };

  void updateRestaurantRating(int value) {
    restaurantRating.value = value;
    if (defaultComments.containsKey(value)) {
      restaurantCommentController.text = defaultComments[value]!;
    }
  }

  void updateClientRating(int value) {
    clientRating.value = value;
    if (defaultComments.containsKey(value)) {
      clientCommentController.text = defaultComments[value]!;
    }
  }

  Future<void> submitRating() async {
    if (restaurantRating.value == 0 || clientRating.value == 0) {
      Get.snackbar(
        'Error', 
        'Por favor califica ambas opciones', 
        backgroundColor: Colors.redAccent, 
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(15),
        borderRadius: 10,
        icon: const Icon(Icons.error_outline, color: Colors.white),
      );
      return;
    }

    isLoading.value = true;
    try {
      final response = await _ratingService.submitRating(
        idPedido: idPedido,
        restaurantRating: restaurantRating.value,
        restaurantComment: restaurantCommentController.text,
        motorcycleRating: clientRating.value, // Usamos este campo para el cliente
        motorcycleComment: clientCommentController.text,
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        Get.snackbar(
          'Éxito', 
          'Calificación enviada correctamente',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          margin: const EdgeInsets.all(15),
          borderRadius: 10,
        );
        Get.offAllNamed(Routes.HOME);
      } else {
        Get.snackbar(
          'Error', 
          'No se pudo enviar la calificación',
          backgroundColor: Colors.redAccent, 
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(15),
          borderRadius: 10,
          icon: const Icon(Icons.error_outline, color: Colors.white),
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error', 
        'Ocurrió un error al enviar la calificación',
        backgroundColor: Colors.redAccent, 
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(15),
        borderRadius: 10,
        icon: const Icon(Icons.error_outline, color: Colors.white),
      );
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    restaurantCommentController.dispose();
    clientCommentController.dispose();
    super.onClose();
  }
}
