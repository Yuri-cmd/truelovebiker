import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:truelovebiker/core/theme/theme_notifier.dart';
import 'package:truelovebiker/core/routes/app_pages.dart';
import 'package:truelovebiker/features/profile/controllers/profile_controller.dart';

class ProfileScreen extends GetView<ProfileController> {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text("Perfil del Repartidor"),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        actions: [
          Row(
            children: [
              Icon(
                isDark ? Icons.dark_mode : Icons.light_mode,
                color: colorScheme.onPrimary,
              ),
              Switch(
                value: isDark,
                inactiveThumbColor: colorScheme.secondary,
                onChanged: (val) {
                  themeNotifier.setTheme(val ? ThemeMode.dark : ThemeMode.light);
                },
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () => _showLogoutDialog(context),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.repartidor.value == null) {
          return const Center(child: Text("No se encontró el perfil."));
        }

        final repartidor = controller.repartidor.value!;
        final usuario = controller.usuario.value!;
        final cuentaBancaria = controller.cuentaBancaria.value!;

        return RefreshIndicator(
          onRefresh: controller.cargarPerfil,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, repartidor, colorScheme),
                _buildPersonalData(context, repartidor, colorScheme, isDark),
                _buildVehicleData(repartidor, colorScheme, isDark),
                _buildBankData(context, cuentaBancaria, colorScheme, isDark),
                _buildStatusSection(repartidor, colorScheme, isDark),
                _buildUserData(usuario, colorScheme, isDark),
                const SizedBox(height: 32),
                _buildSecuritySection(context),
                const SizedBox(height: 100),
              ],
            ),
          ),
        );
      }),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    Get.dialog(
      AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro que deseas cerrar sesión?'),
        actions: [
          TextButton(
            child: const Text('Cancelar'),
            onPressed: () => Get.back(),
          ),
          ElevatedButton(
            child: const Text('Cerrar sesión'),
            onPressed: () {
              Get.back();
              controller.cerrarSesion();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Map<String, dynamic> repartidor, ColorScheme colorScheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildSectionTitle("Datos Personales", colorScheme),
        TextButton.icon(
          icon: Icon(Icons.edit, color: colorScheme.primary),
          label: Text("Editar", style: TextStyle(color: colorScheme.primary)),
          onPressed: () async {
            final result = await Get.toNamed(Routes.EDIT_PROFILE, arguments: repartidor);
            if (result != null) {
              controller.cargarPerfil();
            }
          },
        ),
      ],
    );
  }

  Widget _buildPersonalData(BuildContext context, Map<String, dynamic> repartidor, ColorScheme colorScheme, bool isDark) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              repartidor['activo'] == 1 ? "Activo" : "Inactivo",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: repartidor['activo'] == 1 ? Colors.green : Colors.grey,
              ),
            ),
            Switch(
              value: repartidor['activo'] == 1,
              activeTrackColor: Colors.green,
              onChanged: (value) => _showStatusConfirmDialog(repartidor['activo'] == 1),
            ),
          ],
        ),
        _buildInfoTile(Icons.person, "Nombre", "${repartidor['nombres']} ${repartidor['apellidos']}", colorScheme, isDark),
        _buildInfoTile(Icons.badge, "Tipo Documento", repartidor['tipo_documento'], colorScheme, isDark),
        _buildInfoTile(Icons.credit_card, "Nro Documento", repartidor['nro_documento'], colorScheme, isDark),
        _buildInfoTile(Icons.phone, "Celular", repartidor['celular'] ?? "", colorScheme, isDark),
        _buildInfoTile(Icons.email, "Email", repartidor['email'] ?? "", colorScheme, isDark),
      ],
    );
  }

  void _showStatusConfirmDialog(bool isActive) {
    Get.dialog(
      AlertDialog(
        title: const Text('Confirmar cambio de estado'),
        content: Text('¿Estás seguro de ${isActive ? 'desactivar' : 'activar'} al repartidor?'),
        actions: [
          TextButton(child: const Text('Cancelar'), onPressed: () => Get.back()),
          ElevatedButton(
            child: const Text('Confirmar'),
            onPressed: () {
              Get.back();
              controller.cambiarEstadoRepartidor();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleData(Map<String, dynamic> repartidor, ColorScheme colorScheme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle("Datos del Vehículo", colorScheme),
        _buildInfoTile(Icons.motorcycle, "Vehículo", repartidor['vehiculo'] ?? "", colorScheme, isDark),
      ],
    );
  }

  Widget _buildBankData(BuildContext context, Map<String, dynamic> cuentaBancaria, ColorScheme colorScheme, bool isDark) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionTitle("Cuenta Bancaria", colorScheme),
            TextButton.icon(
              icon: Icon(Icons.edit, color: colorScheme.primary),
              label: Text("Editar", style: TextStyle(color: colorScheme.primary)),
              onPressed: () async {
                final result = await Get.toNamed(Routes.EDIT_BANK, arguments: cuentaBancaria);
                if (result != null) {
                  controller.cargarPerfil();
                }
              },
            ),
          ],
        ),
        _buildInfoTile(Icons.person, "Titular", cuentaBancaria['titular'] ?? "", colorScheme, isDark),
        _buildInfoTile(Icons.badge, "DNI", cuentaBancaria['dni'] ?? "", colorScheme, isDark),
        _buildInfoTile(Icons.account_balance, "Banco", cuentaBancaria['banco']?['nombre'] ?? "", colorScheme, isDark),
        _buildInfoTile(Icons.credit_card, "Número Cuenta", cuentaBancaria['numero_cuenta'] ?? "", colorScheme, isDark),
      ],
    );
  }

  Widget _buildStatusSection(Map<String, dynamic> repartidor, ColorScheme colorScheme, bool isDark) {
    return Column(
      children: [
        _buildSectionTitle("Estado", colorScheme),
        _buildInfoTile(
          Icons.verified, 
          "Aprobado", 
          repartidor['aprobado'] == true || repartidor['aprobado'] == 1 ? "Sí" : "No", 
          colorScheme, 
          isDark,
          color: (repartidor['aprobado'] == true || repartidor['aprobado'] == 1) ? Colors.green : Colors.red
        ),
      ],
    );
  }

  Widget _buildUserData(Map<String, dynamic> usuario, ColorScheme colorScheme, bool isDark) {
    return Column(
      children: [
        _buildSectionTitle("Usuario Asociado", colorScheme),
        _buildInfoTile(Icons.account_circle, "Usuario", usuario['usuario'] ?? "", colorScheme, isDark),
        _buildInfoTile(Icons.email, "Email", usuario['email'] ?? "", colorScheme, isDark),
      ],
    );
  }

  Widget _buildSecuritySection(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.delete_forever, color: Colors.red),
      title: const Text("Eliminar mi cuenta", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
      subtitle: const Text("Esta acción es permanente."),
      onTap: () => _showDeleteDialog(),
    );
  }

  void _showDeleteDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('Eliminar cuenta'),
        content: const Text('¿Estás seguro que deseas eliminar tu cuenta? Esta acción es irreversible.'),
        actions: [
          TextButton(child: const Text('Cancelar'), onPressed: () => Get.back()),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
            onPressed: () {
              Get.back();
              controller.eliminarCuenta();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
      child: Text(
        title,
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorScheme.secondary),
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String title, String value, ColorScheme colorScheme, bool isDark, {Color? color}) {
    return ListTile(
      leading: Icon(icon, color: Colors.red),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(value, style: TextStyle(color: color ?? (isDark ? Colors.grey[400] : Colors.black87))),
    );
  }
}
