import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      foregroundColor: Colors.black,
      backgroundColor: Colors.white,
      title: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // CircleAvatar with Gray Border
            Container(
              padding: const EdgeInsets.all(2.0),
              decoration: const BoxDecoration(
                color: Color.fromRGBO(245, 245, 245, 1), // Border color
                shape: BoxShape.circle,
              ),
              child: PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'profile') {
                    // Aquí puedes manejar lo que pasa cuando seleccionas "Mi perfil"
                    // Ejemplo: Navegar a una nueva pantalla
                  }
                },
                itemBuilder: (BuildContext context) {
                  return [
                    const PopupMenuItem<String>(
                      value: 'profile',
                      child: Row(
                        children: [
                          Icon(Icons.person, color: Colors.black),
                          SizedBox(width: 8),
                          Text('Mi perfil'),
                        ],
                      ),
                    ),
                    // Agrega más elementos al menú si es necesario
                  ];
                },
                // Usamos offset para que el menú se despliegue debajo del CircleAvatar
                offset: const Offset(
                    0, 50), // Cambia el valor según la distancia que quieras
                child: const CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Text(
                    'JS',
                    style: TextStyle(color: Colors.black),
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(2.0), // Border thickness
              decoration: const BoxDecoration(
                color: Color.fromRGBO(245, 245, 245, 1), // Border color
                shape: BoxShape.circle,
              ),
              child: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(
                  Icons.notifications,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Define the preferredSize getter to specify the height of the app bar
  @override
  Size get preferredSize => const Size.fromHeight(56.0);
}
