import 'package:chismes/core/di/injection_container.dart';
import 'package:chismes/core/l10n/l10n.dart';
import 'package:chismes/core/l10n/locale_notifier.dart';
import 'package:chismes/core/theme/theme_mode_notifier.dart';
import 'package:chismes/features/profile/domain/entities/profile_settings.dart';
import 'package:chismes/features/profile/presentation/controllers/profile_controller.dart';
import 'package:chismes/features/profile/presentation/widgets/settings_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'settings_section_test.mocks.dart';

@GenerateMocks([ProfileController, LocaleNotifier])
void main() {
  late MockProfileController mockController;
  late MockLocaleNotifier mockLocaleNotifier;
  late ThemeModeNotifier themeModeNotifier;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    themeModeNotifier = ThemeModeNotifier(await SharedPreferences.getInstance());
    if (getIt.isRegistered<ThemeModeNotifier>()) {
      getIt.unregister<ThemeModeNotifier>();
    }
    getIt.registerSingleton<ThemeModeNotifier>(themeModeNotifier);
    mockController = MockProfileController();
    mockLocaleNotifier = MockLocaleNotifier();

    // Setup GetIt
    if (getIt.isRegistered<LocaleNotifier>()) {
      getIt.unregister<LocaleNotifier>();
    }
    getIt.registerSingleton<LocaleNotifier>(mockLocaleNotifier);

    // Default stubs
    when(mockLocaleNotifier.setLocale(any)).thenAnswer((_) async {});
  });

  tearDown(() {
    if (getIt.isRegistered<ThemeModeNotifier>()) {
      getIt.unregister<ThemeModeNotifier>();
    }
    if (getIt.isRegistered<LocaleNotifier>()) {
      getIt.unregister<LocaleNotifier>();
    }
  });

  Widget createWidget(ProfileSettings settings) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('es'),
      home: Scaffold(
        body: SingleChildScrollView(
          child: SettingsSection(
            settings: settings,
            controller: mockController,
          ),
        ),
      ),
    );
  }

  group('SettingsSection - Renderizado', () {
    testWidgets('debe renderizar título de configuraciones', (tester) async {
      // Arrange
      final settings = ProfileSettings.defaultSettings();

      // Act
      await tester.pumpWidget(createWidget(settings));

      // Assert
      expect(find.text('Configuración'), findsOneWidget);
    });

    testWidgets('debe renderizar sección de notificaciones', (tester) async {
      // Arrange
      final settings = ProfileSettings.defaultSettings();

      // Act
      await tester.pumpWidget(createWidget(settings));

      // Assert
      expect(find.text('Notificaciones'), findsOneWidget);
      expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
    });

    testWidgets('debe renderizar sección de privacidad', (tester) async {
      // Arrange
      final settings = ProfileSettings.defaultSettings();

      // Act
      await tester.pumpWidget(createWidget(settings));

      // Assert
      expect(find.text('Privacidad'), findsOneWidget);
      expect(find.byIcon(Icons.privacy_tip_outlined), findsOneWidget);
    });

    testWidgets('debe renderizar sección de apariencia', (tester) async {
      // Arrange
      final settings = ProfileSettings.defaultSettings();

      // Act
      await tester.pumpWidget(createWidget(settings));

      // Assert
      expect(find.text('Apariencia'), findsOneWidget);
      expect(find.byIcon(Icons.palette_outlined), findsOneWidget);
    });
  });

  group('SettingsSection - Notificaciones generales', () {
    testWidgets('debe mostrar switch de notificaciones generales',
        (tester) async {
      // Arrange
      final settings = ProfileSettings.defaultSettings();

      // Act
      await tester.pumpWidget(createWidget(settings));

      // Assert
      expect(find.text('Notificaciones generales'), findsOneWidget);
      final switchFinder = find.byType(SwitchListTile).first;
      final switchWidget = tester.widget<SwitchListTile>(switchFinder);
      expect(switchWidget.value, settings.notificationsEnabled);
    });

    testWidgets('debe llamar updateSetting al cambiar notificaciones generales',
        (tester) async {
      // Arrange
      final settings = ProfileSettings.defaultSettings();
      when(mockController.updateSetting(any)).thenAnswer((_) async => true);

      // Act
      await tester.pumpWidget(createWidget(settings));
      final switchFinder = find.byType(SwitchListTile).first;
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      // Assert
      verify(mockController.updateSetting(argThat(predicate<ProfileSettings>(
        (s) => s.notificationsEnabled == !settings.notificationsEnabled,
      )))).called(1);
    });

    testWidgets('debe mostrar subopciones cuando notificaciones están activas',
        (tester) async {
      // Arrange
      final settings = ProfileSettings.defaultSettings().copyWith(
        notificationsEnabled: true,
      );

      // Act
      await tester.pumpWidget(createWidget(settings));

      // Assert
      expect(find.text('Notificaciones push'), findsOneWidget);
      expect(find.text('Notificaciones por email'), findsOneWidget);
      expect(find.text('Comentarios'), findsOneWidget);
      expect(find.text('Nuevos seguidores'), findsOneWidget);
    });

    testWidgets('debe ocultar subopciones cuando notificaciones están inactivas',
        (tester) async {
      // Arrange
      final settings = ProfileSettings.defaultSettings().copyWith(
        notificationsEnabled: false,
      );

      // Act
      await tester.pumpWidget(createWidget(settings));

      // Assert
      expect(find.text('Notificaciones push'), findsNothing);
      expect(find.text('Notificaciones por email'), findsNothing);
      expect(find.text('Comentarios'), findsNothing);
      expect(find.text('Nuevos seguidores'), findsNothing);
    });

    testWidgets('debe actualizar push notifications', (tester) async {
      // Arrange
      final settings = ProfileSettings.defaultSettings().copyWith(
        notificationsEnabled: true,
        pushNotifications: false,
      );
      when(mockController.updateSetting(any)).thenAnswer((_) async => true);

      // Act
      await tester.pumpWidget(createWidget(settings));
      final pushSwitch = find.text('Notificaciones push');
      await tester.tap(pushSwitch);
      await tester.pumpAndSettle();

      // Assert
      verify(mockController.updateSetting(argThat(predicate<ProfileSettings>(
        (s) => s.pushNotifications == true,
      )))).called(1);
    });

    testWidgets('debe actualizar email notifications', (tester) async {
      // Arrange
      final settings = ProfileSettings.defaultSettings().copyWith(
        notificationsEnabled: true,
        emailNotifications: false,
      );
      when(mockController.updateSetting(any)).thenAnswer((_) async => true);

      // Act
      await tester.pumpWidget(createWidget(settings));
      final emailSwitch = find.text('Notificaciones por email');
      await tester.tap(emailSwitch);
      await tester.pumpAndSettle();

      // Assert
      verify(mockController.updateSetting(argThat(predicate<ProfileSettings>(
        (s) => s.emailNotifications == true,
      )))).called(1);
    });

    testWidgets('debe actualizar comments notifications', (tester) async {
      // Arrange
      final settings = ProfileSettings.defaultSettings().copyWith(
        notificationsEnabled: true,
        commentsNotifications: false,
      );
      when(mockController.updateSetting(any)).thenAnswer((_) async => true);

      // Act
      await tester.pumpWidget(createWidget(settings));
      final commentsSwitch = find.text('Comentarios');
      await tester.tap(commentsSwitch);
      await tester.pumpAndSettle();

      // Assert
      verify(mockController.updateSetting(argThat(predicate<ProfileSettings>(
        (s) => s.commentsNotifications == true,
      )))).called(1);
    });

    testWidgets('debe actualizar follow notifications', (tester) async {
      // Arrange
      final settings = ProfileSettings.defaultSettings().copyWith(
        notificationsEnabled: true,
        followNotifications: false,
      );
      when(mockController.updateSetting(any)).thenAnswer((_) async => true);

      // Act
      await tester.pumpWidget(createWidget(settings));
      final followSwitch = find.text('Nuevos seguidores');
      await tester.tap(followSwitch);
      await tester.pumpAndSettle();

      // Assert
      verify(mockController.updateSetting(argThat(predicate<ProfileSettings>(
        (s) => s.followNotifications == true,
      )))).called(1);
    });

    testWidgets('debe mostrar error cuando falla actualización',
        (tester) async {
      // Arrange
      final settings = ProfileSettings.defaultSettings();
      when(mockController.updateSetting(any)).thenAnswer((_) async => false);

      // Act
      await tester.pumpWidget(createWidget(settings));
      final switchFinder = find.byType(SwitchListTile).first;
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(SnackBar), findsOneWidget);
      expect(
          find.text('Error al actualizar configuración'), findsOneWidget);
    });
  });

  group('SettingsSection - Privacidad', () {
    testWidgets('debe mostrar nivel de privacidad actual', (tester) async {
      // Arrange
      final settings = ProfileSettings.defaultSettings().copyWith(
        privacyLevel: 'public',
      );

      // Act
      await tester.pumpWidget(createWidget(settings));
      await tester.pumpAndSettle();

      // Scroll para ver privacidad
      await tester.ensureVisible(
        find.text('Privacidad'),
      );

      // Assert
      expect(find.text('Nivel de privacidad'), findsOneWidget);
      expect(find.textContaining('Público'), findsOneWidget);
    });

    testWidgets('debe abrir dialog de privacidad al tocar', (tester) async {
      // Arrange
      final settings = ProfileSettings.defaultSettings();

      // Act
      await tester.pumpWidget(createWidget(settings));
      await tester.pumpAndSettle();
      final l10n =
          AppLocalizations.of(tester.element(find.byType(SettingsSection)))!;

      final tile = find.text(l10n.profileSettingsPrivacyLevel);
      await tester.ensureVisible(tile);
      await tester.tap(tile);
      await tester.pumpAndSettle();

      // Assert
      final dialog = find.byType(AlertDialog);
      expect(dialog, findsOneWidget);
      expect(
        find.descendant(
            of: dialog, matching: find.text(l10n.profileSettingsPrivacyDialogTitle)),
        findsOneWidget,
      );
    });

    testWidgets('debe mostrar opciones de privacidad en dialog',
        (tester) async {
      // Arrange
      final settings = ProfileSettings.defaultSettings();

      // Act
      await tester.pumpWidget(createWidget(settings));
      await tester.pumpAndSettle();

      // Scroll para ver privacidad
      await tester.ensureVisible(
        find.text('Nivel de privacidad'),
      );

      await tester.tap(find.text('Nivel de privacidad'));
      await tester.pumpAndSettle();

      // Assert
      // Solo público y privado ('friends' ya no existe, migración 018)
      expect(find.text('Público'), findsWidgets);
      expect(find.text('Amigos'), findsNothing);
      expect(find.text('Privado'), findsOneWidget);
    });

    testWidgets('debe actualizar privacidad al seleccionar opción',
        (tester) async {
      // Arrange
      final settings = ProfileSettings.defaultSettings().copyWith(
        privacyLevel: 'public',
      );
      when(mockController.updateSetting(any)).thenAnswer((_) async => true);

      // Act
      await tester.pumpWidget(createWidget(settings));
      await tester.pumpAndSettle();

      // Scroll para ver privacidad
      await tester.ensureVisible(
        find.text('Nivel de privacidad'),
      );

      await tester.tap(find.text('Nivel de privacidad'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Privado'));
      await tester.pumpAndSettle();

      // Assert
      verify(mockController.updateSetting(argThat(predicate<ProfileSettings>(
        (s) => s.privacyLevel == 'private',
      )))).called(1);
    });

    testWidgets('debe cerrar dialog al cancelar', (tester) async {
      // Arrange
      final settings = ProfileSettings.defaultSettings();

      // Act
      await tester.pumpWidget(createWidget(settings));
      await tester.pumpAndSettle();

      // Scroll para ver privacidad
      await tester.ensureVisible(
        find.text('Nivel de privacidad'),
      );

      await tester.tap(find.text('Nivel de privacidad'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(AlertDialog), findsNothing);
      verifyNever(mockController.updateSetting(any));
    });

    testWidgets('debe actualizar showEmail', (tester) async {
      // Arrange
      final settings = ProfileSettings.defaultSettings().copyWith(
        showEmail: false,
      );
      when(mockController.updateSetting(any)).thenAnswer((_) async => true);

      // Act
      await tester.pumpWidget(createWidget(settings));
      await tester.pumpAndSettle();

      final l10n =
          AppLocalizations.of(tester.element(find.byType(SettingsSection)))!;

      // Scroll para ver showEmail
      final tile = find.text(l10n.profileSettingsShowEmail);
      await tester.ensureVisible(tile);
      await tester.pumpAndSettle();

      await tester.tap(tile);
      await tester.pumpAndSettle();

      // Assert
      verify(mockController.updateSetting(argThat(predicate<ProfileSettings>(
        (s) => s.showEmail == true,
      )))).called(1);
    });

    testWidgets('debe actualizar showActivity', (tester) async {
      // Arrange
      final settings = ProfileSettings.defaultSettings().copyWith(
        showActivity: false,
      );
      when(mockController.updateSetting(any)).thenAnswer((_) async => true);

      // Act
      await tester.pumpWidget(createWidget(settings));
      await tester.pumpAndSettle();

      final l10n =
          AppLocalizations.of(tester.element(find.byType(SettingsSection)))!;

      // Scroll para ver showActivity
      final tile = find.text(l10n.profileSettingsShowActivity);
      await tester.ensureVisible(tile);
      await tester.pumpAndSettle();

      await tester.tap(tile);
      await tester.pumpAndSettle();

      // Assert
      verify(mockController.updateSetting(argThat(predicate<ProfileSettings>(
        (s) => s.showActivity == true,
      )))).called(1);
    });
  });

  group('SettingsSection - Idioma', () {
    testWidgets('debe mostrar idioma actual', (tester) async {
      // Arrange
      final settings = ProfileSettings.defaultSettings().copyWith(
      );

      // Act
      await tester.pumpWidget(createWidget(settings));
      await tester.pumpAndSettle();

      // Scroll para ver la sección de apariencia
      await tester.ensureVisible(
        find.text('Apariencia'),
      );

      // Assert
      expect(find.text('Idioma'), findsOneWidget);
      expect(find.text('Español'), findsOneWidget);
    });

    testWidgets('debe abrir dialog de idioma al tocar', (tester) async {
      // Arrange
      final settings = ProfileSettings.defaultSettings();

      // Act
      await tester.pumpWidget(createWidget(settings));
      await tester.pumpAndSettle();

      // Scroll para ver idioma
      await tester.ensureVisible(
        find.text('Idioma'),
      );

      await tester.tap(find.text('Idioma'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Español'), findsWidgets);
      expect(find.text('English'), findsOneWidget);
    });

    testWidgets('debe actualizar idioma a inglés', (tester) async {
      // Arrange
      final settings = ProfileSettings.defaultSettings().copyWith(
      );
      when(mockController.updateSetting(any)).thenAnswer((_) async => true);

      // Act
      await tester.pumpWidget(createWidget(settings));
      await tester.pumpAndSettle();

      // Scroll para ver idioma
      await tester.ensureVisible(
        find.text('Idioma'),
      );

      await tester.tap(find.text('Idioma'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();

      // Assert
      verify(mockLocaleNotifier.setLocale(const Locale('en'))).called(1);
      // El idioma no se guarda en settings (fuente única: LocaleNotifier)
      verifyNever(mockController.updateSetting(any));
    });

    testWidgets('muestra el idioma activo de la app', (tester) async {
      // El idioma sale del locale del MaterialApp ('es'), no de settings
      final settings = ProfileSettings.defaultSettings();

      await tester.pumpWidget(createWidget(settings));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Idioma'));

      expect(find.text('Español'), findsOneWidget);
      expect(find.text('English'), findsNothing);
    });

    testWidgets('debe cerrar dialog de idioma al cancelar', (tester) async {
      // Arrange
      final settings = ProfileSettings.defaultSettings();

      // Act
      await tester.pumpWidget(createWidget(settings));
      await tester.pumpAndSettle();

      // Scroll para ver idioma
      await tester.ensureVisible(
        find.text('Idioma'),
      );

      await tester.tap(find.text('Idioma'));
      await tester.pumpAndSettle();

      // Find cancel button in the dialog
      final cancelButtons = find.text('Cancelar');
      await tester.tap(cancelButtons.last);
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(AlertDialog), findsNothing);
      verifyNever(mockController.updateSetting(any));
      verifyNever(mockLocaleNotifier.setLocale(any));
    });
  });

  group('SettingsSection - Tema', () {
    Future<void> openThemeDialog(WidgetTester tester) async {
      await tester.pumpWidget(createWidget(ProfileSettings.defaultSettings()));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Tema'));
      await tester.tap(find.text('Tema'));
      await tester.pumpAndSettle();
    }

    testWidgets('muestra el tema actual (por defecto, el del teléfono)',
        (tester) async {
      // Act
      await tester.pumpWidget(createWidget(ProfileSettings.defaultSettings()));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Tema'), findsOneWidget);
      expect(find.text('Igual que el teléfono'), findsOneWidget);
    });

    testWidgets('el dialog muestra las tres opciones y marca la actual',
        (tester) async {
      // Act
      await openThemeDialog(tester);

      // Assert
      expect(find.byType(AlertDialog), findsOneWidget);
      for (final key in ['themeOption_system', 'themeOption_light', 'themeOption_dark']) {
        expect(find.byKey(Key(key)), findsOneWidget);
      }
      expect(
        find.descendant(
          of: find.byKey(const Key('themeOption_system')),
          matching: find.byIcon(Icons.radio_button_checked),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('themeOption_dark')),
          matching: find.byIcon(Icons.radio_button_unchecked),
        ),
        findsOneWidget,
      );
    });

    testWidgets('elegir Oscuro guarda el tema y actualiza el subtítulo',
        (tester) async {
      // Arrange
      await openThemeDialog(tester);

      // Act
      await tester.tap(find.byKey(const Key('themeOption_dark')));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(AlertDialog), findsNothing);
      expect(themeModeNotifier.mode, ThemeMode.dark);
      expect(find.text('Oscuro'), findsOneWidget);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('app_theme_mode'), 'dark');
      // El tema es del teléfono: no se guarda en settings del servidor
      verifyNever(mockController.updateSetting(any));
    });

    testWidgets('elegir Claro muestra "Claro"', (tester) async {
      // Arrange
      await openThemeDialog(tester);

      // Act
      await tester.tap(find.byKey(const Key('themeOption_light')));
      await tester.pumpAndSettle();

      // Assert
      expect(themeModeNotifier.mode, ThemeMode.light);
      expect(find.text('Claro'), findsOneWidget);
    });

    testWidgets('cancelar no cambia el tema', (tester) async {
      // Arrange
      await openThemeDialog(tester);

      // Act
      await tester.tap(find.text('Cancelar').last);
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(AlertDialog), findsNothing);
      expect(themeModeNotifier.mode, ThemeMode.system);
    });
  });

  group('SettingsSection - Privacy levels text', () {
    testWidgets('debe mostrar texto correcto para public', (tester) async {
      // Arrange
      final settings = ProfileSettings.defaultSettings().copyWith(
        privacyLevel: 'public',
      );

      // Act
      await tester.pumpWidget(createWidget(settings));

      // Assert
      expect(find.textContaining('Público'), findsOneWidget);
    });

    testWidgets('el valor legado friends ya no se muestra (cae en público)',
        (tester) async {
      // Arrange
      final settings = ProfileSettings.defaultSettings().copyWith(
        privacyLevel: 'friends',
      );

      // Act
      await tester.pumpWidget(createWidget(settings));

      // Assert
      expect(find.textContaining('Amigos'), findsNothing);
      expect(find.textContaining('Público'), findsOneWidget);
    });

    testWidgets('debe mostrar texto correcto para private', (tester) async {
      // Arrange
      final settings = ProfileSettings.defaultSettings().copyWith(
        privacyLevel: 'private',
      );

      // Act
      await tester.pumpWidget(createWidget(settings));

      // Assert
      expect(find.textContaining('Privado'), findsOneWidget);
    });

    testWidgets('debe mostrar público por defecto para nivel desconocido',
        (tester) async {
      // Arrange
      final settings = ProfileSettings.defaultSettings().copyWith(
        privacyLevel: 'unknown',
      );

      // Act
      await tester.pumpWidget(createWidget(settings));

      // Assert
      expect(find.textContaining('Público'), findsOneWidget);
    });
  });

  group('SettingsSection - Opciones seleccionadas en dialogs', () {
    testWidgets('debe marcar opción actual en dialog de privacidad',
        (tester) async {
      // Arrange
      final settings = ProfileSettings.defaultSettings().copyWith(
        privacyLevel: 'private',
      );

      // Act
      await tester.pumpWidget(createWidget(settings));
      await tester.pumpAndSettle();

      // Scroll para ver privacidad
      await tester.ensureVisible(
        find.text('Nivel de privacidad'),
      );

      await tester.tap(find.text('Nivel de privacidad'));
      await tester.pumpAndSettle();

      // Assert - 'private' seleccionado; solo hay dos opciones
      expect(find.byIcon(Icons.radio_button_checked), findsNWidgets(1));
      expect(find.byIcon(Icons.radio_button_unchecked), findsNWidgets(1));
    });

    testWidgets('debe marcar idioma actual en dialog de idioma',
        (tester) async {
      // Arrange
      final settings = ProfileSettings.defaultSettings().copyWith(
      );

      // Act
      await tester.pumpWidget(createWidget(settings));
      await tester.pumpAndSettle();

      // Scroll para ver idioma
      await tester.ensureVisible(
        find.text('Idioma'),
      );

      await tester.tap(find.text('Idioma'));
      await tester.pumpAndSettle();

      // Assert - verificar iconos de radio
      expect(find.byIcon(Icons.radio_button_checked), findsNWidgets(1));
      expect(find.byIcon(Icons.radio_button_unchecked), findsNWidgets(1));
    });
  });
}
