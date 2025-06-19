import 'package:flutter/material.dart';
import 'package:truelovebiker/services/api.dart';

class EditarDatosScreen extends StatefulWidget {
  final Map<String, dynamic> repartidor;
  const EditarDatosScreen({super.key, required this.repartidor});

  @override
  State<EditarDatosScreen> createState() => _EditarDatosScreenState();
}

class _EditarDatosScreenState extends State<EditarDatosScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _celularController;
  late TextEditingController _emailController;
  late TextEditingController _departamentoController;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _celularController = TextEditingController(text: widget.repartidor['celular'] ?? "");
    _emailController = TextEditingController(text: widget.repartidor['email'] ?? "");
    _departamentoController = TextEditingController(text: widget.repartidor['departamento'] ?? "");
  }

  @override
  void dispose() {
    _celularController.dispose();
    _emailController.dispose();
    _departamentoController.dispose();
    super.dispose();
  }

  void _guardar() async {
    if (_formKey.currentState!.validate()) {
      try {
        setState(() => isLoading = true);
        final updated = await ApiService.actualizarDatosRepartidor(
          id: widget.repartidor['id'],
          celular: _celularController.text.trim(),
          email: _emailController.text.trim(),
          departamento: _departamentoController.text.trim(),
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(updated['mensaje'] ?? "Datos actualizados.")),
        );
        Navigator.pop(context, updated['repartidor']);
      } catch (e) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Editar Datos Personales")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    TextFormField(
                      controller: _celularController,
                      decoration: const InputDecoration(
                        labelText: "Celular",
                        prefixIcon: Icon(Icons.phone),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Ingrese el celular";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: "Email",
                        prefixIcon: Icon(Icons.email),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Ingrese el email";
                        }
                        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                          return "Ingrese un email válido";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _departamentoController,
                      decoration: const InputDecoration(
                        labelText: "Departamento",
                        prefixIcon: Icon(Icons.location_city),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Ingrese el departamento";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.save),
                      label: const Text("Guardar cambios"),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _guardar,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}