import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:truelovebiker/features/orders/controllers/rating_controller.dart';

class RatingScreen extends GetView<OrderRatingController> {
  const RatingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Califica tu experiencia"),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Icon(Icons.star_rate_rounded, size: 80, color: Colors.amber),
            const SizedBox(height: 16),
            const Text(
              "¡Pedido Entregado!",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "Tu opinión es muy importante para nosotros.",
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            _buildRatingCard(
              title: "¿Cómo calificarías al restaurante?",
              ratingValue: controller.restaurantRating,
              commentController: controller.restaurantCommentController,
              onRatingUpdate: controller.updateRestaurantRating,
            ),
            const SizedBox(height: 24),
            _buildRatingCard(
              title: "¿Qué te pareció el cliente?",
              ratingValue: controller.clientRating,
              commentController: controller.clientCommentController,
              onRatingUpdate: controller.updateClientRating,
            ),
            const SizedBox(height: 48),
            Obx(() => controller.isLoading.value
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: () => controller.submitRating(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text(
                      "ENVIAR CALIFICACIÓN",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  )),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () => Get.offAllNamed('/home'),
              child: const Text("Saltar por ahora", style: TextStyle(color: Colors.grey)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingCard({
    required String title,
    required RxInt ratingValue,
    required TextEditingController commentController,
    required Function(int) onRatingUpdate,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Obx(() => Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return IconButton(
                      icon: Icon(
                        index < ratingValue.value ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 36,
                      ),
                      onPressed: () => onRatingUpdate(index + 1),
                    );
                  }),
                )),
            const SizedBox(height: 12),
            TextField(
              controller: commentController,
              decoration: InputDecoration(
                hintText: "Déjanos un comentario adicional...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }
}
