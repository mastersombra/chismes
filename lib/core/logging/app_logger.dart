import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart' as logger_pkg;

import 'log_entry.dart';
import 'log_level.dart';
import 'remote_logger.dart';
import 'device_info_provider.dart';

/// Logger principal de la aplicación
///
/// **Características:**
/// - Logs estructurados con niveles (debug, info, warning, error, fatal)
/// - Logs en consola en desarrollo (con colores y formato)
/// - Persistencia automática de errores en Supabase (producción)
/// - Context adicional (device info, user ID, operation)
/// - Fire-and-forget: no bloquea la app
///
/// **Uso:**
/// ```dart
/// final logger = getIt<AppLogger>();
///
/// // Logs simples
/// logger.d('Cache cargado exitosamente');
/// logger.i('Usuario creó un gossip');
/// logger.w('Cache versión incorrecta, limpiando');
///
/// // Logs con error
/// logger.e('Error creando gossip', error: e, stackTrace: st);
/// logger.f('App crash crítico', error: e, stackTrace: st);
///
/// // Logs con contexto
/// logger.i('Gossip creado', context: {
///   'gossipId': '123',
///   'cityId': 'MED',
///   'hasImage': true,
/// });
/// ```
@singleton
class AppLogger {
  final RemoteLogger _remoteLogger;
  final DeviceInfoProvider _deviceInfoProvider;
  final logger_pkg.Logger _consoleLogger;

  String? _currentUserId;

  AppLogger(
    this._remoteLogger,
    this._deviceInfoProvider,
  ) : _consoleLogger = logger_pkg.Logger(
          printer: logger_pkg.PrettyPrinter(
            methodCount: 0, // No mostrar call stack en cada log
            errorMethodCount: 8, // Stack trace solo para errores
            lineLength: 120,
            colors: true,
            printEmojis: true,
            dateTimeFormat: logger_pkg.DateTimeFormat.onlyTimeAndSinceStart,
          ),
          level: kDebugMode ? logger_pkg.Level.debug : logger_pkg.Level.info,
        );

  /// Establece el user ID actual (después de login)
  void setUserId(String? userId) {
    _currentUserId = userId;
  }

  /// Log debug (solo desarrollo)
  void d(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) {
    _log(
      LogLevel.debug,
      message,
      error: error,
      stackTrace: stackTrace,
      context: context,
    );
  }

  /// Log info (operaciones normales exitosas)
  void i(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) {
    _log(
      LogLevel.info,
      message,
      error: error,
      stackTrace: stackTrace,
      context: context,
    );
  }

  /// Log warning (situaciones anormales pero no críticas)
  void w(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) {
    _log(
      LogLevel.warning,
      message,
      error: error,
      stackTrace: stackTrace,
      context: context,
    );
  }

  /// Log error (errores que afectan funcionalidad)
  void e(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) {
    _log(
      LogLevel.error,
      message,
      error: error,
      stackTrace: stackTrace,
      context: context,
    );
  }

  /// Log fatal (errores críticos/crashes)
  void f(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) {
    _log(
      LogLevel.fatal,
      message,
      error: error,
      stackTrace: stackTrace,
      context: context,
    );
  }

  /// Log interno
  Future<void> _log(
    LogLevel level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) async {
    // 1. Log en consola (siempre, para desarrollo)
    _logToConsole(level, message, error, stackTrace);

    // 2. Crear entry estructurada
    final entry = LogEntry(
      level: level,
      message: message,
      error: error,
      stackTrace: stackTrace,
      context: context,
      userId: _currentUserId,
      deviceInfo: null, // Se agrega después
    );

    // 3. Persistir en remoto si es error/fatal (fire-and-forget)
    if (level.shouldPersist) {
      _persistRemote(entry).ignore();
    }
  }

  /// Log en consola usando logger package
  void _logToConsole(
    LogLevel level,
    String message,
    Object? error,
    StackTrace? stackTrace,
  ) {
    switch (level) {
      case LogLevel.debug:
        _consoleLogger.d(message, error: error, stackTrace: stackTrace);
        break;
      case LogLevel.info:
        _consoleLogger.i(message, error: error, stackTrace: stackTrace);
        break;
      case LogLevel.warning:
        _consoleLogger.w(message, error: error, stackTrace: stackTrace);
        break;
      case LogLevel.error:
        _consoleLogger.e(message, error: error, stackTrace: stackTrace);
        break;
      case LogLevel.fatal:
        _consoleLogger.f(message, error: error, stackTrace: stackTrace);
        break;
    }
  }

  /// Persiste en remoto con device info
  Future<void> _persistRemote(LogEntry entry) async {
    try {
      // Obtener device info
      final deviceInfo = await _deviceInfoProvider.getDeviceInfo();

      // Crear entry con device info
      final enrichedEntry = entry.copyWith(deviceInfo: deviceInfo);

      // Persistir (fire-and-forget)
      await _remoteLogger.log(enrichedEntry);
    } catch (error) {
      // Si falla el logging remoto, solo mostrar en consola
      // NO propagar el error (el logging no debe romper la app)
      debugPrint('⚠️ Error en remote logging: $error');
    }
  }

  /// Cierra el logger (llamar al cerrar la app)
  void close() {
    _consoleLogger.close();
  }
}
