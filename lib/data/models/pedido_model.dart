class Pedido {
  final int id;
  final String local;
  final String direccionLocal;
  final String direccionEntrega;
  final String cliente;
  final String celular;
  final String? celularWhatsapp;
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
  final String precioDelivery;
  final double total;
  final String tipoComprobante;
  final String? descuento;
  final String? fechaInicio;
  final String? fechaHoraInicio;
  final String? actualizado;
  final double? subtotal;
  final String? celularLocal;
  final String? pagaCon;

  Pedido({
    required this.id,
    required this.local,
    required this.direccionLocal,
    required this.direccionEntrega,
    required this.cliente,
    required this.celular,
    this.celularWhatsapp,
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
    required this.precioDelivery,
    required this.total,
    required this.tipoComprobante,
    required this.descuento,
    this.fechaInicio,
    this.fechaHoraInicio,
    this.actualizado,
    this.subtotal,
    this.celularLocal,
    this.pagaCon,
  });

  factory Pedido.fromJson(Map<String, dynamic> json) {
    return Pedido.fromMap(json);
  }

  factory Pedido.fromMap(Map<String, dynamic> map) {
    return Pedido(
      id: map['id'] ?? 0,
      local: map['local'] ?? map['establecimiento'] ?? '',
      direccionLocal: map['direccionLocal'] ?? map['direccion_local'] ?? map['direccion_completa'] ?? '',
      direccionEntrega: map['direccionEntrega'] ?? map['direccion_entrega'] ?? '',
      cliente: map['cliente'] ?? '',
      celular: map['celular'] ?? '',
      celularWhatsapp: map['celular_whatsapp']?.toString(),
      tiempoEstimado: map['tiempoEstimado'] ?? map['tiempo_estimado'] ?? 0,
      detalle: map['detalle'] ?? map['nota'] ?? '',
      latLocal: _toDouble(map['latLocal'] ?? map['lat_local'] ?? map['latitud_local']),
      lonLocal: _toDouble(map['lonLocal'] ?? map['lon_local'] ?? map['longitud_local']),
      latitud: _toDouble(map['latitud']),
      longitud: _toDouble(map['longitud']),
      productos: map['productos'] ?? map['detalle'] ?? '',
      estado: map['estado']?.toString() ?? '',
      tiempo: map['tiempo'] ?? 0,
      nota: map['nota'] ?? map['detalle'] ?? '',
      tipoPago: map['tipoPago'] ?? map['tipo_pago'] ?? '',
      precioDelivery: map['precioDelivery']?.toString() ?? map['precio_delivery']?.toString() ?? '0.00',
      tipoComprobante: map['tipoComprobante']?.toString() ?? map['tipo_comprobante']?.toString() ?? '',
      total: _toDouble(map['total']),
      descuento: map['descuento']?.toString(),
      fechaInicio: map['fecha_inicio'] ?? map['fecha_hora_inicio'],
      fechaHoraInicio: map['fecha_hora_inicio'] ?? map['fecha_inicio'],
      actualizado: map['actualizado']?.toString(),
      subtotal: _toDouble(map['subtotal']),
      celularLocal: map['celularLocal']?.toString() ?? map['celular_local']?.toString(),
      pagaCon: map['paga_con']?.toString() ?? map['pagaCon']?.toString(),
    );
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) {
      if (value.isEmpty) return 0.0;
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'local': local,
      'direccion_local': direccionLocal,
      'direccion_entrega': direccionEntrega,
      'cliente': cliente,
      'celular': celular,
      'celular_whatsapp': celularWhatsapp,
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
      'precio_delivery': precioDelivery,
      'total': total,
      'tipo_comprobante': tipoComprobante,
      'descuento': descuento,
      'fecha_inicio': fechaInicio,
      'fecha_hora_inicio': fechaHoraInicio,
      'actualizado': actualizado,
      'subtotal': subtotal,
      'celular_local': celularLocal,
      'paga_con': pagaCon,
    };
  }
}
