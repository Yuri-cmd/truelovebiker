import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:truelovebiker/helpers/image_helper.dart';

const mapboxAccessToken =
    '***MAPBOX_TOKEN_REMOVED***';

class DetallePedidoView extends StatelessWidget {
  final Map<String, dynamic> pedido;
  final LatLngBounds bounds;
  final LatLng localPosition;
  final LatLng customerPosition;
  final VoidCallback onStartTrip;

  const DetallePedidoView({
    super.key,
    required this.pedido,
    required this.bounds,
    required this.localPosition,
    required this.customerPosition,
    required this.onStartTrip,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
              bounds: bounds,
              center: bounds.center,
              zoom: 40.0,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://api.mapbox.com/styles/v1/{id}/tiles/{z}/{x}/{y}?access_token={accessToken}',
                additionalOptions: const {
                  'accessToken': mapboxAccessToken,
                  'id': 'mapbox/streets-v12',
                },
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    width: 60.0,
                    height: 60.0,
                    point: localPosition,
                    builder:
                        (ctx) => Icon(
                          Icons.house,
                          size: 50,
                          color: Colors.green[400],
                        ),
                  ),
                  Marker(
                    width: 60.0,
                    height: 60.0,
                    point: customerPosition,
                    builder:
                        (ctx) => Icon(
                          Icons.location_on,
                          size: 50,
                          color: colorScheme.error,
                        ),
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 6,
              color:
                  isDark
                      ? colorScheme.surface.withAlpha((0.98 * 255).toInt())
                      : Colors.white.withAlpha((0.98 * 255).toInt()),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pedido['local'] ?? 'Local desconocido',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.store,
                          size: 16,
                          color: colorScheme.secondary,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            pedido['direccion_local'] ??
                                'Dirección no disponible',
                            style: TextStyle(
                              fontSize: 13,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.shopping_basket,
                          size: 16,
                          color: colorScheme.secondary,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            pedido['productos'] ?? 'Sin productos',
                            style: TextStyle(
                              fontSize: 13,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.payment,
                          size: 16,
                          color: colorScheme.secondary,
                        ),
                        const SizedBox(width: 6),
                        Row(
                          children: [
                            Text(
                              'Pago: ',
                              style: TextStyle(
                                fontSize: 14,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            Text(
                              pedido['tipoPago'] ?? 'N/A',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(width: 6),
                            getMetodoPagoImage(pedido['tipoPago']),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.payment,
                          size: 16,
                          color: colorScheme.secondary,
                        ),
                        const SizedBox(width: 6),
                        Row(
                          children: [
                            Text(
                              'Delivery: ',
                              style: TextStyle(
                                fontSize: 14,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            Text(
                              'S/. ${pedido['precio_delivery']}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.payment,
                          size: 16,
                          color: colorScheme.secondary,
                        ),
                        const SizedBox(width: 6),
                        Row(
                          children: [
                            Text(
                              'Total: ',
                              style: TextStyle(
                                fontSize: 14,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            Text(
                              'S/. ${pedido['total'].toString()}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.payment,
                          size: 16,
                          color: colorScheme.secondary,
                        ),
                        const SizedBox(width: 6),
                        Row(
                          children: [
                            Text(
                              'Descuento: ',
                              style: TextStyle(
                                fontSize: 14,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            Text(
                              'S/. ${pedido['descuento'].toString()}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.timer,
                          size: 16,
                          color: colorScheme.secondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Tiempo estimado: ${pedido['tiempo']} min',
                          style: TextStyle(
                            fontSize: 13,
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 20, thickness: 1),
                    Theme(
                      data: Theme.of(
                        context,
                      ).copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        title: Text(
                          'Ver más detalles',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.primary,
                          ),
                        ),
                        children: [
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                            title: Text(
                              'Dirección de entrega: ${pedido['direccion_entrega'] ?? ''}',
                              style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                            title: Text(
                              'Cliente: ${pedido['cliente'] ?? ''}',
                              style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                            title: Text(
                              'Celular: ${pedido['celular'] ?? ''}',
                              style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          if (pedido['celular_whatsapp'] != null &&
                              pedido['celular_whatsapp'].toString().isNotEmpty)
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                              title: Row(
                                children: [
                                  Text(
                                    'WhatsApp: ${pedido['celular_whatsapp']}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.chat,
                                      color: Colors.green,
                                      size: 16,
                                    ),
                                    onPressed: () async {
                                      final whatsappUrl = Uri.parse(
                                        "https://wa.me/${pedido['celular_whatsapp']}",
                                      );
                                      await launchUrl(
                                        whatsappUrl,
                                        mode: LaunchMode.externalApplication,
                                      );
                                    },
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ],
                              ),
                            ),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                            title: Text(
                              'Nota: ${pedido['nota'] ?? ''}',
                              style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: onStartTrip,
        icon: const Icon(Icons.directions_bike),
        label: const Text('Iniciar viaje'),
        foregroundColor: Colors.white,
        backgroundColor: Colors.black,
      ),
    );
  }
}
