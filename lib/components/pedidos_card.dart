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

  @override
  void initState() {
    super.initState();
    // Actualizar el contador cada minuto
    _counterTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) {
        setState(() {
          // Forzar rebuild para actualizar el tiempo restante
        });
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
                        // Mostrar tiempo restante si hay fecha de inicio
                        if (widget.pedido['fecha_inicio'] != null || widget.pedido['actualizado'] != null)
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
                                  _formatearTiempoRestante(
                                    widget.pedido['fecha_inicio']?.toString() ?? 
                                    widget.pedido['actualizado']?.toString(),
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
