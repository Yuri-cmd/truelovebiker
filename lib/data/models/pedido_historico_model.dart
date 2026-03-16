class PedidoHistorico {
  final int id;
  final String local;
  final String establecimiento;
  final String direccionLocal;
  final String direccionEntrega;
  final String cliente;
  final String celular;
  final String? tiempoEstimado;
  final String? detalle;
  final String latLocal;
  final String lonLocal;
  final String latitud;
  final String longitud;
  final String productos;
  final String estado;
  final int tiempo;
  final String? nota;
  final String tipoPago;
  final String precioDelivery;
  final double total;
  final String tipoComprobante;
  final List<String> productosList;
  final String actualizado;
  final String descuento;
  final String? celularLocal;

  PedidoHistorico({
    required this.id,
    required this.local,
    required this.establecimiento,
    required this.direccionLocal,
    required this.direccionEntrega,
    required this.cliente,
    required this.celular,
    this.tiempoEstimado,
    this.detalle,
    required this.latLocal,
    required this.lonLocal,
    required this.latitud,
    required this.longitud,
    required this.productos,
    required this.estado,
    required this.tiempo,
    this.nota,
    required this.tipoPago,
    required this.precioDelivery,
    required this.total,
    required this.tipoComprobante,
    required this.productosList,
    required this.actualizado,
    required this.descuento,
    this.celularLocal,
  });

  factory PedidoHistorico.fromJson(Map<String, dynamic> json) {
    return PedidoHistorico(
      id: json['id'],
      local: json['local'] ?? '',
      establecimiento: json['establecimiento'] ?? '',
      direccionLocal: json['direccionLocal'] ?? '',
      direccionEntrega: json['direccionEntrega'] ?? '',
      cliente: json['cliente'] ?? '',
      celular: json['celular'] ?? '',
      tiempoEstimado: json['tiempoEstimado'],
      detalle: json['detalle'],
      latLocal: json['latLocal'] ?? '',
      lonLocal: json['lonLocal'] ?? '',
      latitud: json['latitud'] ?? '',
      longitud: json['longitud'] ?? '',
      productos: json['productos'] ?? '',
      estado: json['estado']?.toString() ?? '',
      tiempo: json['tiempo'] ?? 0,
      nota: json['nota'],
      tipoPago: json['tipoPago'] ?? '',
      precioDelivery: json['precioDelivery']?.toString() ?? '0.00',
      total:
          (json['total'] is int)
              ? (json['total'] as int).toDouble()
              : (json['total'] is String)
              ? double.tryParse(json['total']) ?? 0.0
              : (json['total'] as num?)?.toDouble() ?? 0.0,
      tipoComprobante: json['tipoComprobante'] ?? '',
      productosList:
          (json['productosList'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      actualizado: json['actualizado'] ?? '',
      descuento: json['descuento']?.toString() ?? '0.00',
      celularLocal: json['celularLocal'],
    );
  }
}
