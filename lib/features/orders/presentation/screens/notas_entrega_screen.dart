import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:truelovebiker/features/orders/controllers/viaje_controller.dart';

/// Abre la pantalla con las notas y fotos que otros repartidores dejaron sobre
/// el lugar de entrega.
void abrirNotasEntrega(ViajeController controller) {
  Get.to(() => NotasEntregaScreen(controller: controller));
}

// ───────────────────────── Lista de notas ─────────────────────────

class NotasEntregaScreen extends StatelessWidget {
  final ViajeController controller;
  const NotasEntregaScreen({super.key, required this.controller});

  void _verFoto(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                maxScale: 5,
                child: Image.network(url, fit: BoxFit.contain),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: SafeArea(
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 28),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmarBorrar(BuildContext context, int id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Borrar tu nota?'),
        content: const Text('Los demás repartidores ya no la verán.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Borrar')),
        ],
      ),
    );
    if (ok == true) await controller.borrarNotaEntrega(id);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notas de esta dirección'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.to(() => AgregarNotaScreen(controller: controller)),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_a_photo),
        label: const Text('Agregar nota'),
      ),
      body: RefreshIndicator(
        onRefresh: controller.cargarNotasEntrega,
        child: Obx(() {
          final notas = controller.notasEntrega;
          if (notas.isEmpty) {
            return ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const SizedBox(height: 60),
                Icon(Icons.home_work_outlined, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 12),
                const Text(
                  'Aún nadie dejó notas aquí',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Text(
                  'Sé el primero en ayudar a los demás repartidores: deja una nota o una foto de la casa.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
            itemCount: notas.length + 1,
            itemBuilder: (context, i) {
              if (i == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    'Lo que dejaron otros repartidores para llegar más rápido (${notas.length}).',
                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                  ),
                );
              }
              return _NotaCard(
                nota: notas[i - 1],
                onFoto: (url) => _verFoto(context, url),
                onBorrar: (id) => _confirmarBorrar(context, id),
              );
            },
          );
        }),
      ),
    );
  }
}

class _NotaCard extends StatelessWidget {
  final Map<String, dynamic> nota;
  final void Function(String url) onFoto;
  final void Function(int id) onBorrar;
  const _NotaCard({required this.nota, required this.onFoto, required this.onBorrar});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foto = nota['foto_url'] as String?;
    final texto = (nota['nota'] as String?)?.trim();
    final esMia = nota['es_mia'] == true;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest.withAlpha(90),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (foto != null)
              GestureDetector(
                onTap: () => onFoto(foto),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    foto,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    loadingBuilder: (_, child, progress) => progress == null
                        ? child
                        : const SizedBox(
                            height: 200,
                            child: Center(child: CircularProgressIndicator()),
                          ),
                    errorBuilder: (_, __, ___) => const SizedBox(
                      height: 80,
                      child: Center(child: Text('No se pudo cargar la foto')),
                    ),
                  ),
                ),
              ),
            if (texto != null && texto.isNotEmpty) ...[
              if (foto != null) const SizedBox(height: 8),
              Text(texto, style: const TextStyle(fontSize: 15)),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${esMia ? 'Tú' : nota['autor'] ?? 'Repartidor'} · ${nota['hace'] ?? ''}',
                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                  ),
                ),
                if (esMia)
                  InkWell(
                    onTap: () => onBorrar(nota['id'] as int),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.delete_outline, size: 20, color: Colors.grey),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────── Agregar nota ─────────────────────────

class AgregarNotaScreen extends StatefulWidget {
  final ViajeController controller;
  const AgregarNotaScreen({super.key, required this.controller});

  @override
  State<AgregarNotaScreen> createState() => _AgregarNotaScreenState();
}

class _AgregarNotaScreenState extends State<AgregarNotaScreen> {
  final _notaCtrl = TextEditingController();
  File? _foto;
  String? _error;

  ViajeController get c => widget.controller;

  @override
  void dispose() {
    _notaCtrl.dispose();
    super.dispose();
  }

  Future<void> _tomarFoto() async {
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.camera,
        maxWidth: 1280,
        maxHeight: 1280,
        imageQuality: 70,
      );
      if (picked != null) setState(() => _foto = File(picked.path));
    } catch (_) {
      setState(() => _error = 'No se pudo abrir la cámara. Revisa el permiso de cámara.');
    }
  }

  Future<void> _guardar() async {
    final nota = _notaCtrl.text.trim();
    if (nota.isEmpty && _foto == null) {
      setState(() => _error = 'Escribe una nota o toma una foto');
      return;
    }
    setState(() => _error = null);
    final error = await c.agregarNotaEntrega(nota: nota, foto: _foto);
    if (!mounted) return;
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    // Vuelve a la lista, que ya se actualizó con la nota nueva
    Get.back();
    Get.snackbar(
      'Guardado',
      'Ayudarás al siguiente repartidor 🙌',
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(12),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agregar nota o foto'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Cuéntales a los demás repartidores cómo llegar más rápido a esta dirección.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _notaCtrl,
              maxLines: 4,
              maxLength: 500,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'Ej: timbre malogrado, llamar al llegar. Casa de reja negra.',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 8),
            if (_foto != null)
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(_foto!, height: 220, width: double.infinity, fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.black54,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.close, size: 18, color: Colors.white),
                        onPressed: () => setState(() => _foto = null),
                      ),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _tomarFoto,
              icon: const Icon(Icons.photo_camera),
              label: Text(_foto == null ? 'Tomar foto de la casa' : 'Cambiar foto'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!, style: const TextStyle(color: Colors.redAccent)),
            ],
            const SizedBox(height: 14),
            Obx(
              () => ElevatedButton.icon(
                onPressed: c.guardandoNota.value ? null : _guardar,
                icon: c.guardandoNota.value
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check),
                label: const Text('Guardar para otros repartidores'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
