import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:truelovebiker/components/custom_text_field.dart';
import 'package:truelovebiker/services/api.dart';
import 'package:truelovebiker/screen/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:truelovebiker/screen/email_verify_screen.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool isButtonActive = false;
  bool _isObscure = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_updateButtonState);
    _passwordController.addListener(_updateButtonState);
  }

  void _updateButtonState() {
    setState(() {
      isButtonActive =
          _emailController.text.isNotEmpty &&
          _passwordController.text.isNotEmpty;
    });
  }

  void _togglePasswordVisibility() {
    setState(() {
      _isObscure = !_isObscure;
    });
  }

  void _login() async {
    setState(() {
      _isLoading = true;
    });

    String email = _emailController.text;
    String password = _passwordController.text;

    try {
      final response = await ApiService.sendLogin('biker/login', {
        'email': email,
        'password': password,
      });

      if (response['status'] == 'success') {
        final userId = await ApiService.getUsuarioId();
        final condiciones = await ApiService().verificarCondiciones(userId!);

        if (condiciones['puede_trabajar'] == true) {
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        } else {
          final prefs = await SharedPreferences.getInstance();
          await prefs.clear(); // cerrar sesión
          if (!context.mounted) return;
          _mostrarAlerta(condiciones['mensaje'] ?? 'No autorizado');
        }
      } else {
        if (!mounted) return;
        final errorMsg = response['message'] ?? response['error'] ?? 'Credenciales incorrectas';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString().replaceAll('Exception:', '')}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _mostrarAlerta(String mensaje) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        title: Text(
          'Acceso denegado',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          mensaje,
          style: TextStyle(
            color: isDark ? Colors.grey[300] : Colors.black87,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            style: TextButton.styleFrom(
              foregroundColor: isDark ? Colors.redAccent[200] : Colors.red,
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? Colors.black : const Color(0xFFFDE5EB),
      body: Stack(
        children: [
          // Fondo con imagen
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("images/deli.jpg"),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(
            color: isDark 
                ? Colors.black.withAlpha((0.7 * 255).toInt())
                : Colors.black.withAlpha((0.3 * 255).toInt()),
          ),
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Image.asset('images/logo.png', height: 80),
                    const SizedBox(height: 20),
                    Text(
                      '¡Bienvenido Motorizado!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        shadows: isDark ? [
                          Shadow(
                            color: Colors.black.withAlpha((0.8 * 255).toInt()),
                            offset: const Offset(1, 1),
                            blurRadius: 3,
                          ),
                        ] : null,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Inicia sesión para gestionar tus rutas y entregas fácilmente.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isDark ? Colors.grey[200] : Colors.white,
                        fontSize: 16,
                        shadows: isDark ? [
                          Shadow(
                            color: Colors.black.withAlpha((0.8 * 255).toInt()),
                            offset: const Offset(1, 1),
                            blurRadius: 3,
                          ),
                        ] : null,
                      ),
                    ),
                    const SizedBox(height: 30),
                    CustomTextField(
                      controller: _emailController,
                      hintText: 'Correo Electrónico',
                      isPassword: false,
                      prefixIcon: Icons.email,
                    ),
                    const SizedBox(height: 20),
                    CustomTextField(
                      controller: _passwordController,
                      hintText: 'Contraseña',
                      obscureText: _isObscure,
                      onIconPressed: _togglePasswordVisibility,
                      isPassword: true,
                      prefixIcon: Icons.lock,
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () {
                           Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const EmailVerifyScreen(),
                            ),
                          );
                        },
                        child: Text(
                          '¿Olvidaste tu contraseña?',
                          style: TextStyle(
                            color: isDark ? Colors.redAccent[200] : Colors.redAccent,
                            fontWeight: FontWeight.bold,
                            shadows: isDark ? [
                              Shadow(
                                color: Colors.black.withAlpha((0.8 * 255).toInt()),
                                offset: const Offset(1, 1),
                                blurRadius: 2,
                              ),
                            ] : null,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed:
                            isButtonActive && !_isLoading ? _login : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isButtonActive 
                              ? (isDark ? Colors.red[700] : Colors.red) 
                              : Colors.grey,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: isDark ? 8 : 4,
                        ),
                        child: _isLoading
                            ? const SpinKitCircle(
                                color: Colors.white,
                                size: 30.0,
                              )
                            : const Text(
                                'Iniciar sesión',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
