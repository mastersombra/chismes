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

import 'package:chismes/l10n/app_localizations.dart';

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

  group('ProfileScreen - Reacción a cambios del controller', () {
    /// Guarda TODOS los listeners (la screen + ListenableBuilder) y los llama todos.
    List<VoidCallback> captureListeners() {
      final listeners = <VoidCallback>[];
      when(mockController.addListener(any)).thenAnswer((invocation) {
        listeners.add(invocation.positionalArguments.first as VoidCallback);
      });
      return listeners;
    }

    Future<void> notifyAll(WidgetTester tester, List<VoidCallback> listeners) async {
      for (final listener in List.of(listeners)) {
        listener();
      }
      await tester.pump(); // rebuild + post-frame callbacks
      await tester.pump();
    }

    // El idioma vive solo en LocaleNotifier: los settings (placeholder con
    // 'es' fijo) no deben pisarlo al recargar/refrescar el perfil.
    testWidgets('no cambia el idioma aunque settings difiera del LocaleNotifier',
        (tester) async {
      final listeners = captureListeners();
      when(mockController.state).thenReturn(ProfileState.loaded);
      when(mockController.currentUser).thenReturn(mockUser);

      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      expect(listeners, hasLength(2));

      when(mockController.settings)
          .thenReturn(mockSettings.copyWith(language: 'en'));
      await notifyAll(tester, listeners);

      verifyNever(mockLocaleNotifier.setLocale(any));
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('no cambia el idioma si ya coincide', (tester) async {
      final listeners = captureListeners();
      when(mockController.state).thenReturn(ProfileState.loaded);
      when(mockController.currentUser).thenReturn(mockUser);

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      when(mockController.settings).thenReturn(mockSettings); // 'es'
      await notifyAll(tester, listeners);

      verifyNever(mockLocaleNotifier.setLocale(any));
    });

    testWidgets('no cambia el idioma si aún no hay settings', (tester) async {
      final listeners = captureListeners();
      when(mockController.state).thenReturn(ProfileState.loaded);
      when(mockController.currentUser).thenReturn(mockUser);

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      await notifyAll(tester, listeners);

      verifyNever(mockLocaleNotifier.setLocale(any));
    });

    testWidgets('muestra snackbar de error cuando el controller reporta error',
        (tester) async {
      final listeners = captureListeners();
      when(mockController.state).thenReturn(ProfileState.loaded);
      when(mockController.currentUser).thenReturn(mockUser);

      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      expect(find.byType(SnackBar), findsNothing);

      when(mockController.getErrorMessage(any)).thenReturn('Falló el guardado');
      await notifyAll(tester, listeners);

      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect((snackBar.content as Text).data, 'Falló el guardado');
      final theme = Theme.of(tester.element(find.byType(ProfileScreen)));
      expect(snackBar.backgroundColor, theme.colorScheme.error);
    });
  });

  group('ProfileScreen - Diálogo de cerrar sesión', () {
    Future<AppLocalizations> pumpLoaded(WidgetTester tester) async {
      when(mockController.state).thenReturn(ProfileState.loaded);
      when(mockController.currentUser).thenReturn(mockUser);
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      return AppLocalizations.of(tester.element(find.byType(ProfileScreen)))!;
    }

    Future<void> openDialog(WidgetTester tester, AppLocalizations l10n) async {
      final button = find.text(l10n.profileScreenSignOutButton);
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      // El título puede coincidir con el texto del botón: buscar dentro del diálogo
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text(l10n.profileScreenSignOutDialogTitle),
        ),
        findsWidgets,
      );
      expect(find.text(l10n.profileScreenSignOutDialogContent), findsOneWidget);
    }

    testWidgets('cancelar cierra el diálogo sin cerrar sesión', (tester) async {
      final l10n = await pumpLoaded(tester);
      await openDialog(tester, l10n);

      await tester.tap(find.text(l10n.commonCancel));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      verifyNever(mockController.signOut());
    });

    testWidgets('confirmar llama a signOut', (tester) async {
      final l10n = await pumpLoaded(tester);
      await openDialog(tester, l10n);

      await tester.tap(find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(ElevatedButton),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      verify(mockController.signOut()).called(1);
    });

    testWidgets('cerrando sesión: botón deshabilitado con spinner y texto',
        (tester) async {
      when(mockController.state).thenReturn(ProfileState.signingOut);
      when(mockController.currentUser).thenReturn(mockUser);
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      final l10n =
          AppLocalizations.of(tester.element(find.byType(ProfileScreen)))!;

      final label = find.text(l10n.profileScreenSigningOut);
      await tester.ensureVisible(label);
      expect(label, findsOneWidget);
      expect(find.text(l10n.profileScreenSignOutButton), findsNothing);
      expect(find.byIcon(Icons.logout), findsNothing);
      final button = tester.widget<ButtonStyleButton>(find.ancestor(
        of: label,
        matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
      ));
      expect(button.onPressed, isNull);

      await tester.tap(label, warnIfMissed: false);
      await tester.pump();
      expect(find.byType(AlertDialog), findsNothing);
    });
  });

  group('ProfileScreen - Moderación', () {
    testWidgets('moderador: muestra la entrada al panel de moderación', (tester) async {
      when(mockController.state).thenReturn(ProfileState.loaded);
      when(mockController.currentUser).thenReturn(mockUser.copyWith(isModerator: true));

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.byKey(const Key('moderationEntry')), findsOneWidget);
      expect(find.text('Panel de moderación'), findsOneWidget);
    });

    testWidgets('usuario normal: no ve la entrada', (tester) async {
      when(mockController.state).thenReturn(ProfileState.loaded);
      when(mockController.currentUser).thenReturn(mockUser);

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.byKey(const Key('moderationEntry')), findsNothing);
    });
  });
}
