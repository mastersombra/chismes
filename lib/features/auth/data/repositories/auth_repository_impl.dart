import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../../../../core/error/error_codes.dart';
import '../../../../core/error/error_handler.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/logging/logging.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/supabase_auth_datasource.dart';

/// Implementación del repositorio de autenticación
///
/// Maneja errores convirtiendo excepciones a Failures usando Result pattern.
@Singleton(as: AuthRepository)
class AuthRepositoryImpl implements AuthRepository {
  final SupabaseAuthDataSource _dataSource;
  final AppLogger _logger;

  AuthRepositoryImpl(
    this._dataSource,
    this._logger,
  );

  @override
  User? get currentUser {
    final userModel = _dataSource.currentUser;
    return userModel?.toEntity();
  }

  @override
  Stream<User?> get authStateChanges {
    return _dataSource.authStateChanges
        .map((userModel) => userModel?.toEntity());
  }

  @override
  Future<Result<Failure, User>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      // ✅ Verificar si el email existe ANTES de intentar login
      // Esto da mejor UX sin comprometer seguridad (ya exponemos check_email_exists)
      final emailExists = await _dataSource.checkEmailExistsAndConfirmed(email);

      if (!emailExists) {
        // Email no existe o no está confirmado
        _logger.w('Sign in failed: email not found or not confirmed',
            context: {'email': email});
        return Result.failure(const AuthFailure(
          code: ErrorCode.userNotFound,
          technicalMessage: 'User not found or email not confirmed',
        ));
      }

      // Email existe y está confirmado, intentar login
      final userModel = await _dataSource.signInWithEmail(
        email: email,
        password: password,
      );
      return Result.success(userModel.toEntity());
    } on supabase.AuthException catch (error) {
      _logger.w('Sign in with email failed',
          error: error, context: {'email': email, 'code': error.statusCode});
      return Result.failure(_handleAuthException(error));
    } catch (error, stackTrace) {
      _logger.e('Sign in with email failed',
          error: error, stackTrace: stackTrace, context: {'email': email});
      return Result.failure(ErrorHandler.handleError(error, stackTrace));
    }
  }

  @override
  Future<Result<Failure, void>> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      await _dataSource.signUpWithEmailOTP(
        email: email,
        password: password,
      );
      _logger.i('Sign up successful, OTP sent', context: {'email': email});
      return Result.success(null);
    } on supabase.AuthException catch (error) {
      _logger.w('Sign up with email failed',
          error: error, context: {'email': email, 'code': error.statusCode});
      return Result.failure(_handleAuthException(error));
    } catch (error, stackTrace) {
      _logger.e('Sign up with email failed',
          error: error, stackTrace: stackTrace, context: {'email': email});
      return Result.failure(ErrorHandler.handleError(error, stackTrace));
    }
  }

  @override
  Future<Result<Failure, User>> signInWithGoogle() async {
    try {
      final userModel = await _dataSource.signInWithGoogle();
      return Result.success(userModel.toEntity());
    } on supabase.AuthException catch (error) {
      _logger.w('Sign in with Google failed',
          error: error, context: {'code': error.statusCode});
      return Result.failure(_handleAuthException(error));
    } catch (error, stackTrace) {
      _logger.e('Sign in with Google failed',
          error: error, stackTrace: stackTrace);
      return Result.failure(ErrorHandler.handleError(error, stackTrace));
    }
  }

  @override
  Future<Result<Failure, User>> signInWithApple() async {
    try {
      final userModel = await _dataSource.signInWithApple();
      return Result.success(userModel.toEntity());
    } on supabase.AuthException catch (error) {
      _logger.w('Sign in with Apple failed',
          error: error, context: {'code': error.statusCode});
      return Result.failure(_handleAuthException(error));
    } catch (error, stackTrace) {
      _logger.e('Sign in with Apple failed',
          error: error, stackTrace: stackTrace);
      return Result.failure(ErrorHandler.handleError(error, stackTrace));
    }
  }

  @override
  Future<Result<Failure, void>> signOut() async {
    try {
      await _dataSource.signOut();
      return Result.success(null);
    } on supabase.AuthException catch (error) {
      _logger.w('Sign out failed', error: error, context: {'code': error.statusCode});
      return Result.failure(_handleAuthException(error));
    } catch (error, stackTrace) {
      _logger.e('Sign out failed', error: error, stackTrace: stackTrace);
      return Result.failure(ErrorHandler.handleError(error, stackTrace));
    }
  }

  @override
  Future<Result<Failure, User?>> getCurrentUser() async {
    try {
      final userModel = await _dataSource.getCurrentUser();
      return Result.success(userModel?.toEntity());
    } catch (error, stackTrace) {
      _logger.e('Get current user failed',
          error: error, stackTrace: stackTrace);
      return Result.failure(ErrorHandler.handleError(error, stackTrace));
    }
  }

  @override
  Future<Result<Failure, User>> updateProfile({
    String? username,
    String? displayName,
    String? avatarUrl,
    String? bio,
  }) async {
    try {
      final userModel = await _dataSource.updateProfile(
        username: username,
        displayName: displayName,
        avatarUrl: avatarUrl,
        bio: bio,
      );
      return Result.success(userModel.toEntity());
    } on supabase.PostgrestException catch (error) {
      _logger.w('Update profile failed',
          error: error,
          context: {'code': error.code, 'message': error.message});

      // Check for unique constraint violation (username already taken)
      if (error.code == '23505' && error.message.contains('username')) {
        return Result.failure(
          DataFailure(
            code: ErrorCode.usernameAlreadyTaken,
            technicalMessage: 'Username already taken',
          ),
        );
      }

      return Result.failure(ErrorHandler.handleError(error));
    } catch (error, stackTrace) {
      _logger.e('Update profile failed',
          error: error, stackTrace: stackTrace);
      return Result.failure(ErrorHandler.handleError(error, stackTrace));
    }
  }

  @override
  Future<Result<Failure, bool>> isUsernameAvailable(String username) async {
    try {
      final available = await _dataSource.isUsernameAvailable(username);
      return Result.success(available);
    } catch (error, stackTrace) {
      _logger.e('Check username availability failed',
          error: error, stackTrace: stackTrace, context: {'username': username});
      return Result.failure(ErrorHandler.handleError(error, stackTrace));
    }
  }

  @override
  Future<Result<Failure, void>> resetPassword({
    required String email,
  }) async {
    try {
      await _dataSource.resetPassword(email: email);
      return Result.success(null);
    } on supabase.AuthException catch (error) {
      _logger.w('Reset password failed',
          error: error, context: {'email': email, 'code': error.statusCode});
      return Result.failure(_handleAuthException(error));
    } catch (error, stackTrace) {
      _logger.e('Reset password failed',
          error: error, stackTrace: stackTrace, context: {'email': email});
      return Result.failure(ErrorHandler.handleError(error, stackTrace));
    }
  }

  @override
  Future<Result<Failure, void>> updatePassword({
    required String newPassword,
  }) async {
    try {
      await _dataSource.updatePassword(newPassword: newPassword);
      return Result.success(null);
    } on supabase.AuthException catch (error) {
      _logger.w('Update password failed',
          error: error, context: {'code': error.statusCode});
      return Result.failure(_handleAuthException(error));
    } catch (error, stackTrace) {
      _logger.e('Update password failed',
          error: error, stackTrace: stackTrace);
      return Result.failure(ErrorHandler.handleError(error, stackTrace));
    }
  }

  @override
  Future<Result<Failure, void>> resendVerificationEmail() async {
    try {
      await _dataSource.resendVerificationEmail();
      _logger.i('Verification email resent successfully');
      return Result.success(null);
    } on supabase.AuthException catch (error) {
      _logger.w('Resend verification email failed',
          error: error, context: {'code': error.statusCode});
      return Result.failure(_handleAuthException(error));
    } catch (error, stackTrace) {
      _logger.e('Resend verification email failed',
          error: error, stackTrace: stackTrace);
      return Result.failure(ErrorHandler.handleError(error, stackTrace));
    }
  }

  @override
  Future<Result<Failure, User>> verifyOTP({
    required String email,
    required String token,
    bool isPasswordReset = false,
  }) async {
    try {
      final userModel = await _dataSource.verifyOTP(
        email: email,
        token: token,
        isPasswordReset: isPasswordReset,
      );
      _logger.i('OTP verified successfully', context: {'email': email, 'isPasswordReset': isPasswordReset});
      return Result.success(userModel.toEntity());
    } on supabase.AuthException catch (error) {
      _logger.w('Verify OTP failed',
          error: error, context: {'email': email, 'code': error.statusCode});
      return Result.failure(_handleAuthException(error));
    } catch (error, stackTrace) {
      _logger.e('Verify OTP failed',
          error: error, stackTrace: stackTrace, context: {'email': email});
      return Result.failure(ErrorHandler.handleError(error, stackTrace));
    }
  }

  @override
  Future<Result<Failure, void>> resendOTP({
    required String email,
  }) async {
    try {
      await _dataSource.resendOTP(email: email);
      _logger.i('OTP resent successfully', context: {'email': email});
      return Result.success(null);
    } on supabase.AuthException catch (error) {
      _logger.w('Resend OTP failed',
          error: error, context: {'email': email, 'code': error.statusCode});
      return Result.failure(_handleAuthException(error));
    } catch (error, stackTrace) {
      _logger.e('Resend OTP failed',
          error: error, stackTrace: stackTrace, context: {'email': email});
      return Result.failure(ErrorHandler.handleError(error, stackTrace));
    }
  }

  @override
  Future<Result<Failure, bool>> checkEmailExistsAndConfirmed(String email) async {
    try {
      final exists = await _dataSource.checkEmailExistsAndConfirmed(email);
      return Result.success(exists);
    } catch (error, stackTrace) {
      _logger.e('Check email exists failed',
          error: error, stackTrace: stackTrace, context: {'email': email});
      return Result.failure(ErrorHandler.handleError(error, stackTrace));
    }
  }

  // =====================================================
  // MANEJO DE EXCEPCIONES DE SUPABASE AUTH
  // =====================================================

  /// Convierte AuthException a Failure específico
  Failure _handleAuthException(supabase.AuthException error) {
    final message = error.message.toLowerCase();
    final statusCode = error.statusCode;
    final code = error.code; // Código específico de Supabase (ej: 'otp_expired')

    // Invalid credentials
    if (message.contains('invalid') && message.contains('credentials')) {
      return const AuthFailure(
        code: ErrorCode.invalidCredentials,
        technicalMessage: 'Invalid login credentials',
      );
    }
    if (message.contains('invalid login credentials')) {
      return const AuthFailure(
        code: ErrorCode.invalidCredentials,
        technicalMessage: 'Invalid login credentials',
      );
    }

    // Email already registered
    if (message.contains('already') && message.contains('registered')) {
      return const AuthFailure(
        code: ErrorCode.emailAlreadyInUse,
        technicalMessage: 'Email already registered',
      );
    }
    if (message.contains('user already registered')) {
      return const AuthFailure(
        code: ErrorCode.emailAlreadyInUse,
        technicalMessage: 'Email already registered',
      );
    }

    // Weak password
    if (message.contains('password') && message.contains('weak')) {
      return const AuthFailure(
        code: ErrorCode.weakPassword,
        technicalMessage: 'Password is too weak',
      );
    }
    if (message.contains('password is too short')) {
      return const AuthFailure(
        code: ErrorCode.weakPassword,
        technicalMessage: 'Password is too short',
      );
    }

    // User not found
    if (message.contains('user') && message.contains('not found')) {
      return const AuthFailure(
        code: ErrorCode.userNotFound,
        technicalMessage: 'User not found',
      );
    }

    // Token errors - usar código específico de Supabase
    // OTP expired: code = 'otp_expired'
    if (code == 'otp_expired') {
      return const AuthFailure(
        code: ErrorCode.expiredToken,
        technicalMessage: 'OTP expired',
      );
    }

    // Token/OTP invalid: verificar mensaje
    if (message.contains('token') && message.contains('invalid')) {
      return const AuthFailure(
        code: ErrorCode.invalidToken,
        technicalMessage: 'Invalid token',
      );
    }
    if (message.contains('expired')) {
      return const AuthFailure(
        code: ErrorCode.expiredToken,
        technicalMessage: 'Token expired',
      );
    }

    // Session expired
    if (message.contains('session') && message.contains('expired')) {
      return const AuthFailure(
        code: ErrorCode.sessionExpired,
        technicalMessage: 'Session expired',
      );
    }

    // Rate limiting
    if (statusCode == '429') {
      return const AuthFailure(
        code: ErrorCode.tooManyRequests,
        technicalMessage: 'Too many attempts',
      );
    }
    if (message.contains('too many requests')) {
      return const AuthFailure(
        code: ErrorCode.tooManyRequests,
        technicalMessage: 'Too many requests',
      );
    }

    // OAuth cancelled
    if (message.contains('cancelled') || message.contains('canceled')) {
      return const AuthFailure(
        code: ErrorCode.oauthCancelled,
        technicalMessage: 'OAuth cancelled',
      );
    }

    // Email not verified
    if (message.contains('email') && message.contains('not verified')) {
      return const AuthFailure(
        code: ErrorCode.emailNotVerified,
        technicalMessage: 'Email not verified',
      );
    }

    // Fallback: usar mensaje de la excepción
    return AuthFailure(
      code: ErrorCode.unknownError,
      technicalMessage: 'Auth error: ${error.message}',
    );
  }
}
