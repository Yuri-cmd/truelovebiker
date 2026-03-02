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
  });

  factory Pedido.fromJson(Map<String, dynamic> json) {
    return Pedido(
      id: json['id'],
      local: json['local'] ?? '',
      direccionLocal: json['direccion_local'] ?? '',
      direccionEntrega: json['direccion_entrega'] ?? '',
      cliente: json['cliente'] ?? '',
      celular: json['celular'] ?? '',
      celularWhatsapp: json['celular_whatsapp'],
      tiempoEstimado: json['tiempo_estimado'] ?? 0,
      detalle: json['detalle'] ?? '',
      latLocal: (json['lat_local'] as num?)?.toDouble() ?? 0.0,
      lonLocal: (json['lon_local'] as num?)?.toDouble() ?? 0.0,
      latitud: (json['latitud'] as num?)?.toDouble() ?? 0.0,
      longitud: (json['longitud'] as num?)?.toDouble() ?? 0.0,
      productos: json['detalle'] ?? '',
      estado: json['estado']?.toString() ?? '',
      tiempo: json['tiempo'] ?? 0,
      nota: json['nota'] ?? '',
      tipoPago: json['tipo_pago'] ?? '',
      precioDelivery: json['precio_delivery']?.toString() ?? '',
      tipoComprobante: json['tipo_comprobante']?.toString() ?? '',
      total:
          (json['total'] is int)
              ? (json['total'] as int).toDouble()
              : (json['total'] is String)
              ? double.parse(json['total'])
              : (json['total'] as num?)?.toDouble() ?? 0.0,
      descuento: json['descuento']?.toString(),
      fechaInicio: json['fecha_inicio'],
      fechaHoraInicio: json['fecha_hora_inicio'],
      actualizado: json['actualizado'],
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
    };
  }
}
