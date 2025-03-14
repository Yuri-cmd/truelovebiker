import 'package:flutter/material.dart';
import 'package:truelovebiker/view/pedidos_view.dart';

class PedidosScreen extends StatelessWidget {
  const PedidosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pedidos Cercanos'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: const PedidosView(),
    );
  }
}
