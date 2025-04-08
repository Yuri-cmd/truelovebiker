import 'package:flutter/material.dart';
import 'package:truelovebiker/services/api.dart';

class ViewPerfilRepartidor extends StatefulWidget {
  const ViewPerfilRepartidor({super.key});

  @override
  State<ViewPerfilRepartidor> createState() => _ViewPerfilRepartidorState();
}

class _ViewPerfilRepartidorState extends State<ViewPerfilRepartidor> {
  Map<String, dynamic>? repartidor;
  Map<String, dynamic>? usuario;
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
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Perfil del Repartidor")),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : repartidor == null
              ? const Center(child: Text("No se encontró el perfil."))
              : _buildPerfil(),
    );
  }

  /// 🟢 Construye la vista del perfil con los datos obtenidos
  Widget _buildPerfil() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle("Datos Personales"),
          _buildInfoTile(
            Icons.person,
            "Nombre",
            "${repartidor!['nombres']} ${repartidor!['apellidos']}",
          ),
          _buildInfoTile(
            Icons.badge,
            "Tipo Documento",
            repartidor!['tipo_documento'],
          ),
          _buildInfoTile(
            Icons.credit_card,
            "Nro Documento",
            repartidor!['nro_documento'],
          ),
          _buildInfoTile(Icons.phone, "Celular", repartidor!['celular']),
          _buildInfoTile(Icons.email, "Email", repartidor!['email']),
          _buildInfoTile(
            Icons.location_city,
            "Departamento",
            repartidor!['departamento'],
          ),

          _buildSectionTitle("Datos del Vehículo"),
          _buildInfoTile(Icons.motorcycle, "Vehículo", repartidor!['vehiculo']),

          _buildSectionTitle("Estado"),
          _buildInfoTile(
            Icons.verified,
            "Aprobado",
            repartidor!['aprobado'] ? "Sí" : "No",
            color: repartidor!['aprobado'] ? Colors.green : Colors.red,
          ),
          _buildInfoTile(
            Icons.access_time,
            "Fecha Creación",
            repartidor!['created_at'],
          ),
          _buildInfoTile(
            Icons.update,
            "Última Actualización",
            repartidor!['updated_at'],
          ),

          _buildSectionTitle("Usuario Asociado"),
          _buildInfoTile(Icons.account_circle, "Usuario", usuario!['usuario']),
          _buildInfoTile(Icons.person_outline, "Nombre", usuario!['name']),
          _buildInfoTile(Icons.email, "Email", usuario!['email']),
          _buildInfoTile(Icons.lock, "Rol", usuario!['role_id'].toString()),
        ],
      ),
    );
  }

  /// 🟢 Función para mostrar un título de sección
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.blueAccent,
        ),
      ),
    );
  }

  /// 🟢 Función para mostrar un elemento de información
  Widget _buildInfoTile(
    IconData icon,
    String title,
    String value, {
    Color? color,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.blueAccent),
      title: Text(title),
      subtitle: Text(value, style: TextStyle(color: color ?? Colors.black)),
    );
  }
}
