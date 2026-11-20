import 'package:flutter/material.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/logging/logging.dart';
import '../../../../core/result/result.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../home/presentation/screens/main_navigation_screen.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../screens/login_screen.dart';

/// Auth Gate - Guard de autenticación reactivo
///
/// Escucha el stream `authStateChanges` de Supabase y navega automáticamente:
/// - Si hay usuario autenticado → MainNavigationScreen
/// - Si no hay usuario → LoginScreen
///
/// Este widget se encarga de:
/// 1. Restaurar sesión persistida (Supabase lo hace automáticamente)
/// 2. Reaccionar a cambios de autenticación (login, logout, token refresh)
/// 3. Navegar sin mostrar login innecesariamente
///
/// Comportamiento:
/// - Al abrir la app → restaura sesión si existe
/// - Al hacer login → navega a Home automáticamente
/// - Al hacer logout → navega a Login automáticamente
/// - Token expira → Supabase renueva automáticamente (si es válido)
///
/// Validación con el servidor (en segundo plano, no bloquea Home):
/// - Al iniciar y al volver a primer plano (máximo cada
///   [AuthGate.revalidateInterval]) confirma la sesión con `validateSession()`.
/// - Si el servidor la rechaza (cuenta eliminada, sesión revocada, usuario
///   bloqueado) cierra sesión; el stream emite null y se muestra Login.
/// - Sin red o con timeout conserva la sesión (la app funciona offline).
class AuthGate extends StatefulWidget {
  const AuthGate({
    super.key,
    this.revalidateInterval = const Duration(minutes: 5),
  });

  /// Intervalo mínimo entre validaciones al volver a primer plano.
  final Duration revalidateInterval;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> with WidgetsBindingObserver {
  final _authRepository = getIt<AuthRepository>();
  final _logger = getIt<AppLogger>();

  DateTime? _lastValidation;
  bool _validating = false;

  @override
  void initState() {
    super.initState();
    _logger.d('AuthGate: Inicializando guard de autenticación');
    WidgetsBinding.instance.addObserver(this);
    _validateSession();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    final last = _lastValidation;
    if (last != null &&
        DateTime.now().difference(last) < widget.revalidateInterval) {
      return;
    }
    _validateSession();
  }

  Future<void> _validateSession() async {
    if (_validating) return;
    _validating = true;
    _lastValidation = DateTime.now();
    try {
      final result = await _authRepository.validateSession();
      final rejected = result.when(
        onFailure: (_) => false, // No concluyente: conservar la sesión
        onSuccess: (isValid) => !isValid,
      );
      if (!rejected) return;

      _logger.w('AuthGate: Sesión rechazada por el servidor, cerrando sesión');
      await _authRepository.signOut();
    } finally {
      _validating = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authRepository.authStateChanges,
      builder: (context, snapshot) {
        // Loading: esperando primer evento del stream (casi instantáneo ~50-100ms)
        if (snapshot.connectionState == ConnectionState.waiting) {
          _logger.d('AuthGate: Esperando estado de autenticación...');
          return Scaffold(
            backgroundColor: Theme.of(context).colorScheme.primary,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo de la app
                  Icon(
                    Icons.chat_bubble_rounded,
                    size: 60,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Loading indicator
                  SizedBox(
                    width: 30,
                    height: 30,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Error: algo falló al escuchar el stream
        if (snapshot.hasError) {
          _logger.e(
            'AuthGate: Error en authStateChanges',
            error: snapshot.error,
            stackTrace: snapshot.stackTrace,
          );
          // Fallback: mostrar login si hay error
          return const LoginScreen();
        }

        // Verificar si hay usuario autenticado
        final user = snapshot.data;

        if (user != null) {
          // ✅ Usuario autenticado → MainNavigationScreen
          _logger.i(
            'AuthGate: Usuario autenticado',
            context: {'userId': user.id, 'email': user.email},
          );
          return const MainNavigationScreen();
        } else {
          // ❌ No hay usuario → LoginScreen
          _logger.d('AuthGate: No authenticated user, showing login');
          return const LoginScreen();
        }
      },
    );
  }
}
