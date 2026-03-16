import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:truelovebiker/features/profile/controllers/edit_bank_controller.dart';

class EditBankScreen extends GetView<EditBankController> {
  const EditBankScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Editar Cuenta Bancaria")),
      body: Obx(() => controller.isLoading.value
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: controller.formKey,
                child: ListView(
                  children: [
                    TextFormField(
                      controller: controller.titularController,
                      decoration: const InputDecoration(
                        labelText: "Titular",
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value == null || value.isEmpty ? "Ingrese el nombre del titular" : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: controller.dniController,
                      decoration: const InputDecoration(
                        labelText: "DNI",
                        prefixIcon: Icon(Icons.badge),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value == null || value.isEmpty ? "Ingrese el DNI" : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      initialValue: controller.selectedBancoId.value,
                      decoration: const InputDecoration(
                        labelText: "Banco",
                        prefixIcon: Icon(Icons.account_balance),
                        border: OutlineInputBorder(),
                      ),
                      items: controller.bancos.map((banco) => DropdownMenuItem<int>(
                        value: banco['id'],
                        child: Text(banco['nombre']),
                      )).toList(),
                      onChanged: (val) => controller.selectedBancoId.value = val,
                      validator: (val) => val == null ? "Seleccione un banco" : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      initialValue: controller.selectedTipoCuentaId.value,
                      decoration: const InputDecoration(
                        labelText: "Tipo de Cuenta",
                        prefixIcon: Icon(Icons.wallet),
                        border: OutlineInputBorder(),
                      ),
                      items: controller.tiposCuenta.map((tipo) => DropdownMenuItem<int>(
                        value: tipo['id'],
                        child: Text(tipo['nombre']),
                      )).toList(),
                      onChanged: (val) => controller.selectedTipoCuentaId.value = val,
                      validator: (val) => val == null ? "Seleccione un tipo de cuenta" : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: controller.numeroCuentaController,
                      decoration: const InputDecoration(
                        labelText: "Número de Cuenta",
                        prefixIcon: Icon(Icons.credit_card),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value == null || value.isEmpty ? "Ingrese el número de cuenta" : null,
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
                      onPressed: controller.save,
                    ),
                  ],
                ),
              ),
            )),
    );
  }
}
