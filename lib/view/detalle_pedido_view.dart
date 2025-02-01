import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

const mapboxAccessToken =
    '***MAPBOX_TOKEN_REMOVED***';

class DetallePedidoScreen extends StatefulWidget {
  final Map<String, String> pedido;

  const DetallePedidoScreen({super.key, required this.pedido});

  @override
  State<DetallePedidoScreen> createState() => _DetallePedidoScreenState();
}

class _DetallePedidoScreenState extends State<DetallePedidoScreen> {
  // Coordenadas para el local y la dirección del cliente
  final LatLng _localPosition = LatLng(-12.164103512419848, -76.98835812913894);
  final LatLng _customerPosition = LatLng(
    -12.168629013313693,
    -76.99153383511481,
  );

  // Función para mostrar un diálogo de confirmación
  void _confirmStartTrip() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('¿Iniciar viaje?'),
          content: const Text('¿Estás seguro de que deseas iniciar el viaje?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Cerrar el diálogo
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Cerrar el diálogo
                // Aquí puedes agregar la lógica para iniciar el viaje
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Viaje iniciado')));
              },
              child: const Text('Iniciar viaje'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del Pedido'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Detalles del pedido en un Card, ahora se asegura de tomar todo el ancho
            SizedBox(
              width:
                  double
                      .infinity, // Esto hace que el Container (y la Card dentro) tome todo el ancho
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15.0),
                ),
                elevation: 5.0,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Local: ${widget.pedido['local']}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueAccent,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Dirección: ${widget.pedido['direccion']}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Productos a recoger: ${widget.pedido['productos']}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Tiempo estimado: ${widget.pedido['tiempo']}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: // Botón dentro de la Card
                            ElevatedButton(
                          onPressed: _confirmStartTrip,
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            backgroundColor: Colors.blueAccent,
                          ),
                          child: const Text(
                            'Iniciar viaje',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Mapa con los puntos de local y cliente
            Expanded(
              child: FlutterMap(
                options: MapOptions(
                  center: _localPosition, // Centramos el mapa en el local
                  zoom: 14.0,
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
                      // Marcador para el local
                      Marker(
                        width: 60.0,
                        height: 60.0,
                        point: _localPosition,
                        builder:
                            (ctx) => const Icon(
                              Icons.house,
                              size: 50,
                              color: Colors.green, // Ícono de local
                            ),
                      ),
                      // Marcador para la casa del cliente
                      Marker(
                        width: 60.0,
                        height: 60.0,
                        point: _customerPosition,
                        builder:
                            (ctx) => const Icon(
                              Icons.location_on,
                              size: 50,
                              color: Colors.red, // Ícono de cliente
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      backgroundColor: Colors.blue[50],
    );
  }
}
