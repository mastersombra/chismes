import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide ErrorCode;
import 'package:chismes/core/error/error_codes.dart';
import 'package:chismes/core/error/failure.dart';
import 'package:chismes/core/logging/logging.dart';
import 'package:chismes/features/auth/data/datasources/supabase_auth_datasource_impl.dart';
import 'package:chismes/features/auth/data/models/user_model.dart';

import '../../../../helpers/fake_supabase_http.dart';

import 'supabase_auth_datasource_impl_test.mocks.dart';

@GenerateMocks([
  SupabaseClient,
  GoTrueClient,
  User,
  AppLogger,
])
void main() {
  late SupabaseAuthDataSourceImpl dataSource;
  late MockSupabaseClient mockSupabase;
  late MockGoTrueClient mockAuth;
  late MockAppLogger mockLogger;
  late MockUser mockUser;

  setUp(() {
    mockSupabase = MockSupabaseClient();
    mockAuth = MockGoTrueClient();
    mockLogger = MockAppLogger();
    mockUser = MockUser();
    when(mockUser.appMetadata).thenReturn({});

    // Configurar auth mock básico
    when(mockSupabase.auth).thenReturn(mockAuth);

    dataSource = SupabaseAuthDataSourceImpl(mockSupabase, mockLogger);
  });

  group('SupabaseAuthDataSourceImpl', () {
    // NOTA: Muchos tests (signInWithEmail, signInWithGoogle, signInWithApple, getCurrentUser,
    // updateProfile, isUsernameAvailable, checkEmailExistsAndConfirmed, authStateChanges) son omitidos
    // debido a la complejidad de mockear la cadena de builders de Postgrest
    // (SupabaseQueryBuilder -> PostgrestFilterBuilder -> PostgrestTransformBuilder) y
    // las dependencias externas (GoogleSignIn, AppLinks).
    // Estos están cubiertos por integration tests o tests end-to-end.
    // Este archivo se enfoca en los métodos de autenticación pura que se pueden mockear directamente.

    group('currentUser getter', () {
      test('debe retornar UserModel cuando hay usuario autenticado', () {
        // Arrange
        when(mockAuth.currentUser).thenReturn(mockUser);
        when(mockUser.id).thenReturn('user-123');
        when(mockUser.email).thenReturn('test@example.com');
        when(mockUser.emailConfirmedAt).thenReturn(DateTime(2024, 1, 1).toIso8601String());
        when(mockUser.createdAt).thenReturn(DateTime(2024, 1, 1).toIso8601String());

        // Act
        final result = dataSource.currentUser;

        // Assert
        expect(result, isNotNull);
        expect(result!.id, 'user-123');
        expect(result.email, 'test@example.com');
      });

      test('debe retornar null cuando no hay usuario autenticado', () {
        // Arrange
        when(mockAuth.currentUser).thenReturn(null);

        // Act
        final result = dataSource.currentUser;

        // Assert
        expect(result, isNull);
      });
    });

    group('validateSession (sesión vencida)', () {
      test('con el access token vencido retorna true sin llamar getUser',
          () async {
        String b64(String v) =>
            base64Url.encode(utf8.encode(v)).replaceAll('=', '');
        final expiredJwt =
            '${b64('{"alg":"HS256","typ":"JWT"}')}.${b64('{"exp":1}')}.sig';
        final user = User.fromJson({
          'id': 'user-123',
          'aud': 'authenticated',
          'created_at': '2024-01-01T00:00:00Z',
          'app_metadata': <String, dynamic>{},
          'user_metadata': <String, dynamic>{},
        })!;
        when(mockAuth.currentSession).thenReturn(Session(
          accessToken: expiredJwt,
          tokenType: 'bearer',
          user: user,
        ));

        expect(await dataSource.validateSession(), isTrue);
        verifyNever(mockAuth.getUser());
      });
    });

    group('signOut', () {
      test('debe completarse exitosamente cuando sign out funciona', () async {
        // Arrange
        when(mockAuth.currentUser).thenReturn(mockUser);
        when(mockUser.id).thenReturn('user-123');
        when(mockAuth.signOut()).thenAnswer((_) async => {});

        // Act
        await dataSource.signOut();

        // Assert
        verify(mockAuth.signOut()).called(1);
        verify(mockLogger.i('Signing out', context: {'userId': 'user-123'})).called(1);
        verify(mockLogger.i('Sign out successful', context: {'userId': 'user-123'})).called(1);
      });

      test('debe lanzar AuthException cuando sign out falla', () async {
        // Arrange
        when(mockAuth.currentUser).thenReturn(mockUser);
        when(mockUser.id).thenReturn('user-123');
        when(mockAuth.signOut()).thenThrow(const AuthException('Sign out failed'));

        // Act & Assert
        expect(
          () => dataSource.signOut(),
          throwsA(isA<AuthException>()),
        );
      });

      test('debe logear cuando sign out es exitoso con usuario null', () async {
        // Arrange
        when(mockAuth.currentUser).thenReturn(null);
        when(mockAuth.signOut()).thenAnswer((_) async => {});

        // Act
        await dataSource.signOut();

        // Assert
        verify(mockLogger.i('Signing out', context: {'userId': null})).called(1);
      });
    });

    group('resetPassword', () {
      const tEmail = 'test@example.com';

      test('debe completarse exitosamente cuando email es enviado', () async {
        // Arrange
        when(mockAuth.signInWithOtp(
          email: tEmail,
          shouldCreateUser: false,
        )).thenAnswer((_) async => AuthResponse(user: null, session: null));

        // Act
        await dataSource.resetPassword(email: tEmail);

        // Assert
        verify(mockAuth.signInWithOtp(
          email: tEmail,
          shouldCreateUser: false,
        )).called(1);
        verify(mockLogger.i('Sending password reset OTP', context: {'email': tEmail})).called(1);
        verify(mockLogger.i('Password reset OTP sent', context: {'email': tEmail})).called(1);
      });

      test('debe lanzar AuthException cuando email no existe', () async {
        // Arrange
        when(mockAuth.signInWithOtp(
          email: anyNamed('email'),
          shouldCreateUser: anyNamed('shouldCreateUser'),
        )).thenThrow(const AuthException('User not found'));

        // Act & Assert
        expect(
          () => dataSource.resetPassword(email: tEmail),
          throwsA(isA<AuthException>()),
        );
      });

      test('debe logear warning cuando hay AuthException', () async {
        // Arrange
        const exception = AuthException('User not found', statusCode: '404');

        when(mockAuth.signInWithOtp(
          email: anyNamed('email'),
          shouldCreateUser: anyNamed('shouldCreateUser'),
        )).thenThrow(exception);

        // Act & Assert
        await expectLater(
          dataSource.resetPassword(email: tEmail),
          throwsA(same(exception)),
        );

        verify(mockLogger.w(
          'Reset password failed (AuthException)',
          error: exception,
          context: {'code': '404', 'message': 'User not found'},
        )).called(1);
      });
      test('relanza y loguea error si falla con una excepción genérica',
          () async {
        final exception = Exception('Network error');
        when(mockAuth.signInWithOtp(
          email: anyNamed('email'),
          shouldCreateUser: anyNamed('shouldCreateUser'),
        )).thenThrow(exception);

        await expectLater(
          dataSource.resetPassword(email: tEmail),
          throwsA(same(exception)),
        );
        verify(mockLogger.e(
          'Reset password failed',
          error: exception,
          stackTrace: anyNamed('stackTrace'),
          context: {'email': tEmail},
        )).called(1);
      });
    });

    group('updatePassword', () {
      const tNewPassword = 'NewTest123!@';

      test('debe lanzar AuthException cuando password es débil', () async {
        // Arrange
        when(mockAuth.currentUser).thenReturn(mockUser);
        when(mockUser.id).thenReturn('user-123');
        when(mockAuth.updateUser(any)).thenThrow(const AuthException('Password too weak'));

        // Act & Assert
        expect(
          () => dataSource.updatePassword(newPassword: tNewPassword),
          throwsA(isA<AuthException>()),
        );
      });

      test('debe logear intento de actualización', () async {
        // Arrange
        when(mockAuth.currentUser).thenReturn(mockUser);
        when(mockUser.id).thenReturn('user-123');
        when(mockAuth.updateUser(any)).thenThrow(const AuthException('Password too weak'));

        // Act & Assert
        await expectLater(
          dataSource.updatePassword(newPassword: tNewPassword),
          throwsA(isA<AuthException>()),
        );

        verify(mockLogger.i('Updating password', context: {'userId': 'user-123'})).called(1);
      });
      test('envía el nuevo password en UserAttributes', () async {
        when(mockAuth.currentUser).thenReturn(mockUser);
        when(mockUser.id).thenReturn('user-123');
        when(mockAuth.updateUser(any))
            .thenAnswer((_) async => UserResponse.fromJson({}));

        await dataSource.updatePassword(newPassword: tNewPassword);

        final attrs =
            verify(mockAuth.updateUser(captureAny)).captured.single as UserAttributes;
        expect(attrs.password, tNewPassword);
        verify(mockLogger.i('Password updated successfully',
                context: {'userId': 'user-123'}))
            .called(1);
      });

      test('relanza y loguea error si falla con una excepción genérica',
          () async {
        final exception = Exception('Network error');
        when(mockAuth.currentUser).thenReturn(null);
        when(mockAuth.updateUser(any)).thenThrow(exception);

        await expectLater(
          dataSource.updatePassword(newPassword: tNewPassword),
          throwsA(same(exception)),
        );
        verify(mockLogger.e('Update password failed',
                error: exception, stackTrace: anyNamed('stackTrace')))
            .called(1);
      });
    });

    group('signUpWithEmailOTP', () {
      const tEmail = 'test@example.com';
      const tPassword = 'Test123!@';

      test('debe completarse exitosamente cuando sign up funciona', () async {
        // Arrange
        when(mockAuth.signUp(
          email: tEmail,
          password: tPassword,
        )).thenAnswer((_) async => AuthResponse(user: mockUser, session: null));

        // Act
        await dataSource.signUpWithEmailOTP(email: tEmail, password: tPassword);

        // Assert
        verify(mockAuth.signUp(email: tEmail, password: tPassword)).called(1);
        verify(mockLogger.i('Signing up with email OTP', context: {'email': tEmail})).called(1);
        verify(mockLogger.i('Sign up OTP sent', context: {'email': tEmail})).called(1);
      });

      test('debe lanzar AuthException cuando email ya está registrado', () async {
        // Arrange
        when(mockAuth.signUp(
          email: anyNamed('email'),
          password: anyNamed('password'),
        )).thenThrow(const AuthException('Email already registered'));

        // Act & Assert
        expect(
          () => dataSource.signUpWithEmailOTP(email: tEmail, password: tPassword),
          throwsA(isA<AuthException>()),
        );
      });

      test('debe logear error cuando falla', () async {
        // Arrange
        final exception = Exception('Network error');

        when(mockAuth.signUp(
          email: anyNamed('email'),
          password: anyNamed('password'),
        )).thenThrow(exception);

        // Act & Assert
        await expectLater(
          dataSource.signUpWithEmailOTP(email: tEmail, password: tPassword),
          throwsA(same(exception)),
        );

        verify(mockLogger.e(
          'Sign up OTP failed',
          error: exception,
          stackTrace: anyNamed('stackTrace'),
          context: {'email': tEmail},
        )).called(1);
      });
    });

    group('resendOTP', () {
      const tEmail = 'test@example.com';

      test('debe completarse exitosamente cuando OTP es reenviado', () async {
        // Arrange
        when(mockAuth.resend(
          type: OtpType.signup,
          email: tEmail,
        )).thenAnswer((_) async => ResendResponse());

        // Act
        await dataSource.resendOTP(email: tEmail);

        // Assert
        verify(mockAuth.resend(type: OtpType.signup, email: tEmail)).called(1);
        verify(mockLogger.i('Resending OTP', context: {'email': tEmail})).called(1);
        verify(mockLogger.i('OTP resent successfully', context: {'email': tEmail})).called(1);
      });

      test('debe lanzar AuthException cuando hay demasiadas solicitudes', () async {
        // Arrange
        when(mockAuth.resend(
          type: anyNamed('type'),
          email: anyNamed('email'),
        )).thenThrow(const AuthException('Too many requests'));

        // Act & Assert
        expect(
          () => dataSource.resendOTP(email: tEmail),
          throwsA(isA<AuthException>()),
        );
      });
      test('relanza y loguea error si falla con una excepción genérica',
          () async {
        final exception = Exception('Network error');
        when(mockAuth.resend(
          type: anyNamed('type'),
          email: anyNamed('email'),
        )).thenThrow(exception);

        await expectLater(
          dataSource.resendOTP(email: tEmail),
          throwsA(same(exception)),
        );
        verify(mockLogger.e(
          'Resend OTP failed',
          error: exception,
          stackTrace: anyNamed('stackTrace'),
          context: {'email': tEmail},
        )).called(1);
      });
    });

    group('resendVerificationEmail', () {
      test('debe completarse exitosamente cuando email es reenviado', () async {
        // Arrange
        when(mockAuth.currentUser).thenReturn(mockUser);
        when(mockUser.email).thenReturn('test@example.com');
        when(mockAuth.resend(
          type: OtpType.signup,
          email: 'test@example.com',
        )).thenAnswer((_) async => ResendResponse());

        // Act
        await dataSource.resendVerificationEmail();

        // Assert
        verify(mockAuth.resend(type: OtpType.signup, email: 'test@example.com')).called(1);
      });

      test('debe lanzar Exception cuando no hay usuario autenticado', () async {
        // Arrange
        when(mockAuth.currentUser).thenReturn(null);

        // Act & Assert
        expect(
          () => dataSource.resendVerificationEmail(),
          throwsA(isA<Exception>()),
        );
      });

      test('debe lanzar Exception cuando usuario no tiene email', () async {
        // Arrange
        when(mockAuth.currentUser).thenReturn(mockUser);
        when(mockUser.email).thenReturn(null);

        // Act & Assert
        expect(
          () => dataSource.resendVerificationEmail(),
          throwsA(isA<Exception>()),
        );
      });
      test('relanza AuthException y loguea warning con el código', () async {
        const exception = AuthException('Rate limit', statusCode: '429');
        when(mockAuth.currentUser).thenReturn(mockUser);
        when(mockUser.email).thenReturn('test@example.com');
        when(mockAuth.resend(
          type: anyNamed('type'),
          email: anyNamed('email'),
        )).thenThrow(exception);

        await expectLater(
          dataSource.resendVerificationEmail(),
          throwsA(same(exception)),
        );
        verify(mockLogger.w(
          'Resend verification email failed (AuthException)',
          error: exception,
          context: {'code': '429', 'message': 'Rate limit'},
        )).called(1);
      });
    });

    group('Logging', () {
      test('debe logear errores genéricos correctamente', () async {
        // Arrange
        final exception = Exception('Generic error');

        when(mockAuth.currentUser).thenReturn(mockUser);
        when(mockUser.id).thenReturn('user-123');
        when(mockAuth.signOut()).thenThrow(exception);

        // Act & Assert
        await expectLater(dataSource.signOut(), throwsA(same(exception)));

        verify(mockLogger.e(
          'Sign out failed',
          error: exception,
          stackTrace: anyNamed('stackTrace'),
        )).called(1);
      });

      test('debe logear context cuando hay datos relevantes', () async {
        // Arrange
        when(mockAuth.signInWithOtp(
          email: anyNamed('email'),
          shouldCreateUser: anyNamed('shouldCreateUser'),
        )).thenAnswer((_) async => AuthResponse(user: null, session: null));

        // Act
        await dataSource.resetPassword(email: 'test@example.com');

        // Assert
        verify(mockLogger.i(
          'Sending password reset OTP',
          context: {'email': 'test@example.com'},
        )).called(1);
      });
    });
  });

  // Cliente Supabase real sobre HTTP falso: cubre GoTrue (auth), PostgREST y RPC.
  group('SupabaseAuthDataSourceImpl con cliente real (fake HTTP)', () {
    const tUserId = 'user-123';
    const tEmail = 'test@example.com';
    final userJson = <String, dynamic>{
      'id': tUserId,
      'aud': 'authenticated',
      'email': tEmail,
      'email_confirmed_at': '2024-01-01T00:00:00Z',
      'created_at': '2024-01-01T00:00:00Z',
      'app_metadata': <String, dynamic>{},
      'user_metadata': <String, dynamic>{},
    };
    final sessionJson = <String, dynamic>{
      'access_token': 'access-token',
      'token_type': 'bearer',
      'expires_in': 3600,
      'refresh_token': 'refresh-token',
      'user': userJson,
    };
    final profileRow = <String, dynamic>{
      'id': tUserId,
      'username': 'chismoso',
      'display_name': 'Chismoso Mayor',
      'avatar_url': 'https://cdn.test/a.jpg',
      'bio': 'bio',
      'profile_completed': true,
      'updated_at': '2024-02-01T00:00:00Z',
    };

    late FakeSupabaseHttp fake;
    late SupabaseAuthDataSourceImpl ds;
    late MockAppLogger logger;
    // Respuestas por ruta (método + path). Se pueden sobreescribir en cada test.
    late Map<String, http.Response Function(http.Request)> routes;

    http.Response json(http.Request req, Object? body, {int status = 200}) =>
        FakeSupabaseHttp.jsonResponse(req, body, status: status);

    http.Response authError(http.Request req) => json(
          req,
          {'code': 'invalid_credentials', 'msg': 'Invalid login credentials'},
          status: 400,
        );

    http.Response pgError(http.Request req) => json(
          req,
          {'message': 'boom', 'code': '23505', 'details': null, 'hint': null},
          status: 400,
        );

    List<http.Request> requestsTo(String method, String path) => fake.requests
        .where((r) => r.method == method && r.url.path == path)
        .toList();

    setUp(() {
      logger = MockAppLogger();
      routes = {
        'POST /auth/v1/token': (req) => json(req, sessionJson),
        'POST /auth/v1/verify': (req) => json(req, sessionJson),
        'GET /rest/v1/profiles': (req) => json(req, [profileRow]),
        'PATCH /rest/v1/profiles': (req) => json(req, null),
        'POST /rest/v1/rpc/check_email_exists_and_confirmed': (req) =>
            json(req, true),
      };
      fake = FakeSupabaseHttp((req) {
        final route = routes['${req.method} ${req.url.path}'];
        if (route == null) {
          throw StateError('Ruta no esperada: ${req.method} ${req.url}');
        }
        return route(req);
      });
      ds = SupabaseAuthDataSourceImpl(fake.client, logger);
    });

    tearDown(() => fake.client.dispose());

    Future<UserModel> signIn() =>
        ds.signInWithEmail(email: tEmail, password: 'Secret123!');

    group('signInWithEmail', () {
      test('autentica, carga el profile y deja la sesión activa', () async {
        final user = await signIn();

        final tokenReq = requestsTo('POST', '/auth/v1/token').single;
        expect(tokenReq.url.queryParameters['grant_type'], 'password');
        expect(jsonDecode(tokenReq.body),
            containsPair('email', tEmail));
        final profileReq = requestsTo('GET', '/rest/v1/profiles').single;
        expect(profileReq.url.queryParameters['id'], 'eq.$tUserId');

        expect(user.id, tUserId);
        expect(user.email, tEmail);
        expect(user.emailVerified, isTrue);
        expect(user.username, 'chismoso');
        expect(user.displayName, 'Chismoso Mayor');
        expect(user.avatarUrl, 'https://cdn.test/a.jpg');
        expect(user.bio, 'bio');
        expect(user.profileCompleted, isTrue);
        expect(user.updatedAt, DateTime.parse('2024-02-01T00:00:00Z'));
        expect(ds.currentUser!.id, tUserId);
        verify(logger.i('Sign in successful', context: {'userId': tUserId}))
            .called(1);
      });

      test('retorna el user sin profile si la consulta de profile falla',
          () async {
        routes['GET /rest/v1/profiles'] = pgError;

        final user = await signIn();

        expect(user.id, tUserId);
        expect(user.username, isNull);
        expect(user.profileCompleted, isFalse);
        verify(logger.w('Failed to get profile data',
                error: anyNamed('error'), context: {'userId': tUserId}))
            .called(1);
      });

      test('lanza Exception si la respuesta no trae user', () async {
        routes['POST /auth/v1/token'] = (req) => json(req, {});

        await expectLater(
          signIn(),
          throwsA(isA<Exception>().having((e) => e.toString(), 'message',
              contains('Sign in returned null user'))),
        );
        expect(requestsTo('GET', '/rest/v1/profiles'), isEmpty);
        verify(logger.e('Sign in failed',
                error: anyNamed('error'),
                stackTrace: anyNamed('stackTrace'),
                context: {'email': tEmail}))
            .called(1);
      });

      test('relanza AuthException con credenciales inválidas', () async {
        routes['POST /auth/v1/token'] = authError;

        await expectLater(signIn(), throwsA(isA<AuthException>()));
        expect(ds.currentUser, isNull);
        verify(logger.w('Sign in failed (AuthException)',
                error: anyNamed('error'), context: anyNamed('context')))
            .called(1);
      });
    });

    group('authStateChanges', () {
      test('emite el user con profile al iniciar sesión', () async {
        final emitted = <UserModel?>[];
        final sub = ds.authStateChanges.listen(emitted.add);
        addTearDown(sub.cancel);

        await signIn();
        await pumpEventQueue();

        final signedIn = emitted.whereType<UserModel>().last;
        expect(signedIn.id, tUserId);
        expect(signedIn.username, 'chismoso');
      });

      test('emite null al cerrar sesión', () async {
        routes['POST /auth/v1/logout'] = (req) => http.Response('', 204, request: req);
        final emitted = <UserModel?>[];
        final sub = ds.authStateChanges.listen(emitted.add);
        addTearDown(sub.cancel);
        await signIn();
        await pumpEventQueue();

        await ds.signOut();
        await pumpEventQueue();

        expect(requestsTo('POST', '/auth/v1/logout'), hasLength(1));
        expect(emitted.last, isNull);
        expect(emitted.whereType<UserModel>(), isNotEmpty);
        expect(ds.currentUser, isNull);
      });

      test('emite el user sin profile si el profile no se puede parsear',
          () async {
        routes['GET /rest/v1/profiles'] =
            (req) => json(req, [{...profileRow, 'updated_at': 'no-es-fecha'}]);
        await expectLater(signIn(), throwsA(isA<FormatException>()));

        final user = await ds.authStateChanges.firstWhere((u) => u != null);

        expect(user!.id, tUserId);
        expect(user.username, isNull);
        verify(logger.w('Error loading profile in auth state change',
                error: anyNamed('error'), context: {'userId': tUserId}))
            .called(1);
      });
    });

    group('getCurrentUser', () {
      test('retorna null sin sesión y no consulta profiles', () async {
        expect(await ds.getCurrentUser(), isNull);
        expect(fake.requests, isEmpty);
      });

      test('retorna el user con el profile recién consultado', () async {
        await signIn();
        routes['GET /rest/v1/profiles'] =
            (req) => json(req, [{...profileRow, 'username': 'nuevo'}]);

        final user = await ds.getCurrentUser();

        expect(user!.id, tUserId);
        expect(user.username, 'nuevo');
        expect(requestsTo('GET', '/rest/v1/profiles'), hasLength(2));
      });

      test('relanza y loguea si el profile no se puede parsear', () async {
        await signIn();
        routes['GET /rest/v1/profiles'] =
            (req) => json(req, [{...profileRow, 'updated_at': 'no-es-fecha'}]);

        await expectLater(
            ds.getCurrentUser(), throwsA(isA<FormatException>()));
        verify(logger.e('Get current user failed',
                error: anyNamed('error'), stackTrace: anyNamed('stackTrace')))
            .called(1);
      });
    });

    group('updateProfile (Edge Function update-profile)', () {
      const fnPath = '/functions/v1/update-profile';

      test('lanza AuthFailure sin usuario autenticado y no llama a la API',
          () async {
        await expectLater(
          ds.updateProfile(username: 'x'),
          throwsA(isA<AuthFailure>().having(
              (f) => f.code, 'code', ErrorCode.userNotAuthenticated)),
        );
        expect(fake.requests, isEmpty);
      });

      test('envía los campos no nulos y retorna el profile de la respuesta',
          () async {
        // Arrange
        await signIn();
        routes['POST $fnPath'] = (req) => json(req, {
              'profile': {
                ...profileRow,
                'username': 'nuevo',
                'display_name': 'Nuevo Nombre',
                'bio': 'nueva bio',
              },
            });

        // Act
        final user = await ds.updateProfile(
          username: 'nuevo',
          displayName: 'Nuevo Nombre',
          bio: 'nueva bio',
        );

        // Assert
        final call = requestsTo('POST', fnPath).single;
        expect(jsonDecode(call.body), {
          'username': 'nuevo',
          'display_name': 'Nuevo Nombre',
          'bio': 'nueva bio',
        });
        expect(requestsTo('PATCH', '/rest/v1/profiles'), isEmpty);
        expect(user.id, tUserId);
        expect(user.username, 'nuevo');
        expect(user.displayName, 'Nuevo Nombre');
        expect(user.bio, 'nueva bio');
        verify(logger.i('Profile updated successfully',
                context: {'userId': tUserId}))
            .called(1);
      });

      test('envía la foto en base64 y no la incluye en el log', () async {
        // Arrange
        await signIn();
        final avatar = Uint8List.fromList([255, 216, 255, 0, 1]);
        routes['POST $fnPath'] =
            (req) => json(req, {'profile': profileRow});

        // Act
        await ds.updateProfile(avatar: avatar);

        // Assert
        final body = jsonDecode(requestsTo('POST', fnPath).single.body);
        expect(body, {'avatar_base64': base64Encode(avatar)});
        verify(logger.i('Updating profile', context: {
          'userId': tUserId,
          'fields': <String>[],
          'hasAvatar': true,
        })).called(1);
      });

      test('removeAvatar envía remove_avatar y "" borra nombre y bio',
          () async {
        // Arrange
        await signIn();
        routes['POST $fnPath'] =
            (req) => json(req, {'profile': profileRow});

        // Act
        await ds.updateProfile(displayName: '', bio: '', removeAvatar: true);

        // Assert
        final body = jsonDecode(requestsTo('POST', fnPath).single.body);
        expect(body, {'display_name': '', 'bio': '', 'remove_avatar': true});
      });

      test('respuesta no 2xx (FunctionException) se traduce a Failure',
          () async {
        // Arrange
        await signIn();
        routes['POST $fnPath'] = (req) =>
            json(req, {'error': 'username_taken'}, status: 409);

        // Act & Assert
        await expectLater(
          ds.updateProfile(username: 'tomado'),
          throwsA(isA<DataFailure>().having(
              (f) => f.code, 'code', ErrorCode.usernameAlreadyTaken)),
        );
        verify(logger.w('Update profile rejected', context: {
          'status': 409,
          'code': 'usernameAlreadyTaken',
        })).called(1);
      });

      test('200 sin "profile" en la respuesta lanza ServerFailure', () async {
        // Arrange
        await signIn();
        routes['POST $fnPath'] = (req) => json(req, {'ok': true});

        // Act & Assert
        await expectLater(
          ds.updateProfile(bio: 'x'),
          throwsA(isA<ServerFailure>()
              .having((f) => f.code, 'code', ErrorCode.serverError)),
        );
      });
    });

    group('isUsernameAvailable', () {
      test('retorna true si ningún profile tiene ese username', () async {
        routes['GET /rest/v1/profiles'] = (req) => json(req, []);

        expect(await ds.isUsernameAvailable('Libre'), isTrue);

        final req = fake.lastRequest;
        expect(req.url.queryParameters['select'], 'id');
        expect(req.url.queryParameters['username'], 'ilike.Libre');
      });

      test('retorna false si el username ya existe', () async {
        routes['GET /rest/v1/profiles'] =
            (req) => json(req, [{'id': 'otro'}]);

        expect(await ds.isUsernameAvailable('tomado'), isFalse);
      });

      test('relanza y loguea si la consulta falla', () async {
        routes['GET /rest/v1/profiles'] = pgError;

        await expectLater(ds.isUsernameAvailable('x'),
            throwsA(isA<PostgrestException>()));
        verify(logger.e('Check username availability failed',
                error: anyNamed('error'),
                stackTrace: anyNamed('stackTrace'),
                context: {'username': 'x'}))
            .called(1);
      });
    });

    group('verifyOTP', () {
      test('verifica OTP de signup y retorna el user con profile', () async {
        final user = await ds.verifyOTP(email: tEmail, token: '123456');

        final body = jsonDecode(
            requestsTo('POST', '/auth/v1/verify').single.body) as Map;
        expect(body['type'], 'signup');
        expect(body['email'], tEmail);
        expect(body['token'], '123456');
        expect(user.id, tUserId);
        expect(user.username, 'chismoso');
        expect(ds.currentUser!.id, tUserId);
      });

      test('usa el tipo recovery cuando es reset de password', () async {
        await ds.verifyOTP(
            email: tEmail, token: '123456', isPasswordReset: true);

        final body = jsonDecode(
            requestsTo('POST', '/auth/v1/verify').single.body) as Map;
        expect(body['type'], 'recovery');
      });

      test('lanza Exception si la respuesta no trae user', () async {
        routes['POST /auth/v1/verify'] = (req) => json(req, {});

        await expectLater(
          ds.verifyOTP(email: tEmail, token: '123456'),
          throwsA(isA<Exception>().having((e) => e.toString(), 'message',
              contains('Verify OTP returned null user'))),
        );
        verify(logger.e('Verify OTP failed',
                error: anyNamed('error'),
                stackTrace: anyNamed('stackTrace'),
                context: {'email': tEmail}))
            .called(1);
      });

      test('relanza AuthException con OTP inválido', () async {
        routes['POST /auth/v1/verify'] = authError;

        await expectLater(ds.verifyOTP(email: tEmail, token: '000000'),
            throwsA(isA<AuthException>()));
        verify(logger.w('Verify OTP failed (AuthException)',
                error: anyNamed('error'), context: anyNamed('context')))
            .called(1);
      });
    });

    group('checkEmailExistsAndConfirmed', () {
      test('llama al RPC con el email y retorna el bool', () async {
        expect(await ds.checkEmailExistsAndConfirmed(tEmail), isTrue);
        expect(fake.lastBody, {'email_to_check': tEmail});

        routes['POST /rest/v1/rpc/check_email_exists_and_confirmed'] =
            (req) => json(req, false);
        expect(await ds.checkEmailExistsAndConfirmed(tEmail), isFalse);
      });

      test('relanza PostgrestException si el RPC falla', () async {
        routes['POST /rest/v1/rpc/check_email_exists_and_confirmed'] =
            pgError;

        await expectLater(ds.checkEmailExistsAndConfirmed(tEmail),
            throwsA(isA<PostgrestException>()));
        verify(logger.w('Check email exists failed (PostgrestException)',
                error: anyNamed('error'), context: anyNamed('context')))
            .called(1);
      });

      test('relanza y loguea si el RPC retorna null', () async {
        routes['POST /rest/v1/rpc/check_email_exists_and_confirmed'] =
            (req) => http.Response('null', 200,
                headers: {'content-type': 'application/json'}, request: req);

        await expectLater(ds.checkEmailExistsAndConfirmed(tEmail),
            throwsA(isA<TypeError>()));
        verify(logger.e('Check email exists failed',
                error: anyNamed('error'),
                stackTrace: anyNamed('stackTrace'),
                context: {'email': tEmail}))
            .called(1);
      });
    });
    group('validateSession', () {
      http.Response userError(http.Request req, int status, String? code) =>
          json(req, {
            if (code != null) 'error_code': code,
            'msg': 'rejected',
          }, status: status);

      test('sin sesión retorna true sin consultar al servidor', () async {
        expect(await ds.validateSession(), isTrue);
        expect(requestsTo('GET', '/auth/v1/user'), isEmpty);
      });

      test('retorna true cuando el servidor confirma el usuario', () async {
        await signIn();
        routes['GET /auth/v1/user'] = (req) => json(req, userJson);

        expect(await ds.validateSession(), isTrue);
        final req = requestsTo('GET', '/auth/v1/user').single;
        expect(req.headers['Authorization'], 'Bearer access-token');
      });

      for (final code in [
        'user_not_found',
        'session_not_found',
        'user_banned',
        'bad_jwt',
      ]) {
        test('retorna false y loguea warning con $code', () async {
          await signIn();
          routes['GET /auth/v1/user'] = (req) => userError(req, 403, code);

          expect(await ds.validateSession(), isFalse);
          verify(logger.w('Session rejected by server',
                  context: {'code': code, 'statusCode': '403'}))
              .called(1);
        });
      }

      test('servidor sin códigos: 401 cuenta como rechazo', () async {
        await signIn();
        routes['GET /auth/v1/user'] = (req) => userError(req, 401, null);

        expect(await ds.validateSession(), isFalse);
      });

      test('otro código de error no es concluyente: relanza', () async {
        await signIn();
        routes['GET /auth/v1/user'] =
            (req) => userError(req, 429, 'over_request_rate_limit');

        await expectLater(
            ds.validateSession(), throwsA(isA<AuthApiException>()));
      });

      test('5xx no es concluyente: relanza', () async {
        await signIn();
        routes['GET /auth/v1/user'] = (req) => userError(req, 503, null);

        await expectLater(ds.validateSession(),
            throwsA(isA<AuthRetryableFetchException>()));
      });

      test('error de red no es concluyente: relanza', () async {
        await signIn();
        routes['GET /auth/v1/user'] =
            (req) => throw http.ClientException('sin red');

        await expectLater(ds.validateSession(), throwsA(isA<AuthException>()));
      });
    });
  });

  group('SupabaseAuthDataSourceImpl.profileFunctionFailure', () {
    Failure map(int status, dynamic data) =>
        SupabaseAuthDataSourceImpl.profileFunctionFailure(status, data);

    test('401 → AuthFailure unauthorized', () {
      final failure = map(401, {'error': 'unauthorized'});

      expect(failure, isA<AuthFailure>());
      expect(failure.code, ErrorCode.unauthorized);
      expect(failure.technicalMessage, 'update-profile 401: unauthorized');
    });

    test('403 account_restricted → AccountRestrictedFailure con fecha', () {
      final failure = map(403, {
        'code': 'account_restricted',
        'state': 'restricted',
        'restricted_until': '2026-12-01T10:00:00Z',
      });

      expect(failure, isA<AccountRestrictedFailure>());
      expect(failure.code, ErrorCode.accountRestricted);
      expect((failure as AccountRestrictedFailure).restrictedUntil,
          DateTime.utc(2026, 12, 1, 10));
    });

    test('403 account_restricted suspended → accountSuspended', () {
      final failure = map(403, {'code': 'account_restricted', 'state': 'suspended'});

      expect(failure.code, ErrorCode.accountSuspended);
    });

    test('403 sin account_restricted → ServerFailure serverError', () {
      final failure = map(403, {'error': 'forbidden'});

      expect(failure, isA<ServerFailure>());
      expect(failure.code, ErrorCode.serverError);
    });

    test('409 username_cooldown → UsernameCooldownFailure con available_at', () {
      final failure = map(409, {
        'error': 'username_cooldown',
        'available_at': '2026-12-20T00:00:00Z',
      });

      expect(failure, isA<UsernameCooldownFailure>());
      expect(failure.code, ErrorCode.usernameChangeCooldown);
      expect((failure as UsernameCooldownFailure).availableAt,
          DateTime.utc(2026, 12, 20));
    });

    test('409 username_cooldown sin fecha válida → availableAt null', () {
      final noDate = map(409, {'error': 'username_cooldown'});
      final badDate = map(409, {'error': 'username_cooldown', 'available_at': 'mañana'});
      final notString = map(409, {'error': 'username_cooldown', 'available_at': 123});

      expect((noDate as UsernameCooldownFailure).availableAt, isNull);
      expect((badDate as UsernameCooldownFailure).availableAt, isNull);
      expect((notString as UsernameCooldownFailure).availableAt, isNull);
    });

    test('409 username_taken → DataFailure usernameAlreadyTaken', () {
      final failure = map(409, {'error': 'username_taken'});

      expect(failure, isA<DataFailure>());
      expect(failure.code, ErrorCode.usernameAlreadyTaken);
    });

    test('409 con otro error → ServerFailure serverError', () {
      final failure = map(409, {'error': 'conflict'});

      expect(failure, isA<ServerFailure>());
      expect(failure.code, ErrorCode.serverError);
    });

    test('429 → RateLimitFailure con retry_after', () {
      final failure = map(429, {'error': 'rate_limited', 'retry_after': 120});

      expect(failure, isA<RateLimitFailure>());
      expect(failure.code, ErrorCode.rateLimitExceeded);
      expect((failure as RateLimitFailure).retryAfter, 120);
    });

    test('429 sin retry_after → retryAfter null', () {
      final failure = map(429, {'error': 'rate_limited'});

      expect((failure as RateLimitFailure).retryAfter, isNull);
    });

    test('400 content_rejected → ValidationFailure moderationRejected', () {
      final failure = map(400, {'error': 'content_rejected'});

      expect(failure, isA<ValidationFailure>());
      expect(failure.code, ErrorCode.moderationRejected);
    });

    test('400 invalid_image → ValidationFailure invalidImage', () {
      final failure = map(400, {'error': 'invalid_image'});

      expect(failure, isA<ValidationFailure>());
      expect(failure.code, ErrorCode.invalidImage);
    });

    test('400 "username is reserved" → ValidationFailure usernameReserved', () {
      final failure = map(400, {
        'error': 'validation_error',
        'details': 'username is reserved',
      });

      expect(failure, isA<ValidationFailure>());
      expect(failure.code, ErrorCode.usernameReserved);
    });

    test('otro 400 → ValidationFailure validationError con details', () {
      final failure = map(400, {
        'error': 'validation_error',
        'details': 'bio too long',
      });

      expect(failure, isA<ValidationFailure>());
      expect(failure.code, ErrorCode.validationError);
      expect(failure.technicalMessage,
          'update-profile 400: validation_error (bio too long)');
    });

    test('503 moderation_unavailable → ServerFailure moderationUnavailable', () {
      final failure = map(503, {'error': 'moderation_unavailable'});

      expect(failure, isA<ServerFailure>());
      expect(failure.code, ErrorCode.moderationUnavailable);
    });

    test('otro 503 → ServerFailure serviceUnavailable', () {
      final failure = map(503, {'error': 'storage_down'});

      expect(failure, isA<ServerFailure>());
      expect(failure.code, ErrorCode.serviceUnavailable);
    });

    test('500 → ServerFailure serverError', () {
      final failure = map(500, {'error': 'internal'});

      expect(failure, isA<ServerFailure>());
      expect(failure.code, ErrorCode.serverError);
    });

    test('respuesta que no es Map usa el cuerpo en el mensaje técnico', () {
      final failure = map(502, 'Bad Gateway');

      expect(failure, isA<ServerFailure>());
      expect(failure.code, ErrorCode.serverError);
      expect(failure.technicalMessage, 'update-profile 502: Bad Gateway');
    });
  });
}
