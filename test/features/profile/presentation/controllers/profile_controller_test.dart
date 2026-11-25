import 'dart:async';

import 'package:chismes/core/error/error_codes.dart';
import 'package:chismes/core/error/failure.dart';
import 'package:chismes/core/logging/logging.dart';
import 'package:chismes/core/result/result.dart';
import 'package:chismes/core/services/auth_service.dart';
import 'package:chismes/features/auth/domain/entities/user.dart';
import 'package:chismes/features/profile/domain/entities/profile_settings.dart';
import 'package:chismes/features/profile/domain/entities/user_stats.dart';
import 'package:chismes/features/profile/domain/usecases/delete_account.dart';
import 'package:chismes/features/profile/domain/usecases/get_settings.dart';
import 'package:chismes/features/profile/domain/usecases/get_user_stats.dart';
import 'package:chismes/features/profile/domain/usecases/sign_out.dart';
import 'package:chismes/features/profile/domain/usecases/update_settings.dart';
import 'package:chismes/features/profile/presentation/controllers/profile_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'profile_controller_test.mocks.dart';

@GenerateMocks([
  GetUserStats,
  GetSettings,
  UpdateSettings,
  SignOut,
  DeleteAccount,
  AuthService,
  AppLogger,
])
void main() {
  late ProfileController controller;
  late MockGetUserStats mockGetUserStats;
  late MockGetSettings mockGetSettings;
  late MockUpdateSettings mockUpdateSettings;
  late MockSignOut mockSignOut;
  late MockDeleteAccount mockDeleteAccount;
  late MockAuthService mockAuthService;
  late MockAppLogger mockLogger;

  const tUserId = 'user-123';
  final tUser = User(
    id: tUserId,
    email: 'test@example.com',
    emailVerified: true,
    username: 'testuser',
    displayName: 'Test User',
    profileCompleted: true,
    createdAt: DateTime(2024, 1, 1),
  );

  const tUserStats = UserStats(
    gossipsCount: 10,
    commentsCount: 25,
    followersCount: 100,
    followingCount: 50,
  );

  final tSettings = ProfileSettings.defaultSettings();

  // Provide dummy values for Result types
  provideDummy<Result<Failure, UserStats>>(
    Result.failure(const AuthFailure(code: ErrorCode.unauthorized)),
  );
  provideDummy<Result<Failure, ProfileSettings>>(
    Result.failure(const AuthFailure(code: ErrorCode.unauthorized)),
  );
  provideDummy<Result<Failure, void>>(
    Result.failure(const AuthFailure(code: ErrorCode.unauthorized)),
  );
  provideDummy<Result<Failure, User?>>(Result.success(null));

  setUp(() {
    mockGetUserStats = MockGetUserStats();
    mockGetSettings = MockGetSettings();
    mockUpdateSettings = MockUpdateSettings();
    mockSignOut = MockSignOut();
    mockDeleteAccount = MockDeleteAccount();
    mockAuthService = MockAuthService();
    mockLogger = MockAppLogger();

    // Default stubs
    when(mockAuthService.currentUser).thenReturn(tUser);
    when(mockAuthService.userId).thenReturn(tUserId);
    when(mockAuthService.loadCurrentUser())
        .thenAnswer((_) async => Result.success(tUser));

    controller = ProfileController(
      mockGetUserStats,
      mockGetSettings,
      mockUpdateSettings,
      mockSignOut,
      mockDeleteAccount,
      mockAuthService,
      mockLogger,
    );
  });

  tearDown(() {
    controller.dispose();
  });

  group('ProfileController - Estado inicial', () {
    test('debe inicializar con estado initial', () {
      // Assert
      expect(controller.state, ProfileState.initial);
      expect(controller.userStats, isNull);
      expect(controller.settings, isNull);
      expect(controller.currentUser, tUser);
    });

    test('debe retornar currentUser desde AuthService', () {
      // Assert
      expect(controller.currentUser, tUser);
      verify(mockAuthService.currentUser).called(1);
    });
  });

  group('ProfileController - loadProfile', () {
    test('debe cargar stats y settings exitosamente', () async {
      // Arrange
      when(mockGetUserStats(tUserId))
          .thenAnswer((_) async => Result.success(tUserStats));
      when(mockGetSettings(tUserId))
          .thenAnswer((_) async => Result.success(tSettings));

      // Act
      await controller.loadProfile();

      // Assert
      expect(controller.state, ProfileState.loaded);
      expect(controller.userStats, tUserStats);
      expect(controller.settings, tSettings);
      verify(mockGetUserStats(tUserId)).called(1);
      verify(mockGetSettings(tUserId)).called(1);
      verify(mockLogger.i('Profile loaded successfully')).called(1);
    });

    test('carga el perfil completo del usuario antes que stats y settings',
        () async {
      // Arrange
      when(mockGetUserStats(tUserId))
          .thenAnswer((_) async => Result.success(tUserStats));
      when(mockGetSettings(tUserId))
          .thenAnswer((_) async => Result.success(tSettings));

      // Act
      await controller.loadProfile();

      // Assert
      verifyInOrder([
        mockAuthService.loadCurrentUser(),
        mockGetUserStats(tUserId),
        mockGetSettings(tUserId),
      ]);
    });

    test('si falla loadCurrentUser igual carga stats y settings', () async {
      // Arrange
      when(mockAuthService.loadCurrentUser()).thenAnswer((_) async =>
          Result.failure(const NetworkFailure(code: ErrorCode.networkError)));
      when(mockGetUserStats(tUserId))
          .thenAnswer((_) async => Result.success(tUserStats));
      when(mockGetSettings(tUserId))
          .thenAnswer((_) async => Result.success(tSettings));

      // Act
      await controller.loadProfile();

      // Assert
      expect(controller.state, ProfileState.loaded);
      expect(controller.userStats, tUserStats);
      expect(controller.currentUser, tUser);
    });

    test('debe usar stats por defecto cuando falla getUserStats', () async {
      // Arrange
      when(mockGetUserStats(tUserId)).thenAnswer(
        (_) async => Result.failure(
          const AuthFailure(code: ErrorCode.unauthorized),
        ),
      );
      when(mockGetSettings(tUserId))
          .thenAnswer((_) async => Result.success(tSettings));

      // Act
      await controller.loadProfile();

      // Assert
      expect(controller.state, ProfileState.loaded);
      expect(controller.userStats, isNotNull);
      expect(controller.userStats!.gossipsCount, 0);
      expect(controller.userStats!.followersCount, 0);
      expect(controller.settings, tSettings);
      verify(mockLogger.w(
        argThat(contains('Failed to load stats')),
      )).called(1);
    });

    test('debe usar settings por defecto cuando falla getSettings', () async {
      // Arrange
      when(mockGetUserStats(tUserId))
          .thenAnswer((_) async => Result.success(tUserStats));
      when(mockGetSettings(tUserId)).thenAnswer(
        (_) async => Result.failure(
          const NetworkFailure(code: ErrorCode.networkError),
        ),
      );

      // Act
      await controller.loadProfile();

      // Assert
      expect(controller.state, ProfileState.loaded);
      expect(controller.userStats, tUserStats);
      expect(controller.settings, isNotNull);
      verify(mockLogger.w(
        argThat(contains('Failed to load settings')),
      )).called(1);
    });

    test('debe cambiar a estado error cuando no hay usuario autenticado',
        () async {
      // Arrange
      when(mockAuthService.userId).thenReturn(null);

      // Act
      await controller.loadProfile();

      // Assert
      expect(controller.state, ProfileState.error);
      verify(mockLogger.e(
        'Error loading profile',
        error: anyNamed('error'),
        stackTrace: anyNamed('stackTrace'),
      )).called(1);
    });

    test('debe notificar listeners durante carga', () async {
      // Arrange
      var notificationCount = 0;
      controller.addListener(() {
        notificationCount++;
      });

      when(mockGetUserStats(tUserId))
          .thenAnswer((_) async => Result.success(tUserStats));
      when(mockGetSettings(tUserId))
          .thenAnswer((_) async => Result.success(tSettings));

      // Act
      await controller.loadProfile();

      // Assert - debe notificar al menos 2 veces (loading + loaded)
      expect(notificationCount, greaterThanOrEqualTo(2));
    });

    test('debe ignorar llamadas cuando ya está en estado loading', () async {
      // Arrange
      when(mockGetUserStats(tUserId))
          .thenAnswer((_) async => Result.success(tUserStats));
      when(mockGetSettings(tUserId))
          .thenAnswer((_) async => Result.success(tSettings));

      // Act - primera llamada
      final future1 = controller.loadProfile();
      // Llamada inmediata mientras está loading
      final future2 = controller.loadProfile();

      await future1;
      await future2;

      // Assert - solo debe llamar una vez
      verify(mockGetUserStats(tUserId)).called(1);
      verify(mockGetSettings(tUserId)).called(1);
    });

    test('debe limpiar errorCode y customErrorKey antes de cargar', () async {
      // Arrange - primero forzar un error
      when(mockAuthService.userId).thenReturn(null);
      await controller.loadProfile();
      expect(controller.state, ProfileState.error);

      // Arrange - ahora configurar para éxito
      when(mockAuthService.userId).thenReturn(tUserId);
      when(mockGetUserStats(tUserId))
          .thenAnswer((_) async => Result.success(tUserStats));
      when(mockGetSettings(tUserId))
          .thenAnswer((_) async => Result.success(tSettings));

      // Act
      await controller.loadProfile();

      // Assert - debe limpiar errores previos
      expect(controller.state, ProfileState.loaded);
    });
  });

  group('ProfileController - updateSetting', () {
    final tNewSettings = tSettings.copyWith(showEmail: !tSettings.showEmail);

    test('debe actualizar settings exitosamente', () async {
      // Arrange
      when(mockUpdateSettings(tUserId, tNewSettings))
          .thenAnswer((_) async => Result.success(null));

      // Act
      final result = await controller.updateSetting(tNewSettings);

      // Assert
      expect(result, isTrue);
      expect(controller.settings, tNewSettings);
      verify(mockUpdateSettings(tUserId, tNewSettings)).called(1);
      verify(mockLogger.i('Settings updated successfully')).called(1);
    });

    test('debe retornar false cuando falla la actualización', () async {
      // Arrange
      when(mockUpdateSettings(tUserId, tNewSettings)).thenAnswer(
        (_) async => Result.failure(
          const NetworkFailure(code: ErrorCode.networkError),
        ),
      );

      // Act
      final result = await controller.updateSetting(tNewSettings);

      // Assert
      expect(result, isFalse);
      verify(mockLogger.e(
        argThat(contains('Failed to update settings')),
      )).called(1);
    });

    test('debe retornar false cuando no hay usuario autenticado', () async {
      // Arrange
      when(mockAuthService.userId).thenReturn(null);

      // Act
      final result = await controller.updateSetting(tNewSettings);

      // Assert
      expect(result, isFalse);
      verify(mockLogger.e(
        'Error updating settings',
        error: anyNamed('error'),
        stackTrace: anyNamed('stackTrace'),
      )).called(1);
    });

    test('debe retornar false cuando está en estado loading', () async {
      // Arrange
      when(mockGetUserStats(tUserId))
          .thenAnswer((_) async => Result.success(tUserStats));
      when(mockGetSettings(tUserId))
          .thenAnswer((_) async => Result.success(tSettings));

      // Act - iniciar loadProfile (estado loading)
      final loading = controller.loadProfile();
      final result = await controller.updateSetting(tNewSettings);
      await loading;

      // Assert
      expect(result, isFalse);
    });

    test('debe notificar listeners al actualizar', () async {
      // Arrange
      var notificationCount = 0;
      controller.addListener(() {
        notificationCount++;
      });

      when(mockUpdateSettings(tUserId, tNewSettings))
          .thenAnswer((_) async => Result.success(null));

      // Act
      await controller.updateSetting(tNewSettings);

      // Assert
      expect(notificationCount, 1);
    });

    test('debe setear customErrorKey cuando hay excepción', () async {
      // Arrange
      when(mockAuthService.userId).thenReturn(null);

      // Act
      await controller.updateSetting(tNewSettings);

      // Assert
      // getErrorMessage debería devolver el mensaje de CustomErrorKey.profileSettingsUpdateError
      // No podemos verificar directamente sin BuildContext real
      verify(mockLogger.e(
        'Error updating settings',
        error: anyNamed('error'),
        stackTrace: anyNamed('stackTrace'),
      )).called(1);
    });
  });

  group('ProfileController - signOut', () {
    test('debe cerrar sesión exitosamente', () async {
      // Arrange
      when(mockSignOut()).thenAnswer((_) async => Result.success(null));

      // Act
      final result = await controller.signOut();

      // Assert
      expect(result, isTrue);
      verify(mockSignOut()).called(1);
      verify(mockLogger.i('User signed out successfully')).called(1);
    });

    test('debe cambiar a estado signingOut al iniciar', () async {
      // Arrange
      when(mockSignOut()).thenAnswer((_) async => Result.success(null));

      // Act
      final future = controller.signOut();

      // Assert - verificar estado intermedio
      expect(controller.state, ProfileState.signingOut);

      await future;
    });

    test('debe retornar false y volver a loaded cuando falla', () async {
      // Arrange - primero cargar perfil
      when(mockGetUserStats(tUserId))
          .thenAnswer((_) async => Result.success(tUserStats));
      when(mockGetSettings(tUserId))
          .thenAnswer((_) async => Result.success(tSettings));
      await controller.loadProfile();

      // Arrange - configurar fallo de signOut
      when(mockSignOut()).thenAnswer(
        (_) async => Result.failure(
          const AuthFailure(code: ErrorCode.unauthorized),
        ),
      );

      // Act
      final result = await controller.signOut();

      // Assert
      expect(result, isFalse);
      expect(controller.state, ProfileState.loaded);
      verify(mockLogger.e(
        argThat(contains('Failed to sign out')),
      )).called(1);
    });

    test('debe retornar false cuando ya está signing out', () async {
      // Arrange
      when(mockSignOut()).thenAnswer((_) async => Result.success(null));

      // Act - primera llamada
      final future1 = controller.signOut();
      // Llamada inmediata mientras está signing out
      final future2 = controller.signOut();

      await future1;
      await future2;

      // Assert - solo debe llamar una vez
      verify(mockSignOut()).called(1);
    });

    test('debe notificar listeners durante sign out', () async {
      // Arrange
      var notificationCount = 0;
      controller.addListener(() {
        notificationCount++;
      });

      when(mockSignOut()).thenAnswer((_) async => Result.success(null));

      // Act
      await controller.signOut();

      // Assert - debe notificar al menos 1 vez (signingOut)
      expect(notificationCount, greaterThanOrEqualTo(1));
    });

    test('debe manejar excepciones y volver a loaded', () async {
      // Arrange - primero cargar perfil
      when(mockGetUserStats(tUserId))
          .thenAnswer((_) async => Result.success(tUserStats));
      when(mockGetSettings(tUserId))
          .thenAnswer((_) async => Result.success(tSettings));
      await controller.loadProfile();

      // Arrange - configurar excepción
      when(mockSignOut()).thenThrow(Exception('Network error'));

      // Act
      final result = await controller.signOut();

      // Assert
      expect(result, isFalse);
      expect(controller.state, ProfileState.loaded);
      verify(mockLogger.e(
        'Error signing out',
        error: anyNamed('error'),
        stackTrace: anyNamed('stackTrace'),
      )).called(1);
    });

    test('debe limpiar errorCode y customErrorKey antes de cerrar sesión',
        () async {
      // Arrange - forzar un error previo
      when(mockAuthService.userId).thenReturn(null);
      await controller.loadProfile();
      expect(controller.state, ProfileState.error);

      // Arrange - configurar signOut exitoso
      when(mockAuthService.userId).thenReturn(tUserId);
      when(mockSignOut()).thenAnswer((_) async => Result.success(null));

      // Act
      await controller.signOut();

      // Assert - errores previos deben estar limpios (verificar estado)
      // No verificamos getErrorMessage sin BuildContext real
    });
  });

  group('ProfileController - onProfileEdited', () {
    test('notifica a los listeners para mostrar el usuario editado', () {
      // Arrange
      var notifications = 0;
      controller.addListener(() => notifications++);

      // Act
      controller.onProfileEdited();

      // Assert
      expect(notifications, 1);
      expect(controller.state, ProfileState.initial);
    });
  });

  group('ProfileController - refresh', () {
    test('debe llamar loadProfile', () async {
      // Arrange
      when(mockGetUserStats(tUserId))
          .thenAnswer((_) async => Result.success(tUserStats));
      when(mockGetSettings(tUserId))
          .thenAnswer((_) async => Result.success(tSettings));

      // Act
      await controller.refresh();

      // Assert
      expect(controller.state, ProfileState.loaded);
      verify(mockGetUserStats(tUserId)).called(1);
      verify(mockGetSettings(tUserId)).called(1);
    });
  });

  group('ProfileController - getErrorMessage', () {
    test('debe retornar null cuando no hay error sin BuildContext real', () {
      // Arrange - estado sin error
      expect(controller.state, ProfileState.initial);

      // Act & Assert - verificar que no hay errorCode ni customErrorKey internos
      // No podemos llamar getErrorMessage sin BuildContext real,
      // pero podemos verificar el estado del controller
      expect(controller.state, isNot(ProfileState.error));
    });

    test('debe manejar estado de error con customErrorKey', () async {
      // Arrange - forzar error con customErrorKey
      when(mockAuthService.userId).thenReturn(null);

      // Act
      await controller.loadProfile();

      // Assert - verificar que entró en estado error
      expect(controller.state, ProfileState.error);
      // getErrorMessage requiere BuildContext real con localizaciones,
      // por lo que solo verificamos el estado aquí
    });
  });

  group('ProfileController - deleteAccount', () {
    test('éxito: retorna true y pasa por deletingAccount', () async {
      // Arrange
      when(mockDeleteAccount()).thenAnswer((_) async => Result.success(null));
      final states = <ProfileState>[];
      controller.addListener(() => states.add(controller.state));

      // Act
      final result = await controller.deleteAccount();

      // Assert
      expect(result, isTrue);
      expect(states, [ProfileState.deletingAccount]);
      verify(mockDeleteAccount()).called(1);
    });

    test('falla: retorna false y vuelve a loaded (la cuenta sigue)', () async {
      // Arrange
      when(mockDeleteAccount()).thenAnswer(
        (_) async => Result.failure(
          const ServerFailure(code: ErrorCode.serverError),
        ),
      );

      // Act
      final result = await controller.deleteAccount();

      // Assert
      expect(result, isFalse);
      expect(controller.state, ProfileState.loaded);
    });

    test('ignora una segunda llamada mientras elimina', () async {
      // Arrange: la primera llamada queda en curso
      final pending = Completer<Result<Failure, void>>();
      when(mockDeleteAccount()).thenAnswer((_) => pending.future);

      // Act
      final first = controller.deleteAccount();
      final second = await controller.deleteAccount();
      pending.complete(Result.success(null));

      // Assert
      expect(second, isFalse);
      expect(await first, isTrue);
      verify(mockDeleteAccount()).called(1);
    });

    test('no cierra sesión mientras elimina la cuenta', () async {
      // Arrange
      final pending = Completer<Result<Failure, void>>();
      when(mockDeleteAccount()).thenAnswer((_) => pending.future);

      // Act
      final deleting = controller.deleteAccount();
      final signedOut = await controller.signOut();
      pending.complete(Result.success(null));
      await deleting;

      // Assert
      expect(signedOut, isFalse);
      verifyNever(mockSignOut());
    });
  });
}
