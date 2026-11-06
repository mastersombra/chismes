import 'dart:async';
import 'auth_repository.dart';
import 'user.dart';

/// Implementación mock de AuthRepository para desarrollo y testing
/// Simula autenticación sin necesidad de backend
class MockAuthRepository implements AuthRepository {
  User? _currentUser;
  final StreamController<User?> _authStateController = StreamController<User?>.broadcast();

  MockAuthRepository({
    User? initialUser,
  }) : _currentUser = initialUser {
    // Emitir usuario inicial
    _authStateController.add(_currentUser);
  }

  @override
  User? get currentUser => _currentUser;

  @override
  Stream<User?> get authStateChanges => _authStateController.stream;

  @override
  Future<void> signOut() async {
    _currentUser = null;
    _authStateController.add(null);
  }

  @override
  Future<User?> getCurrentUser() async {
    return _currentUser;
  }

  /// Método para simular inicio de sesión (solo para testing)
  Future<void> signIn(User user) async {
    _currentUser = user;
    _authStateController.add(user);
  }

  /// Limpia recursos del stream controller
  void dispose() {
    _authStateController.close();
  }
}
