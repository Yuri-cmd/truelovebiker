import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:truelovebiker/core/widgets/custom_button.dart';
import 'package:truelovebiker/core/widgets/custom_text_field.dart';
import 'package:truelovebiker/features/profile/controllers/change_password_controller.dart';

class ChangePasswordScreen extends GetView<ChangePasswordController> {
  const ChangePasswordScreen({super.key});

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
                    controller: controller.passwordController,
                    hintText: 'Nueva contraseña',
                    prefixIcon: Icons.lock,
                    obscureText: true,
                    isPassword: false,
                  ),
                  const SizedBox(height: 10),
                  Obx(() => controller.errorMessage.isNotEmpty
                      ? Text(
                          controller.errorMessage.value,
                          style: const TextStyle(color: Colors.red),
                        )
                      : const SizedBox.shrink()),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: Obx(() => CustomButton(
                          text: "Guardar contraseña",
                          isLoading: controller.isLoading.value,
                          onPressed: controller.changePassword,
                          backgroundColor: Colors.redAccent,
                          textColor: Colors.white,
                        )),
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
