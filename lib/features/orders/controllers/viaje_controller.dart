import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:truelovebiker/data/models/pedido_model.dart';
import 'package:truelovebiker/data/services/order_service.dart';
import 'package:truelovebiker/data/services/timer_service.dart';
import 'package:truelovebiker/core/routes/app_pages.dart';
import 'package:dio/dio.dart' as dio;

class ViajeController extends GetxController {
  final Pedido pedido;
  ViajeController({required this.pedido});

  final OrderService _orderService = Get.find<OrderService>();
  final TimerService _timerService = Get.find<TimerService>();
  
  final currentState = 1.obs;
  final motorizadoPosition = Rxn<LatLng>();
  final localPosition = Rxn<LatLng>();
  final customerPosition = Rxn<LatLng>();
  final ruta = <LatLng>[].obs;
  final isLoading = true.obs;
  final actualizandoEstado = false.obs;
  final viajeFinalizado = false.obs;
  final timeTick = 0.obs;
  
  // Controlador para manipular el mapa (centrar, zoom, etc.)
  final MapController mapController = MapController();
  
  final mapboxAccessToken = '***MAPBOX_TOKEN_REMOVED***';

  Timer? _alertaSieteTimer;
  bool alertaEnviada = false;
  int _pollingCounter = 0;
  DateTime? _ultimaActualizacionManual;

  @override
  void onInit() {
    super.onInit();
    currentState.value = int.tryParse(pedido.estado) ?? 1;
    
    if (currentState.value == 8) {
      Future.microtask(() => Get.offNamed(Routes.RATING, arguments: pedido.id));
      return;
    }
    if (currentState.value == 0) {
      viajeFinalizado.value = true;
      return;
    }

    // Initialize positions from model
    localPosition.value = LatLng(pedido.latLocal, pedido.lonLocal);
    customerPosition.value = LatLng(pedido.latitud, pedido.longitud);

    _fetchCustomerYLocalPosition();
    _startTracking();
  }

  @override
  void onClose() {
    _timerService.stopTimerForPedido(pedido.id);
    _alertaSieteTimer?.cancel();
    super.onClose();
  }

  void _startTracking() {
    // Intentar obtener la fecha de inicio del pedido del servidor
    DateTime? startTime;
    final String? fInicio = pedido.fechaHoraInicio ?? pedido.fechaInicio;
    if (fInicio != null) {
      try {
        startTime = DateTime.parse(fInicio);
      } catch (e) {}
    }

    _timerService.startTimerForPedido(
      pedido.id,
      startTime: startTime,
      onTick: () {
        _pollingCounter++;
        if (_pollingCounter >= 5) {
          _pollingCounter = 0;
          if (!actualizandoEstado.value) {
            _fetchOrderStatus();
            _fetchMotorcycleLocation();
          }
        }
        timeTick.value++;
        update(); // Force UI update if needed for time
      },
    );
  }

  Future<void> _fetchCustomerYLocalPosition() async {
    try {
      final response = await _orderService.getCustomerAndLocalPosition(pedido.id);
      if (response.statusCode == 200) {
        final data = response.data;
        
        // Coordenadas del Local
        final tempLocalLat = _toDouble(data['locallat'] ?? data['latLocal'] ?? data['lat_local'] ?? data['latitud_local']);
        final tempLocalLon = _toDouble(data['locallon'] ?? data['lonLocal'] ?? data['lon_local'] ?? data['longitud_local']);
        localPosition.value = LatLng(tempLocalLat, tempLocalLon);
        
        double fetchedCustLat = 0.0;
        double fetchedCustLon = 0.0;
        
        if (data['coordinates'] != null && data['coordinates'] is List) {
          List coords = data['coordinates'];
          if (coords.length >= 2) {
            fetchedCustLon = _toDouble(coords[0]); 
            fetchedCustLat = _toDouble(coords[1]);
          }
        } else {
          fetchedCustLat = _toDouble(data['custlat'] ?? data['latitud'] ?? data['lat']);
          fetchedCustLon = _toDouble(data['custlon'] ?? data['longitud'] ?? data['lon'] ?? data['lng']);
        }

        if (fetchedCustLat != 0.0) customerPosition.value = LatLng(fetchedCustLat, fetchedCustLon);
        
        // Centrar mapa si el motorizado aún no tiene posición
        if (motorizadoPosition.value == null && localPosition.value != null && localPosition.value!.latitude != 0.0) {
          mapController.move(localPosition.value!, 15.0);
        }
      }
    } catch (e) {
      // Error fetching positions
    } finally {
      isLoading.value = false;
    }
  }


  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) {
      if (value.isEmpty) return 0.0;
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  Future<void> _fetchOrderStatus() async {
    if (actualizandoEstado.value) return;
    if (_ultimaActualizacionManual != null && DateTime.now().difference(_ultimaActualizacionManual!).inSeconds < 15) return;

    try {
      final response = await _orderService.getOrderStatus(pedido.id);
      if (response.statusCode == 200) {
        final data = response.data;
        int newState = int.tryParse(data['estado'].toString()) ?? 1;

        if (newState != currentState.value) {
          bool esRetrocesoReciente = _ultimaActualizacionManual != null &&
              DateTime.now().difference(_ultimaActualizacionManual!).inSeconds < 20 &&
              newState < currentState.value;

          if (!esRetrocesoReciente) {
            currentState.value = newState;
            if (newState != 7) {
              _alertaSieteTimer?.cancel();
              _alertaSieteTimer = null;
            }
            if (newState == 8) {
              viajeFinalizado.value = true;
              _timerService.clearPedido(pedido.id);
              Get.offNamed(Routes.RATING, arguments: pedido.id);
              return;
            }
            if (newState == 0) {
              viajeFinalizado.value = true;
              _timerService.clearPedido(pedido.id);
            }
          }
        }
      }
    } catch (e) {
      // Error fetching order status
    }
  }

  Future<void> _fetchMotorcycleLocation() async {
    try {
      final response = await _orderService.getMotorcycleLocation(pedido.id);
      if (response.statusCode == 200) {
        final data = response.data;
        double lat = double.parse(data['lat']);
        double lon = double.parse(data['lon']);
        motorizadoPosition.value = LatLng(lat, lon);
        
        // Centrar el mapa en la posición del motorizado
        mapController.move(motorizadoPosition.value!, 15.0);

        if (currentState.value < 6 && localPosition.value != null) {
          _cargarRuta(motorizadoPosition.value!, localPosition.value!);
        } else if (currentState.value >= 0 && customerPosition.value != null) {
          // Cambiamos el >= 6 por >= 0 para forzar el dibujo al cliente si el estado lo amerita, 
          // pero en la lógica de refresco lo mantendremos coherente.
          _cargarRuta(motorizadoPosition.value!, customerPosition.value!);
        }
        
        if (currentState.value == 7) {
          _onEstadoSieteDetectado();
        }
      }
    } catch (e) {
      // Error fetching motorcycle location
    }
  }

  Future<void> _cargarRuta(LatLng initial, LatLng destination) async {
    final String url =
        'https://api.mapbox.com/directions/v5/mapbox/driving/${initial.longitude},${initial.latitude};${destination.longitude},${destination.latitude}?geometries=geojson&access_token=$mapboxAccessToken';

    try {
      final response = await dio.Dio().get(url);
      if (response.statusCode == 200) {
        final List<dynamic> coordinates =
            response.data['routes'][0]['geometry']['coordinates'];

        ruta.assignAll([]);
        ruta.addAll(coordinates.map((coord) => LatLng(coord[1], coord[0])).toList());
      }
    } catch (e) {
      // Error loading route
    }
  }

  void _onEstadoSieteDetectado() {
    if (_alertaSieteTimer != null || viajeFinalizado.value || alertaEnviada) return;

    _alertaSieteTimer = Timer(const Duration(minutes: 7), () async {
      _alertaSieteTimer = null;
      if (!viajeFinalizado.value && !alertaEnviada) {
        alertaEnviada = true;
        await _orderService.sendHelpAlert(pedido.id);
      }
    });
  }

  Future<void> cambiarEstado(int nuevoEstado, String mensaje) async {
    if (actualizandoEstado.value) return;

    Get.dialog(
      AlertDialog(
        title: const Text("Confirmación"),
        content: Text(mensaje),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text("No")),
          TextButton(
            onPressed: () async {
              Get.back();
              final previousState = currentState.value;
              actualizandoEstado.value = true;
              _ultimaActualizacionManual = DateTime.now();
               try {
                await _orderService.updatePedidoEstado(pedido.id, nuevoEstado);
                currentState.value = nuevoEstado;
                
                if (nuevoEstado != 7) {
                  _alertaSieteTimer?.cancel();
                  _alertaSieteTimer = null;
                }
                
                if (nuevoEstado == 8) {
                  Get.offNamed(Routes.RATING, arguments: pedido.id);
                  return;
                }

                // Forzar actualización de posición y ruta inmediatamente
                await _fetchMotorcycleLocation();
                await Future.delayed(const Duration(seconds: 10));
              } catch (e) {
                currentState.value = previousState;
                Get.snackbar(
                  'Error', 
                  'Error al actualizar estado',
                  backgroundColor: Colors.redAccent, 
                  colorText: Colors.white,
                  snackPosition: SnackPosition.BOTTOM,
                  margin: const EdgeInsets.all(15),
                  borderRadius: 10,
                  icon: const Icon(Icons.error_outline, color: Colors.white),
                );
              } finally {
                actualizandoEstado.value = false;
              }
            },
            child: const Text("Sí"),
          ),
        ],
      ),
    );
  }

  String formatTiempoTranscurrido() {
    final elapsed = _timerService.getElapsedTimeForPedidoSync(pedido.id);
    if (elapsed.inSeconds == 0) return 'Calculando...';

    // Obtenemos el tiempo total para el pedido (en minutos)
    final int tiempoTotalMinutos = pedido.tiempo > 0 ? pedido.tiempo : 30;
    final int tiempoTotalSegundos = tiempoTotalMinutos * 60;
    
    // Calculamos el tiempo restante
    final int restanteSegundos = tiempoTotalSegundos - elapsed.inSeconds;

    if (restanteSegundos <= 0) return 'Vencido';

    final minutes = restanteSegundos ~/ 60;
    final seconds = restanteSegundos % 60;

    if (minutes < 60) {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      final hours = minutes ~/ 60;
      final mins = minutes % 60;
      return '${hours}h ${mins.toString().padLeft(2, '0')}m';
    }
  }
}
