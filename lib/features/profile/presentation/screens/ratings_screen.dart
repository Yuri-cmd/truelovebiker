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
        title: const Text('Calificaciones'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        elevation: 0,
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
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: controller.calificaciones.length,
            itemBuilder: (context, index) {
              final item = controller.calificaciones[index];
              return _buildRatingCard(context, item);
            },
          ),
        );
      }),
    );
  }

  Widget _buildRatingCard(BuildContext context, RatingModel item) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;
    final rating = item.rating?.motorcycleRating ?? 0;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 40 : 15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isDark ? Colors.white.withAlpha(10) : Colors.grey.withAlpha(20),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade400, Colors.blue.shade700],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withAlpha(50),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      item.cliente.nombre.isNotEmpty ? item.cliente.nombre[0].toUpperCase() : '?',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.cliente.nombre,
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: -0.2),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Row(
                            children: List.generate(5, (i) {
                              return Icon(
                                i < rating ? Icons.star_rounded : Icons.star_rate_rounded,
                                color: i < rating ? Colors.amber : Colors.grey.withAlpha(60),
                                size: 22,
                              );
                            }),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            rating.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: colorScheme.onSurface.withAlpha(180),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            if (item.rating?.motorcycleComment != null && item.rating!.motorcycleComment.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Divider(height: 1),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withAlpha(5) : Colors.grey.withAlpha(10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  item.rating!.motorcycleComment,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    fontStyle: FontStyle.italic,
                    color: colorScheme.onSurface.withAlpha(200),
                  ),
                ),
              ),
            ] else ...[
              const SizedBox(height: 12),
              Text(
                "Sin comentarios adicionales",
                style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.onSurface.withAlpha(100),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Pedido #${item.idPedido}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.withAlpha(150),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.star_outline_rounded, size: 80, color: Colors.grey.withAlpha(100)),
          ),
          const SizedBox(height: 24),
          const Text(
            'Sin calificaciones aún',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tu buen servicio será recompensado pronto.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, size: 64, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(
              'Ups! Algo salió mal',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red.shade900),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => controller.loadRatings(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('REINTENTAR'),
            ),
          ],
        ),
      ),
    );
  }
}
