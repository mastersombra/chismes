import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chismes/features/auth/presentation/screens/privacy_settings_screen.dart';
import 'package:chismes/core/services/location_service.dart';
import 'package:chismes/core/di/injection_container.dart';

import '../../../../helpers/widget_test_wrapper.dart';
import '../../../../helpers/test_di_helper.dart';
import 'privacy_settings_screen_test.mocks.dart';

@GenerateMocks([
  LocationService,
])
void main() {
  late MockLocationService mockLocationService;

  setUp(() async {
    // Inicializar DI (necesario para LanguageSelector si lo hay)
    await setupTestDI();

    // Inicializar SharedPreferences mock
    SharedPreferences.setMockInitialValues({});

    mockLocationService = MockLocationService();

    // Setup mocks básicos
    when(mockLocationService.getDefaultLocation())
        .thenAnswer((_) async => null);
    when(mockLocationService.clearDefaultLocation())
        .thenAnswer((_) async {});

    // Registrar en DI
    if (getIt.isRegistered<LocationService>()) {
      getIt.unregister<LocationService>();
    }
    getIt.registerSingleton<LocationService>(mockLocationService);
  });

  tearDown(() async {
    if (getIt.isRegistered<LocationService>()) {
      getIt.unregister<LocationService>();
    }
    await tearDownTestDI();
  });

  Widget createTestWidget() {
    return testableWidget(
      child: const PrivacySettingsScreen(),
      useScaffold: false,
    );
  }

  group('PrivacySettingsScreen - Inicialización', () {
    testWidgets('debe renderizar la screen', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Assert
      expect(find.byType(PrivacySettingsScreen), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('debe mostrar loading inicialmente', (tester) async {
      // Arrange
      when(mockLocationService.getDefaultLocation())
          .thenAnswer((_) async {
        // Delay para mantener loading
        await Future.delayed(const Duration(milliseconds: 100));
        return null;
      });

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Cleanup: esperar a que termine el Future
      await tester.pumpAndSettle();
    });

    testWidgets('debe cargar configuración en initState', (tester) async {
      // Arrange
      final savedLocation = SavedLocation(
        countryId: '1',
        regionId: '2',
        cityId: '3',
        countryName: 'Argentina',
        regionName: 'Buenos Aires',
        cityName: 'CABA',
      );

      when(mockLocationService.getDefaultLocation())
          .thenAnswer((_) async => savedLocation);

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      verify(mockLocationService.getDefaultLocation()).called(1);
      expect(find.text('CABA, Buenos Aires, Argentina'), findsOneWidget);
    });

    testWidgets('debe mostrar "sin ubicación" cuando no hay ubicación guardada',
        (tester) async {
      // Arrange
      when(mockLocationService.getDefaultLocation())
          .thenAnswer((_) async => null);

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(ListView), findsOneWidget);
      // Verificar que no hay botón de delete cuando no hay ubicación
      expect(find.byIcon(Icons.delete_outline), findsNothing);
    });
  });

  group('PrivacySettingsScreen - Forget Location', () {
    // TODO: Estos tests requieren ajustes en cómo buscar widgets en dialogs
    // Los dialogs se están mostrando pero la selección de botones no funciona correctamente
    testWidgets('debe mostrar dialog de confirmación al tocar forget',
        (tester) async {
      // Arrange
      final savedLocation = SavedLocation(
        countryId: '1',
        regionId: '2',
        cityId: '3',
        countryName: 'Argentina',
        regionName: 'Buenos Aires',
        cityName: 'CABA',
      );

      when(mockLocationService.getDefaultLocation())
          .thenAnswer((_) async => savedLocation);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Cancelar'), findsOneWidget);
    });

    testWidgets('debe limpiar ubicación al confirmar', (tester) async {
      // Arrange
      final savedLocation = SavedLocation(
        countryId: '1',
        regionId: '2',
        cityId: '3',
        countryName: 'Argentina',
        regionName: 'Buenos Aires',
        cityName: 'CABA',
      );

      when(mockLocationService.getDefaultLocation())
          .thenAnswer((_) async => savedLocation);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Act - Abrir dialog
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      // Confirmar
      // Buscar el botón "Olvidar" por texto
      await tester.tap(find.text('Olvidar'));
      await tester.pumpAndSettle();

      // Assert
      verify(mockLocationService.clearDefaultLocation()).called(1);
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('no debe hacer nada al cancelar forget', (tester) async {
      // Arrange
      final savedLocation = SavedLocation(
        countryId: '1',
        regionId: '2',
        cityId: '3',
        countryName: 'Argentina',
        regionName: 'Buenos Aires',
        cityName: 'CABA',
      );

      when(mockLocationService.getDefaultLocation())
          .thenAnswer((_) async => savedLocation);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Reset para contar solo las llamadas después
      reset(mockLocationService);
      when(mockLocationService.clearDefaultLocation())
          .thenAnswer((_) async {});

      // Act - Abrir dialog
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      // Cancelar
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      // Assert
      verifyNever(mockLocationService.clearDefaultLocation());
    });
  });

  group('PrivacySettingsScreen - Anonymous Mode', () {
    testWidgets('debe cambiar estado al hacer toggle', (tester) async {
      // Arrange
      when(mockLocationService.getDefaultLocation())
          .thenAnswer((_) async => null);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();

      // Assert
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('anonymous_mode'), isTrue);
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('debe mostrar snackbar al activar modo anónimo',
        (tester) async {
      // Arrange
      when(mockLocationService.getDefaultLocation())
          .thenAnswer((_) async => null);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(SnackBar), findsOneWidget);
    });
  });

  group('PrivacySettingsScreen - Privacy Policy & Terms', () {
    testWidgets('debe mostrar dialog de privacy policy al tocar',
        (tester) async {
      // Arrange
      when(mockLocationService.getDefaultLocation())
          .thenAnswer((_) async => null);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Act
      // Buscar el ListTile con ícono open_in_new (primer uno es privacy policy)
      final policyTiles = find.ancestor(
        of: find.byIcon(Icons.open_in_new),
        matching: find.byType(ListTile),
      );

      await tester.tap(policyTiles.first);
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.byType(SingleChildScrollView), findsWidgets);
    });

    testWidgets('debe mostrar dialog de terms of service al tocar',
        (tester) async {
      // Arrange
      when(mockLocationService.getDefaultLocation())
          .thenAnswer((_) async => null);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Act
      // Buscar el segundo ListTile con ícono open_in_new (terms)
      final termsTiles = find.ancestor(
        of: find.byIcon(Icons.open_in_new),
        matching: find.byType(ListTile),
      );

      await tester.tap(termsTiles.last);
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(AlertDialog), findsOneWidget);
    });
  });

  group('PrivacySettingsScreen - Delete Account', () {
    testWidgets('debe mostrar primer dialog de confirmación', (tester) async {
      // Arrange
      when(mockLocationService.getDefaultLocation())
          .thenAnswer((_) async => null);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Act - Scroll hasta el botón
      await tester.scrollUntilVisible(
        find.byIcon(Icons.delete_forever),
        500.0,
      );
      await tester.tap(find.byIcon(Icons.delete_forever));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Cancelar'), findsOneWidget);
    });

    testWidgets('debe mostrar segundo dialog al confirmar primero',
        (tester) async {
      // Arrange
      when(mockLocationService.getDefaultLocation())
          .thenAnswer((_) async => null);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Act - Scroll y abrir primer dialog
      await tester.scrollUntilVisible(
        find.byIcon(Icons.delete_forever),
        500.0,
      );
      await tester.tap(find.byIcon(Icons.delete_forever));
      await tester.pumpAndSettle();

      // Confirmar primer dialog buscando botón "Eliminar"
      await tester.tap(find.text('Eliminar'));
      await tester.pumpAndSettle();

      // Assert - Segundo dialog con TextField
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('no debe eliminar si no se escribe "ELIMINAR"',
        (tester) async {
      // Arrange
      when(mockLocationService.getDefaultLocation())
          .thenAnswer((_) async => null);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Act - Scroll y abrir primer dialog
      await tester.scrollUntilVisible(
        find.byIcon(Icons.delete_forever),
        500.0,
      );
      await tester.tap(find.byIcon(Icons.delete_forever));
      await tester.pumpAndSettle();

      // Confirmar primer dialog
      await tester.tap(find.text('Eliminar'));
      await tester.pumpAndSettle();

      // Escribir texto incorrecto
      await tester.enterText(find.byType(TextField), 'incorrect');
      await tester.pump();

      // Intentar confirmar - buscar el botón "Eliminar permanentemente"
      await tester.tap(find.text('Eliminar permanentemente'));
      await tester.pumpAndSettle();

      // Assert - Debe mostrar snackbar de cancelación
      expect(find.byType(SnackBar), findsOneWidget);
    });
  });

  group('PrivacySettingsScreen - UI Elements', () {
    testWidgets('debe renderizar AppBar con título', (tester) async {
      // Arrange
      when(mockLocationService.getDefaultLocation())
          .thenAnswer((_) async => null);

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('debe renderizar todas las secciones', (tester) async {
      // Arrange
      when(mockLocationService.getDefaultLocation())
          .thenAnswer((_) async => null);

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert - Verificar dividers (indican secciones separadas)
      expect(find.byType(Divider), findsWidgets);
      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('debe tener SwitchListTile para modo anónimo', (tester) async {
      // Arrange
      when(mockLocationService.getDefaultLocation())
          .thenAnswer((_) async => null);

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(SwitchListTile), findsOneWidget);
    });
  });
}
