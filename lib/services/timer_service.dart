import 'dart:async';

class TimerService {
  static final TimerService _instance = TimerService._internal();
  factory TimerService() => _instance;
  TimerService._internal();

  Timer? _globalTimer;
  final Map<int, DateTime> _pedidoStartTimes = {};
  final Map<int, Function()> _callbacks = {};

  void startTimerForPedido(int pedidoId, {required Function() onTick}) {
    // Guardar el tiempo de inicio si no existe
    _pedidoStartTimes.putIfAbsent(pedidoId, () => DateTime.now());

    // Registrar callback para este pedido (puede sobrescribir si es la misma card)
    _callbacks[pedidoId] = onTick;

    // Debug: imprimir estado
    print('TimerService: Iniciando timer para pedido $pedidoId');
    print('TimerService: Total callbacks activos: ${_callbacks.length}');
    print('TimerService: Tiempo de inicio: ${_pedidoStartTimes[pedidoId]}');

    // Iniciar timer global si no existe
    if (_globalTimer == null || !_globalTimer!.isActive) {
      print('TimerService: Creando nuevo timer global');
      _globalTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        // Ejecutar todos los callbacks registrados
        for (var entry in _callbacks.entries) {
          try {
            entry.value();
          } catch (e) {
            print(
              'TimerService: Error en callback para pedido ${entry.key}: $e',
            );
          }
        }
      });
    } else {
      print('TimerService: Reusando timer global existente');
    }
  }

  void stopTimerForPedido(int pedidoId) {
    _callbacks.remove(pedidoId);
    // NO remover _pedidoStartTimes para mantener persistencia
    // _pedidoStartTimes.remove(pedidoId); 
    
    // Si no hay más callbacks, cancelar el timer global
    if (_callbacks.isEmpty) {
      _globalTimer = null;
    }
  }

  DateTime? getStartTimeForPedido(int pedidoId) {
    return _pedidoStartTimes[pedidoId];
  }

  Duration getElapsedTimeForPedido(int pedidoId) {
    final startTime = _pedidoStartTimes[pedidoId];
    if (startTime == null) return Duration.zero;
    return DateTime.now().difference(startTime);
  }

  // Método para limpiar completamente un pedido (usar solo cuando el pedido termine)
  void clearPedido(int pedidoId) {
    _callbacks.remove(pedidoId);
    _pedidoStartTimes.remove(pedidoId);
    
    if (_callbacks.isEmpty) {
      _globalTimer?.cancel();
      _globalTimer = null;
    }
  }
  void dispose() {
    _globalTimer?.cancel();
    _callbacks.clear();
    _pedidoStartTimes.clear();
  }
}
