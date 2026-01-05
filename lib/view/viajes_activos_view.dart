import 'dart:async';
import 'package:flutter/material.dart';
import 'package:truelovebiker/services/api.dart';
import 'package:truelovebiker/services/timer_service.dart';
import 'package:truelovebiker/view/viaje_view.dart';
import 'package:url_launcher/url_launcher.dart';

class ViajesActivosView extends StatefulWidget {
  const ViajesActivosView({super.key});

  @override
  State<ViajesActivosView> createState() => _ViajesActivosViewState();
}

class _ViajesActivosViewState extends State<ViajesActivosView> {
  List<Map<String, dynamic>> _viajesActivos = [];
  bool _isLoading = true;
  Timer? _refreshTimer;
  Timer? _counterTimer; // Timer para actualizar contadores cada segundo
  final TimerService _timerService = TimerService();
  final Set<int> _expandedCards =
      {}; // Para controlar qué cards están expandidas

  // Maps para mantener estado local de tiempos por pedido
  final Map<int, DateTime> _localStartTimes = {};
  final Map<int, int> _originalDurations = {}; // duración original en minutos

  @override
  void initState() {
    super.initState();
    _cargarViajesActivos();

    // Actualizar cada 5 segundos
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _cargarViajesActivos();
    });

    // Usar TimerService persistente para todos los viajes activos
    // El callback se actualizará cuando se carguen los viajes
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _counterTimer?.cancel();
    // NO limpiar TimerService - los timers deben persistir
    _localStartTimes.clear();
    _originalDurations.clear();
    super.dispose();
  }

  String _formatearTiempoRestante(
    String? fechaInicio,
    dynamic tiempoDuracion, [
    int? pedidoId,
  ]) {
    if (fechaInicio == null || fechaInicio.isEmpty || tiempoDuracion == null)
      return '';

    // Si tenemos pedidoId, intentar usar TimerService para consistencia
    if (pedidoId != null) {
      final timerStartTime = _timerService.getStartTimeForPedido(pedidoId);
      if (timerStartTime != null) {
        // Usar tiempo del TimerService (viene de PedidoCard)

        int duracionMinutos = 0;
        if (tiempoDuracion is String) {
          duracionMinutos = int.tryParse(tiempoDuracion) ?? 0;
        } else if (tiempoDuracion is int) {
          duracionMinutos = tiempoDuracion;
        } else if (tiempoDuracion is double) {
          duracionMinutos = tiempoDuracion.round();
        }

        final elapsed = DateTime.now().difference(timerStartTime);
        final totalSeconds = duracionMinutos * 60;
        final remainingSeconds = totalSeconds - elapsed.inSeconds;

        if (remainingSeconds <= 0) {
          return 'Tiempo vencido';
        }

        final minutes = remainingSeconds ~/ 60;
        final seconds = remainingSeconds % 60;

        if (minutes < 60) {
          return '${minutes}:${seconds.toString().padLeft(2, '0')}m restantes';
        } else {
          final hours = minutes ~/ 60;
          final mins = minutes % 60;
          return mins > 0
              ? '${hours}h ${mins}m restantes'
              : '${hours}h restantes';
        }
      }
    }

    // Fallback a lógica de servidor si no hay TimerService
    try {
      int duracionMinutos = 0;
      if (tiempoDuracion is String) {
        duracionMinutos = int.tryParse(tiempoDuracion) ?? 0;
      } else if (tiempoDuracion is int) {
        duracionMinutos = tiempoDuracion;
      } else if (tiempoDuracion is double) {
        duracionMinutos = tiempoDuracion.round();
      }

      if (duracionMinutos <= 0) return 'Sin tiempo definido';

      DateTime fechaInicioDateTime = DateTime.parse(fechaInicio);
      DateTime ahora = DateTime.now();
      int minutosTranscurridos =
          ahora.difference(fechaInicioDateTime).inMinutes;
      int minutosRestantes = duracionMinutos - minutosTranscurridos;

      if (minutosRestantes <= 0) {
        return 'Tiempo vencido';
      }

      if (minutosRestantes < 60) {
        return '${minutosRestantes}m restantes';
      } else {
        int horas = minutosRestantes ~/ 60;
        int minutos = minutosRestantes % 60;
        return minutos > 0
            ? '${horas}h ${minutos}m restantes'
            : '${horas}h restantes';
      }
    } catch (e) {
      return 'Error de tiempo';
    }
  }

  Future<void> _cargarViajesActivos() async {
    try {
      final viajes = await ApiService.obtenerViajesActivos();
      if (mounted) {
        setState(() {
          _viajesActivos = viajes;
          _isLoading = false;

          // Limpiar tiempos locales de pedidos que ya no están activos
          final idsActivos = viajes.map((v) => v['id'] as int).toSet();
          _localStartTimes.removeWhere((id, _) => !idsActivos.contains(id));
          _originalDurations.removeWhere((id, _) => !idsActivos.contains(id));
        });

        // Registrar callbacks en TimerService para cada viaje activo
        for (final viaje in viajes) {
          final pedidoId = viaje['id'] as int;

          // Registrar callback que actualiza la UI cada segundo
          _timerService.startTimerForPedido(
            pedidoId,
            onTick: () {
              if (mounted) {
                setState(() {
                  // Forzar rebuild para mostrar tiempo actualizado
                });
              }
            },
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al cargar viajes: $e')));
      }
    }
  }

  Future<void> _onRefresh() async {
    await _cargarViajesActivos();
  }

  String _getEstadoTexto(String estado) {
    switch (estado) {
      case '0':
        return 'Pedido cancelado';
      case '4':
        return 'En camino al local';
      case '5':
        return 'En el local';
      case '6':
        return 'En camino al cliente';
      case '7':
        return 'En destino';
      default:
        return 'Estado $estado';
    }
  }

  Color _getEstadoColor(String estado) {
    switch (estado) {
      case '0':
        return Colors.red[800]!;
      case '4':
        return Colors.blue;
      case '5':
        return Colors.green;
      case '6':
        return Colors.orange;
      case '7':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getEstadoIcon(String estado) {
    switch (estado) {
      case '0':
        return Icons.cancel;
      case '4':
        return Icons.directions_bike;
      case '5':
        return Icons.store;
      case '6':
        return Icons.delivery_dining;
      case '7':
        return Icons.location_on;
      default:
        return Icons.help_outline;
    }
  }

  Future<void> _abrirEnGoogleMaps(double lat, double lon) async {
    final Uri googleMapsUrl = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lon&travelmode=driving',
    );
    try {
      await _launchUrl(googleMapsUrl);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _launchUrl(Uri url) async {
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  Future<void> _abrirEnWaze(double lat, double lon) async {
    final url = 'waze://?ll=$lat,$lon&navigate=yes';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      // Si Waze no está instalado, abre en el navegador
      final fallbackUrl = 'https://waze.com/ul?ll=$lat,$lon&navigate=yes';
      await launchUrl(
        Uri.parse(fallbackUrl),
        mode: LaunchMode.externalApplication,
      );
    }
  }

  Future<void> _elegirNavegadorYNavegar(double lat, double lon) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Elegir aplicación de navegación'),
          content: const Text('¿Con qué aplicación quieres navegar?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _abrirEnWaze(lat, lon);
              },
              child: const Text('Waze'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _abrirEnGoogleMaps(lat, lon);
              },
              child: const Text('Google Maps'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Viajes Activos'),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarViajesActivos,
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: _onRefresh,
                child:
                    _viajesActivos.isEmpty
                        ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.inbox_outlined,
                                size: 80,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'No tienes viajes activos',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Desliza hacia abajo para actualizar',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        )
                        : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _viajesActivos.length,
                          itemBuilder: (context, index) {
                            final viaje = _viajesActivos[index];
                            return _buildViajeCard(viaje);
                          },
                        ),
              ),
    );
  }

  Widget _buildViajeCard(Map<String, dynamic> viaje) {
    final estado = viaje['estado'] ?? '0';
    final estadoColor = _getEstadoColor(estado);
    final estadoTexto = _getEstadoTexto(estado);
    final estadoIcon = _getEstadoIcon(estado);
    final isExpanded = _expandedCards.contains(viaje['id']);
    final isCancelado = estado == '0';

    // Parsear coordenadas
    final latLocal =
        double.tryParse(viaje['latLocal']?.toString() ?? '0') ?? 0.0;
    final lonLocal =
        double.tryParse(viaje['lonLocal']?.toString() ?? '0') ?? 0.0;
    final latCliente =
        double.tryParse(viaje['latitud']?.toString() ?? '0') ?? 0.0;
    final lonCliente =
        double.tryParse(viaje['longitud']?.toString() ?? '0') ?? 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: isCancelado ? 2 : 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Opacity(
        opacity: isCancelado ? 0.7 : 1.0,
        child: Column(
          children: [
            InkWell(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              onTap:
                  isCancelado
                      ? null
                      : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ViajeView(pedido: viaje),
                          ),
                        );
                      },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header con estado
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: estadoColor.withAlpha((0.1 * 255).toInt()),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: estadoColor),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(estadoIcon, size: 16, color: estadoColor),
                              const SizedBox(width: 4),
                              Text(
                                estadoTexto,
                                style: TextStyle(
                                  color: estadoColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'ID: ${viaje['id']}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Contador de tiempo restante
                    if (viaje['actualizado'] != null && viaje['tiempo'] != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.withAlpha((0.1 * 255).toInt()),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: Colors.orange.withAlpha((0.3 * 255).toInt()),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.timer,
                              size: 14,
                              color: isCancelado ? Colors.grey : Colors.orange,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatearTiempoRestante(
                                viaje['actualizado']?.toString(),
                                viaje['tiempo'],
                                viaje['id'],
                              ),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color:
                                    isCancelado ? Colors.grey : Colors.orange,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 12),

                    // Mostrar mensaje de cancelación si aplica
                    if (isCancelado)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.red[700],
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Este pedido ha sido cancelado y no está disponible',
                                style: TextStyle(
                                  color: Colors.red[700],
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Información del cliente
                    Row(
                      children: [
                        const Icon(Icons.person, size: 18, color: Colors.grey),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            viaje['cliente'] ?? 'Sin nombre',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: isCancelado ? Colors.grey : Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Teléfono del cliente
                    if (viaje['celular'] != null &&
                        viaje['celular'].toString().isNotEmpty)
                      Row(
                        children: [
                          const Icon(Icons.phone, size: 18, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text(
                            viaje['celular'].toString(),
                            style: TextStyle(
                              fontSize: 14,
                              color:
                                  isCancelado ? Colors.grey[400] : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 8),

                    // Dirección de entrega (clickeable solo si no está cancelado)
                    GestureDetector(
                      onTap:
                          isCancelado
                              ? null
                              : () => _elegirNavegadorYNavegar(
                                latCliente,
                                lonCliente,
                              ),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: (isCancelado ? Colors.grey : Colors.blue)
                              .withAlpha((0.05 * 255).toInt()),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: (isCancelado ? Colors.grey : Colors.blue)
                                .withAlpha((0.2 * 255).toInt()),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 18,
                              color: isCancelado ? Colors.grey : Colors.blue,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isCancelado
                                        ? 'Dirección de entrega'
                                        : 'Dirección de entrega (toca para navegar)',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color:
                                          isCancelado
                                              ? Colors.grey
                                              : Colors.blue,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    viaje['direccionEntrega'] ??
                                        'Sin dirección',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color:
                                          isCancelado
                                              ? Colors.grey[600]
                                              : Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (!isCancelado)
                              const Icon(
                                Icons.navigation,
                                size: 16,
                                color: Colors.blue,
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Local/Establecimiento (clickeable solo si no está cancelado)
                    GestureDetector(
                      onTap:
                          isCancelado
                              ? null
                              : () =>
                                  _elegirNavegadorYNavegar(latLocal, lonLocal),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: (isCancelado ? Colors.grey : Colors.green)
                              .withAlpha((0.05 * 255).toInt()),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: (isCancelado ? Colors.grey : Colors.green)
                                .withAlpha((0.2 * 255).toInt()),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.store,
                              size: 18,
                              color: isCancelado ? Colors.grey : Colors.green,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isCancelado
                                        ? 'Local'
                                        : 'Local (toca para navegar)',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color:
                                          isCancelado
                                              ? Colors.grey
                                              : Colors.green,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    viaje['establecimiento'] ??
                                        viaje['local'] ??
                                        'Sin establecimiento',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color:
                                          isCancelado
                                              ? Colors.grey[600]
                                              : Colors.black87,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    viaje['direccionLocal'] ?? 'Sin dirección',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color:
                                          isCancelado
                                              ? Colors.grey[400]
                                              : Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (!isCancelado)
                              const Icon(
                                Icons.navigation,
                                size: 16,
                                color: Colors.green,
                              ),
                          ],
                        ),
                      ),
                    ),

                    // Mostrar nota si existe
                    if (viaje['nota'] != null &&
                        viaje['nota'].toString().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.note,
                              size: 18,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                viaje['nota'].toString(),
                                style: TextStyle(
                                  fontSize: 14,
                                  color:
                                      isCancelado
                                          ? Colors.grey[400]
                                          : Colors.grey,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 12),

                    // Footer con precio, tipo de pago y botones
                    Row(
                      children: [
                        // Precio total y descuento
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: (isCancelado
                                        ? Colors.grey
                                        : Colors.green)
                                    .withAlpha((0.1 * 255).toInt()),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'S/ ${viaje['total'] ?? '0.00'}',
                                    style: TextStyle(
                                      color:
                                          isCancelado
                                              ? Colors.grey
                                              : Colors.green,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (viaje['descuento'] != null &&
                                viaje['descuento'].toString().isNotEmpty &&
                                viaje['descuento'].toString() != '0')
                              Padding(
                                padding: const EdgeInsets.only(left: 8, top: 2),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.local_offer,
                                      size: 14,
                                      color: Colors.red[400],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Descuento: -S/ ${viaje['descuento']}',
                                      style: TextStyle(
                                        color: Colors.red[400],
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(width: 8),
                        // Tipo de pago
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: (isCancelado ? Colors.grey : Colors.blue)
                                .withAlpha((0.1 * 255).toInt()),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            viaje['tipoPago'] ?? 'Sin especificar',
                            style: TextStyle(
                              color: isCancelado ? Colors.grey : Colors.blue,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const Spacer(),
                        // Botón deshabilitado para pedidos cancelados
                        ElevatedButton.icon(
                          onPressed:
                              isCancelado
                                  ? null
                                  : () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) =>
                                                ViajeView(pedido: viaje),
                                      ),
                                    );
                                  },
                          icon: Icon(
                            isCancelado ? Icons.block : Icons.visibility,
                            size: 16,
                          ),
                          label: Text(isCancelado ? 'Cancelado' : 'Ver viaje'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                isCancelado
                                    ? Colors.grey[400]
                                    : Colors.redAccent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Botón para expandir/contraer productos (deshabilitado si está cancelado)
            if (viaje['productosList'] != null &&
                viaje['productosList'] is List &&
                (viaje['productosList'] as List).isNotEmpty)
              Container(
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: Colors.grey.withAlpha((0.2 * 255).toInt()),
                    ),
                  ),
                ),
                child: InkWell(
                  onTap:
                      isCancelado
                          ? null
                          : () {
                            setState(() {
                              if (isExpanded) {
                                _expandedCards.remove(viaje['id']);
                              } else {
                                _expandedCards.add(viaje['id']);
                              }
                            });
                          },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.restaurant_menu,
                          size: 18,
                          color: isCancelado ? Colors.grey : Colors.orange,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Productos (${(viaje['productosList'] as List).length})',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: isCancelado ? Colors.grey : Colors.orange,
                          ),
                        ),
                        const Spacer(),
                        if (!isCancelado)
                          Icon(
                            isExpanded ? Icons.expand_less : Icons.expand_more,
                            color: Colors.orange,
                          ),
                      ],
                    ),
                  ),
                ),
              ),

            // Lista de productos (expandible, solo si no está cancelado)
            if (isExpanded &&
                !isCancelado &&
                viaje['productosList'] != null &&
                viaje['productosList'] is List)
              Container(
                decoration: BoxDecoration(
                  color: Colors.orange.withAlpha((0.05 * 255).toInt()),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Lista de productos:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...(viaje['productosList'] as List).map(
                        (producto) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.circle,
                                size: 6,
                                color: Colors.orange,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                producto.toString(),
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
