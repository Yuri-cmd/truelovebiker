import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:truelovebiker/core/utils/image_helper.dart';
import 'package:truelovebiker/core/widgets/pedido_productos_agrupados.dart';
import 'package:truelovebiker/features/orders/controllers/order_detail_controller.dart';

class OrderDetailScreen extends GetView<OrderDetailController> {
  const OrderDetailScreen({super.key});

  static String get mapboxAccessToken => dotenv.env['MAPBOX_ACCESS_TOKEN'] ?? '';

  @override
  Widget build(BuildContext context) {
    // pedido ahora es un objeto Pedido en el controlador
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
                additionalOptions: {
                  'accessToken': mapboxAccessToken,
                },
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    width: 60.0,
                    height: 60.0,
                    point: controller.localPosition,
                    builder: (ctx) => const Icon(Icons.store, size: 50, color: Colors.green),
                  ),
                  Marker(
                    width: 60.0,
                    height: 60.0,
                    point: controller.customerPosition,
                    builder: (ctx) => const Icon(Icons.location_on, size: 50, color: Colors.blue),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            left: 10,
            right: 10,
            top: 16,
            child: Obx(() => Card(
              color: const Color(0xFF1E1E2C).withValues(alpha: 0.95),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 8,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      pedido.local,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    _buildRow(Icons.store_mall_directory, pedido.direccionLocal),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.shopping_bag, size: 18, color: Colors.white70),
                        const SizedBox(width: 10),
                        Expanded(
                          child: PedidoProductosAgrupados(
                            detalleArray: pedido.detalleArray,
                            fallbackTexto: pedido.productos,
                            textColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildPaymentRow(pedido.tipoPago),
                    const SizedBox(height: 8),
                    _buildPriceRow(Icons.credit_card, "Delivery", "S/. ${pedido.precioDelivery}"),
                    const SizedBox(height: 8),
                    _buildPriceRow(Icons.credit_card, "Total", "S/. ${pedido.total.toStringAsFixed(2)}"),
                    const SizedBox(height: 8),
                    _buildPriceRow(Icons.credit_card, "Descuento", "S/. ${pedido.descuento ?? '0.00'}"),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.timer, size: 18, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                          'Tiempo estimado: ${pedido.tiempo} min',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF9FA8DA)),
                        ),
                      ],
                    ),
                    const Divider(color: Colors.white24, height: 24),
                    InkWell(
                      onTap: () => controller.isExpanded.toggle(),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Ver más detalles",
                            style: TextStyle(color: Color(0xFF9FA8DA), fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          Icon(
                            controller.isExpanded.value ? Icons.expand_less : Icons.expand_more,
                            color: const Color(0xFF9FA8DA),
                          ),
                        ],
                      ),
                    ),
                    if (controller.isExpanded.value) ...[
                      const SizedBox(height: 16),
                      _buildDetailText("Dirección de entrega", pedido.direccionEntrega),
                      const SizedBox(height: 12),
                      _buildDetailText("Cliente", pedido.cliente),
                      const SizedBox(height: 12),
                      _buildDetailText("Celular", pedido.celular),
                      const SizedBox(height: 12),
                      if (pedido.tipoComprobante.isNotEmpty) ...[
                        _buildDetailText("Comprobante", pedido.tipoComprobante),
                        const SizedBox(height: 12),
                      ],
                      _buildDetailText("Nota", pedido.nota),
                    ],
                  ],
                ),
              ),
            )),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: controller.confirmStartTrip,
        icon: const Icon(Icons.directions_bike),
        label: const Text('Iniciar viaje', style: TextStyle(fontWeight: FontWeight.bold)),
        foregroundColor: Colors.white,
        backgroundColor: Colors.black,
      ),
    );
  }

  Widget _buildRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.white70),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 14, color: Colors.white))),
      ],
    );
  }

  Widget _buildPaymentRow(String? tipoPago) {
    return Row(
      children: [
        const Icon(Icons.payment, size: 18, color: Colors.white70),
        const SizedBox(width: 10),
        const Text('Pago: ', style: TextStyle(fontSize: 14, color: Colors.white70)),
        Text(tipoPago ?? 'N/A', style: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold)),
        const SizedBox(width: 8),
        getMetodoPagoImage(tipoPago),
      ],
    );
  }

  Widget _buildPriceRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.white70),
        const SizedBox(width: 10),
        Text('$label: ', style: const TextStyle(fontSize: 14, color: Colors.white70)),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
      ],
    );
  }

  Widget _buildDetailText(String label, dynamic value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "$label: ${value ?? 'No disponible'}",
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
      ],
    );
  }
}
