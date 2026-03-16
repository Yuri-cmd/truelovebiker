import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:truelovebiker/core/routes/app_pages.dart';
import 'package:truelovebiker/features/orders/controllers/active_trips_controller.dart';
import 'package:truelovebiker/data/models/pedido_model.dart';
import 'package:url_launcher/url_launcher.dart';

class ActiveTripsScreen extends GetView<ActiveTripsController> {
  const ActiveTripsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Viajes Activos'),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: controller.refreshTrips,
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.pedidos.isEmpty) {
          return RefreshIndicator(
            onRefresh: controller.refreshTrips,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 150),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inbox_outlined,
                        size: 80,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No tienes viajes activos',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Desliza hacia abajo para actualizar',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.refreshTrips,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: controller.pedidos.length,
            itemBuilder: (context, index) {
              final pedido = controller.pedidos[index];
              return _buildViajeCard(context, pedido);
            },
          ),
        );
      }),
    );
  }

  Widget _buildViajeCard(BuildContext context, Pedido pedido) {
    final estado = pedido.estado;
    final estadoColor = _getEstadoColor(estado);
    final estadoTexto = _getEstadoTexto(estado);
    final estadoIcon = _getEstadoIcon(estado);
    final isCancelado = estado == '0';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: isCancelado ? 2 : 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Opacity(
        opacity: isCancelado ? 0.7 : 1.0,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: isCancelado ? null : () => Get.toNamed(Routes.ACTIVE_ORDER, arguments: pedido.toMap()),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: estadoColor.withAlpha((0.1 * 255).toInt()),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: estadoColor),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(estadoIcon, size: 16, color: estadoColor),
                          const SizedBox(width: 4),
                          Text(
                            estadoTexto,
                            style: TextStyle(color: estadoColor, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Text('ID: ${pedido.id}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 8),
                if (pedido.actualizado != null)
                  _buildTimerBadge(pedido),
                const SizedBox(height: 12),
                if (isCancelado) _buildCancelAlert(),
                _buildClientInfo(context, pedido, isCancelado),
                const SizedBox(height: 12),
                _buildNavigationAction(context, "Entrega", pedido.direccionEntrega, pedido.latitud, pedido.longitud, isCancelado, Colors.blue),
                const SizedBox(height: 8),
                _buildNavigationAction(context, "Local", pedido.local, pedido.latLocal, pedido.lonLocal, isCancelado, Colors.green),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimerBadge(Pedido pedido) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.orange.withAlpha((0.1 * 255).toInt()),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.orange.withAlpha((0.3 * 255).toInt())),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.timer, size: 14, color: Colors.orange),
          const SizedBox(width: 4),
          Text(
            controller.getElapsedTime(pedido.id),
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.orange),
          ),
        ],
      ),
    );
  }

  Widget _buildCancelAlert() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.red[700], size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Este pedido ha sido cancelado y no está disponible',
              style: TextStyle(color: Colors.red[700], fontWeight: FontWeight.w500, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClientInfo(BuildContext context, Pedido pedido, bool isCancelado) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.person, size: 18, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(child: Text(pedido.cliente, style: TextStyle(fontWeight: FontWeight.bold, color: isCancelado ? Colors.grey : Colors.black87))),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.phone, size: 18, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(pedido.celular, style: const TextStyle(fontSize: 13, color: Colors.grey)),
                ],
              ),
            ],
          ),
        ),
        if (!isCancelado) _buildCommunicationButtons(pedido),
      ],
    );
  }

  Widget _buildCommunicationButtons(Pedido pedido) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (pedido.celularWhatsapp != null)
          IconButton(
            onPressed: () => launchUrl(Uri.parse("https://wa.me/${pedido.celularWhatsapp}"), mode: LaunchMode.externalApplication),
            icon: const Icon(Icons.chat, color: Colors.green),
          ),
        IconButton(
          onPressed: () => launchUrl(Uri.parse("tel:${pedido.celular}")),
          icon: const Icon(Icons.call, color: Colors.green),
        ),
      ],
    );
  }

  Widget _buildNavigationAction(BuildContext context, String label, String address, double lat, double lon, bool isCancelado, Color color) {
    return GestureDetector(
      onTap: isCancelado ? null : () => _showNavigationDialog(context, lat, lon),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (isCancelado ? Colors.grey : color).withAlpha((0.05 * 255).toInt()),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: (isCancelado ? Colors.grey : color).withAlpha((0.2 * 255).toInt())),
        ),
        child: Row(
          children: [
            Icon(label == "Entrega" ? Icons.location_on : Icons.store, size: 18, color: isCancelado ? Colors.grey : color),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontSize: 12, color: isCancelado ? Colors.grey : color, fontWeight: FontWeight.w500)),
                  Text(address, style: TextStyle(fontSize: 14, color: isCancelado ? Colors.grey[600] : Colors.black87)),
                ],
              ),
            ),
            if (!isCancelado) Icon(Icons.navigation, size: 16, color: color),
          ],
        ),
      ),
    );
  }

  void _showNavigationDialog(BuildContext context, double lat, double lon) {
    Get.dialog(
      AlertDialog(
        title: const Text('Navegación'),
        content: const Text('¿Qué aplicación deseas usar?'),
        actions: [
          TextButton(child: const Text('Waze'), onPressed: () { Get.back(); _launchNav("waze://?ll=$lat,$lon&navigate=yes"); }),
          TextButton(child: const Text('Google Maps'), onPressed: () { Get.back(); _launchNav("https://www.google.com/maps/dir/?api=1&destination=$lat,$lon"); }),
        ],
      ),
    );
  }

  void _launchNav(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  String _getEstadoTexto(String estado) {
    switch (estado) {
      case '0': return 'Cancelado';
      case '4': return 'En camino al local';
      case '5': return 'En el local';
      case '6': return 'En camino al cliente';
      case '7': return 'En destino';
      default: return 'Estado $estado';
    }
  }

  Color _getEstadoColor(String estado) {
    switch (estado) {
      case '0': return Colors.red[800]!;
      case '4': return Colors.blue;
      case '5': return Colors.green;
      case '6': return Colors.orange;
      case '7': return Colors.red;
      default: return Colors.grey;
    }
  }

  IconData _getEstadoIcon(String estado) {
    switch (estado) {
      case '0': return Icons.cancel;
      case '4': return Icons.directions_bike;
      case '5': return Icons.store;
      case '6': return Icons.delivery_dining;
      case '7': return Icons.location_on;
      default: return Icons.help_outline;
    }
  }
}
