import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:truelovebiker/core/widgets/custom_text_field.dart';
import 'package:truelovebiker/features/auth/controllers/auth_controller.dart';
import 'package:truelovebiker/core/routes/app_pages.dart';

class LoginScreen extends GetView<AuthController> {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? Colors.black : const Color(0xFFFDE5EB),
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
                        color: Colors.white,
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
                      controller: controller.emailController,
                      hintText: 'Correo Electrónico',
                      isPassword: false,
                      prefixIcon: Icons.email,
                    ),
                    const SizedBox(height: 20),
                    Obx(() => CustomTextField(
                      controller: controller.passwordController,
                      hintText: 'Contraseña',
                      obscureText: controller.isObscure.value,
                      onIconPressed: controller.togglePasswordVisibility,
                      isPassword: true,
                      prefixIcon: Icons.lock,
                    )),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () {
                           Get.toNamed(Routes.EMAIL_VERIFY);
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
                      child: Obx(() => ElevatedButton(
                        onPressed:
                            controller.isButtonActive.value && !controller.isLoading.value 
                                ? controller.login 
                                : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: controller.isButtonActive.value 
                              ? (isDark ? Colors.red[700] : Colors.red) 
                              : Colors.grey,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: isDark ? 8 : 4,
                        ),
                        child: controller.isLoading.value
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
                      )),
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
