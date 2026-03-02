import 'package:flutter/material.dart';
import 'package:truelovebiker/components/components.dart';
import 'package:truelovebiker/components/custom_button.dart';
import 'package:truelovebiker/screen/change_password_screen.dart';
import 'package:truelovebiker/services/api.dart';

class EmailVerifyScreen extends StatefulWidget {
  const EmailVerifyScreen({super.key});

  @override
  State<EmailVerifyScreen> createState() => _EmailVerifyScreenState();
}

class _EmailVerifyScreenState extends State<EmailVerifyScreen> {
  final TextEditingController _inputController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();

  bool _isLoading = false;
  String _errorMessage = '';
  int? _userId;
  String? _codigoCorrecto;
  bool _codeSent = false;

  void _handleAction() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    if (!_codeSent) {
      final input = _inputController.text.trim();
      if (input.isEmpty) {
        setState(() {
          _errorMessage = 'Este campo no puede estar vacío';
          _isLoading = false;
        });
        return;
      }

      final result = await ApiService.sendCode(input);

      setState(() {
        _isLoading = false;
      });

      if (result['success']) {
        setState(() {
          _userId = result['id'];
          _codigoCorrecto = result['verification_code']?.toString();
          _codeSent = true;
        });
      }

      _showMessage(result['message'], result['success']);
    } else {
      final code = _codeController.text.trim();
      if (code.isEmpty) {
        setState(() {
          _errorMessage = 'Ingresa el código';
          _isLoading = false;
        });
        return;
      }

      if (code == _codigoCorrecto) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChangePasswordScreen(id: _userId!),
          ),
        );
      } else {
        setState(() {
          _errorMessage = 'Código incorrecto';
        });
      }

      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showMessage(String message, bool success) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(success ? 'Éxito' : 'Error'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK"),
              ),
            ],
          ),
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
                  Text(
                    _codeSent
                        ? 'Ingresa el código recibido'
                        : 'Ingresa tu correo',
                    style: const TextStyle(fontSize: 20, color: Colors.white),
                  ),
                  const SizedBox(height: 20),
                  if (!_codeSent)
                    CustomTextField(
                      controller: _inputController,
                      hintText: 'Correo',
                      prefixIcon: Icons.person,
                      isPassword: false,
                    ),
                  if (_codeSent)
                    CustomTextField(
                      controller: _codeController,
                      hintText: 'Código de verificación',
                      prefixIcon: Icons.lock_clock,
                      isPassword: false,
                      keyboardType: TextInputType.number,
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
                      text: _codeSent ? 'Verificar código' : 'Enviar código',
                      isLoading: _isLoading,
                      onPressed: _handleAction,
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
