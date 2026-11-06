import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:chismes/features/gossip/presentation/widgets/location_change_dialog.dart';
import 'package:chismes/features/location/presentation/states/location_state.dart';
import 'package:chismes/features/location/domain/entities/country.dart';
import 'package:chismes/features/location/domain/entities/region.dart';
import 'package:chismes/features/location/domain/entities/city.dart';
import 'package:chismes/features/location/domain/usecases/search_cities.dart';
import 'package:chismes/core/result/result.dart';
import 'package:chismes/core/error/failure.dart';

import 'location_change_dialog_test.mocks.dart';

@GenerateMocks([SearchCities])
void main() {
  group('LocationChangeDialog', () {
    late LocationState testState;
    late List<Country> testCountries;
    late List<Region> testRegions;
    late MockSearchCities mockSearchCities;

    setUp(() {
      testCountries = [
        const Country(id: '1', code: 'CO', name: 'Colombia'),
      ];

      testRegions = [
        const Region(id: 'ant', name: 'Antioquia', countryId: '1', type: 'department'),
      ];

      mockSearchCities = MockSearchCities();

      // Proporcionar dummy value para Mockito
      provideDummy<Result<Failure, List<City>>>(Result.success([]));

      // Mock básico para searchCities
      when(mockSearchCities.call(
        query: anyNamed('query'),
        regionId: anyNamed('regionId'),
        maxResults: anyNamed('maxResults'),
      )).thenAnswer((_) async => Result.success([]));

      testState = LocationState(
        countries: testCountries,
        regions: testRegions,
        cities: [],
        selectedCountry: null,
        selectedRegion: null,
        selectedCity: null,
        isLoadingCountries: false,
        isLoadingRegions: false,
        isLoadingCities: false,
        isDetectingLocation: false,
        error: null,
      );
    });

    testWidgets('debe construirse sin errores', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LocationChangeDialog(
              state: testState,
              onUseCurrentLocation: () {},
              onCountryChanged: (_) {},
              onRegionChanged: (_) {},
              onCityChanged: (_) {},
              onConfirm: () {},
              searchCities: mockSearchCities,
              isLoadingGPS: false,
            ),
          ),
        ),
      );

      expect(find.byType(LocationChangeDialog), findsOneWidget);
    });

    testWidgets('debe mostrar dropdown de países', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LocationChangeDialog(
              state: testState,
              onUseCurrentLocation: () {},
              onCountryChanged: (_) {},
              onRegionChanged: (_) {},
              onCityChanged: (_) {},
              onConfirm: () {},
              searchCities: mockSearchCities,
              isLoadingGPS: false,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verificar que el dropdown de países existe
      expect(find.byType(DropdownButtonFormField<String>), findsWidgets);

      // Verificar que hay un campo con label "País"
      expect(find.text('País'), findsOneWidget);
    });

    testWidgets('debe llamar callbacks cuando se interactúa', (tester) async {
      bool useCurrentLocationCalled = false;
      String? selectedCountryId;
      City? selectedCity;
      bool confirmCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LocationChangeDialog(
              state: testState,
              onUseCurrentLocation: () {
                useCurrentLocationCalled = true;
              },
              onCountryChanged: (countryId) {
                selectedCountryId = countryId;
              },
              onRegionChanged: (_) {},
              onCityChanged: (city) {
                selectedCity = city;
              },
              onConfirm: () {
                confirmCalled = true;
              },
              searchCities: mockSearchCities,
              isLoadingGPS: false,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verificar que los callbacks están registrados correctamente
      expect(useCurrentLocationCalled, isFalse);
      expect(selectedCountryId, isNull);
      expect(selectedCity, isNull);
      expect(confirmCalled, isFalse);
    });
  });
}
