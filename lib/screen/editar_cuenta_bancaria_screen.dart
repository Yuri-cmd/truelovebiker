import 'package:flutter/material.dart';
import 'package:truelovebiker/services/api.dart';

class EditarCuentaBancariaScreen extends StatefulWidget {
  final Map<String, dynamic> cuentaBancaria;
  const EditarCuentaBancariaScreen({super.key, required this.cuentaBancaria});

  @override
  State<EditarCuentaBancariaScreen> createState() =>
      _EditarCuentaBancariaScreenState();
}

class _EditarCuentaBancariaScreenState
    extends State<EditarCuentaBancariaScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titularController;
  late TextEditingController _dniController;
  late TextEditingController _numeroCuentaController;

  List<Map<String, dynamic>> bancos = [];
  List<Map<String, dynamic>> tiposCuenta = [];
  int? selectedBancoId;
  int? selectedTipoCuentaId;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _titularController = TextEditingController(
      text: widget.cuentaBancaria['titular'] ?? "",
    );
    _dniController = TextEditingController(
      text: widget.cuentaBancaria['dni'] ?? "",
    );
    _numeroCuentaController = TextEditingController(
      text: widget.cuentaBancaria['numero_cuenta'] ?? "",
    );
    selectedBancoId = widget.cuentaBancaria['banco']?['id'];
    selectedTipoCuentaId = widget.cuentaBancaria['tipo_cuenta']?['id'];
    _loadData();
  }

  Future<void> _loadData() async {
    final bancosList = await ApiService.fetchBancos();
    final tiposCuentaList = await ApiService.fetchTiposCuenta();
    setState(() {
      bancos = bancosList;
      tiposCuenta = tiposCuentaList;
      isLoading = false;
    });
  }

  @override
  void dispose() {
    _titularController.dispose();
    _dniController.dispose();
    _numeroCuentaController.dispose();
    super.dispose();
  }

  void _guardar() async {
    if (_formKey.currentState!.validate()) {
      try {
        setState(() => isLoading = true);
        final result = await ApiService.actualizarCuentaBancaria(
          id: widget.cuentaBancaria['id'],
          titular: _titularController.text.trim(),
          dni: _dniController.text.trim(),
          bancoId: selectedBancoId!,
          tipoCuentaId: selectedTipoCuentaId!,
          numeroCuenta: _numeroCuentaController.text.trim(),
          imagenCuenta: null, // O tu archivo si manejas imagen/pdf
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['mensaje'] ?? "Datos bancarios actualizados."),
          ),
        );
        Navigator.pop(context, result['cuenta_bancaria']);
      } catch (e) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Editar Cuenta Bancaria")),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    children: [
                      // Titular
                      TextFormField(
                        controller: _titularController,
                        decoration: const InputDecoration(
                          labelText: "Titular",
                          prefixIcon: Icon(Icons.person),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Ingrese el nombre del titular";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // DNI
                      TextFormField(
                        controller: _dniController,
                        decoration: const InputDecoration(
                          labelText: "DNI",
                          prefixIcon: Icon(Icons.badge),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Ingrese el DNI";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // Banco
                      DropdownButtonFormField<int>(
                        value: selectedBancoId,
                        decoration: const InputDecoration(
                          labelText: "Banco",
                          prefixIcon: Icon(Icons.account_balance),
                          border: OutlineInputBorder(),
                        ),
                        items:
                            bancos
                                .map(
                                  (banco) => DropdownMenuItem<int>(
                                    value: banco['id'],
                                    child: Text(banco['nombre']),
                                  ),
                                )
                                .toList(),
                        onChanged:
                            (val) => setState(() => selectedBancoId = val),
                        validator:
                            (val) => val == null ? "Seleccione un banco" : null,
                      ),
                      const SizedBox(height: 16),
                      // Tipo de cuenta
                      DropdownButtonFormField<int>(
                        value: selectedTipoCuentaId,
                        decoration: const InputDecoration(
                          labelText: "Tipo de Cuenta",
                          prefixIcon: Icon(Icons.wallet),
                          border: OutlineInputBorder(),
                        ),
                        items:
                            tiposCuenta
                                .map(
                                  (tipo) => DropdownMenuItem<int>(
                                    value: tipo['id'],
                                    child: Text(tipo['nombre']),
                                  ),
                                )
                                .toList(),
                        onChanged:
                            (val) => setState(() => selectedTipoCuentaId = val),
                        validator:
                            (val) =>
                                val == null
                                    ? "Seleccione un tipo de cuenta"
                                    : null,
                      ),
                      const SizedBox(height: 16),
                      // Número de cuenta
                      TextFormField(
                        controller: _numeroCuentaController,
                        decoration: const InputDecoration(
                          labelText: "Número de Cuenta",
                          prefixIcon: Icon(Icons.credit_card),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Ingrese el número de cuenta";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(50),
                        ),
                        icon: const Icon(Icons.save),
                        label: const Text("Guardar cambios"),
                        onPressed: _guardar,
                      ),
                    ],
                  ),
                ),
              ),
    );
  }
}
