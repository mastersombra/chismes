import '../models/user_model.dart';

/// Data source abstracto para operaciones de autenticación
///
/// Define el contrato para implementaciones de autenticación.
/// La implementación concreta usa Supabase Auth.
abstract class SupabaseAuthDataSource {
  /// Usuario actualmente autenticado
  UserModel? get currentUser;

  /// Stream de cambios de autenticación
  Stream<UserModel?> get authStateChanges;

  /// Inicia sesión con email y contraseña
  ///
  /// Throws:
  /// - InvalidCredentialsException
  /// - NetworkException
  Future<UserModel> signInWithEmail({
    required String email,
    required String password,
  });

  /// Registra nuevo usuario y envía OTP por email
  ///
  /// Throws:
  /// - EmailAlreadyInUseException
  /// - WeakPasswordException
  /// - NetworkException
  Future<void> signUpWithEmailOTP({
    required String email,
    required String password,
  });

  /// Verifica código OTP
  ///
  /// [isPasswordReset] Indica si es para reset de password (recovery) o signup
  ///
  /// Throws:
  /// - InvalidOtpException
  /// - ExpiredOtpException
  /// - NetworkException
  Future<UserModel> verifyOTP({
    required String email,
    required String token,
    bool isPasswordReset = false,
  });

  /// Reenvía código OTP
  ///
  /// Throws:
  /// - TooManyRequestsException
  /// - NetworkException
  Future<void> resendOTP({
    required String email,
  });

  /// Inicia sesión con Google OAuth
  ///
  /// Throws:
  /// - OAuthCancelledException
  /// - OAuthProviderException
  /// - NetworkException
  Future<UserModel> signInWithGoogle();

  /// Inicia sesión con Apple OAuth
  ///
  /// Throws:
  /// - OAuthCancelledException
  /// - OAuthProviderException
  /// - NetworkException
  Future<UserModel> signInWithApple();

  /// Cierra sesión
  ///
  /// Throws:
  /// - NetworkException
  Future<void> signOut();

  /// Obtiene usuario actual con datos frescos
  ///
  /// Throws:
  /// - NetworkException
  Future<UserModel?> getCurrentUser();

  /// Confirma con el servidor (`GET /auth/v1/user`) que la sesión guardada
  /// sigue vigente.
  ///
  /// Returns:
  /// - `false` solo si el servidor rechaza la sesión: usuario eliminado,
  ///   sesión revocada, usuario bloqueado o JWT inválido.
  /// - `true` si la sesión es válida, si no hay sesión o si el access token
  ///   ya venció (eso lo resuelve el refresh automático de Supabase, que
  ///   cierra la sesión si el refresh token fue revocado).
  ///
  /// Throws:
  /// - AuthException no concluyente (red, timeout, 5xx): la sesión se conserva
  Future<bool> validateSession();

  /// Actualiza perfil del usuario
  ///
  /// Throws:
  /// - UsernameAlreadyTakenException
  /// - NetworkException
  Future<UserModel> updateProfile({
    String? username,
    String? displayName,
    String? avatarUrl,
    String? bio,
  });

  /// Verifica disponibilidad de username
  ///
  /// Throws:
  /// - NetworkException
  Future<bool> isUsernameAvailable(String username);

  /// Envía email de reset de contraseña
  ///
  /// Throws:
  /// - UserNotFoundException
  /// - NetworkException
  Future<void> resetPassword({
    required String email,
  });

  /// Actualiza contraseña del usuario actual
  ///
  /// Throws:
  /// - WeakPasswordException
  /// - NetworkException
  Future<void> updatePassword({
    required String newPassword,
  });

  /// Reenvía email de verificación al usuario actual
  ///
  /// Throws:
  /// - UserNotAuthenticatedException
  /// - NetworkException
  Future<void> resendVerificationEmail();

  /// Verifica si un email existe y está confirmado
  ///
  /// Returns:
  /// - true: Email existe y está confirmado (no permitir registro)
  /// - false: Email no existe O no está confirmado (permitir registro)
  ///
  /// Throws:
  /// - NetworkException
  Future<bool> checkEmailExistsAndConfirmed(String email);
}
