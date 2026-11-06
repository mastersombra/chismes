/// Servicio para obtener información del usuario actual
/// En producción, esto se conectaría con un sistema de autenticación
class UserService {
  String? _currentUser;

  /// Obtiene el usuario actualmente autenticado
  /// 
  /// ⚠️ IMPORTANTE: Esto debe retornar el UID real del usuario, nunca "anonymous".
  /// Si no hay usuario autenticado, retorna null.
  String? getCurrentUser() {
    return _currentUser;
  }

  /// Establece el usuario actual (para desarrollo/testing)
  void setCurrentUser(String userId) {
    if (userId.isEmpty) {
      throw ArgumentError('userId no puede estar vacío. Use un UID real.');
    }
    _currentUser = userId;
  }

  /// Cierra sesión y limpia el usuario
  void logout() {
    _currentUser = null;
  }

  /// Verifica si hay un usuario autenticado
  bool isAuthenticated() {
    return _currentUser != null && _currentUser!.isNotEmpty;
  }

  /// Singleton para acceso global
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();
}
