class Pedido {
  final int id;
  final String local;
  final String direccionLocal;
  final String direccionEntrega;
  final String cliente;
  final String celular;
  final int tiempoEstimado;
  final String detalle;
  final double latLocal;
  final double lonLocal;
  final double latitud;
  final double longitud;
  final String productos;
  final String estado;
  final int tiempo;
  final String nota;
  final String tipoPago;

  Pedido({
    required this.id,
    required this.local,
    required this.direccionLocal,
    required this.direccionEntrega,
    required this.cliente,
    required this.celular,
    required this.tiempoEstimado,
    required this.detalle,
    required this.latLocal,
    required this.lonLocal,
    required this.latitud,
    required this.longitud,
    required this.productos,
    required this.estado,
    required this.tiempo,
    required this.nota,
    required this.tipoPago,
  });

  factory Pedido.fromJson(Map<String, dynamic> json) {
    return Pedido(
      id: json['id'],
      local: json['local'] ?? '',
      direccionLocal: json['direccion_local'] ?? '',
      direccionEntrega: json['direccion_entrega'] ?? '',
      cliente: json['cliente'] ?? '',
      celular: json['celular'] ?? '',
      tiempoEstimado: json['tiempo_estimado'] ?? 0,
      detalle: json['detalle'] ?? '',
      latLocal: json['latitud'] ?? '',
      lonLocal: json['longitud'] ?? '',
      latitud: json['lat_local'] ?? '',
      longitud: json['lon_local'] ?? '',
      productos: json['detalle'] ?? '',
      estado: json['estado'] ?? '',
      tiempo: json['tiempo'] ?? '',
      nota: json['nota'] ?? '',
      tipoPago: json['tipo_pago'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'local': local,
      'direccion_local': direccionLocal,
      'direccion_entrega': direccionEntrega,
      'cliente': cliente,
      'celular': celular,
      'lat_local': latLocal,
      'lon_local': lonLocal,
      'latitud': latitud,
      'longitud': longitud,
      'tiempoEstimado': tiempoEstimado,
      'productos': productos,
      'estado': estado,
      'tiempo': tiempo,
      'nota': nota,
      'tipoPago': tipoPago,
    };
  }
}
