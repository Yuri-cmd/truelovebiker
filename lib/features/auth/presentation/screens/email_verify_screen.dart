import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:truelovebiker/core/widgets/custom_button.dart';
import 'package:truelovebiker/core/widgets/custom_text_field.dart';
import 'package:truelovebiker/features/auth/controllers/email_verify_controller.dart';

class EmailVerifyScreen extends GetView<EmailVerifyController> {
  const EmailVerifyScreen({super.key});

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
                  Obx(() => Text(
                        controller.codeSent.value
                            ? 'Ingresa el código recibido'
                            : 'Ingresa tu correo',
                        style: const TextStyle(fontSize: 20, color: Colors.white),
                      )),
                  const SizedBox(height: 20),
                  Obx(() {
                    if (!controller.codeSent.value) {
                      return CustomTextField(
                        controller: controller.inputController,
                        hintText: 'Correo',
                        prefixIcon: Icons.person,
                        isPassword: false,
                      );
                    } else {
                      return CustomTextField(
                        controller: controller.codeController,
                        hintText: 'Código de verificación',
                        prefixIcon: Icons.lock_clock,
                        isPassword: false,
                        keyboardType: TextInputType.number,
                      );
                    }
                  }),
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
                          text: controller.codeSent.value ? 'Verificar código' : 'Enviar código',
                          isLoading: controller.isLoading.value,
                          onPressed: controller.handleAction,
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
