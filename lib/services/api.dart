import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:truelovebiker/model/pedido_model.dart';
import 'package:truelovebiker/model/rating_model.dart';

class ApiService {
  static const String baseUrl =
      'https://magusemail.com/truelove-back/public/api';
  // static const String baseUrl = 'http://192.168.100.2/truelove-back/public/api';

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
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to POST to $endpoint');
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
      await prefs.setBool('isLoggedIn', true); // Para saber si está logueado

      // Enviar el token almacenado a la API
      String? tokenFcm = prefs.getString('token_fcm');
      if (tokenFcm != null) {
        await updateFcmToken(idbiker, tokenFcm);
      }

      return response;
    } else {
      throw Exception(response['message']);
    }
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
        print('⚠️ Error en la API: ${response.body}');
        return false; // ❌ Falló
      }
    } catch (e) {
      print('❌ Error al enviar la ubicación: $e');
      return false;
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
}
