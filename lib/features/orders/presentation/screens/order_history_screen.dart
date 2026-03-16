import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:truelovebiker/features/orders/controllers/order_history_controller.dart';
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
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.hasError.value) {
          return Center(child: Text('Error: ${controller.errorMessage.value}'));
        }

        if (controller.pedidos.isEmpty) {
          return const Center(child: Text('No hay pedidos en el historial.'));
        }

        return RefreshIndicator(
          onRefresh: controller.loadHistory,
          child: ListView.builder(
            itemCount: controller.pedidos.length,
            padding: const EdgeInsets.only(bottom: 80),
            itemBuilder: (context, index) {
              final pedido = controller.pedidos[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Pedido #${pedido.id}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text(_formatDate(pedido.actualizado), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                      const Divider(),
                      _buildRow(Icons.store, 'Local:', pedido.local),
                      if (pedido.celularLocal != null && pedido.celularLocal!.isNotEmpty)
                        _buildPhoneLink(context, pedido.celularLocal!),
                      const SizedBox(height: 8),
                      _buildRow(Icons.location_on, 'Origen:', pedido.direccionLocal),
                      const SizedBox(height: 8),
                      _buildRow(Icons.flag, 'Destino:', pedido.direccionEntrega),
                      const SizedBox(height: 8),
                      _buildRow(Icons.person, 'Cliente:', pedido.cliente),
                      const Divider(),
                      const Text('Productos:', style: TextStyle(fontWeight: FontWeight.bold)),
                      ...pedido.productosList.map((prod) => Padding(padding: const EdgeInsets.only(left: 8.0, top: 2.0), child: Text('• $prod'))),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total:', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('S/ ${pedido.total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 16)),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      }),
    );
  }

  Widget _buildRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(text: '$label ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[800])),
                TextSpan(text: value, style: const TextStyle(color: Colors.black87)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneLink(BuildContext context, String phone) {
    final formatted = phone.replaceAll('+51', '');
    return InkWell(
      onTap: () => launchUrl(Uri.parse("tel:$formatted")),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            const Icon(Icons.phone, size: 16, color: Colors.green),
            const SizedBox(width: 8),
            Text('Llamar al local: $formatted', style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline)),
          ],
        ),
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateStr;
    }
  }
}
