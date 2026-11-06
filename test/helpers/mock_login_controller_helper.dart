import 'package:mockito/mockito.dart';
import 'package:chismes/features/auth/presentation/controllers/login_controller.dart';
import 'package:chismes/features/auth/presentation/state/auth_state.dart';
import 'package:chismes/core/di/injection_container.dart';

/// Mock simple de LoginController para tests
class MockLoginController extends Mock implements LoginController {}

/// Helper para registrar un mock de LoginController en GetIt.
///
/// Este helper es útil para tests que necesitan LoginController registrado
/// pero no requieren verificar sus llamadas.
///
/// Uso:
/// ```dart
/// setUp(() {
///   setupMockLoginController();
/// });
///
/// tearDown(() {
///   cleanupMockLoginController();
/// });
/// ```
void setupMockLoginController() {
  // Limpiar primero si ya existe
  if (getIt.isRegistered<LoginController>()) {
    getIt.unregister<LoginController>();
  }

  final mockController = MockLoginController();

  // Configurar comportamiento por defecto
  when(mockController.state).thenReturn(const AuthInitial());
  // Los métodos void como addListener y removeListener son manejados automáticamente por Mockito

  getIt.registerSingleton<LoginController>(mockController);
}

/// Limpia el mock de LoginController de GetIt.
///
/// Debe llamarse en tearDown para evitar contaminar otros tests.
Future<void> cleanupMockLoginController() async {
  if (getIt.isRegistered<LoginController>()) {
    await getIt.unregister<LoginController>();
  }
}
