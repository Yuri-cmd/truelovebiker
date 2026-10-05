import 'package:shared_preferences/shared_preferences.dart';

/// Recuerda hasta qué mensaje del chat de cada pedido ya vio el repartidor, para
/// calcular cuántos mensajes nuevos (sin leer) hay.
class ChatVistoStore {
  ChatVistoStore._();

  static String _clave(int pedidoId) => 'chat_ultimo_visto_$pedidoId';

  static Future<int> ultimoVisto(int pedidoId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_clave(pedidoId)) ?? 0;
    } catch (_) {
      return 0;
    }
  }

  static Future<void> marcarVisto(int pedidoId, int ultimoMensajeId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final actual = prefs.getInt(_clave(pedidoId)) ?? 0;
      if (ultimoMensajeId > actual) {
        await prefs.setInt(_clave(pedidoId), ultimoMensajeId);
      }
    } catch (_) {}
  }

  /// Id más alto de la lista de mensajes (0 si no hay).
  static int idMasAlto(List<Map<String, dynamic>> mensajes) {
    var maximo = 0;
    for (final m in mensajes) {
      final id = int.tryParse(m['id']?.toString() ?? '') ?? 0;
      if (id > maximo) maximo = id;
    }
    return maximo;
  }
}
