import 'package:mockito/mockito.dart';
import 'package:chismes/core/logging/app_logger.dart';
import 'package:chismes/core/di/injection_container.dart';

/// Mock simple de AppLogger para tests
class MockAppLogger extends Mock implements AppLogger {}

/// Helper para registrar un mock de AppLogger en GetIt.
///
/// Este helper es útil para tests que necesitan AppLogger registrado
/// pero no requieren verificar sus llamadas.
///
/// Uso:
/// ```dart
/// setUp(() {
///   setupMockAppLogger();
/// });
///
/// tearDown(() {
///   cleanupMockAppLogger();
/// });
/// ```
void setupMockAppLogger() {
  if (!getIt.isRegistered<AppLogger>()) {
    final mockLogger = MockAppLogger();

    // No es necesario configurar stubs explícitamente.
    // Mockito ya maneja los métodos void automáticamente.
    // Los métodos simplemente no harán nada cuando se llamen.

    getIt.registerSingleton<AppLogger>(mockLogger);
  }
}

/// Limpia el mock de AppLogger de GetIt.
///
/// Debe llamarse en tearDown para evitar contaminar otros tests.
Future<void> cleanupMockAppLogger() async {
  if (getIt.isRegistered<AppLogger>()) {
    await getIt.unregister<AppLogger>();
  }
}
