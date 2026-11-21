import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:chismes/core/error/error_codes.dart';
import 'package:chismes/core/error/failure.dart';
import 'package:chismes/core/logging/logging.dart';
import 'package:chismes/core/result/result.dart';
import 'package:chismes/features/profile/data/datasources/profile_remote_datasource.dart';
import 'package:chismes/features/profile/data/models/profile_settings_model.dart';
import 'package:chismes/features/profile/data/models/user_stats_model.dart';
import 'package:chismes/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:chismes/features/profile/domain/entities/profile_settings.dart';
import 'package:chismes/features/profile/domain/entities/user_stats.dart';

import 'profile_repository_impl_test.mocks.dart';

@GenerateMocks([ProfileRemoteDataSource, AppLogger])
void main() {
  late ProfileRepositoryImpl repository;
  late MockProfileRemoteDataSource mockRemoteDataSource;
  late MockAppLogger mockLogger;

  setUp(() {
    mockRemoteDataSource = MockProfileRemoteDataSource();
    mockLogger = MockAppLogger();
    repository = ProfileRepositoryImpl(mockRemoteDataSource, mockLogger);
  });

  group('ProfileRepositoryImpl', () {
    const testUserId = 'test-user-123';

    group('getUserStats', () {
      final tUserStatsModel = UserStatsModel(
        gossipsCount: 42,
        commentsCount: 15,
        followersCount: 100,
        followingCount: 75,
        lastActivityAt: '2024-01-15T10:30:00Z',
      );

      test('debe retornar UserStats cuando datasource retorna exitosamente',
          () async {
        // Arrange
        when(mockRemoteDataSource.getUserStats(testUserId))
            .thenAnswer((_) async => tUserStatsModel);

        // Act
        final result = await repository.getUserStats(testUserId);

        // Assert
        expect(result.isSuccess, isTrue);
        result.when(
          onFailure: (_) => fail('Should be success'),
          onSuccess: (stats) {
            expect(stats, isA<UserStats>());
            expect(stats.gossipsCount, 42);
            expect(stats.commentsCount, 15);
            expect(stats.followersCount, 100);
            expect(stats.followingCount, 75);
            expect(stats.lastActivityAt, isNotNull);
          },
        );

        verify(mockLogger.d('Getting user stats for userId: $testUserId'))
            .called(1);
        verify(mockRemoteDataSource.getUserStats(testUserId)).called(1);
        verify(mockLogger.i('User stats retrieved successfully')).called(1);
      });

      test('debe retornar Failure cuando datasource lanza excepción', () async {
        // Arrange
        final testError = Exception('Network error');
        when(mockRemoteDataSource.getUserStats(testUserId))
            .thenThrow(testError);

        // Act
        final result = await repository.getUserStats(testUserId);

        // Assert
        expect(result.isFailure, isTrue);
        result.when(
          onFailure: (failure) {
            expect(failure, isA<Failure>());
          },
          onSuccess: (_) => fail('Should be failure'),
        );

        verify(mockLogger.e(
          'Error getting user stats',
          error: testError,
          stackTrace: anyNamed('stackTrace'),
          context: {'userId': testUserId},
        )).called(1);
      });

      test('debe convertir correctamente model a entity', () async {
        // Arrange
        when(mockRemoteDataSource.getUserStats(testUserId))
            .thenAnswer((_) async => tUserStatsModel);

        // Act
        final result = await repository.getUserStats(testUserId);

        // Assert
        result.when(
          onFailure: (_) => fail('Should be success'),
          onSuccess: (stats) {
            // Verificar que la conversión preserva los datos
            expect(stats.gossipsCount, tUserStatsModel.gossipsCount);
            expect(stats.commentsCount, tUserStatsModel.commentsCount);
            expect(stats.followersCount, tUserStatsModel.followersCount);
            expect(stats.followingCount, tUserStatsModel.followingCount);
          },
        );
      });

      test('debe manejar stats sin lastActivityAt', () async {
        // Arrange
        final modelWithoutActivity = UserStatsModel(
          gossipsCount: 10,
          commentsCount: 5,
          followersCount: 20,
          followingCount: 15,
          lastActivityAt: null,
        );

        when(mockRemoteDataSource.getUserStats(testUserId))
            .thenAnswer((_) async => modelWithoutActivity);

        // Act
        final result = await repository.getUserStats(testUserId);

        // Assert
        result.when(
          onFailure: (_) => fail('Should be success'),
          onSuccess: (stats) {
            expect(stats.lastActivityAt, isNull);
          },
        );
      });
    });

    group('getSettings', () {
      const tProfileSettingsModel = ProfileSettingsModel(
        notificationsEnabled: true,
        emailNotifications: false,
        pushNotifications: true,
        commentsNotifications: false,
        likesNotifications: true,
        followNotifications: false,
        language: 'en',
        darkMode: true,
        privacyLevel: 'private',
        showEmail: true,
        showActivity: false,
      );

      test('debe retornar ProfileSettings cuando datasource retorna exitosamente',
          () async {
        // Arrange
        when(mockRemoteDataSource.getSettings(testUserId))
            .thenAnswer((_) async => tProfileSettingsModel);

        // Act
        final result = await repository.getSettings(testUserId);

        // Assert
        expect(result.isSuccess, isTrue);
        result.when(
          onFailure: (_) => fail('Should be success'),
          onSuccess: (settings) {
            expect(settings, isA<ProfileSettings>());
            expect(settings.notificationsEnabled, true);
            expect(settings.emailNotifications, false);
            expect(settings.language, 'en');
            expect(settings.darkMode, true);
            expect(settings.privacyLevel, 'private');
          },
        );

        verify(mockLogger.d('Getting settings for userId: $testUserId'))
            .called(1);
        verify(mockRemoteDataSource.getSettings(testUserId)).called(1);
        verify(mockLogger.i('Settings retrieved successfully')).called(1);
      });

      test('debe retornar Failure cuando datasource lanza excepción', () async {
        // Arrange
        final testError = Exception('Database error');
        when(mockRemoteDataSource.getSettings(testUserId)).thenThrow(testError);

        // Act
        final result = await repository.getSettings(testUserId);

        // Assert
        expect(result.isFailure, isTrue);
        result.when(
          onFailure: (failure) {
            expect(failure, isA<Failure>());
          },
          onSuccess: (_) => fail('Should be failure'),
        );

        verify(mockLogger.e(
          'Error getting settings',
          error: testError,
          stackTrace: anyNamed('stackTrace'),
          context: {'userId': testUserId},
        )).called(1);
      });

      test('debe preservar todos los campos de settings', () async {
        // Arrange
        when(mockRemoteDataSource.getSettings(testUserId))
            .thenAnswer((_) async => tProfileSettingsModel);

        // Act
        final result = await repository.getSettings(testUserId);

        // Assert
        result.when(
          onFailure: (_) => fail('Should be success'),
          onSuccess: (settings) {
            expect(settings.notificationsEnabled,
                tProfileSettingsModel.notificationsEnabled);
            expect(settings.emailNotifications,
                tProfileSettingsModel.emailNotifications);
            expect(
                settings.pushNotifications, tProfileSettingsModel.pushNotifications);
            expect(settings.commentsNotifications,
                tProfileSettingsModel.commentsNotifications);
            expect(settings.likesNotifications,
                tProfileSettingsModel.likesNotifications);
            expect(settings.followNotifications,
                tProfileSettingsModel.followNotifications);
            expect(settings.language, tProfileSettingsModel.language);
            expect(settings.darkMode, tProfileSettingsModel.darkMode);
            expect(settings.privacyLevel, tProfileSettingsModel.privacyLevel);
            expect(settings.showEmail, tProfileSettingsModel.showEmail);
            expect(settings.showActivity, tProfileSettingsModel.showActivity);
          },
        );
      });
    });

    group('updateSettings', () {
      const tProfileSettings = ProfileSettings(
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

      test('debe retornar success cuando datasource actualiza exitosamente',
          () async {
        // Arrange
        when(mockRemoteDataSource.updateSettings(
          testUserId,
          any,
        )).thenAnswer((_) async => {});

        // Act
        final result = await repository.updateSettings(testUserId, tProfileSettings);

        // Assert
        expect(result.isSuccess, isTrue);
        result.when(
          onFailure: (_) => fail('Should be success'),
          onSuccess: (_) {
            // Success
          },
        );

        verify(mockLogger.d('Updating settings for userId: $testUserId'))
            .called(1);
        verify(mockRemoteDataSource.updateSettings(testUserId, any)).called(1);
        verify(mockLogger.i('Settings updated successfully')).called(1);
      });

      test('debe convertir entity a model antes de llamar datasource', () async {
        // Arrange
        when(mockRemoteDataSource.updateSettings(
          testUserId,
          any,
        )).thenAnswer((_) async => {});

        // Act
        await repository.updateSettings(testUserId, tProfileSettings);

        // Assert
        final captured = verify(mockRemoteDataSource.updateSettings(
          testUserId,
          captureAny,
        )).captured.single as ProfileSettingsModel;

        expect(captured.notificationsEnabled, tProfileSettings.notificationsEnabled);
        expect(captured.language, tProfileSettings.language);
        expect(captured.darkMode, tProfileSettings.darkMode);
        expect(captured.privacyLevel, tProfileSettings.privacyLevel);
      });

      test('debe retornar Failure cuando datasource lanza excepción', () async {
        // Arrange
        final testError = Exception('Update error');
        when(mockRemoteDataSource.updateSettings(testUserId, any))
            .thenThrow(testError);

        // Act
        final result = await repository.updateSettings(testUserId, tProfileSettings);

        // Assert
        expect(result.isFailure, isTrue);
        result.when(
          onFailure: (failure) {
            expect(failure, isA<Failure>());
          },
          onSuccess: (_) => fail('Should be failure'),
        );

        verify(mockLogger.e(
          'Error updating settings',
          error: testError,
          stackTrace: anyNamed('stackTrace'),
          context: {'userId': testUserId},
        )).called(1);
      });

      test('debe manejar configuración por defecto', () async {
        // Arrange
        final defaultSettings = ProfileSettings.defaultSettings();

        when(mockRemoteDataSource.updateSettings(testUserId, any))
            .thenAnswer((_) async => {});

        // Act
        final result = await repository.updateSettings(testUserId, defaultSettings);

        // Assert
        expect(result.isSuccess, isTrue);
        verify(mockRemoteDataSource.updateSettings(testUserId, any)).called(1);
      });
    });

    group('signOut', () {
      test('debe retornar success cuando datasource cierra sesión exitosamente',
          () async {
        // Arrange
        when(mockRemoteDataSource.signOut()).thenAnswer((_) async => {});

        // Act
        final result = await repository.signOut();

        // Assert
        expect(result.isSuccess, isTrue);
        result.when(
          onFailure: (_) => fail('Should be success'),
          onSuccess: (_) {
            // Success
          },
        );

        verify(mockLogger.i('Signing out')).called(1);
        verify(mockRemoteDataSource.signOut()).called(1);
        verify(mockLogger.i('Signed out successfully')).called(1);
      });

      test('debe loguear en orden correcto', () async {
        // Arrange
        when(mockRemoteDataSource.signOut()).thenAnswer((_) async => {});

        // Act
        await repository.signOut();

        // Assert
        verifyInOrder([
          mockLogger.i('Signing out'),
          mockRemoteDataSource.signOut(),
          mockLogger.i('Signed out successfully'),
        ]);
      });

      test('debe retornar Failure cuando datasource lanza excepción', () async {
        // Arrange
        final testError = Exception('SignOut error');
        when(mockRemoteDataSource.signOut()).thenThrow(testError);

        // Act
        final result = await repository.signOut();

        // Assert
        expect(result.isFailure, isTrue);
        result.when(
          onFailure: (failure) {
            expect(failure, isA<Failure>());
          },
          onSuccess: (_) => fail('Should be failure'),
        );

        verify(mockLogger.e(
          'Error signing out',
          error: testError,
          stackTrace: anyNamed('stackTrace'),
        )).called(1);
      });

      test('no debe loguear éxito cuando signOut falla', () async {
        // Arrange
        final testError = Exception('SignOut error');
        when(mockRemoteDataSource.signOut()).thenThrow(testError);

        // Act
        await repository.signOut();

        // Assert
        verifyNever(mockLogger.i('Signed out successfully'));
      });
    });

    group('Error handling', () {
      test('debe usar ErrorHandler para convertir errores a Failure', () async {
        // Arrange
        final testError = Exception('Test error');
        when(mockRemoteDataSource.getUserStats(testUserId))
            .thenThrow(testError);

        // Act
        final result = await repository.getUserStats(testUserId);

        // Assert
        expect(result.isFailure, isTrue);
        result.when(
          onFailure: (failure) {
            expect(failure, isA<Failure>());
            // ErrorHandler debe haber procesado el error
          },
          onSuccess: (_) => fail('Should be failure'),
        );
      });

      test('debe incluir contexto relevante en logs de error', () async {
        // Arrange
        final testError = Exception('Test error');
        when(mockRemoteDataSource.getUserStats(testUserId))
            .thenThrow(testError);

        // Act
        await repository.getUserStats(testUserId);

        // Assert
        verify(mockLogger.e(
          'Error getting user stats',
          error: testError,
          stackTrace: anyNamed('stackTrace'),
          context: {'userId': testUserId},
        )).called(1);
      });
    });

    group('Edge cases', () {
      test('debe manejar userId vacío', () async {
        // Arrange
        final model = UserStatsModel(
          gossipsCount: 0,
          commentsCount: 0,
          followersCount: 0,
          followingCount: 0,
          lastActivityAt: null,
        );

        when(mockRemoteDataSource.getUserStats(''))
            .thenAnswer((_) async => model);

        // Act
        final result = await repository.getUserStats('');

        // Assert
        expect(result.isSuccess, isTrue);
        verify(mockRemoteDataSource.getUserStats('')).called(1);
      });

      test('debe manejar múltiples llamadas consecutivas', () async {
        // Arrange
        final model = UserStatsModel(
          gossipsCount: 5,
          commentsCount: 2,
          followersCount: 10,
          followingCount: 8,
          lastActivityAt: '2024-01-15T10:30:00Z',
        );

        when(mockRemoteDataSource.getUserStats(testUserId))
            .thenAnswer((_) async => model);

        // Act
        final result1 = await repository.getUserStats(testUserId);
        final result2 = await repository.getUserStats(testUserId);

        // Assert
        expect(result1.isSuccess, isTrue);
        expect(result2.isSuccess, isTrue);
        verify(mockRemoteDataSource.getUserStats(testUserId)).called(2);
      });

      test('debe manejar diferentes tipos de errores', () async {
        // Arrange
        when(mockRemoteDataSource.getUserStats(testUserId))
            .thenThrow(FormatException('Invalid format'));

        // Act
        final result = await repository.getUserStats(testUserId);

        // Assert
        expect(result.isFailure, isTrue);
      });
    });
  });

  group('deleteAccount', () {
    test('éxito: retorna success', () async {
      when(mockRemoteDataSource.deleteAccount()).thenAnswer((_) async {});

      final result = await repository.deleteAccount();

      expect(result.isSuccess, isTrue);
      verify(mockRemoteDataSource.deleteAccount()).called(1);
    });

    test('Failure del datasource → Result.failure con el mismo tipo', () async {
      when(mockRemoteDataSource.deleteAccount()).thenThrow(
        const ServerFailure(code: ErrorCode.serverError, technicalMessage: 'delete-account 500'),
      );

      final result = await repository.deleteAccount();

      expect(result.isFailure, isTrue);
      result.when(
        onFailure: (failure) => expect(failure, isA<ServerFailure>()),
        onSuccess: (_) => fail('Should be failure'),
      );
    });

    test('excepción genérica → Result.failure (nunca lanza)', () async {
      when(mockRemoteDataSource.deleteAccount()).thenThrow(Exception('network'));

      final result = await repository.deleteAccount();

      expect(result.isFailure, isTrue);
    });
  });
}
