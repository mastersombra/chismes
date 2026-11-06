/// Niveles de severidad para logging
///
/// **Uso:**
/// - `debug`: Información detallada para debugging (solo en desarrollo)
/// - `info`: Información general de operaciones exitosas
/// - `warning`: Situaciones anormales pero no críticas
/// - `error`: Errores que afectan funcionalidad pero la app sigue funcionando
/// - `fatal`: Errores críticos que hacen crash o dejan la app inutilizable
enum LogLevel {
  debug('debug'),
  info('info'),
  warning('warning'),
  error('error'),
  fatal('fatal');

  final String value;
  const LogLevel(this.value);

  /// Convierte string a enum
  static LogLevel fromString(String value) {
    return LogLevel.values.firstWhere(
      (level) => level.value == value,
      orElse: () => LogLevel.info,
    );
  }

  /// Retorna true si este nivel debe persistirse en Supabase
  ///
  /// **Estrategia:**
  /// - `debug`, `info`: Solo consola (no persisten)
  /// - `warning`: Solo consola por ahora (mucho volumen)
  /// - `error`, `fatal`: Persisten en Supabase (críticos)
  bool get shouldPersist {
    return this == LogLevel.error || this == LogLevel.fatal;
  }

  /// Emoji para visualización en consola
  String get emoji {
    switch (this) {
      case LogLevel.debug:
        return '🔍';
      case LogLevel.info:
        return 'ℹ️';
      case LogLevel.warning:
        return '⚠️';
      case LogLevel.error:
        return '❌';
      case LogLevel.fatal:
        return '💥';
    }
  }
}
