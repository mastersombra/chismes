import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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

        final params = fake.lastRequest.url.queryParameters;
        expect(fake.lastRequest.url.path, '/rest/v1/gossips');
        expect(params['select'], 'id');
        expect(params['created_by'], 'eq.$testUserId');
        expect(params['status'], 'neq.deleted');
        expect(stats.gossipsCount, 3);
        expect(stats.commentsCount, 0);
        expect(stats.followersCount, 0);
        expect(stats.followingCount, 0);
        expect(DateTime.tryParse(stats.lastActivityAt!), isNotNull);
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

    group('getSettings', () {
      test('debe retornar configuración por defecto con valores correctos',
          () async {
        // Act
        final result = await dataSource.getSettings(testUserId);

        // Assert
        expect(result, isA<ProfileSettingsModel>());
        expect(result.notificationsEnabled, true);
        expect(result.emailNotifications, true);
        expect(result.pushNotifications, true);
        expect(result.commentsNotifications, true);
        expect(result.likesNotifications, true);
        expect(result.followNotifications, true);
        expect(result.language, 'es');
        expect(result.darkMode, false);
        expect(result.privacyLevel, 'public');
        expect(result.showEmail, false);
        expect(result.showActivity, true);

        verify(mockLogger.d('Fetching settings for userId: $testUserId'))
            .called(1);
      });

      test('debe retornar siempre las mismas configuraciones por defecto',
          () async {
        // Act
        final result1 = await dataSource.getSettings(testUserId);
        final result2 = await dataSource.getSettings(testUserId);

        // Assert
        expect(result1.language, result2.language);
        expect(result1.darkMode, result2.darkMode);
        expect(result1.privacyLevel, result2.privacyLevel);
        expect(result1.notificationsEnabled, result2.notificationsEnabled);
      });

      test('debe loguear debug al obtener settings', () async {
        // Act
        await dataSource.getSettings(testUserId);

        // Assert
        verify(mockLogger.d('Fetching settings for userId: $testUserId'))
            .called(1);
      });
    });

    group('updateSettings', () {
      const testSettings = ProfileSettingsModel(
        notificationsEnabled: false,
        emailNotifications: false,
        pushNotifications: true,
        commentsNotifications: true,
        likesNotifications: false,
        followNotifications: true,
        language: 'en',
        darkMode: true,
        privacyLevel: 'private',
        showEmail: true,
        showActivity: false,
      );

      test('debe completar actualización simulada sin errores', () async {
        // Act & Assert - no debe lanzar excepción
        await expectLater(
          dataSource.updateSettings(testUserId, testSettings),
          completes,
        );
      });

      test('debe loguear debug al actualizar settings', () async {
        // Act
        await dataSource.updateSettings(testUserId, testSettings);

        // Assert
        verify(mockLogger.d('Updating settings for userId: $testUserId'))
            .called(1);
      });

      test('debe loguear info con contexto de actualización', () async {
        // Act
        await dataSource.updateSettings(testUserId, testSettings);

        // Assert
        verify(mockLogger.i(
          'Settings would be updated',
          context: {
            'userId': testUserId,
            'settings': testSettings.toJson(),
          },
        )).called(1);
      });

      test('debe esperar latencia simulada de aproximadamente 500ms', () async {
        // Arrange
        final stopwatch = Stopwatch()..start();

        // Act
        await dataSource.updateSettings(testUserId, testSettings);

        // Assert
        stopwatch.stop();
        expect(
          stopwatch.elapsedMilliseconds,
          greaterThanOrEqualTo(400), // Al menos 400ms (500ms - margen)
        );
        expect(
          stopwatch.elapsedMilliseconds,
          lessThan(1000), // Menos de 1 segundo
        );
      });

      test('debe incluir todos los campos de settings en el log', () async {
        // Act
        await dataSource.updateSettings(testUserId, testSettings);

        // Assert
        final captured = verify(mockLogger.i(
          'Settings would be updated',
          context: captureAnyNamed('context'),
        )).captured.single as Map<String, dynamic>;

        final settings = captured['settings'] as Map<String, dynamic>;
        expect(settings, containsPair('language', 'en'));
        expect(settings, containsPair('dark_mode', true));
        expect(settings, containsPair('privacy_level', 'private'));
        expect(settings, containsPair('notifications_enabled', false));
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
      test('debe usar AppLogger inyectado', () async {
        // Arrange
        const testSettings = ProfileSettingsModel(
          notificationsEnabled: true,
          emailNotifications: true,
          pushNotifications: true,
          commentsNotifications: true,
          likesNotifications: true,
          followNotifications: true,
          language: 'es',
          darkMode: false,
          privacyLevel: 'public',
          showEmail: false,
          showActivity: true,
        );

        // Act
        await dataSource.getSettings(testUserId);
        await dataSource.updateSettings(testUserId, testSettings);

        // Assert
        verify(mockLogger.d(any)).called(greaterThan(0));
        verify(mockLogger.i(any, context: anyNamed('context'))).called(1);
      });

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

    group('Edge cases', () {
      test('debe manejar userId vacío en getSettings', () async {
        // Act
        final result = await dataSource.getSettings('');

        // Assert
        expect(result, isA<ProfileSettingsModel>());
        verify(mockLogger.d('Fetching settings for userId: ')).called(1);
      });

      test('debe manejar userId muy largo en getSettings', () async {
        // Arrange
        final longUserId = 'a' * 1000;

        // Act
        final result = await dataSource.getSettings(longUserId);

        // Assert
        expect(result, isA<ProfileSettingsModel>());
        verify(mockLogger.d('Fetching settings for userId: $longUserId'))
            .called(1);
      });

      test('debe manejar múltiples actualizaciones seguidas', () async {
        // Arrange
        const settings1 = ProfileSettingsModel(
          notificationsEnabled: true,
          emailNotifications: true,
          pushNotifications: true,
          commentsNotifications: true,
          likesNotifications: true,
          followNotifications: true,
          language: 'es',
          darkMode: false,
          privacyLevel: 'public',
          showEmail: false,
          showActivity: true,
        );

        const settings2 = ProfileSettingsModel(
          notificationsEnabled: false,
          emailNotifications: false,
          pushNotifications: false,
          commentsNotifications: false,
          likesNotifications: false,
          followNotifications: false,
          language: 'en',
          darkMode: true,
          privacyLevel: 'private',
          showEmail: true,
          showActivity: false,
        );

        // Act
        await dataSource.updateSettings(testUserId, settings1);
        await dataSource.updateSettings(testUserId, settings2);

        // Assert
        verify(mockLogger.i('Settings would be updated', context: anyNamed('context')))
            .called(2);
      });
    });
  });
}
