import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:truelovebiker/features/home/controllers/home_controller.dart';
import 'package:truelovebiker/features/orders/presentation/screens/pedidos_screen.dart';
import 'package:truelovebiker/features/profile/presentation/screens/profile_screen.dart';
import 'package:truelovebiker/features/orders/presentation/screens/active_trips_screen.dart';
import 'package:truelovebiker/features/profile/presentation/screens/ratings_screen.dart';
import 'package:truelovebiker/features/orders/presentation/screens/order_history_screen.dart';

class HomeScreen extends GetView<HomeController> {
  const HomeScreen({super.key});

  static final List<Widget> _screens = [
    const PedidosScreen(),
    const ActiveTripsScreen(),
    const RatingsScreen(),
    const OrderHistoryScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Obx(() => _screens[controller.selectedIndex.value]),
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
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      spreadRadius: 2,
                      offset: Offset(0, 5),
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
                    _buildNavItem(Icons.history, 3),
                    _buildNavItem(Icons.person_outline, 4),
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
      onTap: () => controller.onItemTapped(index),
      child: Obx(() => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: controller.selectedIndex.value == index ? Colors.red : Colors.white,
            size: 30,
          ),
          if (controller.selectedIndex.value == index)
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
      )),
    );
  }
}
