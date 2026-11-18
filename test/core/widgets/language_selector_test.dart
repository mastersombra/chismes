import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chismes/core/widgets/language_selector.dart';
import 'package:chismes/core/l10n/locale_notifier.dart';
import 'package:chismes/core/di/injection_container.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'language_selector_test.mocks.dart';

@GenerateMocks([LocaleNotifier])
void main() {
  group('LanguageSelector', () {
    late MockLocaleNotifier mockLocaleNotifier;

    setUp(() {
      mockLocaleNotifier = MockLocaleNotifier();

      // Setup GetIt
      if (getIt.isRegistered<LocaleNotifier>()) {
        getIt.unregister<LocaleNotifier>();
      }
      getIt.registerSingleton<LocaleNotifier>(mockLocaleNotifier);
    });

    tearDown(() {
      getIt.reset();
    });

    Widget createWidget() {
      return MaterialApp(
        home: Scaffold(
          body: const LanguageSelector(),
        ),
      );
    }

    testWidgets('debe construirse sin errores', (tester) async {
      // Arrange
      when(mockLocaleNotifier.locale).thenReturn(const Locale('es'));

      // Act
      await tester.pumpWidget(createWidget());

      // Assert
      expect(find.byType(LanguageSelector), findsOneWidget);
    });

    testWidgets('debe mostrar PopupMenuButton', (tester) async {
      // Arrange
      when(mockLocaleNotifier.locale).thenReturn(const Locale('es'));

      // Act
      await tester.pumpWidget(createWidget());

      // Assert
      expect(find.byType(PopupMenuButton<Locale>), findsOneWidget);
    });

    testWidgets('debe mostrar bandera del idioma actual (español)', (tester) async {
      // Arrange
      when(mockLocaleNotifier.locale).thenReturn(const Locale('es'));

      // Act
      await tester.pumpWidget(createWidget());

      // Assert
      expect(find.text('🇪🇸'), findsOneWidget);
    });

    testWidgets('debe mostrar bandera del idioma actual (inglés)', (tester) async {
      // Arrange
      when(mockLocaleNotifier.locale).thenReturn(const Locale('en'));

      // Act
      await tester.pumpWidget(createWidget());

      // Assert
      expect(find.text('🇺🇸'), findsOneWidget);
    });

    testWidgets('debe abrir menú al hacer tap', (tester) async {
      // Arrange
      when(mockLocaleNotifier.locale).thenReturn(const Locale('es'));

      // Act
      await tester.pumpWidget(createWidget());
      await tester.tap(find.byType(PopupMenuButton<Locale>));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Español'), findsOneWidget);
      expect(find.text('English'), findsOneWidget);
    });

    testWidgets('debe mostrar check en idioma seleccionado (español)', (tester) async {
      // Arrange
      when(mockLocaleNotifier.locale).thenReturn(const Locale('es'));

      // Act
      await tester.pumpWidget(createWidget());
      await tester.tap(find.byType(PopupMenuButton<Locale>));
      await tester.pumpAndSettle();

      // Assert - Verificar que hay un check visible
      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('debe mostrar check en idioma seleccionado (inglés)', (tester) async {
      // Arrange
      when(mockLocaleNotifier.locale).thenReturn(const Locale('en'));

      // Act
      await tester.pumpWidget(createWidget());
      await tester.tap(find.byType(PopupMenuButton<Locale>));
      await tester.pumpAndSettle();

      // Assert - Verificar que hay un check visible
      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('debe llamar setLocale al seleccionar español', (tester) async {
      // Arrange
      when(mockLocaleNotifier.locale).thenReturn(const Locale('en'));

      // Act
      await tester.pumpWidget(createWidget());
      await tester.tap(find.byType(PopupMenuButton<Locale>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Español'));
      await tester.pumpAndSettle();

      // Assert
      verify(mockLocaleNotifier.setLocale(const Locale('es'))).called(1);
    });

    testWidgets('debe llamar setLocale al seleccionar inglés', (tester) async {
      // Arrange
      when(mockLocaleNotifier.locale).thenReturn(const Locale('es'));

      // Act
      await tester.pumpWidget(createWidget());
      await tester.tap(find.byType(PopupMenuButton<Locale>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();

      // Assert
      verify(mockLocaleNotifier.setLocale(const Locale('en'))).called(1);
    });

    testWidgets('debe tener tooltip "Cambiar idioma"', (tester) async {
      // Arrange
      when(mockLocaleNotifier.locale).thenReturn(const Locale('es'));

      // Act
      await tester.pumpWidget(createWidget());

      // Assert
      final popupButton = tester.widget<PopupMenuButton<Locale>>(
        find.byType(PopupMenuButton<Locale>),
      );
      expect(popupButton.tooltip, equals('Cambiar idioma'));
    });

    testWidgets('debe mostrar ambos idiomas en el menú', (tester) async {
      // Arrange
      when(mockLocaleNotifier.locale).thenReturn(const Locale('es'));

      // Act
      await tester.pumpWidget(createWidget());
      await tester.tap(find.byType(PopupMenuButton<Locale>));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('🇪🇸'), findsNWidgets(2)); // Uno en botón, uno en menú
      expect(find.text('🇺🇸'), findsOneWidget);
      expect(find.text('Español'), findsOneWidget);
      expect(find.text('English'), findsOneWidget);
    });

    testWidgets('debe usar bold para idioma seleccionado', (tester) async {
      // Arrange
      when(mockLocaleNotifier.locale).thenReturn(const Locale('es'));

      // Act
      await tester.pumpWidget(createWidget());
      await tester.tap(find.byType(PopupMenuButton<Locale>));
      await tester.pumpAndSettle();

      // Assert
      final espanolText = tester.widget<Text>(
        find.text('Español'),
      );
      expect(espanolText.style?.fontWeight, equals(FontWeight.bold));

      final englishText = tester.widget<Text>(
        find.text('English'),
      );
      expect(englishText.style?.fontWeight, equals(FontWeight.normal));
    });

    testWidgets('debe mostrar exactamente 2 items en el menú', (tester) async {
      // Arrange
      when(mockLocaleNotifier.locale).thenReturn(const Locale('es'));

      // Act
      await tester.pumpWidget(createWidget());
      await tester.tap(find.byType(PopupMenuButton<Locale>));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(PopupMenuItem<Locale>), findsNWidgets(2));
    });

    testWidgets('debe persistir cambio de locale después de cerrar menú', (tester) async {
      // Arrange
      when(mockLocaleNotifier.locale).thenReturn(const Locale('es'));

      // Act
      await tester.pumpWidget(createWidget());
      await tester.tap(find.byType(PopupMenuButton<Locale>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();

      // Assert - Verificar que llamó setLocale
      verify(mockLocaleNotifier.setLocale(const Locale('en'))).called(1);
    });
  });
}
