import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:truelovebiker/features/profile/controllers/ratings_controller.dart';
import 'package:truelovebiker/data/models/rating_model.dart';

class RatingsScreen extends GetView<RatingsController> {
  const RatingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calificaciones', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        elevation: 3,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.hasError.value) {
          return _buildErrorWidget(controller.errorMessage.value);
        }

        if (controller.calificaciones.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: controller.loadRatings,
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: controller.calificaciones.length,
            itemBuilder: (context, index) {
              final item = controller.calificaciones[index];
              return _buildRatingCard(item);
            },
          ),
        );
      }),
    );
  }

  Widget _buildRatingCard(RatingModel item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.blueAccent,
                  child: Text(
                    item.cliente.nombre.isNotEmpty ? item.cliente.nombre[0].toUpperCase() : '?',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.cliente.nombre, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Row(
                        children: List.generate(5, (i) {
                          return Icon(
                            i < (item.rating?.motorcycleRating ?? 0) ? Icons.star : Icons.star_border,
                            color: Colors.amber,
                            size: 20,
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 6),
            Text(item.rating?.motorcycleComment ?? 'Sin comentarios', style: TextStyle(fontSize: 14, color: Colors.grey[700])),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.sentiment_dissatisfied, size: 80, color: Colors.grey),
          SizedBox(height: 10),
          Text('No hay calificaciones disponibles.', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 60, color: Colors.red),
            const SizedBox(height: 10),
            Text('Error al cargar datos: $error', textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, color: Colors.red)),
          ],
        ),
      ),
    );
  }
}
