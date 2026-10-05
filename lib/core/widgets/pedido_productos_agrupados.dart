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
          _AdicionalesColapsables(
            textColor: textColor,
            resumen: [
              for (final a in adicionales) (a['nombre'] ?? '').toString(),
            ].where((n) => n.isNotEmpty).join(', '),
            filas: [for (final adicional in adicionales) _buildAdicional(adicional)],
          ),
      ],
    );
  }

  Widget _buildAdicional(Map<String, dynamic> adicional) {
    final precio = double.tryParse(adicional['precio']?.toString() ?? '') ?? 0.0;
    final cantidad = adicional['cantidad'];
    final sufijoCantidad = (cantidad != null && cantidad.toString() != '1') ? ' x$cantidad' : '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.amber.shade100,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              '${adicional['nombre'] ?? ''}$sufijoCantidad',
              style: const TextStyle(fontSize: 12.5, color: Colors.black87),
            ),
          ),
          if (precio > 0)
            Text(
              '+ S/ ${precio.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
        ],
      ),
    );
  }
}


/// Adicionales de un producto, plegados por defecto para ahorrar espacio: una sola
/// línea con el total y los nombres, y un toque la despliega con el detalle y precios.
class _AdicionalesColapsables extends StatefulWidget {
  final List<Widget> filas;
  final String resumen;
  final Color? textColor;

  const _AdicionalesColapsables({
    required this.filas,
    required this.resumen,
    this.textColor,
  });

  @override
  State<_AdicionalesColapsables> createState() => _AdicionalesColapsablesState();
}

class _AdicionalesColapsablesState extends State<_AdicionalesColapsables> {
  bool _expandido = false;

  @override
  Widget build(BuildContext context) {
    final total = widget.filas.length;
    final color = widget.textColor?.withValues(alpha: 0.75);
    const estiloTitulo = TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold);

    return Padding(
      padding: const EdgeInsets.only(top: 2, left: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: () => setState(() => _expandido = !_expandido),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: _expandido
                        ? Text('Adicionales ($total)', style: estiloTitulo.copyWith(color: color))
                        : Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(text: 'Adicionales ($total): ', style: estiloTitulo),
                                TextSpan(
                                  text: widget.resumen,
                                  style: const TextStyle(fontSize: 12.5),
                                ),
                              ],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: color),
                          ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    _expandido ? Icons.expand_less : Icons.expand_more,
                    size: 22,
                    color: color,
                  ),
                ],
              ),
            ),
          ),
          if (_expandido)
            for (final fila in widget.filas) ...[
              const SizedBox(height: 4),
              fila,
            ],
        ],
      ),
    );
  }
}
