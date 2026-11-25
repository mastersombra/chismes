import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide ErrorCode;
import 'package:chismes/core/error/error_codes.dart';
import 'package:chismes/core/error/failure.dart';
import 'package:chismes/core/logging/logging.dart';
import 'package:chismes/features/profile/data/datasources/profile_remote_datasource.dart';
import 'package:chismes/features/profile/data/models/profile_settings_model.dart';

import '../../../../helpers/fake_supabase_http.dart';
import 'profile_remote_datasource_test.mocks.dart';

@GenerateMocks([SupabaseClient, AppLogger, GoTrueClient])
void main() {
  late ProfileRemoteDataSource dataSource;
  late MockSupabaseClient mockSupabase;
  late MockAppLogger mockLogger;
  late MockGoTrueClient mockAuth;

  setUp(() {
    mockSupabase = MockSupabaseClient();
    mockLogger = MockAppLogger();
    mockAuth = MockGoTrueClient();

    when(mockSupabase.auth).thenReturn(mockAuth);

    dataSource = ProfileRemoteDataSource(mockSupabase, mockLogger);
  });

  group('ProfileRemoteDataSource', () {
    const testUserId = 'test-user-123';

    group('getUserStats', () {
      late FakeSupabaseHttp fake;

      setUp(() {
        fake = FakeSupabaseHttp();
        dataSource = ProfileRemoteDataSource(fake.client, mockLogger);
      });

      test('cuenta gossips no eliminados del usuario', () async {
        fake.respondJson([
          {'id': 'g1'},
          {'id': 'g2'},
          {'id': 'g3'},
        ]);

        final stats = await dataSource.getUserStats(testUserId);

        final request = fake.requests.first;
        final params = request.url.queryParameters;
        expect(request.url.path, '/rest/v1/public_gossips');
        expect(params['select'], 'id');
        expect(params['created_by'], 'eq.$testUserId');
        expect(params['status'], 'neq.deleted');
        expect(stats.gossipsCount, 3);
        expect(stats.commentsCount, 0);
        expect(stats.followersCount, 0);
        expect(stats.followingCount, 0);
        expect(DateTime.tryParse(stats.lastActivityAt!), isNotNull);
      });

      test('seguidores y seguidos vienen de get_user_profile del propio usuario',
          () async {
        fake.handler = (req) => FakeSupabaseHttp.jsonResponse(
              req,
              req.url.path == '/rest/v1/rpc/get_user_profile'
                  ? {'id': testUserId, 'followers_count': 12, 'following_count': 7}
                  : [
                      {'id': 'g1'},
                    ],
            );

        final stats = await dataSource.getUserStats(testUserId);

        final rpc = fake.requests
            .singleWhere((r) => r.url.path == '/rest/v1/rpc/get_user_profile');
        expect(jsonDecode(rpc.body), {'p_user': testUserId});
        expect(stats.gossipsCount, 1);
        expect(stats.followersCount, 12);
        expect(stats.followingCount, 7);
      });

      test('si get_user_profile falla, contadores en 0 con aviso (no rompe el perfil)',
          () async {
        fake.handler = (req) => req.url.path == '/rest/v1/rpc/get_user_profile'
            ? FakeSupabaseHttp.jsonResponse(
                req,
                {'message': 'boom', 'code': 'XX000', 'details': null, 'hint': null},
                status: 500,
              )
            : FakeSupabaseHttp.jsonResponse(req, [
                {'id': 'g1'},
                {'id': 'g2'},
              ]);

        final stats = await dataSource.getUserStats(testUserId);

        expect(stats.gossipsCount, 2);
        expect(stats.followersCount, 0);
        expect(stats.followingCount, 0);
        verify(mockLogger.w('Could not load follow counts', context: anyNamed('context')))
            .called(1);
      });

      test('retorna 0 gossips cuando el usuario no tiene publicaciones', () async {
        fake.respondJson([]);

        final stats = await dataSource.getUserStats(testUserId);

        expect(stats.gossipsCount, 0);
      });

      test('loguea y propaga PostgrestException', () async {
        fake.respondError(400, message: 'permission denied');

        await expectLater(dataSource.getUserStats(testUserId),
            throwsA(isA<PostgrestException>()));
        verify(mockLogger.e(
          'Error fetching user stats',
          error: anyNamed('error'),
          stackTrace: anyNamed('stackTrace'),
          context: {'userId': testUserId},
        )).called(1);
      });
    });

    group('getSettings (user_settings)', () {
      late FakeSupabaseHttp fake;

      setUp(() {
        fake = FakeSupabaseHttp();
        dataSource = ProfileRemoteDataSource(fake.client, mockLogger);
      });

      test('lee la fila del usuario en user_settings', () async {
        // Arrange
        fake.respondJson([
          {
            'user_id': testUserId,
            'notifications_enabled': false,
            'email_notifications': false,
            'push_notifications': true,
            'comments_notifications': false,
            'likes_notifications': true,
            'follow_notifications': false,
            'privacy_level': 'private',
            'show_email': true,
            'show_activity': false,
          }
        ]);

        // Act
        final result = await dataSource.getSettings(testUserId);

        // Assert
        final req = fake.lastRequest;
        expect(req.method, 'GET');
        expect(req.url.path, '/rest/v1/user_settings');
        expect(req.url.queryParameters['user_id'], 'eq.$testUserId');
        expect(req.url.queryParameters['select'], '*');
        expect(result.notificationsEnabled, isFalse);
        expect(result.emailNotifications, isFalse);
        expect(result.pushNotifications, isTrue);
        expect(result.commentsNotifications, isFalse);
        expect(result.likesNotifications, isTrue);
        expect(result.followNotifications, isFalse);
        expect(result.privacyLevel, 'private');
        expect(result.showEmail, isTrue);
        expect(result.showActivity, isFalse);
        verifyNever(mockLogger.w(any, context: anyNamed('context')));
      });

      test('sin fila usa los valores por defecto y avisa en el log', () async {
        // Arrange
        fake.respondJson([]);

        // Act
        final result = await dataSource.getSettings(testUserId);

        // Assert
        expect(result.notificationsEnabled, isTrue);
        expect(result.emailNotifications, isTrue);
        expect(result.pushNotifications, isTrue);
        expect(result.privacyLevel, 'public');
        expect(result.showEmail, isFalse);
        expect(result.showActivity, isTrue);
        verify(mockLogger.w(
          'user_settings row missing, using defaults',
          context: {'userId': testUserId},
        )).called(1);
      });

      test('loguea y propaga PostgrestException', () async {
        // Arrange
        fake.respondError(400, message: 'permission denied');

        // Act & Assert
        await expectLater(dataSource.getSettings(testUserId),
            throwsA(isA<PostgrestException>()));
        verify(mockLogger.e(
          'Error fetching settings',
          error: anyNamed('error'),
          stackTrace: anyNamed('stackTrace'),
          context: {'userId': testUserId},
        )).called(1);
      });
    });

    group('updateSettings (user_settings)', () {
      late FakeSupabaseHttp fake;
      const testSettings = ProfileSettingsModel(
        notificationsEnabled: false,
        emailNotifications: false,
        pushNotifications: true,
        commentsNotifications: true,
        likesNotifications: false,
        followNotifications: true,
        privacyLevel: 'private',
        showEmail: true,
        showActivity: false,
      );

      setUp(() {
        fake = FakeSupabaseHttp();
        dataSource = ProfileRemoteDataSource(fake.client, mockLogger);
      });

      test('hace PATCH de la fila del usuario con todos los campos', () async {
        // Arrange
        fake.respondJson([
          {'user_id': testUserId}
        ]);

        // Act
        await dataSource.updateSettings(testUserId, testSettings);

        // Assert
        final req = fake.lastRequest;
        expect(req.method, 'PATCH');
        expect(req.url.path, '/rest/v1/user_settings');
        expect(req.url.queryParameters['user_id'], 'eq.$testUserId');
        expect(req.url.queryParameters['select'], 'user_id');
        expect(fake.lastBody, testSettings.toJson());
        verify(mockLogger.i('Settings updated', context: {'userId': testUserId}))
            .called(1);
      });

      test('falla con DataFailure notFound si no se actualizó ninguna fila',
          () async {
        // Arrange
        fake.respondJson([]);

        // Act & Assert
        await expectLater(
          dataSource.updateSettings(testUserId, testSettings),
          throwsA(isA<DataFailure>()
              .having((f) => f.code, 'code', ErrorCode.notFound)),
        );
        verify(mockLogger.e(
          'Error updating settings',
          error: anyNamed('error'),
          stackTrace: anyNamed('stackTrace'),
          context: {'userId': testUserId},
        )).called(1);
        verifyNever(mockLogger.i('Settings updated', context: anyNamed('context')));
      });

      test('loguea y propaga PostgrestException', () async {
        // Arrange
        fake.respondError(403, message: 'permission denied');

        // Act & Assert
        await expectLater(dataSource.updateSettings(testUserId, testSettings),
            throwsA(isA<PostgrestException>()));
        verify(mockLogger.e(
          'Error updating settings',
          error: anyNamed('error'),
          stackTrace: anyNamed('stackTrace'),
          context: {'userId': testUserId},
        )).called(1);
      });
    });

    group('signOut', () {
      test('debe cerrar sesión exitosamente', () async {
        // Arrange
        when(mockAuth.signOut()).thenAnswer((_) async {});

        // Act
        await dataSource.signOut();

        // Assert
        verify(mockLogger.i('Signing out user')).called(1);
        verify(mockAuth.signOut()).called(1);
        verify(mockLogger.i('User signed out successfully')).called(1);
      });

      test('debe loguear en orden correcto', () async {
        // Arrange
        when(mockAuth.signOut()).thenAnswer((_) async {});

        // Act
        await dataSource.signOut();

        // Assert
        verifyInOrder([
          mockLogger.i('Signing out user'),
          mockAuth.signOut(),
          mockLogger.i('User signed out successfully'),
        ]);
      });

      test('debe propagar excepción de Supabase', () async {
        // Arrange
        final testError = Exception('SignOut error');
        when(mockAuth.signOut()).thenThrow(testError);

        // Act & Assert
        await expectLater(
          dataSource.signOut(),
          throwsA(testError),
        );
      });

      test('debe loguear error cuando signOut falla', () async {
        // Arrange
        final testError = Exception('SignOut error');
        when(mockAuth.signOut()).thenThrow(testError);

        // Act
        try {
          await dataSource.signOut();
        } catch (_) {}

        await Future.delayed(
            const Duration(milliseconds: 50)); // Esperar logging async

        // Assert
        verify(mockLogger.i('Signing out user')).called(1);
        verify(mockLogger.e(
          'Error signing out',
          error: testError,
          stackTrace: anyNamed('stackTrace'),
        )).called(1);
      });

      test('no debe loguear éxito cuando signOut falla', () async {
        // Arrange
        final testError = Exception('SignOut error');
        when(mockAuth.signOut()).thenThrow(testError);

        // Act
        try {
          await dataSource.signOut();
        } catch (_) {}

        // Assert
        verifyNever(mockLogger.i('User signed out successfully'));
      });

      test('debe manejar AuthException correctamente', () async {
        // Arrange
        final authError = AuthException('Auth session expired');
        when(mockAuth.signOut()).thenThrow(authError);

        // Act & Assert
        await expectLater(
          dataSource.signOut(),
          throwsA(authError),
        );
      });
    });

    group('Logging behavior', () {

      test('debe incluir contexto relevante en logs de error', () async {
        // Arrange
        final testError = Exception('Test error');
        when(mockAuth.signOut()).thenThrow(testError);

        // Act
        try {
          await dataSource.signOut();
        } catch (_) {}

        await Future.delayed(const Duration(milliseconds: 50));

        // Assert
        verify(mockLogger.e(
          'Error signing out',
          error: testError,
          stackTrace: anyNamed('stackTrace'),
        )).called(1);
      });
    });

  });
}
