class RatingModel {
  final int idPedido;
  final ClienteModel cliente;
  final RatingData? rating;

  RatingModel({required this.idPedido, required this.cliente, this.rating});

  factory RatingModel.fromJson(Map<String, dynamic> json) {
    return RatingModel(
      idPedido: json['id_pedido'],
      cliente: ClienteModel.fromJson(json['cliente']),
      rating:
          json['rating'] != null ? RatingData.fromJson(json['rating']) : null,
    );
  }
}

class ClienteModel {
  final int id;
  final String nombre;
  final String? telefono;

  ClienteModel({required this.id, required this.nombre, this.telefono});

  factory ClienteModel.fromJson(Map<String, dynamic> json) {
    return ClienteModel(
      id: json['id'],
      nombre: json['nombre'],
      telefono: json['telefono'],
    );
  }
}

class RatingData {
  final int motorcycleRating;
  final String motorcycleComment;

  RatingData({required this.motorcycleRating, required this.motorcycleComment});

  factory RatingData.fromJson(Map<String, dynamic> json) {
    return RatingData(
      motorcycleRating: json['motorcycle_rating'],
      motorcycleComment: json['motorcycle_comment'],
    );
  }
}
