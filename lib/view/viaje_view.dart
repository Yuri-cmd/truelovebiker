import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:truelovebiker/screen/rating_screen.dart';
import 'package:truelovebiker/services/api.dart';

const mapboxAccessToken =
    '***MAPBOX_TOKEN_REMOVED***';

class ViajeView extends StatefulWidget {
  final Map<String, dynamic> pedido;

  const ViajeView({super.key, required this.pedido});

  @override
  State<ViajeView> createState() => _ViajeViewState();
}

class _ViajeViewState extends State<ViajeView>
    with SingleTickerProviderStateMixin {
  Timer? _timer;
  LatLng? _localPosition;
  LatLng? _customerPosition;
  LatLng? _motorcyclePosition;
  List<LatLng> _ruta = [];
  int _currentState = 1;
  final Distance _distance = const Distance();
  bool viajeFinalizado = false;
  bool alertaEnviada = false; // Nueva bandera
  @override
  void initState() {
    super.initState();
    _fetchCustomerYLocalPosition(widget.pedido['id']);
    _startTracking();
  }

  void _startTracking() {
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _fetchOrderStatus(widget.pedido['id']);
      _fetchMotorcycleLocation();
    });
  }

  // Nueva función para cargar ambas posiciones antes de actualizar el estado

  Future<void> _fetchCustomerYLocalPosition(int idPedido) async {
    try {
      final data = await ApiService.fetchCustomerYLocalPosition(idPedido);
      double locallat =
          data['locallat'] is String
              ? double.parse(data['locallat'])
              : data['locallat'];
      double locallon =
          data['locallon'] is String
              ? double.parse(data['locallon'])
              : data['locallon'];
      double custlat =
          data['custlat'] is String
              ? double.parse(data['custlat'])
              : data['custlat'];
      double custlon =
          data['custlon'] is String
              ? double.parse(data['custlon'])
              : data['custlon'];

      setState(() {
        _localPosition = LatLng(locallat, locallon);
        _customerPosition = LatLng(custlat, custlon);
      });
    } catch (e) {
      throw ("Error al obtener ubicación del motorizado: $e");
    }
  }

  Future<void> _fetchOrderStatus(int idPedido) async {
    try {
      final data = await ApiService.fetchOrderStatus(idPedido);
      int newState = int.tryParse(data['estado'].toString()) ?? 1;

      if (newState != _currentState) {
        setState(() {
          _currentState = newState;
        });
        _fetchMotorcycleLocation();
      }
    } catch (e) {
      throw ("Error al obtener estado del pedido: $e");
    }
  }

  Future<void> _fetchMotorcycleLocation() async {
    try {
      final data = await ApiService.fetchMotorcycleLocation(
        widget.pedido['id'],
      );
      double lat = double.parse(data['lat']);
      double lon = double.parse(data['lon']);
      LatLng newPosition = LatLng(lat, lon);

      setState(() {
        _motorcyclePosition = newPosition;
      });
      if (_currentState == 4) {
        _cargarRuta(_motorcyclePosition!, _localPosition!);
        _verificarDistancia(
          _motorcyclePosition!,
          _localPosition!,
          5,
          "¿Ya llegó al local?",
        );
      }

      if (_currentState == 5) {
        _cargarRuta(_motorcyclePosition!, _customerPosition!);
        _verificarDistancia(
          _motorcyclePosition!,
          _customerPosition!,
          7,
          "¿Ya llegó al destino?",
        );
      }
      if (_currentState == 7) {
        onEstadoSieteDetectado(widget.pedido['id']);
      }
    } catch (e) {
      throw ("Error al obtener ubicación del motorizado: $e");
    }
  }

  Future<void> _cargarRuta(LatLng initialCord, LatLng finalCord) async {
    final List<LatLng> ruta = await ApiService.obtenerRuta(
      initialCord,
      finalCord,
      mapboxAccessToken,
    );
    setState(() {
      _ruta = ruta;
    });
  }

  void _verificarDistancia(
    LatLng origen,
    LatLng destino,
    int nuevoEstado,
    String mensaje,
  ) {
    double distancia = _distance(origen, destino);
    if (distancia <= 2) {
      _cambiarEstado(nuevoEstado, mensaje);
    }
  }

  void _cambiarEstado(int nuevoEstado, String mensaje) async {
    bool confirmacion = await _mostrarAlerta(mensaje);
    if (confirmacion) {
      await ApiService.actualizarEstado(widget.pedido['id'], nuevoEstado);
      setState(() {
        _currentState = nuevoEstado;
      });
    }
  }

  Future<bool> _mostrarAlerta(String mensaje) async {
    return await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Confirmación"),
            content: Text(mensaje),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("No"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Sí"),
              ),
            ],
          ),
    );
  }

  // Función para cuando detectes que el estado es 7
  void onEstadoSieteDetectado(int idPedido) {
    Timer(Duration(minutes: 7), () async {
      if (!viajeFinalizado && !alertaEnviada) {
        alertaEnviada = true; // Evitar que se mande más de una vez
        await ApiService.mandarAlertaDeAuxilio(idPedido);
        print('🚨 Se mandó la alerta de auxilio');
      } else {
        print('✅ El viaje fue finalizado antes de los 7 minutos');
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_localPosition == null || _customerPosition == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.redAccent,
          title: const Text('Detalle del Pedido'),
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del Pedido'),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: FlutterMap(
              options: MapOptions(
                center:
                    _motorcyclePosition ??
                    _localPosition ??
                    LatLng(-12.0464, -77.0428),
                zoom: 14.0,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://api.mapbox.com/styles/v1/mapbox/streets-v12/tiles/{z}/{x}/{y}?access_token={accessToken}',
                  additionalOptions: const {'accessToken': mapboxAccessToken},
                ),
                MarkerLayer(
                  markers: [
                    if (_localPosition != null)
                      Marker(
                        point: _localPosition!,
                        builder:
                            (ctx) => Image.asset(
                              'images/casa.png',
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                            ),
                      ),

                    Marker(
                      point: _customerPosition!,
                      builder:
                          (ctx) => const Icon(
                            Icons.location_on,
                            size: 40,
                            color: Colors.red,
                          ),
                    ),
                    if (_motorcyclePosition != null)
                      Marker(
                        point: _motorcyclePosition!,
                        builder:
                            (ctx) => Image.asset(
                              'images/moto.png',
                              width: 20,
                              height: 20,
                              fit: BoxFit.cover,
                            ),
                      ),
                  ],
                ),
                PolylineLayer(
                  polylineCulling: false,
                  polylines: [
                    Polyline(
                      points: _ruta,
                      color: Colors.blue,
                      strokeWidth: 4.0,
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_currentState == 5) // Mostrar botón si el estado es 4
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed:
                    () => _cambiarEstado(6, "¿Confirmar camino al cliente'?"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black, // Color del botón
                  padding: const EdgeInsets.symmetric(
                    vertical: 16.0,
                    horizontal: 32.0,
                  ),
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                child: const Text(
                  "En camino al cliente",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),

          if (_currentState == 7)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: () {
                  viajeFinalizado = true;
                  _cambiarEstado(8, "¿Desea finalizar el viaje?");
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) =>
                              RatingScreen(idPedido: widget.pedido['id']),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black, // Color del botón
                  padding: const EdgeInsets.symmetric(
                    vertical: 16.0,
                    horizontal: 32.0,
                  ),
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                child: const Text(
                  "Finalizar Viaje",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
