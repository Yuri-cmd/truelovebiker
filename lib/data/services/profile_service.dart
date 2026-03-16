import 'package:dio/dio.dart';
import 'package:truelovebiker/core/api/api_client.dart';

class ProfileService {
  final Dio _dio = ApiClient.dio;

  Future<Response> getBikerProfile(int bikerId) async {
    return await _dio.get('biker/perfil/$bikerId');
  }

  Future<Response> updateProfile({
    required int id,
    required String name,
    required String usuario,
    required String email,
    required String phone,
  }) async {
    return await _dio.post('biker/perfil/update', data: {
      'id': id,
      'name': name,
      'usuario': usuario,
      'email': email,
      'phone': phone,
    });
  }

  Future<Response> updateBankData({
    required int id,
    required String bank,
    required String accountType,
    required String accountCode,
    required String accountNumber,
  }) async {
    return await _dio.post('biker/cuenta-bancaria/update', data: {
      'id': id,
      'banco': bank,
      'tipo_cuenta': accountType,
      'codigo_interbancario': accountCode,
      'numero_cuenta': accountNumber,
    });
  }

  Future<Response> updateBikerInfo({
    required int id,
    required String cellul,
    required String email,
    required String department,
  }) async {
    return await _dio.put('repartidores/info/$id', data: {
      'celular': cellul,
      'email': email,
      'departamento': department,
    });
  }

  Future<Response> getBancos() async {
    return await _dio.get('bancos');
  }

  Future<Response> getTiposCuenta() async {
    return await _dio.get('tipos-cuenta');
  }

  Future<Response> updateBankAccount({
    required int id,
    required String titular,
    required String dni,
    required int bancoId,
    required int tipoCuentaId,
    required String numeroCuenta,
    dynamic imagenCuenta,
  }) async {
    return await _dio.post('cuenta-bancaria/$id', data: {
      'titular': titular,
      'dni': dni,
      'banco_id': bancoId,
      'tipo_cuenta_id': tipoCuentaId,
      'numero_cuenta': numeroCuenta,
      if (imagenCuenta != null) 'imagen_cuenta': imagenCuenta,
    });
  }
}
