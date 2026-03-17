import 'package:dio/dio.dart';
import 'package:truelovebiker/core/api/api_client.dart';

class OrderService {
  final Dio _dio = ApiClient.dio;

  Future<Response> getPedidos(int bikerId) async {
    return await _dio.get('biker/get/pedidos/$bikerId');
  }

  Future<Response> startTrip(int bikerId, int pedidoId) async {
    // Original used form-urlencoded
    return await _dio.post(
      'biker/iniciar_viaje', 
      data: FormData.fromMap({
        'id_motorizado': bikerId.toString(),
        'id': pedidoId.toString()
      })
    );
  }

  Future<Response> updatePedidoEstado(int pedidoId, int estado) async {
    return await _dio.post(
      'update-estado/pedido',
      data: FormData.fromMap({
        'id': pedidoId.toString(),
        'estado': estado.toString()
      })
    );
  }

  Future<Response> getOrderStatus(int pedidoId) async {
    return await _dio.get('pedidos/$pedidoId');
  }

  Future<Response> getMotorcycleLocation(int pedidoId) async {
    return await _dio.get('motorcycle-location/$pedidoId');
  }

  Future<Response> getCustomerAndLocalPosition(int pedidoId) async {
    return await _dio.get('customer-local-location/$pedidoId');
  }

  Future<Response> sendHelpAlert(int pedidoId) async {
    return await _dio.post('biker/alerta-auxilio', data: {'id_pedido': pedidoId});
  }

  Future<Response> updateLocation(int bikerId, double lat, double lon) async {
    return await _dio.post('biker/location/update', data: {
      'latitude': lat,
      'longitude': lon,
      'motorizado_id': bikerId,
    });
  }

  Future<Response> getViajesActivos(int bikerId) async {
    return await _dio.get('biker/viajes-activos/$bikerId');
  }

  Future<Response> getViajes(int bikerId) async {
    return await _dio.get('biker/viajes/$bikerId');
  }

  Future<Response> getOrderHistory(int bikerId) async {
    return await _dio.get('biker/viajes/$bikerId');
  }
}
