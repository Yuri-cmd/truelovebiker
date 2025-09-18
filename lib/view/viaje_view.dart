import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:truelovebiker/screen/chat_screen.dart';
import 'package:truelovebiker/screen/rating_screen.dart';
import 'package:truelovebiker/services/api.dart';
import 'package:url_launcher/url_launcher.dart';

const mapboxAccessToken =
    '***MAPBOX_TOKEN_REMOVED***';

class ViajeView extends StatefulWidget {
  final Map<String, dynamic> pedido;

  const ViajeView({super.key, required this.pedido});

  @override
  State<ViajeView> createState() => _ViajeViewState();
}

class _ViajeViewState extends State<ViajeView>
    with SingleTickerProviderStateMixin {
  Timer? _timer;
  LatLng? _localPosition;
  LatLng? _customerPosition;
  LatLng? _motorcyclePosition;
  List<LatLng> _ruta = [];
  int _currentState = 1;
  bool viajeFinalizado = false;
  bool alertaEnviada = false; // Nueva bandera
  bool _actualizandoEstado = false; // Para evitar conflictos con el polling
  DateTime?
  _ultimaActualizacionManual; // Timestamp de última actualización manual

  @override
  void initState() {
    super.initState();
    // Inicializar el estado desde los datos del pedido
    _currentState = int.tryParse(widget.pedido['estado'].toString()) ?? 1;
    
    // Verificar si el viaje ya está finalizado desde el inicio
    if (_currentState == 0) {
      // Usar addPostFrameCallback para mostrar la alerta después de que se construya el widget
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mostrarAlertaViajeFinalizadoYSalir();
      });
      return; // No inicializar tracking si ya está finalizado
    }
    
    _fetchCustomerYLocalPosition(widget.pedido['id']);
    _startTracking();
  }

  void _startTracking() {
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      // Solo hacer polling si no estamos actualizando manualmente
      if (!_actualizandoEstado) {
        _fetchOrderStatus(widget.pedido['id']);
        _fetchMotorcycleLocation();
      }
    });
  }

  // Nueva función para cargar ambas posiciones antes de actualizar el estado

  Future<void> _fetchCustomerYLocalPosition(int idPedido) async {
    try {
      final data = await ApiService.fetchCustomerYLocalPosition(idPedido);
      double locallat =
          data['locallat'] is String
              ? double.parse(data['locallat'])
              : data['locallat'];
      double locallon =
          data['locallon'] is String
              ? double.parse(data['locallon'])
              : data['locallon'];
      double custlat =
          data['custlat'] is String
              ? double.parse(data['custlat'])
              : data['custlat'];
      double custlon =
          data['custlon'] is String
              ? double.parse(data['custlon'])
              : data['custlon'];

      setState(() {
        _localPosition = LatLng(locallat, locallon);
        _customerPosition = LatLng(custlon, custlat);
      });
    } catch (e) {
      throw ("Error al obtener ubicación del motorizado: $e");
    }
  }

  Future<void> _fetchOrderStatus(int idPedido) async {
    try {
      // No actualizar estado si estamos en proceso de actualización manual
      if (_actualizandoEstado) return;

      // No actualizar si hace poco hubo una actualización manual (menos de 10 segundos)
      if (_ultimaActualizacionManual != null &&
          DateTime.now().difference(_ultimaActualizacionManual!).inSeconds <
              10) {
        return;
      }

      final data = await ApiService.fetchOrderStatus(idPedido);
      int newState = int.tryParse(data['estado'].toString()) ?? 1;

      if (newState != _currentState) {
        setState(() {
          _currentState = newState;
        });
        
        // Verificar si el viaje fue cancelado/finalizado (estado 0)
        if (newState == 0) {
          _mostrarAlertaViajeFinalizadoYSalir();
          return; // Salir temprano, no continuar con otras actualizaciones
        }
        
        _fetchMotorcycleLocation();
      }
    } catch (e) {
      throw ('Error al obtener estado del pedido: $e');
    }
  }

  Future<void> _fetchMotorcycleLocation() async {
    try {
      final data = await ApiService.fetchMotorcycleLocation(
        widget.pedido['id'],
      );
      double lat = double.parse(data['lat']);
      double lon = double.parse(data['lon']);
      LatLng newPosition = LatLng(lat, lon);

      setState(() {
        _motorcyclePosition = newPosition;
      });
      if (_currentState == 4) {
        _cargarRuta(_motorcyclePosition!, _localPosition!);
      }

      if (_currentState == 6) {
        _cargarRuta(_motorcyclePosition!, _customerPosition!);
      }
      if (_currentState == 7) {
        onEstadoSieteDetectado(widget.pedido['id']);
      }
    } catch (e) {
      throw ("Error al obtener ubicación del motorizado: $e");
    }
  }

  Future<void> _cargarRuta(LatLng initialCord, LatLng finalCord) async {
    final List<LatLng> ruta = await ApiService.obtenerRuta(
      initialCord,
      finalCord,
      mapboxAccessToken,
    );
    setState(() {
      _ruta = ruta;
    });
  }

  void _mostrarAlertaViajeFinalizadoYSalir() {
    // Cancelar el timer para evitar más actualizaciones
    _timer?.cancel();
    
    showDialog(
      context: context,
      barrierDismissible: false, // No permitir cerrar tocando fuera
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.red,
                size: 28,
              ),
              const SizedBox(width: 8),
              const Text(
                'Viaje Finalizado',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          content: const Text(
            'El viaje ha sido finalizado o cancelado. Serás redirigido a la pantalla anterior.',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Cerrar el diálogo
                Navigator.of(context).pop(); // Volver a la vista anterior
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Entendido',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  void _cambiarEstado(int nuevoEstado, String mensaje) async {
    bool confirmacion = await _mostrarAlerta(mensaje);
    if (confirmacion) {
      setState(() {
        _actualizandoEstado = true; // Bloquear polling temporalmente
        _ultimaActualizacionManual = DateTime.now(); // Marcar timestamp
      });

      try {
        await ApiService.actualizarEstado(widget.pedido['id'], nuevoEstado);
        setState(() {
          _currentState = nuevoEstado;
        });

        // Esperar un poco antes de permitir polling nuevamente
        await Future.delayed(
          const Duration(seconds: 5),
        ); // Aumenté a 5 segundos
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al actualizar estado')),
        );
      } finally {
        setState(() {
          _actualizandoEstado = false; // Permitir polling nuevamente
        });
      }
    }
  }

  Future<bool> _mostrarAlerta(String mensaje) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // Evita que se cierre sin elegir una opción
      builder:
          (context) => AlertDialog(
            title: const Text("Confirmación"),
            content: Text(mensaje),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("No"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Sí"),
              ),
            ],
          ),
    );

    return result ?? false; // Si el usuario no eligió nada, asumimos "No"
  }

  // Función para cuando detectes que el estado es 7
  void onEstadoSieteDetectado(int idPedido) {
    Timer(Duration(minutes: 7), () async {
      if (!viajeFinalizado && !alertaEnviada) {
        alertaEnviada = true; // Evitar que se mande más de una vez
        await ApiService.mandarAlertaDeAuxilio(idPedido);
      }
    });
  }

  Future<void> _abrirEnGoogleMaps(LatLng destino) async {
    final Uri googleMapsUrl = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${destino.longitude},${destino.latitude}&travelmode=driving',
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

  Future<void> _abrirEnWaze(LatLng destino) async {
    final url =
        'waze://?ll=${destino.longitude},${destino.latitude}&navigate=yes';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      // Si Waze no está instalado, abre en el navegador
      final fallbackUrl =
          'https://waze.com/ul?ll=${destino.longitude},${destino.latitude}&navigate=yes';
      await launchUrl(
        Uri.parse(fallbackUrl),
        mode: LaunchMode.externalApplication,
      );
    }
  }

  Future<void> _elegirNavegadorYNavegar(LatLng destino) async {
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
                _abrirEnWaze(destino);
              },
              child: const Text('Waze'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _abrirEnGoogleMaps(destino);
              },
              child: const Text('Google Maps'),
            ),
          ],
        );
      },
    );
  }

  void _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    await launchUrl(launchUri);
  }

  void _mostrarBottomSheetPedido(BuildContext context) {
    final pedido = widget.pedido;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle del modal
              Container(
                width: 40,
                height: 5,
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.redAccent, Color(0xFFE57373)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Icon(Icons.receipt_long, color: Colors.white, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Detalles del Pedido",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "ID: ${pedido['id']}",
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha((0.2 * 255).toInt()),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "S/ ${pedido['total'] ?? '0.00'}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Contenido scrolleable
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Información del cliente
                      _buildInfoCard(
                        title: "Información del Cliente",
                        icon: Icons.person,
                        color: Colors.blue,
                        children: [
                          _buildInfoRow(
                            icon: Icons.person_outline,
                            label: "Cliente",
                            value: pedido['cliente'] ?? 'Sin nombre',
                          ),
                          if (pedido['celular'] != null && pedido['celular'].toString().isNotEmpty)
                            _buildInfoRow(
                              icon: Icons.phone,
                              label: "Teléfono",
                              value: pedido['celular'].toString(),
                              isClickable: true,
                              onTap: () => _makePhoneCall(pedido['celular'].toString()),
                              trailingIcon: Icons.call,
                            ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Ubicaciones
                      _buildInfoCard(
                        title: "Ubicaciones",
                        icon: Icons.location_on,
                        color: Colors.green,
                        children: [
                          _buildInfoRow(
                            icon: Icons.store,
                            label: "Local",
                            value: pedido['establecimiento'] ?? pedido['local'] ?? 'Sin establecimiento',
                            subtitle: pedido['direccionLocal'] ?? pedido['direccion_local'] ?? '',
                            isClickable: true,
                            onTap: () {
                              if (_localPosition != null) {
                                Navigator.pop(context);
                                _elegirNavegadorYNavegar(_localPosition!);
                              }
                            },
                            trailingIcon: Icons.navigation,
                          ),
                          _buildInfoRow(
                            icon: Icons.home,
                            label: "Entrega",
                            value: pedido['direccionEntrega'] ?? pedido['direccion_entrega'] ?? 'Sin dirección',
                            isClickable: true,
                            onTap: () {
                              if (_customerPosition != null) {
                                Navigator.pop(context);
                                _elegirNavegadorYNavegar(_customerPosition!);
                              }
                            },
                            trailingIcon: Icons.navigation,
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Productos (si existen)
                      if (pedido['productos'] != null && pedido['productos'].toString().isNotEmpty)
                        _buildInfoCard(
                          title: "Productos",
                          icon: Icons.shopping_bag,
                          color: Colors.orange,
                          children: [
                            _buildProductos(pedido['productos']),
                          ],
                        ),
                      
                      const SizedBox(height: 16),
                      
                      // Información del pedido
                      _buildInfoCard(
                        title: "Detalles del Pedido",
                        icon: Icons.description,
                        color: Colors.purple,
                        children: [
                          if (pedido['nota'] != null && pedido['nota'].toString().isNotEmpty)
                            _buildInfoRow(
                              icon: Icons.note,
                              label: "Nota",
                              value: pedido['nota'].toString(),
                            ),
                          _buildInfoRow(
                            icon: Icons.payment,
                            label: "Tipo de pago",
                            value: pedido['tipoPago'] ?? 'Sin especificar',
                          ),
                          if (pedido['tipoComprobante'] != null && pedido['tipoComprobante'].toString().isNotEmpty)
                            _buildInfoRow(
                              icon: Icons.receipt,
                              label: "Comprobante",
                              value: pedido['tipoComprobante'].toString(),
                            ),
                          _buildInfoRow(
                            icon: Icons.delivery_dining,
                            label: "Precio delivery",
                            value: "S/ ${pedido['precioDelivery'] ?? pedido['precio_delivery'] ?? '0.00'}",
                          ),
                          _buildInfoRow(
                            icon: Icons.payment,
                            label: "Descuento",
                            value: "S/ ${pedido['descuento'] ?? '0.00'}",
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.1 * 255).toInt()),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header de la card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withAlpha((0.1 * 255).toInt()),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // Contenido de la card
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    String? subtitle,
    bool isClickable = false,
    VoidCallback? onTap,
    IconData? trailingIcon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: isClickable ? onTap : null,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isClickable ? Colors.grey[50] : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: isClickable ? Border.all(color: Colors.grey[300]!) : null,
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.grey[600], size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    if (subtitle != null && subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailingIcon != null) ...[
                const SizedBox(width: 8),
                Icon(
                  trailingIcon,
                  color: isClickable ? Colors.redAccent : Colors.grey,
                  size: 20,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductos(dynamic productos) {
    if (productos is List) {
      return Column(
        children: productos.map((producto) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.fastfood, color: Colors.orange[700], size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    producto.toString(),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      );
    } else {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange[200]!),
        ),
        child: Row(
          children: [
            Icon(Icons.fastfood, color: Colors.orange[700], size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                productos.toString(),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_localPosition == null || _customerPosition == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.redAccent,
          title: const Text('Detalle del Pedido'),
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del Pedido'),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          // Mapa que ocupa toda la pantalla
          FlutterMap(
            options: MapOptions(
              center:
                  _motorcyclePosition ??
                  _localPosition ??
                  LatLng(-12.0464, -77.0428),
              zoom: 14.0,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://api.mapbox.com/styles/v1/mapbox/streets-v12/tiles/{z}/{x}/{y}?access_token={accessToken}',
                additionalOptions: const {'accessToken': mapboxAccessToken},
              ),
              MarkerLayer(
                markers: [
                  if (_localPosition != null)
                    Marker(
                      point: _localPosition!,
                      builder:
                          (ctx) => Image.asset(
                            'images/casa.png',
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                          ),
                    ),

                  Marker(
                    point: _customerPosition!,
                    builder:
                        (ctx) => const Icon(
                          Icons.location_on,
                          size: 40,
                          color: Colors.red,
                        ),
                  ),
                  if (_motorcyclePosition != null)
                    Marker(
                      point: _motorcyclePosition!,
                      builder:
                          (ctx) => Image.asset(
                            'images/moto.png',
                            width: 20,
                            height: 20,
                            fit: BoxFit.cover,
                          ),
                    ),
                ],
              ),
              PolylineLayer(
                polylineCulling: false,
                polylines: [
                  Polyline(points: _ruta, color: Colors.blue, strokeWidth: 4.0),
                ],
              ),
            ],
          ),

          // Botones superpuestos en la parte inferior del mapa
          Positioned(
            bottom: 150, // Espacio para los floating action buttons
            left: 16,
            right: 16,
            child: Column(
              children: [
                if (_currentState == 4) // Botón para confirmar llegada al local
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha((0.3 * 255).toInt()),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () => _cambiarEstado(5, "¿Ya llegó al local?"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        textStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        "Llegué al local",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),

                if (_currentState == 5) // Botón existente para ir al cliente
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha((0.3 * 255).toInt()),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed:
                          () => _cambiarEstado(
                            6,
                            "¿Confirmar camino al cliente?",
                          ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        textStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        "En camino al cliente",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),

                if (_currentState ==
                    6) // Botón para confirmar llegada al destino
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha((0.3 * 255).toInt()),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed:
                          () => _cambiarEstado(7, "¿Ya llegó al destino?"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        textStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        "Llegué al destino",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),

                if (_currentState == 7)
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha((0.3 * 255).toInt()),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () async {
                        viajeFinalizado = true;
                        bool confirmacion = await _mostrarAlerta(
                          "¿Desea finalizar el viaje?",
                        );
                        if (confirmacion) {
                          await ApiService.actualizarEstado(
                            widget.pedido['id'],
                            8,
                          );
                          setState(() {
                            _currentState = 8;
                          });
                        }
                        if (!context.mounted) return;
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) =>
                                    RatingScreen(idPedido: widget.pedido['id']),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        textStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        "Finalizar Viaje",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 20.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FloatingActionButton(
              heroTag: 'info_button',
              onPressed: () => _mostrarBottomSheetPedido(context),
              backgroundColor: Colors.white,
              child: const Icon(Icons.info, color: Colors.redAccent),
            ),
            const SizedBox(width: 10),
            FloatingActionButton(
              heroTag: 'chat_button',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => ChatScreen(pedidoId: widget.pedido['id']),
                  ),
                );
              },
              backgroundColor: Colors.redAccent,
              child: const Icon(Icons.chat, color: Colors.white),
            ),
            const SizedBox(width: 10),
            FloatingActionButton(
              heroTag: 'navigation_button',
              onPressed:
                  () => _elegirNavegadorYNavegar(
                    _currentState == 4 ? _localPosition! : _customerPosition!,
                  ),
              backgroundColor: Colors.redAccent,
              child: const Icon(Icons.map, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
