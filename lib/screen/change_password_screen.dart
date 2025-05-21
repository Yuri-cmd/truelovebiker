import 'package:flutter/material.dart';
import 'package:truelovebiker/components/custom_button.dart';
import 'package:truelovebiker/components/custom_text_field.dart';
import 'package:truelovebiker/screen/login_screen.dart';
import 'package:truelovebiker/services/api.dart';

class ChangePasswordScreen extends StatefulWidget {
  final int id;
  const ChangePasswordScreen({super.key, required this.id});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';

  void _changePassword() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final newPassword = _passwordController.text.trim();

    if (newPassword.isEmpty) {
      setState(() {
        _errorMessage = 'La contraseña no puede estar vacía';
        _isLoading = false;
      });
      return;
    }

    final result = await ApiService.updatePassword(widget.id, newPassword);

    setState(() {
      _isLoading = false;
    });

    _showAlert(result['message'], result['success']);
  }

  void _showAlert(String message, bool success) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(success ? "Éxito" : "Error"),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (success) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => LoginScreen()),
                  );
                }
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black12,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("images/deli.jpg"),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(color: Colors.black.withAlpha((0.3 * 255).toInt())),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('images/logo.png', height: 80),
                  const Text(
                    'Cambia tu contraseña',
                    style: TextStyle(fontSize: 20, color: Colors.white),
                  ),
                  const SizedBox(height: 20),
                  CustomTextField(
                    controller: _passwordController,
                    hintText: 'Nueva contraseña',
                    prefixIcon: Icons.lock,
                    obscureText: true,
                    isPassword: false,
                  ),
                  const SizedBox(height: 10),
                  if (_errorMessage.isNotEmpty)
                    Text(
                      _errorMessage,
                      style: const TextStyle(color: Colors.red),
                    ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: CustomButton(
                      text: "Guardar contraseña",
                      isLoading: _isLoading,
                      onPressed: _changePassword,
                      backgroundColor: Colors.redAccent,
                      textColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
