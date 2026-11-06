import 'package:flutter/material.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/logging/logging.dart';
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
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final _authRepository = getIt<AuthRepository>();
  final _logger = getIt<AppLogger>();

  @override
  void initState() {
    super.initState();
    _logger.d('AuthGate: Inicializando guard de autenticación');
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
          _logger.d('AuthGate: No hay usuario autenticado, mostrando login');
          return const LoginScreen();
        }
      },
    );
  }
}
