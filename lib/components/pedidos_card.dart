import 'dart:async';
import 'package:flutter/material.dart';
import 'package:truelovebiker/helpers/image_helper.dart';

class PedidoCard extends StatefulWidget {
  final Map<String, dynamic> pedido;
  final VoidCallback onTap;

  const PedidoCard({super.key, required this.pedido, required this.onTap});

  @override
  State<PedidoCard> createState() => _PedidoCardState();
}

class _PedidoCardState extends State<PedidoCard> {
  Timer? _counterTimer;
  int? _secondsRemaining; // contador local en segundos si no hay timestamp
  bool _usingLocalCountdown = false;

  @override
  void initState() {
    super.initState();
    // Inicializar contador local si no hay fecha de inicio/actualizado en el pedido
    final fecha = _obtenerFechaDePedido();
    if (fecha == null) {
      // Intentar inicializar desde el campo `tiempo` (minutos)
      final tiempo = widget.pedido['tiempo'];
      int minutos = 0;
      if (tiempo is String) {
        minutos = int.tryParse(tiempo) ?? 0;
      } else if (tiempo is int) {
        minutos = tiempo;
      } else if (tiempo is double) {
        minutos = tiempo.round();
      }

      if (minutos > 0) {
        _secondsRemaining = minutos * 60;
        _usingLocalCountdown = true;
      }
    }

    // Actualizar el contador cada segundo para mostrar decremento en tiempo real
    _counterTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;

      if (_usingLocalCountdown) {
        if (_secondsRemaining != null && _secondsRemaining! > 0) {
          setState(() {
            _secondsRemaining = _secondsRemaining! - 1;
          });
        }
      } else {
        // Forzar rebuild para actualizar tiempo calculado por fecha (si existe)
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _counterTimer?.cancel();
    super.dispose();
  }

  String _formatearTiempoRestante(String? fechaInicio, dynamic tiempoDuracion) {
    if (fechaInicio == null || fechaInicio.isEmpty || tiempoDuracion == null) {
      return 'Sin tiempo definido';
    }
    
    try {
      // Parsear la fecha de inicio
      DateTime fechaInicioDateTime;
      
      // Intentar diferentes formatos de fecha
      try {
        fechaInicioDateTime = DateTime.parse(fechaInicio);
      } catch (e) {
        // Si falla, intentar con formato personalizado o usar la fecha actual
        return 'Formato de fecha inválido';
      }
      
      DateTime ahora = DateTime.now();
      
      // Convertir duración a minutos
      int duracionMinutos = 0;
      if (tiempoDuracion is String) {
        duracionMinutos = int.tryParse(tiempoDuracion) ?? 0;
      } else if (tiempoDuracion is int) {
        duracionMinutos = tiempoDuracion;
      } else if (tiempoDuracion is double) {
        duracionMinutos = tiempoDuracion.round();
      }
      
      if (duracionMinutos <= 0) return 'Sin tiempo definido';
      
      // Calcular tiempo transcurrido desde el inicio
      Duration tiempoTranscurrido = ahora.difference(fechaInicioDateTime);
      int minutosTranscurridos = tiempoTranscurrido.inMinutes;
      
      // Calcular tiempo restante
      int minutosRestantes = duracionMinutos - minutosTranscurridos;
      
      if (minutosRestantes <= 0) {
        return 'Tiempo vencido';
      }
      
      // Formatear tiempo restante
      if (minutosRestantes < 60) {
        return '${minutosRestantes}m restantes';
      } else {
        int horas = minutosRestantes ~/ 60;
        int minutos = minutosRestantes % 60;
        if (minutos > 0) {
          return '${horas}h ${minutos}m restantes';
        } else {
          return '${horas}h restantes';
        }
      }
    } catch (e) {
      return 'Error de tiempo';
    }
  }

  // Intenta obtener una fecha (string) válida desde distintas claves posibles
  String? _obtenerFechaDePedido() {
    final posibles = [
      'fecha_inicio',
      'actualizado',
      'updated_at',
      'fecha_inicio_at',
      'created_at',
    ];

    for (final key in posibles) {
      final v = widget.pedido[key];
      if (v != null) {
        final s = v.toString();
        if (s.isNotEmpty) return s;
      }
    }
    return null;
  }

  // Formatea segundos restantes en cadena legible
  String _formatSecondsRemaining(int seconds) {
    if (seconds <= 0) return 'Tiempo vencido';
    final minutes = seconds ~/ 60;
    if (minutes < 60) return '${minutes}m restantes';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (mins > 0) return '${hours}h ${mins}m restantes';
    return '${hours}h restantes';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: widget.onTap,
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        elevation: 5,
        color: colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.location_on, color: Colors.redAccent, size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// Título principal y tiempo estimado
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            widget.pedido['local'] ?? 'Sin nombre',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Mostrar tiempo restante si hay fecha de inicio o si usamos contador local
                        if (_usingLocalCountdown || widget.pedido['fecha_inicio'] != null || widget.pedido['actualizado'] != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.withAlpha(
                                (0.1 * 255).toInt(),
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.orange.withAlpha((0.3 * 255).toInt()),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.timer,
                                  size: 14,
                                  color: Colors.orange,
                                ),
                                const SizedBox(width: 4),
                                        Text(
                                          // Si estamos usando contador local, mostrar ese valor
                                          _usingLocalCountdown && _secondsRemaining != null
                                              ? _formatSecondsRemaining(_secondsRemaining!)
                                              : _formatearTiempoRestante(
                                                  _obtenerFechaDePedido(),
                                                  widget.pedido['tiempo'],
                                                ),
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.orange,
                                          ),
                                        ),
                              ],
                            ),
                          )
                        else
                          // Fallback: mostrar tiempo estimado original
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blueAccent.withAlpha(
                                (0.1 * 255).toInt(),
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${widget.pedido['tiempo'] ?? '0'}m estimado',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.blueAccent,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    _buildInfoLine(
                      context,
                      'Dirección Local',
                      widget.pedido['direccion_local'],
                    ),
                    _buildInfoLine(
                      context,
                      'Dirección Entrega',
                      widget.pedido['direccion_entrega'],
                    ),
                    _buildInfoLine(context, 'Nota', widget.pedido['nota']),
                    _buildInfoLine(
                      context,
                      'Delivery',
                      'S/. ${widget.pedido['precio_delivery']}',
                    ),
                    _buildInfoLine(
                      context,
                      'Total',
                      'S/. ${widget.pedido['total'].toString()}',
                    ),
                    _buildInfoLine(
                      context,
                      'Descuento',
                      'S/. ${widget.pedido['descuento'].toString()}',
                    ),
                    /// Método de pago + ícono
                    Row(
                      children: [
                        Text(
                          'Pago: ',
                          style: TextStyle(
                            fontSize: 14,
                            color: colorScheme.onSurface.withAlpha(
                              (0.6 * 255).toInt(),
                            ),
                          ),
                        ),
                        Text(
                          widget.pedido['tipoPago'] ?? 'N/A',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(width: 6),
                        getMetodoPagoImage(widget.pedido['tipoPago']),
                      ],
                    ),
                    _buildInfoLine(
                      context,
                      'Tipo Comprobante',
                      widget.pedido['tipo_comprobante'].toString(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoLine(BuildContext context, String label, String? value) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: RichText(
        text: TextSpan(
          text: '$label: ',
          style: TextStyle(
            fontSize: 14,
            color: colorScheme.onSurface.withAlpha((0.6 * 255).toInt()),
          ),
          children: [
            TextSpan(
              text: value ?? 'N/A',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
