import '../../../../core/error/failure.dart';
import '../../../../core/result/result.dart';
import '../entities/user.dart';

/// Repositorio de autenticación
///
/// Define el contrato para todas las operaciones de autenticación.
/// Todas las operaciones retornan `Result<Failure, T>` siguiendo el
/// patrón de manejo de errores del proyecto.
///
/// Implementaciones:
/// - SupabaseAuthRepositoryImpl (producción con Supabase Auth)
/// - MockAuthRepository (desarrollo/testing)
abstract class AuthRepository {
  /// Usuario actualmente autenticado, null si no hay sesión
  User? get currentUser;

  /// Stream de cambios en el estado de autenticación
  ///
  /// Emite el usuario actual cuando cambia, null cuando se desautentica.
  /// Útil para reaccionar a cambios de sesión en toda la app.
  Stream<User?> get authStateChanges;

  /// Inicia sesión con email y contraseña
  ///
  /// [email] Email del usuario
  /// [password] Contraseña del usuario
  ///
  /// Returns:
  /// - Success: Usuario autenticado
  /// - Failure: InvalidCredentialsFailure, NetworkFailure, etc.
  Future<Result<Failure, User>> signInWithEmail({
    required String email,
    required String password,
  });

  /// Registra un nuevo usuario con email y contraseña
  ///
  /// Envía un código OTP de 6 dígitos al email del usuario.
  /// El usuario NO queda autenticado hasta verificar el OTP.
  ///
  /// [email] Email del nuevo usuario
  /// [password] Contraseña del nuevo usuario
  ///
  /// Returns:
  /// - Success: void (OTP enviado, usuario debe verificar con verifyOTP)
  /// - Failure: EmailAlreadyInUseFailure, WeakPasswordFailure, etc.
  ///
  /// Flujo completo:
  /// 1. signUpWithEmail() → OTP enviado
  /// 2. verifyOTP() → Usuario verificado y autenticado
  /// 3. updateProfile() → Completar perfil
  Future<Result<Failure, void>> signUpWithEmail({
    required String email,
    required String password,
  });

  /// Verifica el código OTP enviado por email
  ///
  /// [email] Email del usuario
  /// [token] Código OTP de 6 dígitos
  /// [isPasswordReset] Indica si es para reset de password (recovery) o signup
  ///
  /// Returns:
  /// - Success: Usuario verificado y autenticado
  /// - Failure: InvalidOtpFailure, ExpiredOtpFailure, etc.
  Future<Result<Failure, User>> verifyOTP({
    required String email,
    required String token,
    bool isPasswordReset = false,
  });

  /// Reenvía el código OTP por email
  ///
  /// [email] Email del usuario
  ///
  /// Returns:
  /// - Success: void (OTP reenviado)
  /// - Failure: NetworkFailure, TooManyRequestsFailure, etc.
  Future<Result<Failure, void>> resendOTP({
    required String email,
  });

  /// Inicia sesión con Google OAuth
  ///
  /// Returns:
  /// - Success: Usuario autenticado
  /// - Failure: OAuthCancelledFailure, NetworkFailure, etc.
  Future<Result<Failure, User>> signInWithGoogle();

  /// Inicia sesión con Apple OAuth
  ///
  /// Returns:
  /// - Success: Usuario autenticado
  /// - Failure: OAuthCancelledFailure, NetworkFailure, etc.
  Future<Result<Failure, User>> signInWithApple();

  /// Cierra la sesión del usuario actual
  ///
  /// Returns:
  /// - Success: void (sesión cerrada)
  /// - Failure: NetworkFailure, etc.
  Future<Result<Failure, void>> signOut();

  /// Obtiene el usuario actual de forma asíncrona
  ///
  /// Útil para refrescar datos del usuario o verificar sesión.
  ///
  /// Returns:
  /// - Success: Usuario actual o null si no hay sesión
  /// - Failure: NetworkFailure, etc.
  Future<Result<Failure, User?>> getCurrentUser();

  /// Actualiza el perfil del usuario actual
  ///
  /// Solo actualiza los campos que no son null.
  ///
  /// [username] Nuevo username (debe ser único)
  /// [displayName] Nuevo nombre a mostrar
  /// [avatarUrl] Nueva URL de avatar
  /// [bio] Nueva biografía
  ///
  /// Returns:
  /// - Success: Usuario actualizado
  /// - Failure: UsernameAlreadyTakenFailure, NetworkFailure, etc.
  Future<Result<Failure, User>> updateProfile({
    String? username,
    String? displayName,
    String? avatarUrl,
    String? bio,
  });

  /// Verifica si un username está disponible
  ///
  /// [username] Username a verificar
  ///
  /// Returns:
  /// - Success: true si disponible, false si ya existe
  /// - Failure: NetworkFailure, etc.
  Future<Result<Failure, bool>> isUsernameAvailable(String username);

  /// Envía email para resetear contraseña
  ///
  /// [email] Email del usuario
  ///
  /// Returns:
  /// - Success: void (email enviado)
  /// - Failure: UserNotFoundFailure, NetworkFailure, etc.
  Future<Result<Failure, void>> resetPassword({
    required String email,
  });

  /// Actualiza la contraseña del usuario actual
  ///
  /// [newPassword] Nueva contraseña
  ///
  /// Returns:
  /// - Success: void (contraseña actualizada)
  /// - Failure: WeakPasswordFailure, NetworkFailure, etc.
  Future<Result<Failure, void>> updatePassword({
    required String newPassword,
  });

  /// Reenvía el email de verificación al usuario actual
  ///
  /// Envía un nuevo email de confirmación al usuario autenticado.
  /// Solo aplicable si el email aún no está verificado.
  ///
  /// Returns:
  /// - Success: void (email enviado)
  /// - Failure: UserNotAuthenticatedFailure, NetworkFailure, etc.
  Future<Result<Failure, void>> resendVerificationEmail();

  /// Verifica si un email existe y está confirmado
  ///
  /// Permite prevenir intentos de registro duplicados.
  ///
  /// [email] Email a verificar
  ///
  /// Returns:
  /// - Success: true si el email existe y está confirmado, false en caso contrario
  /// - Failure: NetworkFailure, etc.
  Future<Result<Failure, bool>> checkEmailExistsAndConfirmed(String email);
}
