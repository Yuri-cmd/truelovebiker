import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:truelovebiker/services/api.dart';
import 'package:truelovebiker/view/login_view.dart';
import 'package:truelovebiker/screen/home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    final userId = await ApiService.getUsuarioId();
    if (isLoggedIn) {
      final condiciones = await ApiService().verificarCondiciones(userId!);

      if (condiciones['puede_trabajar'] == true) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } else {
        await prefs.clear(); // cerrar sesión
        if (!mounted) return;
        _mostrarAlerta(condiciones['mensaje'] ?? 'No autorizado');
      }
    }
  }

  void _mostrarAlerta(String mensaje) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Acceso denegado'),
            content: Text(mensaje),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const LoginView();
  }
}
