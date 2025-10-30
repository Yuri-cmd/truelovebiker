import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:truelovebiker/components/pedidos_card.dart';
import 'package:truelovebiker/model/pedido_model.dart';
import 'package:truelovebiker/screen/detalle_pedido_screen.dart';
import 'package:truelovebiker/services/api.dart';
import 'package:truelovebiker/services/firebase_api.dart';

class PedidosView extends StatefulWidget {
  const PedidosView({super.key});

  @override
  State<PedidosView> createState() => _PedidosViewState();
}

class _PedidosViewState extends State<PedidosView> {
  List<Pedido> pedidos = [];
  final ApiService apiService = ApiService();
  Timer? timer;
  bool isLoading = true;
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    loadInitialPedidos();
    timer = Timer.periodic(
      const Duration(seconds: 5),
      (Timer t) => loadPedidos(),
    );
  }

  Future<void> loadPedidos() async {
    try {
      final data = await apiService.fetchPedidos();
      if (mounted) {
        setState(() {
          List<Pedido> nuevosPedidos =
              data.where((p) => p.estado.toString() == "2").toList();
          List<Pedido> pedidosActualizados = List.from(pedidos);

          for (var nuevoPedido in nuevosPedidos) {
            bool existe = pedidosActualizados.any(
              (p) => p.id == nuevoPedido.id,
            );
            if (!existe) {
              pedidosActualizados.add(nuevoPedido);
            }
          }

          pedidos = data;
        });
      }
    } catch (e) {
      setState(() {
        hasError = true;
      });
      debugPrint('Error cargando pedidos: $e');
    }
  }

  bool areListsEqual(List<Pedido> oldList, List<Pedido> newList) {
    if (oldList.length != newList.length) return false;
    for (int i = 0; i < oldList.length; i++) {
      if (oldList[i].id != newList[i].id) return false;
    }
    return true;
  }

  Future<void> loadInitialPedidos() async {
    setState(() {
      isLoading = true;
    });

    await loadPedidos();

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: loadPedidos,
      child:
          isLoading
              ? _buildLoadingSpinner()
              : pedidos.isEmpty
              ? _buildNoPedidosWidget()
              : _buildPedidosList(),
    );
  }

  Widget _buildLoadingSpinner() {
    return const Center(
      child: SpinKitWaveSpinner(color: Colors.blueAccent, size: 50.0),
    );
  }

  Widget _buildNoPedidosWidget() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 150),
        Center(
          child: Column(
            children: [
              const Icon(
                Icons.shopping_cart_outlined,
                size: 80,
                color: Colors.grey,
              ),
              const SizedBox(height: 10),
              const Text(
                "No hay pedidos disponibles por ahora",
                style: TextStyle(fontSize: 18, color: Colors.black54),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPedidosList() {
    return ListView.builder(
      itemCount: pedidos.length,
      itemBuilder: (context, index) {
        final pedido = pedidos[index];
        return PedidoCard(
          pedido: pedido.toMap(),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => DetallePedidoScreen(pedido: pedido.toMap()),
              ),
            );
          },
        );
      },
    );
  }
}
