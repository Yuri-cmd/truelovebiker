import 'dart:io';
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

  /// Notas y fotos que otros repartidores dejaron sobre el lugar de entrega del pedido.
  /// El repartidor se identifica por el token (Authorization), no por un id.
  Future<Response> getNotasEntrega(int pedidoId) async {
    return await _dio.get(
      'biker/pedidos/$pedidoId/notas-entrega',
      options: Options(extra: {'no_logout_401': true}),
    );
  }

  Future<Response> addNotaEntrega({
    required int pedidoId,
    String? nota,
    File? foto,
  }) async {
    final form = FormData.fromMap({
      if (nota != null && nota.trim().isNotEmpty) 'nota': nota.trim(),
      if (foto != null)
        'foto': await MultipartFile.fromFile(
          foto.path,
          filename: 'casa_${pedidoId}_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
    });
    return await _dio.post(
      'biker/pedidos/$pedidoId/notas-entrega',
      data: form,
      options: Options(extra: {'no_logout_401': true}),
    );
  }

  Future<Response> deleteNotaEntrega(int notaId) async {
    return await _dio.delete(
      'biker/notas-entrega/$notaId',
      options: Options(extra: {'no_logout_401': true}),
    );
  }

  /// GPS en vivo del cliente (null si no lo comparte o el pedido aún no va en camino).
  Future<Response> getClientLiveLocation(int pedidoId) async {
    return await _dio.get('pedido/$pedidoId/ubicacion-cliente');
  }

  /// El repartidor cancela un pedido que no pudo entregar (queda cancelado al instante). Un administrador lo
  /// revisa después y, si fue culpa del cliente, puede generarle una deuda.
  Future<Response> solicitarCancelacion({
    required int pedidoId,
    required String motivo,
    String? detalle,
    bool culpaCliente = false,
  }) async {
    return await _dio.post('biker/pedidos/$pedidoId/solicitar-cancelacion', data: {
      'motivo': motivo,
      if (detalle != null && detalle.isNotEmpty) 'detalle': detalle,
      'culpa_cliente': culpaCliente,
    });
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
