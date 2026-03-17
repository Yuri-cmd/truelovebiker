import 'package:flutter/material.dart';
import 'package:truelovebiker/core/utils/image_helper.dart';
import 'package:truelovebiker/data/services/timer_service.dart';

class PedidoCard extends StatefulWidget {
  final Map<String, dynamic> pedido;
  final VoidCallback onTap;

  const PedidoCard({super.key, required this.pedido, required this.onTap});

  @override
  State<PedidoCard> createState() => _PedidoCardState();
}

class _PedidoCardState extends State<PedidoCard> {
  final TimerService _timerService = TimerService();
  Function()? _timerCallback;

  @override
  void initState() {
    super.initState();
    final pedidoId = widget.pedido['id'];
    _timerCallback = () {
      if (mounted) setState(() {});
    };
    _timerService.startTimerForPedido(pedidoId, onTick: _timerCallback!);
  }

  @override
  void dispose() {
    if (_timerCallback != null) {
      _timerService.removeCallbackForPedido(widget.pedido['id'], _timerCallback!);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pedido = widget.pedido;
    final id = pedido['id'];
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
              const Icon(Icons.location_on, color: Colors.redAccent, size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            pedido['local'] ?? pedido['establecimiento'] ?? 'Sin nombre',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.timer, size: 14, color: Colors.orange),
                              const SizedBox(width: 4),
                              Text(
                                _getTimerText(id),
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.orange,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _buildInfoLine(context, 'Dirección Local', pedido['direccionLocal'] ?? pedido['direccion_local']),
                    _buildInfoLine(context, 'Dirección Entrega', pedido['direccionEntrega'] ?? pedido['direccion_entrega']),
                    _buildInfoLine(context, 'Nota', pedido['nota'] ?? pedido['detalle']),
                    _buildInfoLine(context, 'Delivery', 'S/ ${pedido['precioDelivery'] ?? pedido['precio_delivery']}'),
                    _buildInfoLine(context, 'Total', 'S/ ${pedido['total']}'),
                    _buildInfoLine(context, 'Descuento', 'S/ ${pedido['descuento'] ?? "0.00"}'),
                    
                    Row(
                      children: [
                        Text(
                          'Pago: ',
                          style: TextStyle(fontSize: 14, color: colorScheme.onSurface.withValues(alpha: 0.6)),
                        ),
                        Text(
                          pedido['tipoPago'] ?? 'N/A',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: colorScheme.onSurface),
                        ),
                        const SizedBox(width: 6),
                        getMetodoPagoImage(pedido['tipoPago']),
                      ],
                    ),
                    const SizedBox(height: 6),
                    _buildInfoLine(context, 'Tipo Comprobante', pedido['tipoComprobante'] ?? pedido['tipo_comprobante']),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoLine(BuildContext context, String label, dynamic value) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: RichText(
        text: TextSpan(
          text: '$label: ',
          style: TextStyle(fontSize: 14, color: colorScheme.onSurface.withValues(alpha: 0.6)),
          children: [
            TextSpan(
              text: value?.toString() ?? 'N/A',
              style: TextStyle(fontWeight: FontWeight.w500, color: colorScheme.onSurface),
            ),
          ],
        ),
      ),
    );
  }

  String _getTimerText(int id) {
    final status = widget.pedido['estado']?.toString();
    if (status == '0' || status == '8') return 'Finalizado';
    
    final elapsed = _timerService.getElapsedTimeForPedidoSync(id);
    if (elapsed.inSeconds == 0) return 'Calculando...';

    final minutes = elapsed.inMinutes;
    final seconds = elapsed.inSeconds % 60;
    
    // Si el tiempo es muy alto o marcamos como vencido (lógica original)
    if (minutes > 30) return 'Tiempo vencido';

    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
