import 'package:dio/dio.dart';
import 'package:truelovebiker/core/api/api_client.dart';

class ChatService {
  final Dio _dio = ApiClient.dio;

  Future<List<Map<String, dynamic>>> getMessages(int pedidoId) async {
    final response = await _dio.get('chats/$pedidoId');

    if (response.statusCode == 200) {
      final List<dynamic> jsonData = response.data;
      return jsonData.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Error al cargar mensajes');
    }
  }

  Future<bool> sendMessage({
    required int pedidoId,
    required int senderId,
    required String message,
  }) async {
    final response = await _dio.post(
      'chats/storeMotorizado',
      data: {
        'pedido_id': pedidoId,
        'sender_id': senderId,
        'message': message,
      },
    );

    return response.statusCode == 201;
  }
}
