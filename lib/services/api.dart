import 'dart:convert';
import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:truelovebiker/model/pedido_model.dart';
import 'package:truelovebiker/model/rating_model.dart';
import 'package:truelovebiker/model/pedido_historico_model.dart';

class ApiService {
  static const String _productionUrl =
      'https://magusemail.com/truelove-back/public/api';
  static const String _localUrl =
      'http://192.168.100.50/truelove-back/public/api';

  // Cambiar este valor para alternar entre desarrollo y producción
  static const bool _useProduction = true;

  static String get baseUrl => _useProduction ? _productionUrl : _localUrl;

  static Future<dynamic> _post(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/$endpoint'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      // Intentar decodificar JSON para códigos 200-499
      if (response.statusCode >= 200 && response.statusCode < 500) {
        try {
          return json.decode(response.body);
        } catch (e) {
          throw Exception('Error al procesar respuesta del servidor');
        }
      } else {
        throw Exception('Error en el servidor (${response.statusCode})');
      }
    } catch (e) {
      rethrow;
    }
  }

  static Future<int?> getUsuarioId() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt('id_biker');
  }

  static Future<dynamic> sendLogin(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    final response = await _post(endpoint, data);

    if (response['status'] == 'success') {
      // Guardar datos en SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();

      // Obtener datos del usuario
      String usuario = response['user']['usuario'];
      int idbiker = response['repartidor']['id'];
      String name = response['user']['name'];
      String email = response['user']['email'];

      // Guardar en SharedPreferences
      await prefs.setInt('id_biker', idbiker);
      await prefs.setString('usuario', usuario);
      await prefs.setString('name', name);
      await prefs.setString('email', email);
      await prefs.setBool('isLoggedIn', true);

      // Enviar el token almacenado a la API
      String? tokenFcm = prefs.getString('token_fcm');
      if (tokenFcm != null && tokenFcm.isNotEmpty) {
        await updateFcmToken(response['repartidor']['id'], tokenFcm);
      }
    }

    return response;
  }

  static Future<bool> updateFcmToken(int idBiker, String tokenFcm) async {
    final url = Uri.parse("$baseUrl/biker/update-token");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"id_reparto": idBiker, "token_fcm": tokenFcm}),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  static Future<http.Response> startTripApi(int idBiker, int id) async {
    final url = Uri.parse(
      '$baseUrl/biker/iniciar_viaje',
    ); // Cambia esta URL por la correcta de tu API
    final response = await http.post(
      url,
      body: {'id_motorizado': idBiker.toString(), 'id': id.toString()},
    );
    return response;
  }

  Future<List<Pedido>> fetchPedidos() async {
    final int? idBiker = await getUsuarioId();
    final String apiUrl = '$baseUrl/biker/get/pedidos/$idBiker';
    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final dynamic decodedResponse = json.decode(response.body);

        // Verificar si la respuesta es una lista
        if (decodedResponse is List) {
          return decodedResponse
              .map((pedido) => Pedido.fromJson(pedido))
              .toList();
        } else {
          throw Exception('Formato inesperado de respuesta');
        }
      } else {
        throw Exception('Error al cargar los pedidos');
      }
    } catch (error) {
      throw Exception('Error al obtener los pedidos: $error');
    }
  }

  static Future<bool> sendLocationData(
    double latitude,
    double longitude,
  ) async {
    final int? usuarioId = await getUsuarioId();
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/biker/location/update'),
        body: jsonEncode({
          'latitude': latitude,
          'longitude': longitude,
          'motorizado_id': usuarioId,
        }),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return true; // ✅ Éxito
      } else {
        throw ('⚠️ Error en la API: ${response.body}');
      }
    } catch (e) {
      throw ('❌ Error al enviar la ubicación: $e');
    }
  }

  static Future<List<RatingModel>> fetchRatings() async {
    final int? usuarioId = await getUsuarioId();
    final response = await http.get(
      Uri.parse('$baseUrl/ratings/biker/$usuarioId'),
    );

    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => RatingModel.fromJson(json)).toList();
    } else {
      throw Exception('Error al cargar los datos');
    }
  }

  static Future<List<LatLng>> obtenerRuta(
    LatLng origen,
    LatLng destino,
    String mapboxAccessToken,
  ) async {
    final String url =
        'https://api.mapbox.com/directions/v5/mapbox/driving/${origen.longitude},${origen.latitude};${destino.longitude},${destino.latitude}?geometries=geojson&access_token=$mapboxAccessToken';

    try {
      final Response response = await Dio().get(url);
      if (response.statusCode == 200) {
        final List<dynamic> coordinates =
            response.data['routes'][0]['geometry']['coordinates'];

        return coordinates.map((coord) => LatLng(coord[1], coord[0])).toList();
      }
    } catch (e) {
      throw ('Error obteniendo la ruta: $e');
    }
    return [];
  }

  static Future<Map<String, dynamic>> fetchOrderStatus(int idPedido) async {
    final response = await http.get(
      Uri.parse('$baseUrl/pedidos/${idPedido.toString()}'),
    );
    try {
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to POST to $baseUrl');
      }
    } catch (error) {
      throw Exception('Error al guardar el pedido: $error');
    }
  }

  static Future<Map<String, dynamic>> fetchMotorcycleLocation(
    int idPedido,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/motorcycle-location/$idPedido'),
      );

      if (response.statusCode == 200) {
        // Si la respuesta es exitosa, parseamos los datos
        return json.decode(response.body);
      } else {
        throw Exception('Error al obtener la ubicación del motorizado');
      }
    } catch (e) {
      throw Exception('Error de red: $e');
    }
  }

  static Future<http.Response> actualizarEstado(
    int idPedido,
    int estado,
  ) async {
    final url = Uri.parse(
      '$baseUrl/update-estado/pedido',
    ); // Cambia esta URL por la correcta de tu API
    final response = await http.post(
      url,
      body: {'id': idPedido.toString(), 'estado': estado.toString()},
    );
    return response;
  }

  static Future<Map<String, dynamic>> fetchCustomerYLocalPosition(
    int idPedido,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/customer-local-location/$idPedido'),
      );

      if (response.statusCode == 200) {
        // Si la respuesta es exitosa, parseamos los datos
        return json.decode(response.body);
      } else {
        throw Exception('Error al obtener la ubicación del motorizado');
      }
    } catch (e) {
      throw Exception('Error de red: $e');
    }
  }

  Future<Map<String, dynamic>?> obtenerPerfilRepartidor() async {
    final int? usuarioId = await getUsuarioId();
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/biker/perfil/$usuarioId"),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        throw ("Error al obtener el perfil: ${response.statusCode}");
      }
    } catch (e) {
      throw ("Error en la consulta: $e");
    }
  }

  static Future<void> mandarAlertaDeAuxilio(int idPedido) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/biker/alerta-auxilio'),
        body: jsonEncode({'id_pedido': idPedido}),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode != 200) {
        throw Exception('Error al mandar alerta');
      }
    } catch (e) {
      throw ('Error mandando alerta de auxilio: $e');
    }
  }

  static Future<bool> submitRating({
    required int idPedido,
    required int restaurantRating,
    required String restaurantComment,
    required int motorcycleRating,
    required String motorcycleComment,
  }) async {
    final url = Uri.parse("$baseUrl/ratings");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "id_pedido": idPedido,
        "restaurant_rating": restaurantRating,
        "restaurant_comment": restaurantComment,
        "motorcycle_rating": motorcycleRating,
        "motorcycle_comment": motorcycleComment,
      }),
    );

    if (response.statusCode == 201) {
      return true;
    } else {
      return false;
    }
  }

  Future<Map<String, dynamic>> verificarCondiciones(int id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/biker/condiciones/$id'),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      return {
        'puede_trabajar': false,
        'mensaje': 'Error al consultar condiciones',
      };
    }
  }

  Future<bool> actualizarEstadoRepartidor(int activo) async {
    try {
      final int? usuarioId = await getUsuarioId();
      final response = await http.post(
        Uri.parse('$baseUrl/repartidor/estado'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'activo': activo, 'id': usuarioId}),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  static Future<Map<String, dynamic>> sendCode(String email) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/biker/sendCode"),
        body: {'email': email},
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return data;
      } else {
        // Si el backend devuelve error con json (como en tu ejemplo)
        return {
          'success': false,
          'message': data['message'] ?? 'Error desconocido',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error en la consulta: $e'};
    }
  }

  static Future<Map<String, dynamic>> updatePassword(
    int id,
    String newPassword,
  ) async {
    try {
      final url = Uri.parse('$baseUrl/biker/update-password');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'id': id, 'password': newPassword}),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'message': responseData['message']};
      } else {
        return {'success': false, 'message': responseData['message']};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión'};
    }
  }

  static Future<List<Map<String, dynamic>>> fetchBancos() async {
    final response = await http.get(Uri.parse('$baseUrl/bancos'));
    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((e) => e as Map<String, dynamic>).toList();
    } else {
      throw Exception('Error al cargar bancos');
    }
  }

  static Future<List<Map<String, dynamic>>> fetchTiposCuenta() async {
    final response = await http.get(Uri.parse('$baseUrl/tipos-cuenta'));
    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((e) => e as Map<String, dynamic>).toList();
    } else {
      throw Exception('Error al cargar tipos de cuenta');
    }
  }

  static Future<Map<String, dynamic>> actualizarCuentaBancaria({
    required int id,
    required String titular,
    required String dni,
    required int bancoId,
    required int tipoCuentaId,
    required String numeroCuenta,
    dynamic imagenCuenta, // Puede ser un File o null
  }) async {
    var uri = Uri.parse('$baseUrl/cuenta-bancaria/$id');
    var request = http.MultipartRequest('POST', uri);
    request.fields['_method'] = 'POST';
    request.fields['titular'] = titular;
    request.fields['dni'] = dni;
    request.fields['banco_id'] = bancoId.toString();
    request.fields['tipo_cuenta_id'] = tipoCuentaId.toString();
    request.fields['numero_cuenta'] = numeroCuenta;
    request.fields['imagen_cuenta'] = '';

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else if (response.statusCode == 422) {
      // Errores de validación
      throw Exception(
        json.decode(response.body)['errores'] ?? 'Error de validación',
      );
    } else {
      throw Exception('Error al guardar datos bancarios');
    }
  }

  static Future<Map<String, dynamic>> actualizarDatosRepartidor({
    required int id,
    required String celular,
    required String email,
    required String departamento,
  }) async {
    final uri = Uri.parse('$baseUrl/repartidores/info/$id');
    final response = await http.put(
      uri,
      headers: {
        'Content-Type': 'application/json',
        // Agrega aquí tu header de autorización si usas JWT/Bearer
      },
      body: json.encode({
        'celular': celular,
        'email': email,
        'departamento': departamento,
      }),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else if (response.statusCode == 422) {
      throw Exception(
        json.decode(response.body)['errores'] ?? 'Error de validación',
      );
    } else {
      throw Exception('Error al actualizar datos personales');
    }
  }

  // Método para verificar si el motorizado tiene un viaje activo
  static Future<Map<String, dynamic>?> verificarViajeActivo() async {
    try {
      final int? idBiker = await getUsuarioId();
      if (idBiker == null) return null;

      final response = await http.get(
        Uri.parse('$baseUrl/biker/viaje-activo/$idBiker'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Si hay un viaje activo, devuelve la información del pedido
        if (data['tiene_viaje_activo'] == true) {
          return data['pedido'];
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Método para obtener todos los viajes activos del motorizado
  static Future<List<Map<String, dynamic>>> obtenerViajesActivos() async {
    try {
      final int? idBiker = await getUsuarioId();
      if (idBiker == null) return [];
      final response = await http.get(
        Uri.parse('$baseUrl/biker/viajes-activos/$idBiker'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Si la respuesta es directamente un array
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        }
        // Si la respuesta es un objeto con propiedad 'viajes'
        else if (data is Map && data['viajes'] != null) {
          return List<Map<String, dynamic>>.from(data['viajes']);
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<List<PedidoHistorico>> fetchHistorialPedidos() async {
    try {
      final int? idBiker = await getUsuarioId();
      if (idBiker == null) return [];

      final response = await http.get(
        Uri.parse('$baseUrl/biker/viajes/$idBiker'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => PedidoHistorico.fromJson(json)).toList();
      } else {
        throw Exception('Error al cargar historial de pedidos');
      }
    } catch (e) {
      throw Exception('Error al obtener historial: $e');
    }
  }

  Future<Map<String, dynamic>> getAppVersion(String appName) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/app-version/$appName'),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {
          'status': response.statusCode,
          'message': 'Error al obtener la versión',
        };
      }
    } catch (e) {
      return {'status': 500, 'message': 'Error de conexión'};
    }
  }

  static Future<void> acknowledgeNotification(
    String? notificationId,
    String status,
  ) async {
    if (notificationId == null || notificationId.isEmpty) return;

    try {
      await http.post(
        Uri.parse('$baseUrl/notifications/update-status'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'notification_id': notificationId, 'status': status}),
      );
    } catch (e) {
      log('Error acknowledging notification: $e');
    }
  }
}
