import 'dart:async';
import 'package:flutter/foundation.dart';

/// Configuración global de tests.
///
/// Este archivo se ejecuta automáticamente antes de TODOS los tests.
/// No necesitas importarlo ni llamarlo manualmente.
///
/// Referencia: https://api.flutter.dev/flutter/flutter_test/flutter_test-library.html

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  // Silenciar debugPrint para evitar output durante tests
  debugPrint = (String? message, {int? wrapWidth}) {
    // No hacer nada - silenciar completamente durante tests
  };

  // Ejecutar los tests
  await testMain();
}
