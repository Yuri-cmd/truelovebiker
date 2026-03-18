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
        title: const Text("Detalle del Pedido"),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        actions: [
          GetBuilder<ViajeController>(
            builder: (controller) => Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(50),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.timer, size: 16, color: Colors.white),
                  const SizedBox(width: 4),
                  Text(
                    controller.formatTiempoTranscurrido(),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.currentState.value == 0) {
          return _buildViajeCancelado();
        }

        return Stack(
          children: [
            _buildMap(),
            _buildCustomerHeader(context),
            if (controller.actualizandoEstado.value)
              const Center(child: CircularProgressIndicator()),
          ],
        );
      }),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 20, left: 16, right: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Obx(() => _buildStatusButton(context)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FloatingActionButton(
                  heroTag: 'info',
                  onPressed: () => _mostrarBottomSheetPedido(context),
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.info, color: Colors.red),
                ),
                const SizedBox(width: 12),
                FloatingActionButton(
                  heroTag: 'chat',
                  onPressed: () {
                    final pedido = controller.pedido;
                    if (pedido.celularWhatsapp != null) {
                      launchUrl(Uri.parse("https://wa.me/${pedido.celularWhatsapp}"), mode: LaunchMode.externalApplication);
                    }
                  },
                  backgroundColor: Colors.redAccent,
                  child: const Icon(Icons.chat, color: Colors.white),
                ),
                const SizedBox(width: 12),
                FloatingActionButton(
                  heroTag: 'nav',
                  onPressed: () {
                    final pos = controller.currentState.value < 6 
                        ? controller.localPosition.value 
                        : controller.customerPosition.value;
                    if (pos != null) {
                      _elegirNavegadorYNavegar(context, pos.latitude, pos.longitude);
                    }
                  },
                  backgroundColor: Colors.redAccent,
                  child: const Icon(Icons.map, color: Colors.white),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMap() {
    return FlutterMap(
      mapController: controller.mapController,
      options: MapOptions(
        center: controller.motorizadoPosition.value ?? controller.localPosition.value ?? LatLng(-12.046374, -77.042793),
        zoom: 15.0,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://api.mapbox.com/styles/v1/mapbox/streets-v11/tiles/{z}/{x}/{y}?access_token={accessToken}',
          additionalOptions: {
            'accessToken': controller.mapboxAccessToken,
          },
        ),
        Obx(() => controller.ruta.isNotEmpty
          ? PolylineLayer(
              polylines: [
                // Línea de borde (más gruesa)
                Polyline(
                  points: controller.ruta,
                  strokeWidth: 7.0,
                  color: Colors.blue.withAlpha(50),
                ),
                // Línea principal
                Polyline(
                  points: controller.ruta,
                  strokeWidth: 4.0,
                  color: const Color(0xFF2196F3),
                ),
              ],
            )
          : const SizedBox.shrink()),
        Obx(() => MarkerLayer(
          markers: [
            if (controller.motorizadoPosition.value != null)
              Marker(
                point: controller.motorizadoPosition.value!,
                width: 60,
                height: 60,
                builder: (ctx) => _buildPremiumMarker(
                  icon: Icons.motorcycle,
                  color: const Color(0xFF2196F3),
                  isPulse: true,
                ),
              ),
            if (controller.localPosition.value != null)
              Marker(
                point: controller.localPosition.value!,
                width: 50,
                height: 50,
                builder: (ctx) => _buildPremiumMarker(
                  icon: Icons.storefront,
                  color: const Color(0xFF4CAF50),
                ),
              ),
            if (controller.customerPosition.value != null)
              Marker(
                point: controller.customerPosition.value!,
                width: 50,
                height: 50,
                builder: (ctx) => _buildPremiumMarker(
                  icon: Icons.person_pin_circle,
                  color: const Color(0xFFFF5252),
                ),
              ),
          ],
        )),
      ],
    );
  }

  Widget _buildCustomerHeader(BuildContext context) {
    final pedido = controller.pedido;
    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark 
                              ? Colors.white10 
                              : Colors.grey[100],
                          shape: BoxShape.circle,
                        ),
           child: const Icon(Icons.person, color: Colors.blue),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      pedido.cliente,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => launchUrl(Uri.parse("tel:${pedido.celular}")),
                icon: const Icon(Icons.phone, color: Colors.green),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusButton(BuildContext context) {
    final state = controller.currentState.value;
    String text = "";
    Color color = Colors.black;

    switch (state) {
      case 2:
      case 3:
      case 4:
        text = "Llegué al local";
        color = Colors.green;
        break;
      case 5:
        text = "Recogí el pedido";
        color = const Color(0xFF2196F3);
        break;
      case 6:
        text = "Llegué donde el cliente";
        color = Colors.orange;
        break;
      case 7:
        text = "Entregado";
        color = Colors.red;
        break;
      default:
        text = _getStatusText(state);
    }

    return GestureDetector(
      onTap: () => _handleStatusTap(state),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
    );
  }

  void _handleStatusTap(int state) {
    if (state < 5) {
      controller.cambiarEstado(5, "¿Ya llegaste al local?");
    } else if (state == 5) {
      controller.cambiarEstado(6, "¿Ya recogiste el pedido?");
    } else if (state == 6) {
      controller.cambiarEstado(7, "¿Llegaste a la ubicación del cliente?");
    } else if (state == 7) {
      controller.cambiarEstado(8, "¿Entregaste el pedido correctamente?");
    }
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
  Widget _buildViajeCancelado() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cancel_outlined, color: Colors.red, size: 100),
          const SizedBox(height: 16),
          const Text("Viaje Cancelado", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
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
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.redAccent,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Detalles del Pedido",
                        style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              "Productos: S/ ${(pedido.subtotal ?? 0.0).toStringAsFixed(2)}",
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                            ),
                            Text(
                              "Delivery: S/ ${pedido.precioDelivery}",
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                "Total: S/ ${pedido.total.toStringAsFixed(2)}",
                                style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.receipt_long, color: Colors.white, size: 30),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Celular: ${pedido.celular}",
                            style: TextStyle(color: Colors.white.withAlpha(200), fontSize: 14),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                "ID: ${pedido.id}",
                                style: TextStyle(color: Colors.white.withAlpha(200), fontSize: 14),
                              ),
                              const SizedBox(width: 16),
                              const Icon(Icons.timer, color: Colors.white, size: 14),
                              const SizedBox(width: 4),
                              GetBuilder<ViajeController>(
                                builder: (controller) => Text(
                                  controller.formatTiempoTranscurrido(),
                                  style: const TextStyle(color: Colors.white, fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildSectionHeader(Icons.person, "Información del Cliente", Colors.blue),
                  _buildInfoCard([
                    _buildDetailRow(Icons.person_outline, "Cliente", pedido.cliente),
                    const Divider(height: 1),
                    _buildDetailRow(Icons.phone_outlined, "Teléfono", pedido.celular),
                  ]),
                  const SizedBox(height: 16),
                  _buildSectionHeader(Icons.location_on, "Ubicaciones", Colors.green),
                  _buildInfoCard([
                    _buildDetailRow(Icons.store, "Local", pedido.local, isNavigation: true, lat: pedido.latLocal, lon: pedido.lonLocal),
                    const Divider(height: 1),
                    _buildDetailRow(Icons.home, "Entrega", pedido.direccionEntrega, isNavigation: true, lat: pedido.latitud, lon: pedido.longitud),
                  ]),
                  const SizedBox(height: 16),
                  _buildInfoCard([
                    Text(
                      pedido.productos,
                      style: TextStyle(fontSize: 15, color: Theme.of(context).textTheme.bodyLarge?.color),
                    ),
                  ]),
                  const SizedBox(height: 16),
                   _buildSectionHeader(Icons.payment, "Pago", Colors.blue),
                  _buildInfoCard([
                    _buildDetailRow(Icons.payment, "Tipo Pago", pedido.tipoPago),
                    const Divider(height: 1),
                    _buildDetailRow(Icons.money, "Precio Delivery", "S/ ${pedido.precioDelivery}"),
                  ]),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: Colors.grey.withAlpha(30))),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: children),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, dynamic value, {bool isNavigation = false, double? lat, double? lon}) {
    return InkWell(
      onTap: isNavigation && lat != null && lon != null ? () => _elegirNavegadorYNavegar(Get.context!, lat, lon) : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 22, color: Colors.grey[400]),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(
                    value?.toString() ?? 'N/A',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Theme.of(Get.context!).textTheme.bodyLarge?.color),
                  ),
                ],
              ),
            ),
            if (isNavigation)
              const Icon(Icons.navigation, size: 18, color: Colors.redAccent),
          ],
        ),
      ),
    );
  }

  Widget _buildNavOption({required BuildContext context, required IconData icon, required String title, required VoidCallback onTap}) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.redAccent.withAlpha(25),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.redAccent),
      ),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color)),
      onTap: onTap,
    );
  }

  Future<void> _elegirNavegadorYNavegar(BuildContext context, double lat, double lon) async {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Wrap(
          children: [
            _buildNavOption(
              context: context,
              icon: Icons.map,
              title: "Google Maps",
              onTap: () {
                Get.back();
                _launchUrl("https://www.google.com/maps/dir/?api=1&destination=$lat,$lon&travelmode=driving");
              },
            ),
             _buildNavOption(
              context: context,
              icon: Icons.language,
              title: "Google Maps (Navegador)",
              onTap: () {
                Get.back();
                _launchUrl("https://www.google.com/maps/dir/?api=1&destination=$lat,$lon");
              },
            ),
            _buildNavOption(
              context: context,
              icon: Icons.navigation,
              title: "Waze",
              onTap: () {
                Get.back();
                _launchUrl("waze://?ll=$lat,$lon&navigate=yes");
              },
            ),
          ],
        ),
      ),
    );
  }

  void _launchUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
         // Si falla el esquema nativo, intentar abrir en navegador normal
         await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      // Fallback a navegador
      try {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      } catch (e2) {
        Get.snackbar('Error', 'No se pudo abrir la navegación');
      }
    }
  }

  Widget _buildPremiumMarker({required IconData icon, required Color color, bool isPulse = false}) {
    return Stack(
      alignment: Alignment.center,
      children: [
        if (isPulse)
          _PulseAnimation(color: color),
        Container(
          height: 38,
          width: 38,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withAlpha(80),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
            border: Border.all(color: color, width: 2),
          ),
          child: Center(
            child: Icon(icon, color: color, size: 20),
          ),
        ),
      ],
    );
  }
}

class _PulseAnimation extends StatefulWidget {
  final Color color;
  const _PulseAnimation({required this.color});

  @override
  State<_PulseAnimation> createState() => _PulseAnimationState();
}

class _PulseAnimationState extends State<_PulseAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: 60 * _controller.value,
          height: 60 * _controller.value,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color.withOpacity(1 - _controller.value),
          ),
        );
      },
    );
  }
}
