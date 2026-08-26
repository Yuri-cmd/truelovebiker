import 'package:flutter/material.dart';

/// Muestra los productos de un pedido agrupando cada adicional debajo
/// de su producto principal (en vez de un texto plano tipo
/// "RAMEN x 1, Mostaza x 1, Kepchup x 1, CLASICO x 1, ...").
///
/// Espera `detalleArray` en el formato que envía el backend:
/// [{ nombre, cantidad, precio, tipo: 'item' | 'adicional' }, ...]
/// donde cada 'adicional' pertenece al 'item' inmediatamente anterior.
class PedidoProductosAgrupados extends StatelessWidget {
  final List<dynamic>? detalleArray;
  final String fallbackTexto;
  final Color? textColor;

  const PedidoProductosAgrupados({
    super.key,
    required this.detalleArray,
    this.fallbackTexto = 'Sin productos',
    this.textColor,
  });

  List<Map<String, dynamic>> _agrupar() {
    final grupos = <Map<String, dynamic>>[];
    if (detalleArray == null) return grupos;

    Map<String, dynamic>? ultimoGrupo;
    for (final item in detalleArray!) {
      final detalle = Map<String, dynamic>.from(item as Map);
      final tipo = detalle['tipo']?.toString();

      if (tipo == 'item') {
        ultimoGrupo = {'producto': detalle, 'adicionales': <Map<String, dynamic>>[]};
        grupos.add(ultimoGrupo);
      } else if (tipo == 'adicional' && ultimoGrupo != null) {
        (ultimoGrupo['adicionales'] as List<Map<String, dynamic>>).add(detalle);
      } else {
        // Sin tipo o adicional huérfano: mostrarlo como producto propio.
        ultimoGrupo = {'producto': detalle, 'adicionales': <Map<String, dynamic>>[]};
        grupos.add(ultimoGrupo);
      }
    }
    return grupos;
  }

  @override
  Widget build(BuildContext context) {
    final grupos = _agrupar();

    final resolvedColor = textColor ?? Theme.of(context).textTheme.bodyLarge?.color;

    if (grupos.isEmpty) {
      return Text(
        fallbackTexto,
        style: TextStyle(fontSize: 15, color: resolvedColor),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < grupos.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          _buildGrupo(context, grupos[i], resolvedColor),
        ],
      ],
    );
  }

  Widget _buildGrupo(BuildContext context, Map<String, dynamic> grupo, Color? textColor) {
    final producto = grupo['producto'] as Map<String, dynamic>;
    final adicionales = grupo['adicionales'] as List<Map<String, dynamic>>;
    final cantidad = producto['cantidad']?.toString() ?? '1';
    final nombre = producto['nombre']?.toString() ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '($cantidad) $nombre',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        if (adicionales.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final adicional in adicionales)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${adicional['nombre'] ?? ''}'
                      '${(adicional['cantidad'] != null && adicional['cantidad'].toString() != '1') ? ' x${adicional['cantidad']}' : ''}',
                      style: const TextStyle(fontSize: 12.5, color: Colors.black87),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
