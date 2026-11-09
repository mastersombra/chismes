import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chismes/features/gossip/presentation/widgets/location_selector.dart';
import 'package:chismes/features/gossip/presentation/states/add_gossip_state.dart';
import 'package:chismes/features/location/domain/entities/country.dart';
import 'package:chismes/features/location/domain/entities/region.dart';
import 'package:chismes/features/location/domain/entities/city.dart';
import '../../../../helpers/widget_test_wrapper.dart';

void main() {
  group('LocationSelector', () {
    final mockCountries = [
      const Country(id: '1', code: 'CO', name: 'Colombia'),
      const Country(id: '2', code: 'AR', name: 'Argentina'),
    ];

    final mockRegions = [
      const Region(id: 'ant', name: 'Antioquia', countryId: '1', type: 'department'),
      const Region(id: 'cun', name: 'Cundinamarca', countryId: '1', type: 'department'),
    ];

    final mockCities = [
      const City(id: 'med', name: 'Medellín', regionId: 'ant'),
      const City(id: 'env', name: 'Envigado', regionId: 'ant'),
    ];

    testWidgets('debe mostrar loading cuando isLoadingCountries = true', (tester) async {
      // Arrange
      const state = AddGossipState(
        idempotencyKey: 'test-key',
        isLoadingCountries: true,
        countries: [],
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LocationSelector(
              state: state,
              onCountrySelected: (_) {},
              onRegionSelected: (_) {},
              onCitySelected: (_) {},
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('debe mostrar lista de países', (tester) async {
      // Arrange
      final state = AddGossipState(
        idempotencyKey: 'test-key',
        countries: mockCountries,
        isLoadingCountries: false,
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LocationSelector(
              state: state,
              onCountrySelected: (_) {},
              onRegionSelected: (_) {},
              onCitySelected: (_) {},
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);

      // Tap para abrir dropdown
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();

      // Verificar que están los países
      expect(find.text('Colombia'), findsOneWidget);
      expect(find.text('Argentina'), findsOneWidget);
    });

    testWidgets('debe llamar onCountrySelected al seleccionar país', (tester) async {
      // Arrange
      final state = AddGossipState(
        idempotencyKey: 'test-key',
        countries: mockCountries,
        isLoadingCountries: false,
      );
      String? selectedCountryId;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LocationSelector(
              state: state,
              onCountrySelected: (id) {
                selectedCountryId = id;
              },
              onRegionSelected: (_) {},
              onCitySelected: (_) {},
            ),
          ),
        ),
      );

      // Abrir dropdown y seleccionar
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Colombia').last);
      await tester.pumpAndSettle();

      // Assert
      expect(selectedCountryId, '1');
    });

    testWidgets('debe mostrar loading cuando isLoadingRegions = true', (tester) async {
      // Arrange
      final state = AddGossipState(
        idempotencyKey: 'test-key',
        countries: mockCountries,
        selectedCountryId: '1',
        isLoadingRegions: true,
        regions: [],
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LocationSelector(
              state: state,
              onCountrySelected: (_) {},
              onRegionSelected: (_) {},
              onCitySelected: (_) {},
            ),
          ),
        ),
      );

      // Assert - Debe haber al menos 1 CircularProgressIndicator (en región)
      expect(find.byType(CircularProgressIndicator), findsAtLeastNWidgets(1));
    });

    testWidgets('debe mostrar lista de regiones después de seleccionar país', (tester) async {
      // Arrange
      final state = AddGossipState(
        idempotencyKey: 'test-key',
        countries: mockCountries,
        selectedCountryId: '1',
        regions: mockRegions,
        isLoadingRegions: false,
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LocationSelector(
              state: state,
              onCountrySelected: (_) {},
              onRegionSelected: (_) {},
              onCitySelected: (_) {},
            ),
          ),
        ),
      );

      // Assert - Debe haber 2 dropdowns (país y región)
      expect(find.byType(DropdownButtonFormField<String>), findsNWidgets(2));

      // Tap en el segundo dropdown (región)
      await tester.tap(find.byType(DropdownButtonFormField<String>).last);
      await tester.pumpAndSettle();

      // Verificar que están las regiones
      expect(find.text('Antioquia'), findsOneWidget);
      expect(find.text('Cundinamarca'), findsOneWidget);
    });

    testWidgets('debe llamar onRegionSelected al seleccionar región', (tester) async {
      // Arrange
      final state = AddGossipState(
        idempotencyKey: 'test-key',
        countries: mockCountries,
        selectedCountryId: '1',
        regions: mockRegions,
        isLoadingRegions: false,
      );
      String? selectedRegionId;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LocationSelector(
              state: state,
              onCountrySelected: (_) {},
              onRegionSelected: (id) {
                selectedRegionId = id;
              },
              onCitySelected: (_) {},
            ),
          ),
        ),
      );

      // Abrir dropdown de región y seleccionar
      await tester.tap(find.byType(DropdownButtonFormField<String>).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Antioquia').last);
      await tester.pumpAndSettle();

      // Assert
      expect(selectedRegionId, 'ant');
    });

    testWidgets('debe mostrar loading cuando isLoadingCities = true', (tester) async {
      // Arrange
      final state = AddGossipState(
        idempotencyKey: 'test-key',
        countries: mockCountries,
        selectedCountryId: '1',
        regions: mockRegions,
        selectedRegionId: 'ant',
        isLoadingCities: true,
        cities: [],
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LocationSelector(
              state: state,
              onCountrySelected: (_) {},
              onRegionSelected: (_) {},
              onCitySelected: (_) {},
            ),
          ),
        ),
      );

      // Assert - Debe haber al menos 1 CircularProgressIndicator (en ciudad)
      expect(find.byType(CircularProgressIndicator), findsAtLeastNWidgets(1));
    });

    testWidgets('debe mostrar lista de ciudades después de seleccionar región', (tester) async {
      // Arrange
      final state = AddGossipState(
        idempotencyKey: 'test-key',
        countries: mockCountries,
        selectedCountryId: '1',
        regions: mockRegions,
        selectedRegionId: 'ant',
        cities: mockCities,
        isLoadingCities: false,
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LocationSelector(
              state: state,
              onCountrySelected: (_) {},
              onRegionSelected: (_) {},
              onCitySelected: (_) {},
            ),
          ),
        ),
      );

      // Assert - Debe haber 3 dropdowns (país, región, ciudad)
      expect(find.byType(DropdownButtonFormField<String>), findsNWidgets(3));

      // Tap en el tercer dropdown (ciudad)
      await tester.tap(find.byType(DropdownButtonFormField<String>).last);
      await tester.pumpAndSettle();

      // Verificar que están las ciudades
      expect(find.text('Medellín'), findsOneWidget);
      expect(find.text('Envigado'), findsOneWidget);
    });

    testWidgets('debe llamar onCitySelected al seleccionar ciudad', (tester) async {
      // Arrange
      final state = AddGossipState(
        idempotencyKey: 'test-key',
        countries: mockCountries,
        selectedCountryId: '1',
        regions: mockRegions,
        selectedRegionId: 'ant',
        cities: mockCities,
        isLoadingCities: false,
      );
      String? selectedCityId;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LocationSelector(
              state: state,
              onCountrySelected: (_) {},
              onRegionSelected: (_) {},
              onCitySelected: (id) {
                selectedCityId = id;
              },
            ),
          ),
        ),
      );

      // Abrir dropdown de ciudad y seleccionar
      await tester.tap(find.byType(DropdownButtonFormField<String>).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Medellín').last);
      await tester.pumpAndSettle();

      // Assert
      expect(selectedCityId, 'med');
    });

    testWidgets('no debe mostrar dropdown de región cuando no hay país', (tester) async {
      // Arrange
      final state = AddGossipState(
        idempotencyKey: 'test-key',
        countries: mockCountries,
        selectedCountryId: null, // No país seleccionado
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LocationSelector(
              state: state,
              onCountrySelected: (_) {},
              onRegionSelected: (_) {},
              onCitySelected: (_) {},
            ),
          ),
        ),
      );

      // Assert - Solo debe haber 1 dropdown (país)
      expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
    });

    testWidgets('no debe mostrar dropdown de ciudad cuando no hay región', (tester) async {
      // Arrange
      final state = AddGossipState(
        idempotencyKey: 'test-key',
        countries: mockCountries,
        selectedCountryId: '1',
        regions: mockRegions,
        selectedRegionId: null, // No región seleccionada
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LocationSelector(
              state: state,
              onCountrySelected: (_) {},
              onRegionSelected: (_) {},
              onCitySelected: (_) {},
            ),
          ),
        ),
      );

      // Assert - Debe haber 2 dropdowns (país y región), pero no ciudad
      expect(find.byType(DropdownButtonFormField<String>), findsNWidgets(2));
    });

    testWidgets('dropdown de país debe estar deshabilitado durante loading', (tester) async {
      // Arrange
      const state = AddGossipState(
        idempotencyKey: 'test-key',
        isLoadingCountries: true,
        countries: [],
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LocationSelector(
              state: state,
              onCountrySelected: (_) {},
              onRegionSelected: (_) {},
              onCitySelected: (_) {},
            ),
          ),
        ),
      );

      // Assert
      final dropdown = tester.widget<DropdownButtonFormField<String>>(
        find.byType(DropdownButtonFormField<String>),
      );
      expect(dropdown.onChanged, isNull);
    });

    testWidgets('dropdown de región debe estar deshabilitado durante loading', (tester) async {
      final state = AddGossipState(
        idempotencyKey: 'test-key',
        countries: mockCountries,
        selectedCountryId: '1',
        regions: mockRegions,
        isLoadingRegions: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LocationSelector(
              state: state,
              onCountrySelected: (_) {},
              onRegionSelected: (_) {},
              onCitySelected: (_) {},
            ),
          ),
        ),
      );

      final regionDropdown = tester.widget<DropdownButtonFormField<String>>(
        find.byType(DropdownButtonFormField<String>).last,
      );
      expect(regionDropdown.onChanged, isNull);
    });

    testWidgets('dropdown de ciudad debe estar deshabilitado durante loading', (tester) async {
      final state = AddGossipState(
        idempotencyKey: 'test-key',
        countries: mockCountries,
        selectedCountryId: '1',
        regions: mockRegions,
        selectedRegionId: 'ant',
        cities: mockCities,
        isLoadingCities: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LocationSelector(
              state: state,
              onCountrySelected: (_) {},
              onRegionSelected: (_) {},
              onCitySelected: (_) {},
            ),
          ),
        ),
      );

      final cityDropdown = tester.widget<DropdownButtonFormField<String>>(
        find.byType(DropdownButtonFormField<String>).last,
      );
      expect(cityDropdown.onChanged, isNull);
    });

    testWidgets('debe tener iconos correctos en cada dropdown', (tester) async {
      final state = AddGossipState(
        idempotencyKey: 'test-key',
        countries: mockCountries,
        selectedCountryId: '1',
        regions: mockRegions,
        selectedRegionId: 'ant',
        cities: mockCities,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LocationSelector(
              state: state,
              onCountrySelected: (_) {},
              onRegionSelected: (_) {},
              onCitySelected: (_) {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.public), findsOneWidget);
      expect(find.byIcon(Icons.location_city), findsOneWidget);
      expect(find.byIcon(Icons.location_on), findsOneWidget);
    });

    testWidgets('debe tener labels correctos', (tester) async {
      final state = AddGossipState(
        idempotencyKey: 'test-key',
        countries: mockCountries,
        selectedCountryId: '1',
        regions: mockRegions,
        selectedRegionId: 'ant',
        cities: mockCities,
      );

      await tester.pumpWidget(
        testableWidget(
          child: LocationSelector(
            state: state,
            onCountrySelected: (_) {},
            onRegionSelected: (_) {},
            onCitySelected: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('País'), findsOneWidget);
      expect(find.text('Región'), findsOneWidget);
      expect(find.text('Ciudad'), findsOneWidget);
    });

    testWidgets('debe tener espaciado correcto entre dropdowns', (tester) async {
      final state = AddGossipState(
        idempotencyKey: 'test-key',
        countries: mockCountries,
        selectedCountryId: '1',
        regions: mockRegions,
        selectedRegionId: 'ant',
        cities: mockCities,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LocationSelector(
              state: state,
              onCountrySelected: (_) {},
              onRegionSelected: (_) {},
              onCitySelected: (_) {},
            ),
          ),
        ),
      );

      final sizedBoxes = tester.widgetList<SizedBox>(find.byType(SizedBox));
      final spacings = sizedBoxes.where((box) => box.height == 16.0);
      expect(spacings.length, greaterThanOrEqualTo(2));
    });

    testWidgets('debe tener Column como contenedor principal', (tester) async {
      final state = AddGossipState(
        idempotencyKey: 'test-key',
        countries: mockCountries,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LocationSelector(
              state: state,
              onCountrySelected: (_) {},
              onRegionSelected: (_) {},
              onCitySelected: (_) {},
            ),
          ),
        ),
      );

      expect(find.byType(Column), findsWidgets);
    });

    testWidgets('dropdowns deben tener borderRadius correcto', (tester) async {
      final state = AddGossipState(
        idempotencyKey: 'test-key',
        countries: mockCountries,
        selectedCountryId: '1',
        regions: mockRegions,
        selectedRegionId: 'ant',
        cities: mockCities,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LocationSelector(
              state: state,
              onCountrySelected: (_) {},
              onRegionSelected: (_) {},
              onCitySelected: (_) {},
            ),
          ),
        ),
      );

      final countryDropdown = tester.widget<DropdownButtonFormField<String>>(
        find.byType(DropdownButtonFormField<String>).first,
      );

      final decoration = countryDropdown.decoration;
      final border = decoration.border as OutlineInputBorder;
      expect(border.borderRadius, BorderRadius.circular(12));
    });

    testWidgets('debe tener ValueKey único para cada dropdown', (tester) async {
      final state = AddGossipState(
        idempotencyKey: 'test-key',
        countries: mockCountries,
        selectedCountryId: '1',
        regions: mockRegions,
        selectedRegionId: 'ant',
        cities: mockCities,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LocationSelector(
              state: state,
              onCountrySelected: (_) {},
              onRegionSelected: (_) {},
              onCitySelected: (_) {},
            ),
          ),
        ),
      );

      expect(find.byKey(const ValueKey('country_1')), findsOneWidget);
      expect(find.byKey(const ValueKey('region_ant')), findsOneWidget);
      expect(find.byKey(const ValueKey('city_null')), findsOneWidget);
    });

    testWidgets('debe tener validadores en todos los dropdowns', (tester) async {
      final state = AddGossipState(
        idempotencyKey: 'test-key',
        countries: mockCountries,
        selectedCountryId: '1',
        regions: mockRegions,
        selectedRegionId: 'ant',
        cities: mockCities,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Form(
              child: LocationSelector(
                state: state,
                onCountrySelected: (_) {},
                onRegionSelected: (_) {},
                onCitySelected: (_) {},
              ),
            ),
          ),
        ),
      );

      final dropdowns = tester.widgetList<DropdownButtonFormField<String>>(
        find.byType(DropdownButtonFormField<String>),
      );

      for (final dropdown in dropdowns) {
        expect(dropdown.validator, isNotNull);
      }
    });

    testWidgets('validador de país debe retornar mensaje correcto', (tester) async {
      final state = AddGossipState(
        idempotencyKey: 'test-key',
        countries: mockCountries,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Form(
              child: LocationSelector(
                state: state,
                onCountrySelected: (_) {},
                onRegionSelected: (_) {},
                onCitySelected: (_) {},
              ),
            ),
          ),
        ),
      );

      final countryDropdown = tester.widget<DropdownButtonFormField<String>>(
        find.byType(DropdownButtonFormField<String>),
      );

      final validationResult = countryDropdown.validator?.call(null);
      expect(validationResult, isNotNull); // Verifica que hay error, no el contenido específico
      expect(validationResult, isA<String>()); // Verifica que es un string
    });

    testWidgets('validador de región debe retornar mensaje correcto', (tester) async {
      final state = AddGossipState(
        idempotencyKey: 'test-key',
        countries: mockCountries,
        selectedCountryId: '1',
        regions: mockRegions,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Form(
              child: LocationSelector(
                state: state,
                onCountrySelected: (_) {},
                onRegionSelected: (_) {},
                onCitySelected: (_) {},
              ),
            ),
          ),
        ),
      );

      final regionDropdown = tester.widget<DropdownButtonFormField<String>>(
        find.byType(DropdownButtonFormField<String>).last,
      );

      final validationResult = regionDropdown.validator?.call(null);
      expect(validationResult, isNotNull); // Verifica que hay error, no el contenido específico
      expect(validationResult, isA<String>()); // Verifica que es un string
    });

    testWidgets('validador de ciudad debe retornar mensaje correcto', (tester) async {
      final state = AddGossipState(
        idempotencyKey: 'test-key',
        countries: mockCountries,
        selectedCountryId: '1',
        regions: mockRegions,
        selectedRegionId: 'ant',
        cities: mockCities,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Form(
              child: LocationSelector(
                state: state,
                onCountrySelected: (_) {},
                onRegionSelected: (_) {},
                onCitySelected: (_) {},
              ),
            ),
          ),
        ),
      );

      final cityDropdown = tester.widget<DropdownButtonFormField<String>>(
        find.byType(DropdownButtonFormField<String>).last,
      );

      final validationResult = cityDropdown.validator?.call(null);
      expect(validationResult, isNotNull); // Verifica que hay error, no el contenido específico
      expect(validationResult, isA<String>()); // Verifica que es un string
    });

    testWidgets('debe renderizar SizedBox.shrink cuando no hay país', (tester) async {
      final state = AddGossipState(
        idempotencyKey: 'test-key',
        countries: mockCountries,
        selectedCountryId: null,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LocationSelector(
              state: state,
              onCountrySelected: (_) {},
              onRegionSelected: (_) {},
              onCitySelected: (_) {},
            ),
          ),
        ),
      );

      // Solo debe haber un dropdown
      expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
    });

    testWidgets('debe renderizar SizedBox.shrink cuando no hay región', (tester) async {
      final state = AddGossipState(
        idempotencyKey: 'test-key',
        countries: mockCountries,
        selectedCountryId: '1',
        regions: mockRegions,
        selectedRegionId: null,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LocationSelector(
              state: state,
              onCountrySelected: (_) {},
              onRegionSelected: (_) {},
              onCitySelected: (_) {},
            ),
          ),
        ),
      );

      // Debe haber 2 dropdowns (país y región), pero no ciudad
      expect(find.byType(DropdownButtonFormField<String>), findsNWidgets(2));
    });

    testWidgets('debe inicializar con valores seleccionados', (tester) async {
      final state = AddGossipState(
        idempotencyKey: 'test-key',
        countries: mockCountries,
        selectedCountryId: '1',
        regions: mockRegions,
        selectedRegionId: 'ant',
        cities: mockCities,
        selectedCityId: 'med',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LocationSelector(
              state: state,
              onCountrySelected: (_) {},
              onRegionSelected: (_) {},
              onCitySelected: (_) {},
            ),
          ),
        ),
      );

      final countryDropdown = tester.widget<DropdownButtonFormField<String>>(
        find.byType(DropdownButtonFormField<String>).at(0),
      );
      expect(countryDropdown.initialValue, '1');

      final regionDropdown = tester.widget<DropdownButtonFormField<String>>(
        find.byType(DropdownButtonFormField<String>).at(1),
      );
      expect(regionDropdown.initialValue, 'ant');

      final cityDropdown = tester.widget<DropdownButtonFormField<String>>(
        find.byType(DropdownButtonFormField<String>).at(2),
      );
      expect(cityDropdown.initialValue, 'med');
    });

    testWidgets('CircularProgressIndicator debe tener strokeWidth 2', (tester) async {
      const state = AddGossipState(
        idempotencyKey: 'test-key',
        isLoadingCountries: true,
        countries: [],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LocationSelector(
              state: state,
              onCountrySelected: (_) {},
              onRegionSelected: (_) {},
              onCitySelected: (_) {},
            ),
          ),
        ),
      );

      final progress = tester.widget<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator),
      );
      expect(progress.strokeWidth, 2);
    });

    testWidgets('suffixIcon debe ser CircularProgressIndicator durante loading', (tester) async {
      const state = AddGossipState(
        idempotencyKey: 'test-key',
        isLoadingCountries: true,
        countries: [],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LocationSelector(
              state: state,
              onCountrySelected: (_) {},
              onRegionSelected: (_) {},
              onCitySelected: (_) {},
            ),
          ),
        ),
      );

      final dropdown = tester.widget<DropdownButtonFormField<String>>(
        find.byType(DropdownButtonFormField<String>),
      );
      expect(dropdown.decoration.suffixIcon, isNotNull);
    });

    testWidgets('suffixIcon debe ser null cuando NO está loading', (tester) async {
      final state = AddGossipState(
        idempotencyKey: 'test-key',
        countries: mockCountries,
        isLoadingCountries: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LocationSelector(
              state: state,
              onCountrySelected: (_) {},
              onRegionSelected: (_) {},
              onCitySelected: (_) {},
            ),
          ),
        ),
      );

      final dropdown = tester.widget<DropdownButtonFormField<String>>(
        find.byType(DropdownButtonFormField<String>),
      );
      expect(dropdown.decoration.suffixIcon, isNull);
    });
  });
}
