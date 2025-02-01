import 'package:flutter/material.dart';
import 'package:truelovebiker/view/detalle_pedido_view.dart';

class PedidosView extends StatelessWidget {
  const PedidosView({super.key});

  @override
  Widget build(BuildContext context) {
    // Lista de pedidos simulada
    final List<Map<String, String>> pedidos = [
      {
        'local': 'Supermercado ABC',
        'direccion': 'Av. Principal 123',
        'productos': 'Pan, Leche, Jugo',
        'tiempo': '15 minutos',
      },
      {
        'local': 'Farmacia XYZ',
        'direccion': 'Calle Ficticia 456',
        'productos': 'Medicamentos, Crema',
        'tiempo': '10 minutos',
      },
      {
        'local': 'Tienda de Ropa',
        'direccion': 'Calle Ropa 789',
        'productos': 'Camisa, Pantalón',
        'tiempo': '20 minutos',
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pedidos Cercanos'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListView.builder(
          itemCount: pedidos.length,
          itemBuilder: (context, index) {
            final pedido = pedidos[index];
            return GestureDetector(
              onTap: () {
                // Navegar a la pantalla de detalles al hacer clic
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DetallePedidoScreen(pedido: pedido),
                  ),
                );
              },
              child: Card(
                margin: const EdgeInsets.symmetric(vertical: 10),
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      // Icono de local
                      Icon(
                        Icons.location_on,
                        color: Colors.blueAccent,
                        size: 40,
                      ),
                      const SizedBox(width: 12),
                      // Detalles del pedido
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pedido['local']!,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Dirección: ${pedido['direccion']}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Productos: ${pedido['productos']}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tiempo estimado: ${pedido['tiempo']}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.blueAccent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
      backgroundColor: Colors.blue[50],
    );
  }
}
