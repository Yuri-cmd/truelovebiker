import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:truelovebiker/services/api.dart';
import 'package:truelovebiker/view/detalle_pedido_view.dart';
import 'package:truelovebiker/view/viaje_view.dart';

class DetallePedidoScreen extends StatefulWidget {
  final Map<String, dynamic> pedido;

  const DetallePedidoScreen({super.key, required this.pedido});

  @override
  State<DetallePedidoScreen> createState() => _DetallePedidoScreenState();
}

class _DetallePedidoScreenState extends State<DetallePedidoScreen> {
  late LatLng _localPosition;
  late LatLng _customerPosition;

  @override
  void initState() {
    super.initState();
    _localPosition = LatLng(
      widget.pedido['lat_local'],
      widget.pedido['lon_local'],
    );

    _customerPosition = LatLng(
      widget.pedido['latitud'],
      widget.pedido['longitud'],
    );
  }

  LatLngBounds _calculateBounds(LatLng point1, LatLng point2) {
    final latitudes = [point1.latitude, point2.latitude];
    final longitudes = [point1.longitude, point2.longitude];
    return LatLngBounds(
      LatLng(
        latitudes.reduce((a, b) => a < b ? a : b),
        longitudes.reduce((a, b) => a < b ? a : b),
      ),
      LatLng(
        latitudes.reduce((a, b) => a > b ? a : b),
        longitudes.reduce((a, b) => a > b ? a : b),
      ),
    );
  }

  void _confirmStartTrip(int id) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final int? idBiker = prefs.getInt('id_biker');
    if (!mounted) return;

    if (idBiker != null) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('¿Iniciar viaje?'),
            content: const Text(
              '¿Estás seguro de que deseas iniciar el viaje?',
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () async {
                  final response = await ApiService.startTripApi(idBiker, id);
                  if (response.statusCode == 200) {
                    if (!context.mounted) return;
                    Navigator.of(context).pop(); // Cerrar dialog primero
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Viaje iniciado')),
                    );
                    if (mounted) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => ViajeView(pedido: widget.pedido),
                        ),
                      );
                    }
                  } else {
                    if (!context.mounted) return;
                    Navigator.of(context).pop(); // Cerrar dialog primero
                    
                    String errorMessage = 'Error al iniciar el viaje';
                    
                    // Manejar error específico cuando ya tiene motorizado asignado
                    if (response.statusCode == 400) {
                      try {
                        final responseData = jsonDecode(response.body);
                        if (responseData != null && 
                            responseData['status'] == 'error' && 
                            responseData['message'] != null) {
                          errorMessage = responseData['message'];
                        }
                      } catch (e) {
                        // Si hay error parseando, mantener mensaje por defecto
                      }
                    }
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(errorMessage),
                        backgroundColor: Colors.red,
                        duration: const Duration(seconds: 4),
                      ),
                    );
                  }
                },
                child: const Text('Iniciar viaje'),
              ),
            ],
          );
        },
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: id_biker no encontrado')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bounds = _calculateBounds(_localPosition, _customerPosition);
    return DetallePedidoView(
      pedido: widget.pedido,
      bounds: bounds,
      localPosition: _localPosition,
      customerPosition: _customerPosition,
      onStartTrip: () => _confirmStartTrip(widget.pedido['id']),
    );
  }
}
