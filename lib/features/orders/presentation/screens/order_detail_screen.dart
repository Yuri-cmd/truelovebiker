import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:truelovebiker/core/utils/image_helper.dart';
import 'package:truelovebiker/features/orders/controllers/order_detail_controller.dart';

class OrderDetailScreen extends GetView<OrderDetailController> {
  const OrderDetailScreen({super.key});

  static const mapboxAccessToken = '***MAPBOX_TOKEN_REMOVED***';

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final pedido = controller.pedido;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del Pedido'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              bounds: controller.bounds,
              center: controller.bounds.center,
              zoom: 15.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://api.mapbox.com/styles/v1/mapbox/streets-v11/tiles/{z}/{x}/{y}?access_token={accessToken}',
                additionalOptions: const {
                  'accessToken': mapboxAccessToken,
                },
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    width: 60.0,
                    height: 60.0,
                    point: controller.localPosition,
                    builder: (ctx) => const Icon(Icons.house, size: 50, color: Colors.green),
                  ),
                  Marker(
                    width: 60.0,
                    height: 60.0,
                    point: controller.customerPosition,
                    builder: (ctx) => Icon(Icons.location_on, size: 50, color: colorScheme.error),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            left: 10,
            right: 10,
            top: 16,
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 6,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      pedido['local'] ?? 'Local desconocido',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    _buildRow(Icons.store, pedido['direccion_local'] ?? 'No disponible'),
                    const SizedBox(height: 6),
                    _buildRow(Icons.shopping_basket, pedido['productos'] ?? 'Sin productos'),
                    const SizedBox(height: 6),
                    _buildPaymentRow(pedido['tipoPago']),
                    const SizedBox(height: 6),
                    _buildPriceRow("Delivery", "S/. ${pedido['precio_delivery']}"),
                    const SizedBox(height: 6),
                    _buildPriceRow("Total", "S/. ${pedido['total']}"),
                    const SizedBox(height: 6),
                    _buildPriceRow("Descuento", "S/. ${pedido['descuento']}"),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.timer, size: 16, color: Colors.blue),
                        const SizedBox(width: 6),
                        Text(
                          'Tiempo estimado: ${pedido['tiempo']} min',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.red),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: controller.confirmStartTrip,
        icon: const Icon(Icons.directions_bike),
        label: const Text('Iniciar viaje'),
        foregroundColor: Colors.white,
        backgroundColor: Colors.black,
      ),
    );
  }

  Widget _buildRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 6),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
      ],
    );
  }

  Widget _buildPaymentRow(String? tipoPago) {
    return Row(
      children: [
        const Icon(Icons.payment, size: 16, color: Colors.grey),
        const SizedBox(width: 6),
        Text('Pago: ${tipoPago ?? 'N/A'}', style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 6),
        getMetodoPagoImage(tipoPago),
      ],
    );
  }

  Widget _buildPriceRow(String label, String value) {
    return Row(
      children: [
        const Icon(Icons.money, size: 16, color: Colors.grey),
        const SizedBox(width: 6),
        Text('$label: ', style: const TextStyle(fontSize: 14, color: Colors.grey)),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
