import 'package:flutter/foundation.dart';

/// Configuración global para silenciar output durante tests.
///
/// Este helper silencia debugPrint y otros outputs que contaminan
/// la salida de tests.
///
/// Uso en setUpAll():
/// ```dart
/// setUpAll(() {
///   silenceDebugPrint();
/// });
/// ```

/// Guarda la función original de debugPrint
DebugPrintCallback? _originalDebugPrint;

/// Silencia debugPrint globalmente para evitar output durante tests.
///
/// Esto afecta a:
/// - debugPrint() directos en el código
/// - Logs que usan debugPrint internamente
/// - Error handlers que imprimen con debugPrint
void silenceDebugPrint() {
  _originalDebugPrint = debugPrint;
  debugPrint = (String? message, {int? wrapWidth}) {
    // No hacer nada - silenciar completamente
  };
}

/// Restaura debugPrint a su comportamiento original.
///
/// Debe llamarse en tearDownAll() para no afectar otros tests.
void restoreDebugPrint() {
  if (_originalDebugPrint != null) {
    debugPrint = _originalDebugPrint!;
  }
}
