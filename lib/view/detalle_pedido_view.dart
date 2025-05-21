import 'package:flutter/material.dart';
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
                        (ctx) => const Icon(
                          Icons.house,
                          size: 50,
                          color: Colors.green,
                        ),
                  ),
                  Marker(
                    width: 60.0,
                    height: 60.0,
                    point: customerPosition,
                    builder:
                        (ctx) => const Icon(
                          Icons.location_on,
                          size: 50,
                          color: Colors.red,
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
              color: Colors.white.withOpacity(0.95),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pedido['local'] ?? 'Local desconocido',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.store,
                          size: 16,
                          color: Colors.blueGrey,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            pedido['direccion_local'] ??
                                'Dirección no disponible',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.shopping_basket,
                          size: 16,
                          color: Colors.blueGrey,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            pedido['productos'] ?? 'Sin productos',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.payment,
                          size: 16,
                          color: Colors.blueGrey,
                        ),
                        const SizedBox(width: 6),
                        Row(
                          children: [
                            const Text(
                              'Pago: ',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              pedido['tipoPago'] ?? 'N/A',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
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
                        const Icon(
                          Icons.timer,
                          size: 16,
                          color: Colors.blueGrey,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Tiempo estimado: ${pedido['tiempo']} min',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.blueAccent,
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
                        title: const Text(
                          'Ver más detalles',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        children: [
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                            title: Text(
                              'Dirección de entrega: ${pedido['direccion_entrega'] ?? ''}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                            title: Text(
                              'Cliente: ${pedido['cliente'] ?? ''}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                            title: Text(
                              'Celular: ${pedido['celular'] ?? ''}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                            title: Text(
                              'Nota: ${pedido['nota'] ?? ''}',
                              style: const TextStyle(fontSize: 12),
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
