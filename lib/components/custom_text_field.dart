import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  final Function()? onIconPressed;
  final bool isPassword; // Indicador para saber si es un campo de contraseña
  final IconData? prefixIcon; // Nuevo campo para el icono de prefijo

  const CustomTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.obscureText = false,
    this.onIconPressed,
    required this.isPassword, // Se espera un valor para isPassword
    this.prefixIcon, // Se inicializa como opcional
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        hintText: hintText,
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 10,
          horizontal: 12,
        ),
        prefixIcon:
            prefixIcon != null
                ? Icon(prefixIcon, color: Colors.grey)
                : null, // Mostrar el icono solo si se proporciona
        // Agregar el sufijo solo si es un campo de contraseña
        suffixIcon:
            isPassword
                ? IconButton(
                  icon: Icon(
                    obscureText ? Icons.visibility : Icons.visibility_off,
                    color: Colors.grey,
                  ),
                  onPressed: onIconPressed, // Llama a la función de toggling
                )
                : null, // No se agrega ningún sufijo si no es un campo de contraseña
      ),
    );
  }
}
