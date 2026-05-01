import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:truelovebiker/features/orders/controllers/order_history_controller.dart';
import 'package:truelovebiker/data/models/pedido_historico_model.dart';
import 'package:url_launcher/url_launcher.dart';

class OrderHistoryScreen extends GetView<OrderHistoryController> {
  const OrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Pedidos'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.hasError.value) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 60, color: Colors.grey),
                const SizedBox(height: 16),
                Text('Error: ${controller.errorMessage.value}', 
                     style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: controller.loadHistory,
                  child: const Text('Reintentar'),
                )
              ],
            ),
          );
        }

        if (controller.pedidos.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 80, color: Colors.grey.withAlpha(50)),
                const SizedBox(height: 16),
                const Text('No hay pedidos en el historial.', 
                     style: TextStyle(color: Colors.grey, fontSize: 18)),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.loadHistory,
          child: ListView.builder(
            itemCount: controller.pedidos.length,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemBuilder: (context, index) {
              final pedido = controller.pedidos[index];
              return _buildOrderCard(context, pedido);
            },
          ),
        );
      }),
    );
  }

  Widget _buildOrderCard(BuildContext context, PedidoHistorico pedido) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 50 : 20),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isDark ? Colors.white.withAlpha(10) : Colors.grey.withAlpha(20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header del Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withAlpha(5) : Colors.grey.withAlpha(10),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withAlpha(20),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.receipt_long, size: 18, color: Colors.red),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Pedido #${pedido.id}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
                Text(
                  _formatDate(pedido.actualizado),
                  style: TextStyle(
                    color: colorScheme.onSurface.withAlpha(150),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Local y Teléfono
                _buildInfoSection(
                  icon: Icons.storefront_rounded,
                  iconColor: Colors.blue,
                  title: 'Establecimiento',
                  value: pedido.local,
                  trailing: (pedido.celularLocal != null && pedido.celularLocal!.isNotEmpty)
                      ? IconButton(
                          onPressed: () => launchUrl(Uri.parse("tel:${pedido.celularLocal}")),
                          icon: const Icon(Icons.phone_in_talk, size: 20, color: Colors.green),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        )
                      : null,
                ),
                const SizedBox(height: 16),

                // Direcciones
                Row(
                  children: [
                    Column(
                      children: [
                        const Icon(Icons.circle, size: 10, color: Colors.blue),
                        Container(width: 2, height: 25, color: Colors.grey.withAlpha(50)),
                        const Icon(Icons.location_on, size: 14, color: Colors.red),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pedido.direccionLocal,
                            style: TextStyle(
                              fontSize: 13,
                              color: colorScheme.onSurface.withAlpha(200),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            pedido.direccionEntrega,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Cliente
                _buildInfoSection(
                  icon: Icons.person_outline_rounded,
                  iconColor: Colors.orange,
                  title: 'Cliente',
                  value: pedido.cliente,
                ),
                
                const Divider(height: 32),

                // Productos
                const Text(
                  'Productos',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: pedido.productosList.map((prod) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withAlpha(10) : Colors.grey.withAlpha(20),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      prod,
                      style: const TextStyle(fontSize: 12),
                    ),
                  )).toList(),
                ),

                const Divider(height: 32),

                // Total
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pago: ${pedido.tipoPago}',
                          style: TextStyle(
                            fontSize: 11,
                            color: colorScheme.onSurface.withAlpha(150),
                          ),
                        ),
                        if (pedido.descuento != "0.00")
                          Text(
                            'Dcto: S/ ${pedido.descuento}',
                            style: const TextStyle(fontSize: 11, color: Colors.green),
                          ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Total Pagado',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
                        ),
                        Text(
                          'S/ ${pedido.total.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            color: Colors.red,
                            fontSize: 22,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    Widget? trailing,
  }) {
    final theme = Get.context!;
    final colorScheme = Theme.of(theme).colorScheme;

    return Row(
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: colorScheme.onSurface.withAlpha(100),
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr).toLocal();
      final months = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
      return '${date.day} ${months[date.month - 1]} ${date.year}, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateStr;
    }
  }
}
