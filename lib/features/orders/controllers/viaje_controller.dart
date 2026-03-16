import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:truelovebiker/data/services/order_service.dart';
import 'package:truelovebiker/data/services/timer_service.dart';
import 'package:dio/dio.dart' as dio;

class ViajeController extends GetxController {
  final Map<String, dynamic> pedido;
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
  
  final mapboxAccessToken = '***MAPBOX_TOKEN_REMOVED***';

  Timer? _alertaSieteTimer;
  bool alertaEnviada = false;
  int _pollingCounter = 0;
  DateTime? _ultimaActualizacionManual;

  @override
  void onInit() {
    super.onInit();
    currentState.value = int.tryParse(pedido['estado'].toString()) ?? 1;
    
    if (currentState.value == 0 || currentState.value == 8) {
      viajeFinalizado.value = true;
      return;
    }

    _fetchCustomerYLocalPosition();
    _startTracking();
  }

  @override
  void onClose() {
    _timerService.stopTimerForPedido(pedido['id']);
    _alertaSieteTimer?.cancel();
    super.onClose();
  }

  void _startTracking() {
    _timerService.startTimerForPedido(
      pedido['id'],
      onTick: () {
        _pollingCounter++;
        if (_pollingCounter >= 5) {
          _pollingCounter = 0;
          if (!actualizandoEstado.value) {
            _fetchOrderStatus();
            _fetchMotorcycleLocation();
          }
        }
        update(); // Force UI update if needed for time
      },
    );
  }

  Future<void> _fetchCustomerYLocalPosition() async {
    try {
      final response = await _orderService.getCustomerAndLocalPosition(pedido['id']);
      if (response.statusCode == 200) {
        final data = response.data;
        localPosition.value = LatLng(
          data['locallat'] is String ? double.parse(data['locallat']) : data['locallat'],
          data['locallon'] is String ? double.parse(data['locallon']) : data['locallon']
        );
        customerPosition.value = LatLng(
          data['custlon'] is String ? double.parse(data['custlon']) : data['custlon'],
          data['custlat'] is String ? double.parse(data['custlat']) : data['custlat']
        );
      }
    } catch (e) {
      print("Error fetching positions: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _fetchOrderStatus() async {
    if (actualizandoEstado.value) return;
    if (_ultimaActualizacionManual != null && DateTime.now().difference(_ultimaActualizacionManual!).inSeconds < 15) return;

    try {
      final response = await _orderService.getOrderStatus(pedido['id']);
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
            if (newState == 0 || newState == 8) {
              viajeFinalizado.value = true;
              _timerService.clearPedido(pedido['id']);
            }
          }
        }
      }
    } catch (e) {
      print("Error fetching order status: $e");
    }
  }

  Future<void> _fetchMotorcycleLocation() async {
    try {
      final response = await _orderService.getMotorcycleLocation(pedido['id']);
      if (response.statusCode == 200) {
        final data = response.data;
        double lat = double.parse(data['lat']);
        double lon = double.parse(data['lon']);
        motorizadoPosition.value = LatLng(lat, lon);

        if (currentState.value > 0 && currentState.value < 5 && localPosition.value != null) {
          _cargarRuta(motorizadoPosition.value!, localPosition.value!);
        } else if (currentState.value == 6 && customerPosition.value != null) {
          _cargarRuta(motorizadoPosition.value!, customerPosition.value!);
        }
        
        if (currentState.value == 7) {
          _onEstadoSieteDetectado();
        }
      }
    } catch (e) {
      print("Error fetching motorcycle location: $e");
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
      print("Error loading route: $e");
    }
  }

  void _onEstadoSieteDetectado() {
    if (_alertaSieteTimer != null || viajeFinalizado.value || alertaEnviada) return;

    _alertaSieteTimer = Timer(const Duration(minutes: 7), () async {
      _alertaSieteTimer = null;
      if (!viajeFinalizado.value && !alertaEnviada) {
        alertaEnviada = true;
        await _orderService.sendHelpAlert(pedido['id']);
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
              currentState.value = nuevoEstado;

              if (nuevoEstado != 7) {
                _alertaSieteTimer?.cancel();
                _alertaSieteTimer = null;
              }
              if (nuevoEstado == 0 || nuevoEstado == 8) {
                viajeFinalizado.value = true;
              }

              try {
                await _orderService.updatePedidoEstado(pedido['id'], nuevoEstado);
                await Future.delayed(const Duration(seconds: 10));
              } catch (e) {
                currentState.value = previousState;
                Get.snackbar('Error', 'Error al actualizar estado');
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
    final startTime = _timerService.getStartTimeForPedidoSync(pedido['id']);
    if (startTime == null) return '00:00';

    final elapsed = _timerService.getElapsedTimeForPedidoSync(pedido['id']);
    final minutes = elapsed.inMinutes;
    final seconds = elapsed.inSeconds % 60;

    if (minutes < 60) {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      final hours = minutes ~/ 60;
      final mins = minutes % 60;
      return '${hours}h ${mins.toString().padLeft(2, '0')}m';
    }
  }
}
