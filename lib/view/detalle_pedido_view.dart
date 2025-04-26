import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

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
            left: 5,
            right: 5,
            top: 10,
            child: Card(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15.0),
              ),
              elevation: 5.0,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Local: ${pedido['local']}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Dirección: ${pedido['direccion_local']}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Productos a recoger: ${pedido['productos']}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Tiempo estimado: ${pedido['tiempo']} minutos',
                      style: const TextStyle(fontSize: 12),
                    ),
                    // ExpansionTile para desglosar más detalles
                    ExpansionTile(
                      tilePadding:
                          EdgeInsets
                              .zero, // Elimina el espacio interno del título
                      childrenPadding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 0,
                      ), // Reduce el espacio interno
                      title: const Text(
                        'Ver más detalles',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            'Dirección de entrega: ${pedido['direccion_entrega']}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            'Cliente: ${pedido['cliente']}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            'Celular: ${pedido['celular']}',
                            style: const TextStyle(fontSize: 12),
                          ),
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
        onPressed: onStartTrip,
        icon: const Icon(Icons.directions_bike),
        label: const Text('Iniciar viaje'),
        foregroundColor: Colors.white,
        backgroundColor: Colors.black,
      ),
    );
  }
}
