import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class TimerService {
  static final TimerService _instance = TimerService._internal();
  factory TimerService() => _instance;
  TimerService._internal();

  Timer? _globalTimer;
  final Map<int, DateTime> _pedidoStartTimes = {};
  final Map<int, List<Function()>> _callbacks = {};
  bool _isInitialized = false;

  // ✨ Método público para inicializar en el main
  Future<void> initializeOnAppStart() async {
    await _initializeIfNeeded();
  }

  // Cargar tiempos de inicio desde SharedPreferences
  Future<void> _initializeIfNeeded() async {
    if (_isInitialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedTimesJson = prefs.getString('pedido_start_times');

      if (savedTimesJson != null) {
        final Map<String, dynamic> savedTimes = jsonDecode(savedTimesJson);

        for (var entry in savedTimes.entries) {
          final pedidoId = int.tryParse(entry.key);
          final timeString = entry.value as String?;

          if (pedidoId != null && timeString != null) {
            try {
              final startTime = DateTime.parse(timeString);
              _pedidoStartTimes[pedidoId] = startTime;
              print(
                'TimerService: Cargado tiempo para pedido $pedidoId: $startTime',
              );
            } catch (e) {
              print(
                'TimerService: Error parseando tiempo para pedido $pedidoId: $e',
              );
            }
          }
        }

        print(
          'TimerService: Cargados ${_pedidoStartTimes.length} tiempos de SharedPreferences',
        );
      } else {
        print('TimerService: No hay tiempos guardados en SharedPreferences');
      }
    } catch (e) {
      print('TimerService: Error cargando tiempos desde SharedPreferences: $e');
    }

    _isInitialized = true;
  }

  // Guardar tiempos de inicio en SharedPreferences
  Future<void> _saveStartTimes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final Map<String, String> timesToSave = {};

      for (var entry in _pedidoStartTimes.entries) {
        timesToSave[entry.key.toString()] = entry.value.toIso8601String();
      }

      await prefs.setString('pedido_start_times', jsonEncode(timesToSave));
      print(
        'TimerService: Guardados ${timesToSave.length} tiempos en SharedPreferences',
      );
    } catch (e) {
      print('TimerService: Error guardando tiempos en SharedPreferences: $e');
    }
  }

  void startTimerForPedido(int pedidoId, {required Function() onTick}) async {
    // Inicializar si es necesario
    await _initializeIfNeeded();

    // Guardar el tiempo de inicio si no existe
    if (!_pedidoStartTimes.containsKey(pedidoId)) {
      _pedidoStartTimes[pedidoId] = DateTime.now();
      // Guardar inmediatamente en SharedPreferences
      await _saveStartTimes();
    }

    // Registrar callback para este pedido (permitir múltiples listeners)
    final list = _callbacks.putIfAbsent(pedidoId, () => <Function()>[]);
    // Evitar duplicados por referencia
    if (!list.any((cb) => cb == onTick)) {
      list.add(onTick);
    }

    // Debug: imprimir estado
    final totalCallbacks = _callbacks.values.fold<int>(0, (s, l) => s + l.length);
    print('TimerService: Iniciando timer para pedido $pedidoId');
    print(
      'TimerService: Callbacks registrados - pedidoIds: ${_callbacks.length}, totalCallbacks: $totalCallbacks',
    );
    print('TimerService: Tiempo de inicio: ${_pedidoStartTimes[pedidoId]}');

    // Iniciar timer global si no existe
    if (_globalTimer == null || !_globalTimer!.isActive) {
      print('TimerService: Creando nuevo timer global');
      _globalTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        // Ejecutar todos los callbacks registrados
        int totalCallbacks = 0;
        for (var entry in _callbacks.entries) {
          totalCallbacks += entry.value.length;
        }

        if (totalCallbacks > 50) {
          print('TimerService: WARNING - total callbacks = $totalCallbacks');
        }

        for (var entry in _callbacks.entries) {
          for (var cb in entry.value) {
            try {
              cb();
            } catch (e) {
              print(
                'TimerService: Error en callback para pedido ${entry.key}: $e',
              );
            }
          }
        }
      });
    } else {
      print('TimerService: Reusando timer global existente');
    }
  }

  /// Quita todos los callbacks registrados para un pedido.
  /// Si se pasa [callbackToRemove], sólo remueve esa referencia concreta.
  void stopTimerForPedido(int pedidoId, {Function()? callbackToRemove}) {
    if (callbackToRemove == null) {
      _callbacks.remove(pedidoId);
    } else {
      final list = _callbacks[pedidoId];
      if (list != null) {
        list.removeWhere((cb) => cb == callbackToRemove);
        if (list.isEmpty) _callbacks.remove(pedidoId);
      }
    }

    // NO remover _pedidoStartTimes para mantener persistencia
    // Los tiempos se mantienen hasta que se complete o cancele el pedido

    // Si no hay más callbacks, cancelar el timer global
    if (_callbacks.isEmpty) {
      _globalTimer?.cancel();
      _globalTimer = null;
    }
  }

  /// Remueve un callback específico para un pedido (conveniencia)
  void removeCallbackForPedido(int pedidoId, Function() callback) {
    stopTimerForPedido(pedidoId, callbackToRemove: callback);
  }

  bool isTimerRunningForPedido(int pedidoId) {
    return _callbacks.containsKey(pedidoId) && _callbacks[pedidoId]!.isNotEmpty;
  }

  Future<DateTime?> getStartTimeForPedido(int pedidoId) async {
    // Asegurar que los datos estén cargados
    await _initializeIfNeeded();
    return _pedidoStartTimes[pedidoId];
  }

  // Método síncrono para compatibilidad (deprecado - usar la versión async)
  DateTime? getStartTimeForPedidoSync(int pedidoId) {
    return _pedidoStartTimes[pedidoId];
  }

  Future<Duration> getElapsedTimeForPedido(int pedidoId) async {
    final startTime = await getStartTimeForPedido(pedidoId);
    if (startTime == null) return Duration.zero;
    return DateTime.now().difference(startTime);
  }

  // Método síncrono para compatibilidad (deprecado - usar la versión async)
  Duration getElapsedTimeForPedidoSync(int pedidoId) {
    final startTime = _pedidoStartTimes[pedidoId];
    if (startTime == null) return Duration.zero;
    return DateTime.now().difference(startTime);
  }

  // Método para limpiar completamente un pedido (usar solo cuando el pedido termine)
  Future<void> clearPedido(int pedidoId) async {
    _callbacks.remove(pedidoId);
    _pedidoStartTimes.remove(pedidoId);

    // Guardar cambios en SharedPreferences
    await _saveStartTimes();

    if (_callbacks.isEmpty) {
      _globalTimer?.cancel();
      _globalTimer = null;
    }
  }

  void dispose() async {
    _globalTimer?.cancel();
    _callbacks.clear();

    // Guardar tiempos antes de limpiar (para casos de cierre de app)
    await _saveStartTimes();

    // Solo limpiar memoria, no SharedPreferences
    _pedidoStartTimes.clear();
    _isInitialized = false;
  }

  // Método para limpiar todos los pedidos completados de SharedPreferences
  Future<void> clearAllCompletedPedidos(List<int> activePedidoIds) async {
    try {
      await _initializeIfNeeded();

      // Mantener solo los pedidos activos
      final currentPedidos = Set<int>.from(_pedidoStartTimes.keys);
      final now = DateTime.now();

      for (int pedidoId in currentPedidos) {
        if (!activePedidoIds.contains(pedidoId)) {
          final startTime = _pedidoStartTimes[pedidoId];
          // Solo eliminar timestamps muy viejos (ej. > 24h) para evitar resets
          if (startTime == null || now.difference(startTime) > Duration(hours: 24)) {
            _pedidoStartTimes.remove(pedidoId);
          }
        }
      }

      await _saveStartTimes();
      print(
        'TimerService: Limpieza completada, manteniendo ${_pedidoStartTimes.length} pedidos activos',
      );
    } catch (e) {
      print('TimerService: Error en limpieza de pedidos completados: $e');
    }
  }
}
