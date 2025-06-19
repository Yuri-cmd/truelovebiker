import 'package:flutter/material.dart';
import 'package:truelovebiker/helpers/image_helper.dart';

class PedidoCard extends StatelessWidget {
  final Map<String, dynamic> pedido;
  final VoidCallback onTap;

  const PedidoCard({super.key, required this.pedido, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
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
              Icon(
                Icons.location_on,
                color: Colors.redAccent,
                size: 40,
              ),
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
                            pedido['local'] ?? 'Sin nombre',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blueAccent.withAlpha((0.1 * 255).toInt()),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            pedido['tiempo'].toString(),
                            style: TextStyle(
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
                      pedido['direccion_local'],
                    ),
                    _buildInfoLine(
                      context,
                      'Dirección Entrega',
                      pedido['direccion_entrega'],
                    ),
                    _buildInfoLine(context, 'Nota', pedido['nota']),
                    _buildInfoLine(
                      context,
                      'Delivery',
                      'S/. ${pedido['precio_delivery']}',
                    ),
                    _buildInfoLine(
                      context,
                      'Total',
                      'S/. ${pedido['total'].toString()}',
                    ),

                    /// Método de pago + ícono
                    Row(
                      children: [
                        Text(
                          'Pago: ',
                          style: TextStyle(fontSize: 14, color: colorScheme.onSurface.withAlpha((0.6 * 255).toInt())),
                        ),
                        Text(
                          pedido['tipoPago'] ?? 'N/A',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(width: 6),
                        getMetodoPagoImage(pedido['tipoPago']),
                      ],
                    ),
                    _buildInfoLine(
                      context,
                      'Tipo Comprobante',
                      pedido['tipo_comprobante'].toString(),
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
          style: TextStyle(fontSize: 14, color: colorScheme.onSurface.withAlpha((0.6 * 255).toInt())),
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