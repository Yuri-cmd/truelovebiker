import 'dart:async';
import 'package:flutter/material.dart';
import 'package:truelovebiker/services/api.dart';
import 'package:truelovebiker/view/viaje_view.dart';

class ViajesActivosView extends StatefulWidget {
  const ViajesActivosView({super.key});

  @override
  State<ViajesActivosView> createState() => _ViajesActivosViewState();
}

class _ViajesActivosViewState extends State<ViajesActivosView> {
  List<Map<String, dynamic>> _viajesActivos = [];
  bool _isLoading = true;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _cargarViajesActivos();
    // Actualizar cada 30 segundos
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _cargarViajesActivos();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _cargarViajesActivos() async {
    try {
      final viajes = await ApiService.obtenerViajesActivos();
      if (mounted) {
        setState(() {
          _viajesActivos = viajes;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar viajes: $e')),
        );
      }
    }
  }

  Future<void> _onRefresh() async {
    await _cargarViajesActivos();
  }

  String _getEstadoTexto(String estado) {
    switch (estado) {
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _onRefresh,
              child: _viajesActivos.isEmpty
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

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
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
                        Icon(
                          estadoIcon,
                          size: 16,
                          color: estadoColor,
                        ),
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
              const SizedBox(height: 12),
              
              // Información del cliente
              Row(
                children: [
                  const Icon(Icons.person, size: 18, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      viaje['cliente'] ?? 'Sin nombre',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Teléfono del cliente
              if (viaje['celular'] != null && viaje['celular'].toString().isNotEmpty)
                Row(
                  children: [
                    const Icon(Icons.phone, size: 18, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      viaje['celular'].toString(),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 8),
              
              // Dirección de entrega
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_on, size: 18, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      viaje['direccionEntrega'] ?? 'Sin dirección',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Local/Establecimiento
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.store, size: 18, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      viaje['establecimiento'] ?? viaje['local'] ?? 'Sin establecimiento',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              
              // Mostrar nota si existe
              if (viaje['nota'] != null && viaje['nota'].toString().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.note, size: 18, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          viaje['nota'].toString(),
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              
              const SizedBox(height: 12),
              
              // Footer con precio y tipo de pago
              Row(
                children: [
                  // Precio total
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withAlpha((0.1 * 255).toInt()),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.attach_money,
                          size: 16,
                          color: Colors.green,
                        ),
                        Text(
                          'S/ ${viaje['total'] ?? '0.00'}',
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Tipo de pago
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.withAlpha((0.1 * 255).toInt()),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      viaje['tipoPago'] ?? 'Sin especificar',
                      style: const TextStyle(
                        color: Colors.blue,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ViajeView(pedido: viaje),
                        ),
                      );
                    },
                    icon: const Icon(Icons.visibility, size: 16),
                    label: const Text('Ver viaje'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
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
    );
  }
}
