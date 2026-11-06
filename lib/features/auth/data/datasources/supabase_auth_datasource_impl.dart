import 'dart:async';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../../../../core/config/supabase_config.dart';
import '../../../../core/logging/logging.dart';
import '../models/user_model.dart';
import 'supabase_auth_datasource.dart';

/// Implementación de SupabaseAuthDataSource usando Supabase Auth
@Singleton(as: SupabaseAuthDataSource)
class SupabaseAuthDataSourceImpl implements SupabaseAuthDataSource {
  final AppLogger _logger;
  final supabase.SupabaseClient _supabase;

  SupabaseAuthDataSourceImpl(
    this._logger,
  ) : _supabase = SupabaseConfig.client;

  @override
  UserModel? get currentUser {
    final supabaseUser = _supabase.auth.currentUser;
    if (supabaseUser == null) return null;

    // Intentar obtener profile desde el caché local
    // Si no existe, retornar con profile vacío (se cargará después)
    return UserModel.fromSupabase(
      supabaseUser: supabaseUser,
      profileData: null, // Se cargará con getCurrentUser()
    );
  }

  @override
  Stream<UserModel?> get authStateChanges {
    return _supabase.auth.onAuthStateChange.asyncMap((event) async {
      final supabaseUser = event.session?.user;
      if (supabaseUser == null) return null;

      try {
        // Obtener profile completo
        final profileData = await _getProfileData(supabaseUser.id);
        return UserModel.fromSupabase(
          supabaseUser: supabaseUser,
          profileData: profileData,
        );
      } catch (e) {
        _logger.w('Error loading profile in auth state change',
            error: e, context: {'userId': supabaseUser.id});
        // Retornar user sin profile
        return UserModel.fromSupabase(
          supabaseUser: supabaseUser,
          profileData: null,
        );
      }
    });
  }

  @override
  Future<UserModel> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      _logger.i('Signing in with email', context: {'email': email});

      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw Exception('Sign in returned null user');
      }

      final profileData = await _getProfileData(response.user!.id);

      _logger.i('Sign in successful', context: {'userId': response.user!.id});

      return UserModel.fromSupabase(
        supabaseUser: response.user!,
        profileData: profileData,
      );
    } on supabase.AuthException catch (e) {
      _logger.w('Sign in failed (AuthException)',
          error: e, context: {'code': e.statusCode, 'message': e.message});
      rethrow;
    } catch (e, stackTrace) {
      _logger.e('Sign in failed',
          error: e, stackTrace: stackTrace, context: {'email': email});
      rethrow;
    }
  }

  @override
  Future<UserModel> signInWithGoogle() async {
    try {
      _logger.i('Signing in with Google');

      // 1. Iniciar Google Sign-In
      // iOS lee automáticamente CLIENT_ID de GoogleService-Info.plist
      final googleSignIn = GoogleSignIn(
        scopes: ['email'],
      );

      // 2. Trigger del flujo de autenticación de Google
      final googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        // Usuario canceló el login - NO es un error real
        _logger.i('Google sign-in cancelled by user');
        throw const supabase.AuthException('oauth_cancelled');
      }

      // 3. Obtener tokens de autenticación
      final googleAuth = await googleUser.authentication;

      if (googleAuth.idToken == null) {
        throw Exception('No ID Token from Google');
      }

      _logger.i('Google authentication successful, signing in to Supabase',
          context: {'email': googleUser.email});

      // 4. Autenticar en Supabase con el ID token de Google
      // Solo idToken - Supabase tiene "Skip nonce checks" activado para iOS
      final response = await _supabase.auth.signInWithIdToken(
        provider: supabase.OAuthProvider.google,
        idToken: googleAuth.idToken!,
      );

      if (response.user == null) {
        throw Exception('Supabase returned null user');
      }

      // 5. Obtener profile data
      final profileData = await _getProfileData(response.user!.id);

      // 6. Verificar si el profile existe, si no, crearlo
      await _ensureProfileExists(response.user!.id);

      _logger.i('Google sign in successful',
          context: {'userId': response.user!.id});

      return UserModel.fromSupabase(
        supabaseUser: response.user!,
        profileData: profileData,
      );
    } on supabase.AuthException catch (e) {
      _logger.w('Google sign in failed (AuthException)',
          error: e, context: {'code': e.statusCode, 'message': e.message});
      rethrow;
    } catch (e, stackTrace) {
      _logger.e('Google sign in failed', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<UserModel> signInWithApple() async {
    try {
      _logger.i('Signing in with Apple');

      final response = await _supabase.auth.signInWithOAuth(
        supabase.OAuthProvider.apple,
        redirectTo: 'chismes://auth/callback',
        authScreenLaunchMode: supabase.LaunchMode.externalApplication, // Usar Safari externo en iOS
      );

      if (!response) {
        throw Exception('Apple OAuth returned false');
      }

      // Esperar a que el auth state change emita el usuario
      var user = await authStateChanges.first;

      if (user == null) {
        throw Exception('No user after Apple OAuth');
      }

      // Verificar si el profile existe, si no, crearlo
      await _ensureProfileExists(user.id);

      _logger.i('Apple sign in successful', context: {'userId': user.id});

      return user;
    } on supabase.AuthException catch (e) {
      _logger.w('Apple sign in failed (AuthException)',
          error: e, context: {'code': e.statusCode, 'message': e.message});
      rethrow;
    } catch (e, stackTrace) {
      _logger.e('Apple sign in failed', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      _logger.i('Signing out', context: {'userId': userId});

      await _supabase.auth.signOut();

      _logger.i('Sign out successful', context: {'userId': userId});
    } on supabase.AuthException catch (e) {
      _logger.w('Sign out failed (AuthException)',
          error: e, context: {'code': e.statusCode, 'message': e.message});
      rethrow;
    } catch (e, stackTrace) {
      _logger.e('Sign out failed', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    try {
      final supabaseUser = _supabase.auth.currentUser;
      if (supabaseUser == null) return null;

      final profileData = await _getProfileData(supabaseUser.id);

      return UserModel.fromSupabase(
        supabaseUser: supabaseUser,
        profileData: profileData,
      );
    } catch (e, stackTrace) {
      _logger.e('Get current user failed', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<UserModel> updateProfile({
    String? username,
    String? displayName,
    String? avatarUrl,
    String? bio,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('No authenticated user');
      }

      _logger.i('Updating profile', context: {
        'userId': userId,
        'hasUsername': username != null,
        'hasDisplayName': displayName != null,
        'hasAvatar': avatarUrl != null,
        'hasBio': bio != null,
      });

      // Construir update data (solo campos no-null)
      final Map<String, dynamic> updateData = {};
      if (username != null) updateData['username'] = username;
      if (displayName != null) updateData['display_name'] = displayName;
      if (avatarUrl != null) updateData['avatar_url'] = avatarUrl;
      if (bio != null) updateData['bio'] = bio;

      // Actualizar profile en Supabase
      await _supabase.from('profiles').update(updateData).eq('id', userId);

      // Obtener profile actualizado
      final profileData = await _getProfileData(userId);
      final supabaseUser = _supabase.auth.currentUser!;

      _logger.i('Profile updated successfully', context: {'userId': userId});

      return UserModel.fromSupabase(
        supabaseUser: supabaseUser,
        profileData: profileData,
      );
    } on supabase.PostgrestException catch (e) {
      _logger.w('Update profile failed (PostgrestException)',
          error: e, context: {'code': e.code, 'message': e.message});
      rethrow;
    } catch (e, stackTrace) {
      _logger.e('Update profile failed', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<bool> isUsernameAvailable(String username) async {
    try {
      _logger.d('Checking username availability',
          context: {'username': username});

      final response = await _supabase
          .from('profiles')
          .select('id')
          .ilike('username', username)
          .maybeSingle();

      final available = response == null;

      _logger.d('Username availability checked',
          context: {'username': username, 'available': available});

      return available;
    } catch (e, stackTrace) {
      _logger.e('Check username availability failed',
          error: e, stackTrace: stackTrace, context: {'username': username});
      rethrow;
    }
  }

  @override
  Future<void> resetPassword({
    required String email,
  }) async {
    try {
      _logger.i('Sending password reset OTP', context: {'email': email});

      // Envía OTP de 6 dígitos para reset password
      // shouldCreateUser: false asegura que solo funcione para usuarios existentes
      await _supabase.auth.signInWithOtp(
        email: email,
        shouldCreateUser: false,
      );

      _logger.i('Password reset OTP sent', context: {'email': email});
    } on supabase.AuthException catch (e) {
      _logger.w('Reset password failed (AuthException)',
          error: e, context: {'code': e.statusCode, 'message': e.message});
      rethrow;
    } catch (e, stackTrace) {
      _logger.e('Reset password failed',
          error: e, stackTrace: stackTrace, context: {'email': email});
      rethrow;
    }
  }

  @override
  Future<void> updatePassword({
    required String newPassword,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      _logger.i('Updating password', context: {'userId': userId});

      await _supabase.auth.updateUser(
        supabase.UserAttributes(password: newPassword),
      );

      _logger.i('Password updated successfully', context: {'userId': userId});
    } on supabase.AuthException catch (e) {
      _logger.w('Update password failed (AuthException)',
          error: e, context: {'code': e.statusCode, 'message': e.message});
      rethrow;
    } catch (e, stackTrace) {
      _logger.e('Update password failed', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> resendVerificationEmail() async {
    try {
      final user = _supabase.auth.currentUser;

      if (user == null) {
        throw Exception('No authenticated user');
      }

      final email = user.email;
      if (email == null) {
        throw Exception('User has no email');
      }

      _logger.i('Resending verification email', context: {'email': email});

      // Supabase resend verification
      await _supabase.auth.resend(
        type: supabase.OtpType.signup,
        email: email,
      );

      _logger.i('Verification email resent successfully', context: {'email': email});
    } on supabase.AuthException catch (e) {
      _logger.w('Resend verification email failed (AuthException)',
          error: e, context: {'code': e.statusCode, 'message': e.message});
      rethrow;
    } catch (e, stackTrace) {
      _logger.e('Resend verification email failed',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> signUpWithEmailOTP({
    required String email,
    required String password,
  }) async {
    try {
      _logger.i('Signing up with email OTP', context: {'email': email});

      // Signup con Supabase - NO auto-confirma email
      await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      _logger.i('Sign up OTP sent', context: {'email': email});
    } on supabase.AuthException catch (e) {
      _logger.w('Sign up OTP failed (AuthException)',
          error: e, context: {'code': e.statusCode, 'message': e.message});
      rethrow;
    } catch (e, stackTrace) {
      _logger.e('Sign up OTP failed',
          error: e, stackTrace: stackTrace, context: {'email': email});
      rethrow;
    }
  }

  @override
  Future<UserModel> verifyOTP({
    required String email,
    required String token,
    bool isPasswordReset = false,
  }) async {
    try {
      final otpType = isPasswordReset ? supabase.OtpType.recovery : supabase.OtpType.signup;
      _logger.i('Verifying OTP', context: {'email': email, 'type': otpType.name});

      final response = await _supabase.auth.verifyOTP(
        email: email,
        token: token,
        type: otpType,
      );

      if (response.user == null) {
        throw Exception('Verify OTP returned null user');
      }

      final profileData = await _getProfileData(response.user!.id);

      _logger.i('OTP verified successfully', context: {'userId': response.user!.id});

      return UserModel.fromSupabase(
        supabaseUser: response.user!,
        profileData: profileData,
      );
    } on supabase.AuthException catch (e) {
      _logger.w('Verify OTP failed (AuthException)',
          error: e, context: {'code': e.statusCode, 'message': e.message});
      rethrow;
    } catch (e, stackTrace) {
      _logger.e('Verify OTP failed',
          error: e, stackTrace: stackTrace, context: {'email': email});
      rethrow;
    }
  }

  @override
  Future<void> resendOTP({
    required String email,
  }) async {
    try {
      _logger.i('Resending OTP', context: {'email': email});

      await _supabase.auth.resend(
        type: supabase.OtpType.signup,
        email: email,
      );

      _logger.i('OTP resent successfully', context: {'email': email});
    } on supabase.AuthException catch (e) {
      _logger.w('Resend OTP failed (AuthException)',
          error: e, context: {'code': e.statusCode, 'message': e.message});
      rethrow;
    } catch (e, stackTrace) {
      _logger.e('Resend OTP failed',
          error: e, stackTrace: stackTrace, context: {'email': email});
      rethrow;
    }
  }

  // =====================================================
  // HELPERS PRIVADOS
  // =====================================================

  /// Obtiene datos de profile desde la tabla profiles
  Future<Map<String, dynamic>?> _getProfileData(String userId) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      return response;
    } catch (e) {
      _logger.w('Failed to get profile data',
          error: e, context: {'userId': userId});
      return null;
    }
  }

  /// Crea un profile manualmente si el trigger falló
  Future<void> _createProfile(String userId) async {
    try {
      await _supabase.from('profiles').insert({
        'id': userId,
        'username': null,
        'display_name': null,
        'profile_completed': false,
      });

      _logger.i('Profile created manually', context: {'userId': userId});
    } catch (e) {
      _logger.e('Failed to create profile manually',
          error: e, context: {'userId': userId});
      rethrow;
    }
  }

  /// Asegura que el profile existe, creándolo si es necesario
  Future<void> _ensureProfileExists(String userId) async {
    final profileData = await _getProfileData(userId);

    if (profileData == null) {
      _logger.w('Profile not found, creating manually',
          context: {'userId': userId});
      await _createProfile(userId);
    }
  }

  @override
  Future<bool> checkEmailExistsAndConfirmed(String email) async {
    try {
      _logger.d('Checking if email exists and is confirmed',
          context: {'email': email});

      final response = await _supabase.rpc(
        'check_email_exists_and_confirmed',
        params: {'email_to_check': email},
      );

      final exists = response as bool;

      _logger.d('Email existence check completed',
          context: {'email': email, 'exists': exists});

      return exists;
    } on supabase.PostgrestException catch (e) {
      _logger.w('Check email exists failed (PostgrestException)',
          error: e, context: {'code': e.code, 'message': e.message});
      rethrow;
    } catch (e, stackTrace) {
      _logger.e('Check email exists failed',
          error: e, stackTrace: stackTrace, context: {'email': email});
      rethrow;
    }
  }
}
