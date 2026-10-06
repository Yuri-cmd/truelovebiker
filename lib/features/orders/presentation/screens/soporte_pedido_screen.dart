import 'package:dio/dio.dart' as dio;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:truelovebiker/core/routes/app_pages.dart';
import 'package:truelovebiker/data/models/pedido_model.dart';
import 'package:truelovebiker/data/services/order_service.dart';

/// Motivo que el repartidor puede elegir al pedir soporte / cancelar un pedido.
class _MotivoSoporte {
  final String titulo;
  final String? detalle;

  /// El problema es del cliente: el administrador verá sugerida una deuda al aprobar.
  final bool culpaCliente;

  const _MotivoSoporte(this.titulo, {this.detalle, this.culpaCliente = false});
}

const _motivos = <_MotivoSoporte>[
  _MotivoSoporte(
    'Cliente no contesta',
    detalle: 'Por ningún medio y tengo el producto conmigo',
    culpaCliente: true,
  ),
  _MotivoSoporte('Cliente no desea recibir el producto', culpaCliente: true),
  _MotivoSoporte('Cliente desea cancelar pedido', culpaCliente: true),
  _MotivoSoporte(
    'Cliente no contesta por ningún medio (esperé 10 minutos)',
    culpaCliente: true,
  ),
  _MotivoSoporte('Otros'),
];

/// Pantalla de soporte del pedido: el repartidor elige el problema y el pedido se
/// cancela en el momento. Un administrador revisa después el motivo y decide si el
/// cliente queda con una deuda.
class SoportePedidoScreen extends StatefulWidget {
  final Pedido pedido;
  const SoportePedidoScreen({super.key, required this.pedido});

  @override
  State<SoportePedidoScreen> createState() => _SoportePedidoScreenState();
}

class _SoportePedidoScreenState extends State<SoportePedidoScreen> {
  static const _naranja = Color(0xFFD65A25);

  final _mensajeCtrl = TextEditingController();
  _MotivoSoporte? _seleccion;
  bool _enviando = false;
  String? _error;

  @override
  void dispose() {
    _mensajeCtrl.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    final motivo = _seleccion;
    if (motivo == null || _enviando) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('¿Cancelar el pedido?'),
            content: Text(
              'El pedido #${widget.pedido.id} se cancelará ahora y no se puede deshacer.\n\nMotivo: ${motivo.titulo}',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Volver'),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text(
                  'Sí, cancelar',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
    if (confirmar != true || !mounted) return;

    setState(() {
      _enviando = true;
      _error = null;
    });

    try {
      await Get.find<OrderService>().solicitarCancelacion(
        pedidoId: widget.pedido.id,
        motivo: motivo.titulo,
        detalle: _mensajeCtrl.text.trim(),
        culpaCliente: motivo.culpaCliente,
      );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder:
            (ctx) => AlertDialog(
              title: const Text('Pedido cancelado'),
              content: const Text(
                'El pedido quedó cancelado y ya avisamos al cliente y al local. Un administrador revisará el motivo.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Entendido'),
                ),
              ],
            ),
      );
      // El viaje terminó: vuelve al inicio para ver los pedidos disponibles
      Get.offAllNamed(Routes.HOME);
    } on dio.DioException catch (e) {
      final data = e.response?.data;
      setState(() {
        _error =
            (data is Map && data['message'] != null)
                ? data['message'].toString()
                : 'No se pudo cancelar el pedido. Revisa tu conexión e inténtalo de nuevo.';
      });
    } catch (_) {
      setState(
        () => _error = 'No se pudo cancelar el pedido. Inténtalo de nuevo.',
      );
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  Widget _opcion(_MotivoSoporte m) {
    final seleccionado = identical(_seleccion, m);

    if (seleccionado) {
      return Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: _naranja,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _naranja.withAlpha(70),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    m.titulo,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (m.detalle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      m.detalle!,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white, size: 28),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      width: double.infinity,
      child: OutlinedButton(
        onPressed: _enviando ? null : () => setState(() => _seleccion = m),
        style: OutlinedButton.styleFrom(
          foregroundColor: _naranja,
          side: const BorderSide(color: _naranja, width: 1.2),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        child: Text(
          m.titulo.toUpperCase(),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
            fontSize: 13.5,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF262626),
        foregroundColor: Colors.white,
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Soporte',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            Text(
              'Pedido #${widget.pedido.id}',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w400),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          children: [
            Text(
              '¿En qué podemos ayudarte?',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Selecciona el tipo de problema:',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            for (final m in _motivos) _opcion(m),
            if (_seleccion?.culpaCliente == true)
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withAlpha(40),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'El pedido se cancelará ahora. Un administrador revisará el motivo y podrá generar una deuda al cliente.',
                  style: TextStyle(fontSize: 13),
                ),
              ),
            const SizedBox(height: 10),
            Text(
              'Mensaje inicial (opcional):',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _mensajeCtrl,
              maxLines: 3,
              maxLength: 1000,
              enabled: !_enviando,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'Cuéntanos más sobre el problema…',
                filled: true,
                fillColor: Colors.grey.withAlpha(25),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.withAlpha(60)),
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: Colors.redAccent)),
            ],
            const SizedBox(height: 16),
            SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: (_seleccion == null || _enviando) ? null : _enviar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E88E5),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFF90BEDF),
                  disabledForegroundColor: Colors.white70,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child:
                    _enviando
                        ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                        : const Text(
                          'CANCELAR PEDIDO',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
