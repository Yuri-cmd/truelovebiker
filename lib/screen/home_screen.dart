import 'package:flutter/material.dart';
import 'package:truelovebiker/screen/pedidos_screen.dart';
import 'package:truelovebiker/screen/perfil_screen.dart';
import 'package:truelovebiker/screen/viajes_activos_screen.dart';
import 'package:truelovebiker/view/calificaciones_page.dart';
import 'package:truelovebiker/services/api.dart';
import 'package:truelovebiker/view/viaje_view.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const PedidosScreen(),
    const ViajesActivosScreen(),
    CalificacionesPage(),
    ViewPerfilRepartidor(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkViajeActivo(); // Verificar al iniciar
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Verificar cuando la app vuelve al foreground
      _checkViajeActivo();
    }
  }

  Future<void> _checkViajeActivo() async {
    final viajesActivos = await ApiService.obtenerViajesActivos();
    if (viajesActivos.isNotEmpty && mounted) {
      if (viajesActivos.length == 1) {
        // Si solo tiene un viaje activo, ir directo a ese viaje
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ViajeView(pedido: viajesActivos.first),
          ),
        );
      } else if (viajesActivos.length > 1) {
        // Si tiene múltiples viajes, ir a la vista de viajes activos
        setState(() {
          _selectedIndex = 1; // Índice de la pestaña de viajes activos
        });
      }
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _screens[_selectedIndex],
          SafeArea(
            bottom: true,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      spreadRadius: 2,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                width: MediaQuery.of(context).size.width * 0.9,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildNavItem(Icons.shopping_bag_outlined, 0),
                    _buildNavItem(Icons.directions_bike, 1),
                    _buildNavItem(Icons.star_border, 2),
                    _buildNavItem(Icons.person_outline, 3),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, int index) {
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: _selectedIndex == index ? Colors.red : Colors.white,
            size: 30,
          ),
          if (_selectedIndex == index)
            Container(
              margin: const EdgeInsets.only(top: 4),
              height: 4,
              width: 20,
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
        ],
      ),
    );
  }
}
