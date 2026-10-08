import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:truelovebiker/core/storage/secure_storage.dart';
import 'package:truelovebiker/data/services/firebase_api.dart';
import 'package:truelovebiker/data/services/misc_service.dart';

enum _Estado { cargando, ok, aviso, error }

class _Chequeo {
  final String titulo;
  final String detalle;
  final _Estado estado;
  final String? accion;
  final VoidCallback? onAccion;

  const _Chequeo(this.titulo, this.detalle, this.estado, {this.accion, this.onAccion});
}

/// Pantalla para que el repartidor compruebe si su teléfono puede recibir los avisos de pedidos:
/// permisos, ahorro de batería, token de notificaciones y una prueba real de envío.
class NotificacionesDiagnosticoScreen extends StatefulWidget {
  const NotificacionesDiagnosticoScreen({super.key});

  @override
  State<NotificacionesDiagnosticoScreen> createState() => _NotificacionesDiagnosticoScreenState();
}

class _NotificacionesDiagnosticoScreenState extends State<NotificacionesDiagnosticoScreen> with WidgetsBindingObserver {
  final _misc = MiscService();

  List<_Chequeo> _chequeos = [];
  bool _revisando = true;
  String _version = '';

  // Prueba real
  bool _probando = false;
  _Estado? _estadoPrueba;
  String? _mensajePrueba;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _revisar();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Al volver de los ajustes del teléfono se vuelve a revisar todo.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_revisando && !_probando) _revisar();
  }

  Future<int?> _idRepartidor() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('id_biker') ?? await SecureStorage.getBikerId();
  }

  Future<void> _revisar() async {
    setState(() => _revisando = true);
    final lista = <_Chequeo>[];

    try {
      final info = await PackageInfo.fromPlatform();
      _version = '${info.version} (${info.buildNumber})';
    } catch (_) {}

    // 1) Permiso de notificaciones
    var permisoOk = false;
    try {
      final ajustes = await FirebaseMessaging.instance.getNotificationSettings();
      permisoOk = ajustes.authorizationStatus == AuthorizationStatus.authorized ||
          ajustes.authorizationStatus == AuthorizationStatus.provisional;
      if (Platform.isAndroid) {
        final plugin = FlutterLocalNotificationsPlugin()
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        final habilitadas = await plugin?.areNotificationsEnabled();
        if (habilitadas == false) permisoOk = false;
      }
    } catch (e) {
      log('⚠️ diagnóstico: permiso: $e');
    }
    lista.add(permisoOk
        ? const _Chequeo('Permiso de notificaciones', 'Activado', _Estado.ok)
        : _Chequeo(
            'Permiso de notificaciones',
            'Las notificaciones de TrueLove están desactivadas. Sin esto no verás los pedidos.',
            _Estado.error,
            accion: 'Abrir ajustes',
            onAccion: openAppSettings,
          ));

    // 2) Ahorro de batería (solo Android)
    if (Platform.isAndroid) {
      var sinRestriccion = false;
      try {
        sinRestriccion = await Permission.ignoreBatteryOptimizations.isGranted;
      } catch (_) {}
      lista.add(sinRestriccion
          ? const _Chequeo('Ahorro de batería', 'TrueLove no está restringida', _Estado.ok)
          : _Chequeo(
              'Ahorro de batería',
              'El teléfono puede cerrar la app y dejar de mostrar pedidos. En Ajustes → Batería, elige "Sin restricciones" para TrueLove.',
              _Estado.aviso,
              accion: 'Abrir ajustes',
              onAccion: openAppSettings,
            ));
    }

    // 3) Token del teléfono
    String? token;
    try {
      token = await FirebaseMessaging.instance.getToken();
    } catch (e) {
      log('⚠️ diagnóstico: token: $e');
    }
    final tieneToken = token != null && token.isNotEmpty;
    lista.add(tieneToken
        ? const _Chequeo('Identificador del teléfono', 'El teléfono tiene su identificador de notificaciones', _Estado.ok)
        : const _Chequeo(
            'Identificador del teléfono',
            'No se pudo obtener. Revisa tu conexión a internet y vuelve a intentarlo.',
            _Estado.error,
          ));

    // 4) Lo que sabe el servidor
    final id = await _idRepartidor();
    if (tieneToken && id != null) {
      try {
        // Se vuelve a registrar el token para que el servidor tenga el de hoy
        await FirebaseApi().sincronizarToken('diagnostico');
        final res = await _misc.diagnosticoNotificaciones(id, token);
        final d = Map<String, dynamic>.from(res.data);
        final enServidor = d['token_en_servidor'] == true;
        final coincide = d['token_coincide'] == true;
        final enviados = d['enviados_7d'] ?? 0;
        final recibidos = d['recibidos_7d'] ?? 0;

        lista.add(enServidor && coincide
            ? const _Chequeo('Registro en el servidor', 'El servidor te conoce y envía a este teléfono', _Estado.ok)
            : _Chequeo(
                'Registro en el servidor',
                enServidor
                    ? 'El servidor tiene otro teléfono registrado. Cierra sesión y vuelve a entrar.'
                    : 'El servidor no tiene tu teléfono registrado. Cierra sesión y vuelve a entrar.',
                _Estado.error,
              ));

        final ultimo = d['ultimo_recibido']?.toString();
        final fechaUltimo = ultimo != null
            ? ' Último confirmado: ${ultimo.split('.').first.replaceFirst('T', ' ')}.'
            : '';
        final String textoAvisos;
        if (enviados == 0) {
          textoAvisos = 'Todavía no te han enviado avisos.';
        } else if (Platform.isIOS) {
          textoAvisos = 'Te enviamos $enviados avisos. En iPhone el sistema los muestra sin que la app los confirme.';
        } else {
          textoAvisos = 'Te enviamos $enviados y el teléfono confirmó $recibidos.$fechaUltimo';
        }
        lista.add(_Chequeo(
          'Avisos de los últimos 7 días',
          textoAvisos,
          // En iPhone el sistema muestra el aviso sin abrir la app, así que la app casi nunca
          // confirma: ahí un 0 no significa que no llegue (para eso está la prueba real).
          (enviados > 0 && recibidos == 0 && !Platform.isIOS) ? _Estado.aviso : _Estado.ok,
        ));
      } catch (e) {
        log('⚠️ diagnóstico: servidor: $e');
        lista.add(const _Chequeo('Registro en el servidor', 'No se pudo consultar. Revisa tu conexión.', _Estado.aviso));
      }
    }

    if (!mounted) return;
    setState(() {
      _chequeos = lista;
      _revisando = false;
    });
  }

  /// Manda un aviso real y espera a que llegue a este teléfono.
  Future<void> _probar() async {
    final id = await _idRepartidor();
    if (id == null) return;

    setState(() {
      _probando = true;
      _estadoPrueba = _Estado.cargando;
      _mensajePrueba = 'Enviando el aviso de prueba…';
    });

    final llego = Completer<void>();
    final suscripcion = FirebaseMessaging.onMessage.listen((m) {
      if (m.data['type'] == 'diagnostico' && !llego.isCompleted) llego.complete();
    });
    final inicio = DateTime.now();

    try {
      await FirebaseApi().sincronizarToken('diagnostico');
      final res = await _misc.probarNotificacion(id);
      final resultado = res.data['resultado']?.toString();

      switch (resultado) {
        case 'sin_token':
          _resultadoPrueba(_Estado.error, 'El servidor no tiene tu teléfono registrado. Cierra sesión y vuelve a entrar.');
        case 'token_invalido':
          _resultadoPrueba(_Estado.error, 'Google ya no reconoce este teléfono. Cierra sesión y vuelve a entrar.');
        case 'enviado':
          await llego.future.timeout(const Duration(seconds: 20));
          final seg = DateTime.now().difference(inicio).inSeconds;
          _resultadoPrueba(_Estado.ok, '¡Llegó! El aviso tardó $seg s. Tu teléfono recibe las notificaciones.');
        default:
          _resultadoPrueba(_Estado.error, 'No se pudo enviar el aviso de prueba. Inténtalo de nuevo.');
      }
    } on TimeoutException {
      _resultadoPrueba(
        _Estado.aviso,
        'El aviso salió pero no llegó en 20 segundos. Revisa el ahorro de batería y que tengas internet, y vuelve a probar.',
      );
    } catch (e) {
      log('⚠️ diagnóstico: prueba: $e');
      _resultadoPrueba(_Estado.error, 'No se pudo hacer la prueba. Revisa tu conexión.');
    } finally {
      await suscripcion.cancel();
    }
  }

  void _resultadoPrueba(_Estado estado, String mensaje) {
    if (!mounted) return;
    setState(() {
      _probando = false;
      _estadoPrueba = estado;
      _mensajePrueba = mensaje;
    });
  }

  Color _color(_Estado e) {
    switch (e) {
      case _Estado.ok:
        return const Color(0xFF16A34A);
      case _Estado.aviso:
        return const Color(0xFFD97706);
      case _Estado.error:
        return Colors.red.shade700;
      case _Estado.cargando:
        return Colors.grey;
    }
  }

  IconData _icono(_Estado e) {
    switch (e) {
      case _Estado.ok:
        return Icons.check_circle_rounded;
      case _Estado.aviso:
        return Icons.warning_amber_rounded;
      case _Estado.error:
        return Icons.cancel_rounded;
      case _Estado.cargando:
        return Icons.hourglass_top_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hayErrores = _chequeos.any((c) => c.estado == _Estado.error);
    final hayAvisos = _chequeos.any((c) => c.estado == _Estado.aviso);

    return Scaffold(
      appBar: AppBar(title: const Text('Diagnóstico de notificaciones')),
      body: RefreshIndicator(
        onRefresh: _revisar,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_revisando)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              _banner(hayErrores, hayAvisos),
              const SizedBox(height: 16),
              for (final c in _chequeos) _tarjeta(c, scheme),
              const SizedBox(height: 8),
              _tarjetaPrueba(scheme),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  'Versión de la app: $_version',
                  style: TextStyle(color: scheme.onSurface.withValues(alpha: 0.5), fontSize: 12),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _banner(bool hayErrores, bool hayAvisos) {
    final estado = hayErrores ? _Estado.error : (hayAvisos ? _Estado.aviso : _Estado.ok);
    final texto = hayErrores
        ? 'Tu teléfono NO puede recibir pedidos todavía. Corrige lo marcado en rojo.'
        : hayAvisos
            ? 'Casi listo: hay cosas que pueden hacer que pierdas pedidos.'
            : 'Tu teléfono está listo para recibir pedidos.';
    final color = _color(estado);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Icon(_icono(estado), color: color, size: 32),
          const SizedBox(width: 12),
          Expanded(child: Text(texto, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 15))),
        ],
      ),
    );
  }

  Widget _tarjeta(_Chequeo c, ColorScheme scheme) {
    final color = _color(c.estado);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(_icono(c.estado), color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c.titulo, style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(c.detalle, style: TextStyle(color: scheme.onSurface.withValues(alpha: 0.7), fontSize: 13)),
                  if (c.accion != null)
                    TextButton(
                      onPressed: c.onAccion,
                      style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 32)),
                      child: Text(c.accion!),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tarjetaPrueba(ColorScheme scheme) {
    final estado = _estadoPrueba;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Prueba real', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(
              'Te mandamos un aviso ahora mismo y comprobamos que llegue a este teléfono.',
              style: TextStyle(color: scheme.onSurface.withValues(alpha: 0.7), fontSize: 13),
            ),
            if (estado != null) ...[
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (estado == _Estado.cargando)
                    const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  else
                    Icon(_icono(estado), color: _color(estado), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _mensajePrueba ?? '',
                      style: TextStyle(color: _color(estado), fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _probando ? null : _probar,
                icon: const Icon(Icons.notifications_active_rounded),
                label: Text(_probando ? 'Probando…' : 'Enviar aviso de prueba'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
