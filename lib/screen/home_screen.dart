import 'package:flutter/material.dart';
import "package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart";
import 'package:truelovebiker/components/components.dart';
import 'package:truelovebiker/theme/app_theme.dart';
import 'package:truelovebiker/view/pedidos_view.dart';

// Definir un GlobalKey para el Scaffold
final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      endDrawer: CustomNavOption(
        options: [
          NavOption(
            title: 'Cerrar sesión',
            icon: Icons.exit_to_app,
            targetView: _buildScreen('Cerrar sesión', Colors.red),
          ),
        ],
      ),
      body: PersistentTabView(
        context,
        screens: [
          const PedidosView(),
          const PedidosView(),
          const PedidosView(),
        ],
        items: [
          PersistentBottomNavBarItem(
            icon: const Icon(Icons.shopping_bag_outlined),
            title: 'Pedidos',
            activeColorPrimary: AppTheme.primary,
            inactiveColorPrimary: Colors.grey,
          ),
          PersistentBottomNavBarItem(
            icon: const Icon(Icons.shopping_bag_outlined),
            title: 'Pedidos',
            activeColorPrimary: AppTheme.primary,
            inactiveColorPrimary: Colors.grey,
          ),
          PersistentBottomNavBarItem(
            icon: const Icon(Icons.shopping_bag_outlined),
            title: 'Pedidos',
            activeColorPrimary: AppTheme.primary,
            inactiveColorPrimary: Colors.grey,
          ),
        ],
        navBarStyle: NavBarStyle.style6,
      ),
    );
  }

  Widget _buildScreen(String title, Color color) {
    return Scaffold(
      appBar: AppBar(title: Text(title), backgroundColor: color),
      body: Center(
        child: Text(
          '$title Screen',
          style: const TextStyle(fontSize: 24, color: Colors.white),
        ),
      ),
      backgroundColor: color,
    );
  }
}
