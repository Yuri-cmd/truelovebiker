import 'package:dio/dio.dart';
import 'package:truelovebiker/core/api/api_client.dart';

class RatingService {
  final Dio _dio = ApiClient.dio;

  Future<Response> getBikerRatings(int bikerId) async {
    return await _dio.get('ratings/biker/$bikerId');
  }

  Future<Response> submitRating({
    required int idPedido,
    required int restaurantRating,
    required String restaurantComment,
    required int motorcycleRating,
    required String motorcycleComment,
  }) async {
    return await _dio.post('ratings', data: {
      "id_pedido": idPedido,
      "restaurant_rating": restaurantRating,
      "restaurant_comment": restaurantComment,
      "motorcycle_rating": motorcycleRating,
      "motorcycle_comment": motorcycleComment,
    });
  }
}
