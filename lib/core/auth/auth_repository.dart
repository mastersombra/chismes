import 'user.dart';

/// Repositorio de autenticación abstracto
/// Define el contrato para cualquier implementación de autenticación
/// 
/// Implementaciones:
/// - MockAuthRepository (desarrollo/testing)
/// - SupabaseAuthRepository (producción con Supabase Auth)
/// - CustomAuthRepository (otras implementaciones)
abstract class AuthRepository {
  /// Usuario actualmente autenticado, null si no hay sesión
  User? get currentUser;

  /// Stream de cambios en el estado de autenticación
  /// Emite el usuario actual cuando cambia, null cuando se desautentica
  Stream<User?> get authStateChanges;

  /// Cierra la sesión del usuario actual
  Future<void> signOut();

  /// Obtiene el usuario actual de forma asíncrona
  Future<User?> getCurrentUser();
}
