import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:truelovebiker/features/orders/controllers/viaje_controller.dart';
import 'package:url_launcher/url_launcher.dart';

class ViajeScreen extends GetView<ViajeController> {
  const ViajeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Viaje #${controller.pedido['id']}"),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => controller.formatTiempoTranscurrido(), // Just a placeholder or logic check
          ),
        ],
      ),
      body: Obx(() {
        if (controller.viajeFinalizado.value) {
          return _buildViajeFinalizado();
        }

        return Stack(
          children: [
            _buildMap(),
            _buildStatusCard(context),
            if (controller.actualizandoEstado.value)
              const Center(child: CircularProgressIndicator()),
          ],
        );
      }),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'info',
            onPressed: () => _mostrarBottomSheetPedido(context),
            backgroundColor: Colors.white,
            child: const Icon(Icons.receipt_long, color: Colors.red),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'nav',
            onPressed: () {
              if (controller.currentState.value < 6) {
                _elegirNavegadorYNavegar(context, controller.localPosition.value!);
              } else {
                _elegirNavegadorYNavegar(context, controller.customerPosition.value!);
              }
            },
            backgroundColor: Colors.red,
            child: const Icon(Icons.navigation, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildMap() {
    return FlutterMap(
      options: MapOptions(
        center: controller.motorizadoPosition.value ?? LatLng(-12.046374, -77.042793),
        zoom: 15.0,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://api.mapbox.com/styles/v1/mapbox/streets-v11/tiles/{z}/{x}/{y}?access_token={accessToken}',
          additionalOptions: {
            'accessToken': controller.mapboxAccessToken,
          },
        ),
        if (controller.ruta.isNotEmpty)
          PolylineLayer(
            polylines: [
              Polyline(
                points: controller.ruta,
                strokeWidth: 4.0,
                color: Colors.blue,
              ),
            ],
          ),
        MarkerLayer(
          markers: [
            if (controller.motorizadoPosition.value != null)
              Marker(
                point: controller.motorizadoPosition.value!,
                builder: (ctx) => const Icon(Icons.motorcycle, color: Colors.red, size: 40),
              ),
            if (controller.localPosition.value != null)
              Marker(
                point: controller.localPosition.value!,
                builder: (ctx) => const Icon(Icons.store, color: Colors.green, size: 40),
              ),
            if (controller.customerPosition.value != null)
              Marker(
                point: controller.customerPosition.value!,
                builder: (ctx) => const Icon(Icons.person_pin_circle, color: Colors.blue, size: 40),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusCard(BuildContext context) {
    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _getStatusText(controller.currentState.value),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  Text(
                    controller.formatTiempoTranscurrido(),
                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildActionButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton() {
    final state = controller.currentState.value;
    if (state < 5) {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          minimumSize: const Size.fromHeight(50),
        ),
        onPressed: () => controller.cambiarEstado(5, "¿Ya llegaste al local?"),
        child: const Text("LLEGUÉ AL LOCAL", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      );
    } else if (state == 5) {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          minimumSize: const Size.fromHeight(50),
        ),
        onPressed: () => controller.cambiarEstado(6, "¿Ya recogiste el pedido?"),
        child: const Text("PEDIDO RECOGIDO / EN CAMINO", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      );
    } else if (state == 6) {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
          minimumSize: const Size.fromHeight(50),
        ),
        onPressed: () => controller.cambiarEstado(7, "¿Llegaste a la ubicación del cliente?"),
        child: const Text("LLEGUÉ DONDE EL CLIENTE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      );
    } else if (state == 7) {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          minimumSize: const Size.fromHeight(50),
        ),
        onPressed: () => controller.cambiarEstado(8, "¿Entregaste el pedido correctamente?"),
        child: const Text("ENTREGADO / FINALIZAR", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      );
    }
    return const SizedBox.shrink();
  }

  String _getStatusText(int state) {
    switch (state) {
      case 1: return "Buscando Repartidor";
      case 2: return "Confirmado";
      case 3: return "En Preparación";
      case 4: return "Listo para Recojo";
      case 5: return "Repartidor en Local";
      case 6: return "En Camino";
      case 7: return "En Puerta del Cliente";
      case 8: return "Entregado";
      case 0: return "Cancelado";
      default: return "Cargando...";
    }
  }

  Widget _buildViajeFinalizado() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle_outline, color: Colors.green, size: 100),
          const SizedBox(height: 16),
          const Text("Viaje Finalizado", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => Get.back(),
            child: const Text("VOLVER AL INICIO"),
          ),
        ],
      ),
    );
  }

  void _mostrarBottomSheetPedido(BuildContext context) {
    final pedido = controller.pedido;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(width: 40, height: 5, margin: const EdgeInsets.only(top: 12, bottom: 8), decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text("Pedido #${pedido['id']}", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const Divider(),
                  _buildDetailRow(Icons.person, "Cliente", pedido['cliente']),
                  _buildDetailRow(Icons.phone, "Celular", pedido['celular']),
                  _buildDetailRow(Icons.store, "Local", pedido['establecimiento']),
                  _buildDetailRow(Icons.location_on, "Recojo", pedido['direccionLocal']),
                  _buildDetailRow(Icons.home, "Entrega", pedido['direccionEntrega']),
                  _buildDetailRow(Icons.shopping_bag, "Productos", pedido['productos']),
                  _buildDetailRow(Icons.payment, "Pago", pedido['tipoPago']),
                  _buildDetailRow(Icons.money, "Paga con", pedido['paga_con']),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("TOTAL", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      Text("S/ ${pedido['total']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.red)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12)),
                Text(value?.toString() ?? 'N/A', style: const TextStyle(fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _elegirNavegadorYNavegar(BuildContext context, LatLng destino) async {
    Get.bottomSheet(
      Container(
        color: Colors.white,
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.map),
              title: const Text("Google Maps"),
              onTap: () async {
                Get.back();
                final url = Uri.parse('google.navigation:q=${destino.latitude},${destino.longitude}&mode=d');
                if (await canLaunchUrl(url)) {
                  await launchUrl(url);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.navigation),
              title: const Text("Waze"),
              onTap: () async {
                Get.back();
                final url = Uri.parse('waze://?ll=${destino.latitude},${destino.longitude}&navigate=yes');
                if (await canLaunchUrl(url)) {
                  await launchUrl(url);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
