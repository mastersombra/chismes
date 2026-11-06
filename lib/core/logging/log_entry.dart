import 'log_level.dart';

/// Entrada de log estructurada
///
/// Contiene toda la información necesaria para diagnosticar un problema:
/// - Mensaje descriptivo
/// - Nivel de severidad
/// - Error y stack trace (si aplica)
/// - Contexto adicional (operación, IDs, datos)
/// - Device info
/// - User ID
class LogEntry {
  final LogLevel level;
  final String message;
  final String? errorType;
  final Object? error;
  final StackTrace? stackTrace;
  final Map<String, dynamic>? context;
  final String? userId;
  final Map<String, dynamic>? deviceInfo;
  final DateTime timestamp;

  LogEntry({
    required this.level,
    required this.message,
    this.errorType,
    this.error,
    this.stackTrace,
    this.context,
    this.userId,
    this.deviceInfo,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Serializa para Supabase
  Map<String, dynamic> toJson() {
    return {
      'level': level.value,
      'message': message,
      'error_type': errorType ?? error?.runtimeType.toString(),
      'stack_trace': stackTrace?.toString(),
      'user_id': userId,
      'device_info': deviceInfo,
      'context': context,
      'created_at': timestamp.toIso8601String(),
    };
  }

  /// Crea copia con nuevos valores
  LogEntry copyWith({
    LogLevel? level,
    String? message,
    String? errorType,
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
    String? userId,
    Map<String, dynamic>? deviceInfo,
    DateTime? timestamp,
  }) {
    return LogEntry(
      level: level ?? this.level,
      message: message ?? this.message,
      errorType: errorType ?? this.errorType,
      error: error ?? this.error,
      stackTrace: stackTrace ?? this.stackTrace,
      context: context ?? this.context,
      userId: userId ?? this.userId,
      deviceInfo: deviceInfo ?? this.deviceInfo,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.write('${level.emoji} [${level.value.toUpperCase()}] $message');

    if (errorType != null) {
      buffer.write(' | Type: $errorType');
    }

    if (error != null) {
      buffer.write('\n   Error: $error');
    }

    if (context != null && context!.isNotEmpty) {
      buffer.write('\n   Context: $context');
    }

    if (stackTrace != null) {
      buffer.write('\n   Stack:\n$stackTrace');
    }

    return buffer.toString();
  }
}
