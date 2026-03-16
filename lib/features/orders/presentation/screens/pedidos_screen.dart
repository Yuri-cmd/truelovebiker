import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:truelovebiker/core/widgets/pedidos_card.dart';
import 'package:truelovebiker/core/routes/app_pages.dart';
import 'package:truelovebiker/features/orders/controllers/pedidos_controller.dart';

class PedidosScreen extends GetView<PedidosController> {
  const PedidosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pedidos Cercanos'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: SpinKitWaveSpinner(color: Colors.blueAccent, size: 50.0),
          );
        }

        if (controller.pedidos.isEmpty) {
          return RefreshIndicator(
            onRefresh: controller.loadPedidos,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 150),
                Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.shopping_cart_outlined,
                        size: 80,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 10),
                      Text(
                        "No hay pedidos disponibles por ahora",
                        style: TextStyle(fontSize: 18, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.loadPedidos,
          child: ListView.builder(
            itemCount: controller.pedidos.length,
            itemBuilder: (context, index) {
              final pedido = controller.pedidos[index];
              return PedidoCard(
                pedido: pedido.toMap(),
                onTap: () {
                  Get.toNamed(Routes.ORDER_DETAIL, arguments: pedido.toMap());
                },
              );
            },
          ),
        );
      }),
    );
  }
}
