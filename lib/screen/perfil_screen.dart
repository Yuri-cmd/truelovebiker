import 'package:flutter/material.dart';
import 'package:truelovebiker/screen/editar_cuenta_bancaria_screen.dart';
import 'package:truelovebiker/screen/editar_datos_screen.dart';
import 'package:truelovebiker/services/api.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:truelovebiker/main.dart';

class ViewPerfilRepartidor extends StatefulWidget {
  const ViewPerfilRepartidor({super.key});

  @override
  State<ViewPerfilRepartidor> createState() => _ViewPerfilRepartidorState();
}

class _ViewPerfilRepartidorState extends State<ViewPerfilRepartidor> {
  Map<String, dynamic>? repartidor;
  Map<String, dynamic>? usuario;
  Map<String, dynamic>? cuentaBancaria;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarPerfil();
  }

  /// 🟢 Función para obtener el perfil del repartidor
  Future<void> _cargarPerfil() async {
    final apiService = ApiService();
    final data = await apiService.obtenerPerfilRepartidor();

    if (data != null) {
      setState(() {
        repartidor = data['repartidor'];
        usuario = data['usuario'];
        cuentaBancaria = data['cuentaBancaria'];
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _cambiarEstadoRepartidor() async {
    final nuevoEstado = repartidor!['activo'] == 1 ? 0 : 1;

    final confirmar = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirmar cambio de estado'),
            content: Text(
              '¿Estás seguro de ${nuevoEstado == 1 ? 'activar' : 'desactivar'} al repartidor?',
            ),
            actions: [
              TextButton(
                child: const Text('Cancelar'),
                onPressed: () => Navigator.of(context).pop(false),
              ),
              ElevatedButton(
                child: const Text('Confirmar'),
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          ),
    );

    if (confirmar != true) return;

    final apiService = ApiService();
    final success = await apiService.actualizarEstadoRepartidor(nuevoEstado);

    if (success) {
      setState(() {
        repartidor!['activo'] = nuevoEstado;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Estado actualizado correctamente.')),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al actualizar el estado.')),
      );
    }
  }

  Future<void> _cerrarSesion() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs
        .clear(); // Esto borra todos los datos guardados en SharedPreferences

    // Navega a la pantalla de login y limpia el historial para que no se pueda volver atrás
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  Future<void> _eliminarCuenta() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Eliminar cuenta'),
            content: const Text(
              '¿Estás seguro que deseas eliminar tu cuenta? Esta acción es irreversible y perderás todos tus datos.',
            ),
            actions: [
              TextButton(
                child: const Text('Cancelar'),
                onPressed: () => Navigator.of(context).pop(false),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text(
                  'Eliminar',
                  style: TextStyle(color: Colors.white),
                ),
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          ),
    );

    if (confirmar != true) return;

    final apiService = ApiService();
    final success = await apiService.borrarCuenta();

    if (success) {
      _cerrarSesion();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cuenta eliminada correctamente.')),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al eliminar la cuenta.')),
      );
    }
  }

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
                  setThemeMode(val ? ThemeMode.dark : ThemeMode.light);
                },
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder:
                    (context) => AlertDialog(
                      title: const Text('Cerrar sesión'),
                      content: const Text(
                        '¿Estás seguro que deseas cerrar sesión?',
                      ),
                      actions: [
                        TextButton(
                          child: const Text('Cancelar'),
                          onPressed: () => Navigator.of(context).pop(false),
                        ),
                        ElevatedButton(
                          child: const Text('Cerrar sesión'),
                          onPressed: () => Navigator.of(context).pop(true),
                        ),
                      ],
                    ),
              );
              if (confirm == true) {
                _cerrarSesion();
              }
            },
          ),
        ],
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : repartidor == null
              ? const Center(child: Text("No se encontró el perfil."))
              : RefreshIndicator(
                onRefresh: _cargarPerfil,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildSectionTitle("Datos Personales", colorScheme),
                          TextButton.icon(
                            icon: Icon(Icons.edit, color: colorScheme.primary),
                            label: Text(
                              "Editar",
                              style: TextStyle(color: colorScheme.primary),
                            ),
                            onPressed: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (_) => EditarDatosScreen(
                                        repartidor: repartidor!,
                                      ),
                                ),
                              );
                              if (result != null) {
                                setState(() {
                                  repartidor = result;
                                });
                                if(!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Datos personales actualizados.',
                                    ),
                                  ),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            repartidor!['activo'] == 1 ? "Activo" : "Inactivo",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color:
                                  repartidor!['activo'] == 1
                                      ? Colors.green
                                      : Colors.grey,
                            ),
                          ),
                          Switch(
                            value: repartidor!['activo'] == 1,
                            activeTrackColor: Colors.green,
                            inactiveThumbColor: Colors.grey,
                            onChanged: (value) {
                              _cambiarEstadoRepartidor();
                            },
                          ),
                        ],
                      ),
                      _buildInfoTile(
                        Icons.person,
                        "Nombre",
                        "${repartidor!['nombres']} ${repartidor!['apellidos']}",
                        colorScheme: colorScheme,
                        isDark: isDark,
                      ),
                      _buildInfoTile(
                        Icons.badge,
                        "Tipo Documento",
                        repartidor!['tipo_documento'],
                        colorScheme: colorScheme,
                        isDark: isDark,
                      ),
                      _buildInfoTile(
                        Icons.credit_card,
                        "Nro Documento",
                        repartidor!['nro_documento'],
                        colorScheme: colorScheme,
                        isDark: isDark,
                      ),
                      _buildInfoTile(
                        Icons.phone,
                        "Celular",
                        repartidor!['celular'],
                        colorScheme: colorScheme,
                        isDark: isDark,
                      ),
                      _buildInfoTile(
                        Icons.email,
                        "Email",
                        repartidor!['email'],
                        colorScheme: colorScheme,
                        isDark: isDark,
                      ),
                      _buildInfoTile(
                        Icons.location_city,
                        "Departamento",
                        repartidor!['departamento'],
                        colorScheme: colorScheme,
                        isDark: isDark,
                      ),
                      _buildSectionTitle("Datos del Vehículo", colorScheme),
                      _buildInfoTile(
                        Icons.motorcycle,
                        "Vehículo",
                        repartidor!['vehiculo'],
                        colorScheme: colorScheme,
                        isDark: isDark,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildSectionTitle("Cuenta Bancaria", colorScheme),
                          TextButton.icon(
                            icon: Icon(Icons.edit, color: colorScheme.primary),
                            label: Text(
                              "Editar",
                              style: TextStyle(color: colorScheme.primary),
                            ),
                            onPressed: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (_) => EditarCuentaBancariaScreen(
                                        cuentaBancaria: cuentaBancaria!,
                                      ),
                                ),
                              );
                              if (result != null) {
                                setState(() {
                                  cuentaBancaria = result;
                                });
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Cuenta bancaria actualizada.',
                                    ),
                                  ),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                      _buildInfoTile(
                        Icons.verified,
                        "Titular",
                        cuentaBancaria!['titular'],
                        colorScheme: colorScheme,
                        isDark: isDark,
                      ),
                      _buildInfoTile(
                        Icons.person,
                        "Titular",
                        cuentaBancaria!['titular'],
                        colorScheme: colorScheme,
                        isDark: isDark,
                      ),
                      _buildInfoTile(
                        Icons.badge,
                        "DNI",
                        cuentaBancaria!['dni'],
                        colorScheme: colorScheme,
                        isDark: isDark,
                      ),
                      _buildInfoTile(
                        Icons.account_balance,
                        "Banco",
                        cuentaBancaria!['banco']['nombre'],
                        colorScheme: colorScheme,
                        isDark: isDark,
                      ),
                      _buildInfoTile(
                        Icons.wallet,
                        "Tipo Cuenta",
                        cuentaBancaria!['tipo_cuenta']['nombre'],
                        colorScheme: colorScheme,
                        isDark: isDark,
                      ),
                      _buildInfoTile(
                        Icons.credit_card,
                        "Número Cuenta",
                        cuentaBancaria!['numero_cuenta'],
                        colorScheme: colorScheme,
                        isDark: isDark,
                      ),
                      _buildSectionTitle("Estado", colorScheme),
                      _buildInfoTile(
                        Icons.verified,
                        "Aprobado",
                        repartidor!['aprobado'] ? "Sí" : "No",
                        color:
                            repartidor!['aprobado'] ? Colors.green : Colors.red,
                        colorScheme: colorScheme,
                        isDark: isDark,
                      ),
                      _buildInfoTile(
                        Icons.access_time,
                        "Fecha Creación",
                        repartidor!['created_at'],
                        colorScheme: colorScheme,
                        isDark: isDark,
                      ),
                      _buildInfoTile(
                        Icons.update,
                        "Última Actualización",
                        repartidor!['updated_at'],
                        colorScheme: colorScheme,
                        isDark: isDark,
                      ),
                      _buildSectionTitle("Usuario Asociado", colorScheme),
                      _buildInfoTile(
                        Icons.account_circle,
                        "Usuario",
                        usuario!['usuario'],
                        colorScheme: colorScheme,
                        isDark: isDark,
                      ),
                      _buildInfoTile(
                        Icons.person_outline,
                        "Nombre",
                        usuario!['name'],
                        colorScheme: colorScheme,
                        isDark: isDark,
                      ),
                      _buildInfoTile(
                        Icons.email,
                        "Email",
                        usuario!['email'],
                        colorScheme: colorScheme,
                        isDark: isDark,
                      ),
                      _buildInfoTile(
                        Icons.lock,
                        "Rol",
                        usuario!['role_id'].toString(),
                        colorScheme: colorScheme,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 32),
                      _buildSectionTitle("Seguridad", colorScheme),
                      ListTile(
                        leading: const Icon(Icons.delete_forever, color: Colors.red),
                        title: const Text(
                          "Eliminar mi cuenta",
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: const Text(
                          "Esta acción es permanente y no se puede deshacer.",
                        ),
                        onTap: _eliminarCuenta,
                      ),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildSectionTitle(String title, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: colorScheme.secondary,
        ),
      ),
    );
  }

  Widget _buildInfoTile(
    IconData icon,
    String title,
    String value, {
    Color? color,
    required ColorScheme colorScheme,
    required bool isDark,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.red),
      title: Text(
        title,
        style: TextStyle(
          color: isDark ? colorScheme.onSurface : colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        value,
        style: TextStyle(
          color:
              color ?? (isDark ? colorScheme.onSurfaceVariant : Colors.black),
        ),
      ),
    );
  }
}
