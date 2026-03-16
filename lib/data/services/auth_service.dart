import 'package:dio/dio.dart';
import 'package:truelovebiker/core/api/api_client.dart';

class AuthService {
  final Dio _dio = ApiClient.dio;

  Future<Response> login(String usuario, String password) async {
    return await _dio.post('auth/login', data: {
      'usuario': usuario,
      'password': password,
    });
  }

  Future<Response> updateFcmToken(int idBiker, String tokenFcm) async {
    return await _dio.post('biker/update-token', data: {
      'id_reparto': idBiker,
      'token_fcm': tokenFcm,
    });
  }

  Future<Response> sendCode(String email) async {
    // Note: Original used http.post with body: {'email': email} which defaults to form-urlencoded
    return await _dio.post(
      'biker/sendCode', 
      data: FormData.fromMap({'email': email})
    );
  }

  Future<Response> updatePassword(int id, String newPassword) async {
    return await _dio.post('biker/update-password', data: {
      'id': id,
      'password': newPassword,
    });
  }

  Future<Response> updateBikerStatus(int id, int activo) async {
    return await _dio.post('repartidor/estado', data: {
      'id': id,
      'activo': activo,
    });
  }
  
  Future<Response> checkBikerConditions(int id) async {
    return await _dio.get('biker/condiciones/$id');
  }

  Future<Response> deleteAccount() async {
    return await _dio.post('account/request-deletion');
  }
}
