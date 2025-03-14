import 'package:flutter/material.dart';
// import 'package:truelove/theme/app_theme.dart';

class NavOption {
  final String title;
  final IconData icon;
  final Widget targetView;

  NavOption({
    required this.title,
    required this.icon,
    required this.targetView,
  });
}

class CustomNavOption extends StatelessWidget {
  final List<NavOption> options;

  const CustomNavOption({super.key, required this.options});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: const BoxDecoration(color: Colors.black),
            child: Center(
              // Usamos Center para centrar la imagen
              child: Image.asset(
                'images/logo.png',
                height: 140,
                width: 140,
                fit: BoxFit.contain,
              ),
            ),
          ),
          ...options.map((option) {
            return ListTile(
              leading: Icon(option.icon),
              title: Text(option.title),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => option.targetView),
                );
              },
            );
          }),
        ],
      ),
    );
  }
}
