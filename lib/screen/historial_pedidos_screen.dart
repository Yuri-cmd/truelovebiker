import 'package:flutter/material.dart';
import 'package:truelovebiker/model/pedido_historico_model.dart';
import 'package:truelovebiker/services/api.dart';
import 'package:url_launcher/url_launcher.dart';

class HistorialPedidosScreen extends StatefulWidget {
  const HistorialPedidosScreen({super.key});

  @override
  State<HistorialPedidosScreen> createState() => _HistorialPedidosScreenState();
}

class _HistorialPedidosScreenState extends State<HistorialPedidosScreen> {
  late Future<List<PedidoHistorico>> _futurePedidos;

  @override
  void initState() {
    super.initState();
    _futurePedidos = ApiService.fetchHistorialPedidos();
  }

  Future<void> _refresh() async {
    setState(() {
      _futurePedidos = ApiService.fetchHistorialPedidos();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Pedidos'),
        backgroundColor: Colors.red, // Match app theme
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<PedidoHistorico>>(
          future: _futurePedidos,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                child: Text('No hay pedidos en el historial.'),
              );
            }

            final pedidos = snapshot.data!;
            return ListView.builder(
              itemCount: pedidos.length,
              padding: const EdgeInsets.only(
                bottom: 80,
              ), // Space for bottom nav
              itemBuilder: (context, index) {
                final pedido = pedidos[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Pedido #${pedido.id}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              _formatDate(pedido.actualizado),
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const Divider(),
                        _buildRow(Icons.store, 'Local:', pedido.local),
                        if (pedido.celularLocal != null &&
                            pedido.celularLocal!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          InkWell(
                            onTap:
                                () => _makePhoneCall(
                                  _formatPhone(pedido.celularLocal!),
                                ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.phone,
                                  size: 16,
                                  color: Colors.green,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Llamar al local: ${_formatPhone(pedido.celularLocal!)}',
                                  style: const TextStyle(
                                    color: Colors.blue,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        _buildRow(
                          Icons.location_on,
                          'Origen:',
                          pedido.direccionLocal,
                        ),
                        const SizedBox(height: 8),
                        _buildRow(
                          Icons.flag,
                          'Destino:',
                          pedido.direccionEntrega,
                        ),
                        const SizedBox(height: 8),
                        _buildRow(Icons.person, 'Cliente:', pedido.cliente),
                        const Divider(),
                        const Text(
                          'Productos:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        ...pedido.productosList.map(
                          (prod) => Padding(
                            padding: const EdgeInsets.only(left: 8.0, top: 2.0),
                            child: Text('• $prod'),
                          ),
                        ),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'S/ ${pedido.total.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '$label ',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                TextSpan(
                  text: value,
                  style: const TextStyle(color: Colors.black87),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateStr;
    }
  }

  String _formatPhone(String phone) {
    return phone.replaceAll('+51', '');
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo llamar a $phoneNumber')),
        );
      }
    }
  }
}
