import 'package:dio/dio.dart';
import 'package:truelovebiker/core/constants/constants.dart';
import 'package:get/get.dart' as getx;
import 'package:truelovebiker/core/storage/secure_storage.dart';

class ApiClient {
  static final Dio _dio = _createDio();

  static Dio _createDio() {
    var dio = Dio(
      BaseOptions(
        baseUrl: Constants.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await SecureStorage.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          if (e.response?.statusCode == 401) {
            await SecureStorage.clearSession();
            if (getx.Get.context != null) {
              getx.Get.offAllNamed('/login');
            }
          }
          return handler.next(e);
        },
      ),
    );
    return dio;
  }

  static Dio get dio => _dio;
}
