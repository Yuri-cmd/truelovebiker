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
      backgroundColor: Theme.of(context).brightness == Brightness.dark 
          ? const Color(0xFF121212) 
          : const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Viajes Activos'),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
        elevation: 0,
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
                      Icon(Icons.inbox_outlined, size: 80, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No tienes viajes activos', style: TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.w500)),
                      SizedBox(height: 8),
                      Text('Desliza hacia abajo para actualizar', style: TextStyle(fontSize: 14, color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.refreshTrips,
          child: GetBuilder<ActiveTripsController>(
            builder: (controller) => ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: controller.pedidos.length,
              itemBuilder: (context, index) {
                final pedido = controller.pedidos[index];
                return _buildViajeCard(context, pedido);
              },
            ),
          ),
        );
      }),
    );
  }

  Widget _buildViajeCard(BuildContext context, Pedido pedido) {
    
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status and ID row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStatusBadge(pedido.estado),
                      Text(
                        "ID: ${pedido.id}",
                        style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Timer badge
                  _buildTimerBadge(pedido.id),
                  const SizedBox(height: 16),
                  
                  // Customer row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark 
                              ? Colors.white10 
                              : Colors.grey[100],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.person, color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.grey, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pedido.cliente,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Text(
                              pedido.celular,
                              style: const TextStyle(color: Colors.grey, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                      _buildCircleCallButton(() => launchUrl(Uri.parse("tel:${pedido.celular}"))),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Delivery address block
                  _buildAddressBlock(
                    context: context,
                    icon: Icons.location_on,
                    title: "Dirección de entrega (toca para navegar)",
                    address: pedido.direccionEntrega,
                    color: Colors.blue,
                    onTap: () => _elegirNavegadorYNavegar(context, pedido, isLocal: false),
                  ),
                  const SizedBox(height: 12),
                  
                  // Local address block
                  _buildAddressBlock(
                    context: context,
                    icon: Icons.store,
                    title: "Local (toca para navegar)",
                    address: "${pedido.local}\n${pedido.direccionLocal}",
                    color: Colors.green,
                    onTap: () => _elegirNavegadorYNavegar(context, pedido, isLocal: true),
                  ),
                  const SizedBox(height: 12),
                  
                  // Call local link
                  if (pedido.celularLocal != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 12),
                      child: InkWell(
                        onTap: () => launchUrl(Uri.parse("tel:${pedido.celularLocal}")),
                        child: Row(
                          children: [
                            const Icon(Icons.phone, size: 16, color: Colors.green),
                            const SizedBox(width: 8),
                            Text(
                              "Llamar al local: ${pedido.celularLocal}",
                              style: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  
                  // Price and Action row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          "S/ ${pedido.total.toStringAsFixed(2)}",
                          style: TextStyle(
                            color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF81C784) : Colors.green, 
                            fontWeight: FontWeight.bold, 
                            fontSize: 18
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                             Text(
                              pedido.tipoPago,
                              style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                            if (pedido.descuento != null && pedido.descuento != "0.00")
                              Row(
                                children: [
                                  const Icon(Icons.local_offer, size: 12, color: Colors.red),
                                  const SizedBox(width: 4),
                                  Text(
                                    "Descuento: -S/ ${pedido.descuento}",
                                    style: const TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              )
                            else if (pedido.descuento != null)
                               Row(
                                children: [
                                  const Icon(Icons.local_offer, size: 12, color: Colors.red),
                                  const SizedBox(width: 4),
                                  Text(
                                    "Descuento: -S/ ${pedido.descuento}",
                                    style: const TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                      _buildVerViajeButton(() => Get.toNamed(Routes.ACTIVE_ORDER, arguments: pedido)),
                    ],
                  ),
                ],
              ),
            ),
            
            // Products section
            _buildProductsSection(context, pedido),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String estado) {
    String text = "En proceso";
    Color color = Colors.orange;
    
    switch (estado) {
      case '5':
        text = "En el local";
        color = Colors.green;
        break;
      case '6':
        text = "En camino";
        color = Colors.blue;
        break;
      case '7':
        text = "En la puerta";
        color = Colors.purple;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.store, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerBadge(int pedidoId) {
    final timeStr = controller.getElapsedTime(pedidoId);
    final bool isVencido = timeStr == 'Vencido';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isVencido ? Colors.red.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
        border: Border.all(color: isVencido ? Colors.red.withValues(alpha: 0.3) : Colors.orange.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer, size: 14, color: isVencido ? Colors.red : Colors.orange),
          const SizedBox(width: 6),
          Text(
            isVencido ? "Tiempo vencido" : timeStr,
            style: TextStyle(color: isVencido ? Colors.red : Colors.orange, fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildCircleCallButton(VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: const BoxDecoration(
          color: Color(0xFF4CAF50),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.phone, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _buildAddressBlock({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String address,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          border: Border.all(color: color.withValues(alpha: 0.1)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(color: color.withValues(alpha: 0.8), fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    address,
                    style: TextStyle(fontSize: 14, color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black87),
                  ),
                ],
              ),
            ),
            Icon(Icons.navigation, size: 18, color: color.withValues(alpha: 0.6)),
          ],
        ),
      ),
    );
  }

  Widget _buildVerViajeButton(VoidCallback onTap) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.visibility, size: 18),
      label: const Text("Ver viaje"),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFFF5252),
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _buildProductsSection(BuildContext context, Pedido pedido) {
    final bool isExpanded = controller.expandedCards.contains(pedido.id);
    final count = pedido.productos.split(',').length;

    return Column(
      children: [
        const Divider(height: 1, color: Color(0xFFEEEEEE)),
        InkWell(
          onTap: () => controller.toggleExpanded(pedido.id),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                const Icon(Icons.restaurant, color: Colors.orange, size: 18),
                const SizedBox(width: 10),
                Text(
                  "Productos ($count)",
                  style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const Spacer(),
                Icon(
                  isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: Colors.orange,
                ),
              ],
            ),
          ),
        ),
        if (isExpanded)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: pedido.productos.split(',').map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    const Icon(Icons.circle, size: 6, color: Colors.orange),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        p.trim(),
                        style: TextStyle(fontSize: 14, color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black87),
                      ),
                    ),
                  ],
                ),
              )).toList(),
            ),
          ),
      ],
    );
  }

  void _elegirNavegadorYNavegar(BuildContext context, Pedido pedido, {required bool isLocal}) {
    final lat = isLocal ? pedido.latLocal : pedido.latitud;
    final lon = isLocal ? pedido.lonLocal : pedido.longitud;
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Wrap(
          children: [
            _buildNavOption(
              icon: Icons.map,
              title: "Google Maps",
              onTap: () {
                Get.back();
                _launchUrl("https://www.google.com/maps/dir/?api=1&destination=$lat,$lon&travelmode=driving");
              },
            ),
             _buildNavOption(
              icon: Icons.language,
              title: "Google Maps (Navegador)",
              onTap: () {
                Get.back();
                _launchUrl("https://www.google.com/maps/dir/?api=1&destination=$lat,$lon");
              },
            ),
            _buildNavOption(
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

  Widget _buildNavOption({required IconData icon, required String title, required VoidCallback onTap}) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.redAccent.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.redAccent),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      onTap: onTap,
    );
  }

  void _launchUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
         await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      try {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      } catch (e2) {
        Get.snackbar('Error', 'No se pudo abrir la navegación');
      }
    }
  }
}
