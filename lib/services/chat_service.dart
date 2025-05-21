import 'dart:convert';
import 'package:http/http.dart' as http;

class ChatService {
  // static const String baseUrl =
  // 'https://magusemail.com/truelove-back/public/api';
  static const String baseUrl = 'http://192.168.100.2/truelove-back/public/api';

  Future<List<Map<String, dynamic>>> getMessages(int pedidoId) async {
    final response = await http.get(Uri.parse('$baseUrl/chats/$pedidoId'));

    if (response.statusCode == 200) {
      final List<dynamic> jsonData = json.decode(response.body);
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
    final response = await http.post(
      Uri.parse('$baseUrl/chats/storeCliente'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'pedido_id': pedidoId,
        'sender_id': senderId,
        'message': message,
      }),
    );

    return response.statusCode == 201;
  }
}
