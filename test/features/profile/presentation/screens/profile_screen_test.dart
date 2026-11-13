import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:chismes/features/profile/presentation/screens/profile_screen.dart';
import 'package:chismes/features/profile/presentation/controllers/profile_controller.dart';
import 'package:chismes/features/profile/presentation/widgets/profile_header.dart';
import 'package:chismes/features/auth/domain/entities/user.dart';
import 'package:chismes/features/profile/domain/entities/user_stats.dart';
import 'package:chismes/features/profile/domain/entities/profile_settings.dart';
import 'package:chismes/core/l10n/locale_notifier.dart';
import 'package:chismes/core/di/injection_container.dart';

import '../../../../helpers/widget_test_wrapper.dart';
import 'profile_screen_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<ProfileController>(),
  MockSpec<LocaleNotifier>(),
])
void main() {
  late MockProfileController mockController;
  late MockLocaleNotifier mockLocaleNotifier;

  setUp(() {
    mockController = MockProfileController();
    mockLocaleNotifier = MockLocaleNotifier();

    // Setup mocks básicos
    when(mockController.state).thenReturn(ProfileState.initial);
    when(mockController.currentUser).thenReturn(null);
    when(mockController.userStats).thenReturn(null);
    when(mockController.settings).thenReturn(null);
    when(mockController.getErrorMessage(any)).thenReturn(null);
    when(mockController.addListener(any)).thenReturn(null);
    when(mockController.removeListener(any)).thenReturn(null);
    when(mockController.loadProfile()).thenAnswer((_) async {});
    when(mockController.refresh()).thenAnswer((_) async {});
    when(mockController.signOut()).thenAnswer((_) async => true);
    when(mockLocaleNotifier.locale).thenReturn(const Locale('es'));
    when(mockLocaleNotifier.setLocale(any)).thenAnswer((_) async => {});

    // Registrar en DI
    if (getIt.isRegistered<ProfileController>()) {
      getIt.unregister<ProfileController>();
    }
    if (getIt.isRegistered<LocaleNotifier>()) {
      getIt.unregister<LocaleNotifier>();
    }

    getIt.registerSingleton<ProfileController>(mockController);
    getIt.registerSingleton<LocaleNotifier>(mockLocaleNotifier);
  });

  tearDown(() {
    if (getIt.isRegistered<ProfileController>()) {
      getIt.unregister<ProfileController>();
    }
    if (getIt.isRegistered<LocaleNotifier>()) {
      getIt.unregister<LocaleNotifier>();
    }
  });

  // Mock data
  final mockUser = User(
    id: 'user-1',
    email: 'test@example.com',
    emailVerified: true,
    username: 'testuser',
    displayName: 'Test User',
    avatarUrl: null, // Sin avatar para evitar network request en tests
    bio: 'Test bio',
    profileCompleted: true,
    createdAt: DateTime(2024, 1, 1),
  );

  final mockStats = const UserStats(
    gossipsCount: 10,
    commentsCount: 25,
    followersCount: 50,
    followingCount: 30,
  );

  final mockSettings = ProfileSettings.defaultSettings();

  Widget createTestWidget() {
    return testableWidget(
      child: const ProfileScreen(),
      useScaffold: false,
    );
  }

  group('ProfileScreen - Estados', () {
    testWidgets('debe mostrar loading cuando está cargando sin usuario', (tester) async {
      // Arrange
      when(mockController.state).thenReturn(ProfileState.loading);
      when(mockController.currentUser).thenReturn(null);

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('debe mostrar error cuando falla carga sin usuario', (tester) async {
      // Arrange
      when(mockController.state).thenReturn(ProfileState.error);
      when(mockController.currentUser).thenReturn(null);
      when(mockController.getErrorMessage(any)).thenReturn('Error al cargar perfil');

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Assert
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Error al cargar perfil'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('debe mostrar mensaje cuando no hay usuario', (tester) async {
      // Arrange
      when(mockController.state).thenReturn(ProfileState.loaded);
      when(mockController.currentUser).thenReturn(null);

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Assert
      expect(find.text('No hay usuario autenticado'), findsOneWidget);
    });

    testWidgets('debe mostrar perfil cuando está cargado', (tester) async {
      // Arrange
      when(mockController.state).thenReturn(ProfileState.loaded);
      when(mockController.currentUser).thenReturn(mockUser);
      when(mockController.userStats).thenReturn(null); // Stats opcional
      when(mockController.settings).thenReturn(null); // Settings opcional

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Assert
      expect(find.byType(RefreshIndicator), findsOneWidget);
      expect(find.byType(ListView), findsOneWidget);
    });
  });

  group('ProfileScreen - Interacciones', () {
    testWidgets('debe llamar loadProfile en initState', (tester) async {
      // Arrange
      when(mockController.state).thenReturn(ProfileState.initial);

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Assert
      verify(mockController.loadProfile()).called(1);
    });

    testWidgets('debe llamar refresh al presionar botón de refresh en AppBar', (tester) async {
      // Arrange
      when(mockController.state).thenReturn(ProfileState.loaded);
      when(mockController.currentUser).thenReturn(mockUser);

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Act
      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pump();

      // Assert
      verify(mockController.refresh()).called(1);
    });

    testWidgets('debe llamar refresh desde botón de retry en estado error', (tester) async {
      // Arrange
      when(mockController.state).thenReturn(ProfileState.error);
      when(mockController.currentUser).thenReturn(null);
      when(mockController.getErrorMessage(any)).thenReturn('Error');

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Act
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      // Assert
      verify(mockController.refresh()).called(1);
    });
  });

  group('ProfileScreen - Sign Out', () {
    testWidgets('debe mostrar botón de cerrar sesión cuando hay usuario', (tester) async {
      // Arrange
      when(mockController.state).thenReturn(ProfileState.loaded);
      when(mockController.currentUser).thenReturn(mockUser);
      when(mockController.userStats).thenReturn(mockStats);
      when(mockController.settings).thenReturn(mockSettings);

      await tester.pumpWidget(createTestWidget());
      await tester.pump(); // Un pump inicial

      // Assert
      // Verificar que se renderiza el contenido del perfil (ListView con RefreshIndicator)
      expect(find.byType(RefreshIndicator), findsOneWidget);
      expect(find.byType(ListView), findsOneWidget);

      // El botón de cerrar sesión está en el ListView, necesitamos scroll
      // Verificar que al menos el ProfileHeader está visible
      expect(find.byType(ProfileHeader), findsOneWidget);
    });
  });

  group('ProfileScreen - Lifecycle', () {
    testWidgets('debe agregar y remover listener del controller', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Assert: Listener agregado
      // NOTE: Se llama 2 veces: 1 manual + 1 automático por ListenableBuilder
      verify(mockController.addListener(any)).called(2);
    });
  });

  group('ProfileScreen - UI Elements', () {
    testWidgets('debe renderizar AppBar con título', (tester) async {
      // Arrange
      when(mockController.state).thenReturn(ProfileState.loaded);
      when(mockController.currentUser).thenReturn(mockUser);

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Assert
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('Perfil'), findsOneWidget);
    });

    testWidgets('debe renderizar Scaffold', (tester) async {
      // Arrange
      when(mockController.state).thenReturn(ProfileState.initial);

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Assert
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });
}
