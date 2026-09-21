import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Botones de contacto (llamar + WhatsApp) para el cliente de un pedido.
///
/// El backend solo envía `celularWhatsapp` cuando es distinto al `celular`
/// normal (si es igual, llega null); por eso siempre hay que usar
/// `celularWhatsapp ?? celular` como número de WhatsApp.
class ContactButtons extends StatelessWidget {
  final String? celular;
  final String? celularWhatsapp;
  final double size;
  final Color? color;
  final Color? backgroundColor;

  const ContactButtons({
    super.key,
    required this.celular,
    required this.celularWhatsapp,
    this.size = 20,
    this.color,
    this.backgroundColor,
  });

  String? get _numeroWhatsapp => celularWhatsapp ?? celular;

  // No se usa canLaunchUrl() como guardia: en Android 11+ requiere declarar
  // el esquema en <queries> del manifest, y si ese paso falla o el build no
  // se recompiló, canLaunchUrl devuelve false y el botón queda mudo sin
  // ningún error visible. Se intenta abrir directamente y solo se atrapa el
  // error, igual que el resto de la app (ver _launchUrl en viaje_screen.dart).
  Future<void> _llamar() async {
    if (celular == null || celular!.isEmpty) return;
    try {
      await launchUrl(
        Uri.parse('tel:$celular'),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      // Sin app de teléfono disponible; no hay más que hacer aquí.
    }
  }

  Future<void> _abrirWhatsapp() async {
    final numero = _numeroWhatsapp;
    if (numero == null || numero.isEmpty) return;
    // Normaliza a solo dígitos y antepone el código de país si no lo tiene.
    final digits = numero.replaceAll(RegExp(r'[^0-9]'), '');
    final numeroConPrefijo = digits.startsWith('51') ? digits : '51$digits';
    try {
      await launchUrl(
        Uri.parse('https://wa.me/$numeroConPrefijo'),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      // WhatsApp no instalado o sin navegador disponible.
    }
  }

  Widget _buildButton({
    required IconData icon,
    required VoidCallback onTap,
    required Color iconColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      child: Container(
        width: size * 2,
        height: size * 2,
        decoration: BoxDecoration(
          color: backgroundColor ?? iconColor.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color ?? iconColor, size: size),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildButton(icon: Icons.phone, onTap: _llamar, iconColor: Colors.blue),
        const SizedBox(width: 8),
        _buildButton(
          icon:
              Icons
                  .chat, // ícono estilo WhatsApp sin depender de un paquete de íconos de marca
          onTap: _abrirWhatsapp,
          iconColor: Colors.green,
        ),
      ],
    );
  }
}
