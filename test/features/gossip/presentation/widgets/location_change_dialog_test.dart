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
import 'package:chismes/features/gossip/presentation/widgets/city_autocomplete_optimized.dart';
import 'package:chismes/features/location/presentation/managers/location_error_key.dart';
import 'package:chismes/l10n/app_localizations.dart';
import '../../../../helpers/widget_test_wrapper.dart';

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
        testableWidget(
          child: LocationChangeDialog(
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
      );
      await tester.pumpAndSettle();

      expect(find.byType(LocationChangeDialog), findsOneWidget);
    });

    testWidgets('debe mostrar dropdown de países', (tester) async {
      await tester.pumpWidget(
        testableWidget(
          child: LocationChangeDialog(
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
      );
      await tester.pumpAndSettle();

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
        testableWidget(
          child: LocationChangeDialog(
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
      );
      await tester.pumpAndSettle();

      // Tocar la tarjeta GPS dispara onUseCurrentLocation
      await tester.tap(find.byIcon(Icons.my_location));
      await tester.pump();
      expect(useCurrentLocationCalled, isTrue);

      // Elegir un país dispara onCountryChanged con su id
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Colombia').last);
      await tester.pumpAndSettle();
      expect(selectedCountryId, '1');

      // Sin ciudad seleccionada no se confirma
      expect(selectedCity, isNull);
      expect(confirmCalled, isFalse);
    });

    group('Interacciones completas', () {
      const country = Country(id: '1', code: 'CO', name: 'Colombia');
      const region =
          Region(id: 'ant', name: 'Antioquia', countryId: '1', type: 'department');
      const city = City(id: 'med', regionId: 'ant', name: 'Medellín');

      late int gpsCalls;
      late int confirmCalls;
      late List<String?> countryChanges;
      late List<String?> regionChanges;

      setUp(() {
        gpsCalls = 0;
        confirmCalls = 0;
        countryChanges = [];
        regionChanges = [];
      });

      LocationState stateWith({
        Country? selectedCountry,
        Region? selectedRegion,
        City? selectedCity,
        bool isLoadingCountries = false,
        bool isLoadingRegions = false,
        LocationErrorKey? errorKey,
        String? errorEntityName,
      }) {
        return LocationState(
          countries: testCountries,
          regions: testRegions,
          cities: const [],
          selectedCountry: selectedCountry,
          selectedRegion: selectedRegion,
          selectedCity: selectedCity,
          isLoadingCountries: isLoadingCountries,
          isLoadingRegions: isLoadingRegions,
          isLoadingCities: false,
          isDetectingLocation: false,
          errorKey: errorKey,
          errorEntityName: errorEntityName,
        );
      }

      LocationChangeDialog buildDialog(LocationState state,
          {bool isLoadingGPS = false}) {
        return LocationChangeDialog(
          state: state,
          onUseCurrentLocation: () => gpsCalls++,
          onCountryChanged: countryChanges.add,
          onRegionChanged: regionChanges.add,
          onCityChanged: (_) {},
          onConfirm: () => confirmCalls++,
          searchCities: mockSearchCities,
          isLoadingGPS: isLoadingGPS,
        );
      }

      /// Monta el diálogo encima de una ruta base para poder probar el pop.
      Future<AppLocalizations> pumpAsDialog(
          WidgetTester tester, LocationState state) async {
        await tester.pumpWidget(
          testableWidget(
            child: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => buildDialog(state),
                ),
                child: const Text('HOST'),
              ),
            ),
          ),
        );
        await tester.tap(find.text('HOST'));
        await tester.pumpAndSettle();
        expect(find.byType(LocationChangeDialog), findsOneWidget);
        return AppLocalizations.of(
            tester.element(find.byType(LocationChangeDialog)))!;
      }

      Future<AppLocalizations> pumpInline(
          WidgetTester tester, LocationState state,
          {bool isLoadingGPS = false}) async {
        await tester.pumpWidget(testableWidget(
          child: buildDialog(state, isLoadingGPS: isLoadingGPS),
        ));
        await tester.pumpAndSettle();
        return AppLocalizations.of(
            tester.element(find.byType(LocationChangeDialog)))!;
      }

      testWidgets('el botón cerrar hace pop del diálogo', (tester) async {
        await pumpAsDialog(tester, stateWith());

        await tester.tap(find.byIcon(Icons.close));
        await tester.pumpAndSettle();

        expect(find.byType(LocationChangeDialog), findsNothing);
        expect(find.text('HOST'), findsOneWidget);
        expect(confirmCalls, 0);
      });

      testWidgets('el botón cancelar hace pop sin confirmar', (tester) async {
        final l10n = await pumpAsDialog(tester, stateWith());

        await tester.tap(find.text(l10n.cancel));
        await tester.pumpAndSettle();

        expect(find.byType(LocationChangeDialog), findsNothing);
        expect(confirmCalls, 0);
      });

      testWidgets('muestra el error localizado con el nombre de la entidad',
          (tester) async {
        final l10n = await pumpInline(
          tester,
          stateWith(
            errorKey: LocationErrorKey.countryNotAvailable,
            errorEntityName: 'Narnia',
          ),
        );

        expect(find.byIcon(Icons.error_outline), findsOneWidget);
        expect(find.text(l10n.locationErrorCountryNotAvailable('Narnia')),
            findsOneWidget);
      });

      testWidgets('sin error no muestra el banner', (tester) async {
        await pumpInline(tester, stateWith());
        expect(find.byIcon(Icons.error_outline), findsNothing);
      });

      testWidgets('GPS cargando: muestra texto de detección y no responde al tap',
          (tester) async {
        await tester.pumpWidget(testableWidget(
          child: buildDialog(stateWith(), isLoadingGPS: true),
        ));
        await tester.pump();
        final l10n = AppLocalizations.of(
            tester.element(find.byType(LocationChangeDialog)))!;

        expect(find.text(l10n.gossipLocationSelectorDetectingText),
            findsOneWidget);
        expect(find.text(l10n.locationUseCurrentLocation), findsNothing);
        expect(find.byIcon(Icons.arrow_forward_ios), findsNothing);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        await tester.tap(find.byIcon(Icons.my_location));
        await tester.pump();
        expect(gpsCalls, 0);
      });

      testWidgets('países cargando: spinner y dropdown deshabilitado',
          (tester) async {
        await tester.pumpWidget(testableWidget(
          child: buildDialog(stateWith(isLoadingCountries: true)),
        ));
        await tester.pump();

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        await tester.tap(find.byType(DropdownButtonFormField<String>));
        await tester.pump();
        expect(find.text('Colombia'), findsNothing);
        expect(countryChanges, isEmpty);
      });

      testWidgets('con país seleccionado muestra regiones y notifica el cambio',
          (tester) async {
        final l10n =
            await pumpInline(tester, stateWith(selectedCountry: country));

        expect(find.text(l10n.locationRegionLabel), findsOneWidget);
        expect(find.byType(CityAutocompleteOptimized), findsNothing);

        await tester.tap(find.byType(DropdownButtonFormField<String>).last);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Antioquia').last);
        await tester.pumpAndSettle();

        expect(regionChanges, ['ant']);
      });

      testWidgets('regiones cargando: spinner y dropdown deshabilitado',
          (tester) async {
        await tester.pumpWidget(testableWidget(
          child: buildDialog(
              stateWith(selectedCountry: country, isLoadingRegions: true)),
        ));
        await tester.pump();

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        await tester.tap(find.byType(DropdownButtonFormField<String>).last);
        await tester.pump();
        expect(find.text('Antioquia'), findsNothing);
        expect(regionChanges, isEmpty);
      });

      testWidgets('con región seleccionada muestra el autocomplete de ciudad',
          (tester) async {
        await pumpInline(
            tester, stateWith(selectedCountry: country, selectedRegion: region));

        final autocomplete = tester.widget<CityAutocompleteOptimized>(
            find.byType(CityAutocompleteOptimized));
        expect(autocomplete.regionId, 'ant');
        expect(autocomplete.searchCities, same(mockSearchCities));
      });

      testWidgets('confirmar sin ciudad está deshabilitado', (tester) async {
        final l10n = await pumpInline(
            tester, stateWith(selectedCountry: country, selectedRegion: region));

        final button = tester.widget<FilledButton>(find.byType(FilledButton));
        expect(button.onPressed, isNull);
        await tester.tap(find.text(l10n.confirm));
        await tester.pump();
        expect(confirmCalls, 0);
      });

      testWidgets('confirmar con todo válido llama onConfirm y hace pop',
          (tester) async {
        final l10n = await pumpAsDialog(
          tester,
          stateWith(
            selectedCountry: country,
            selectedRegion: region,
            selectedCity: city,
          ),
        );

        await tester.ensureVisible(find.text(l10n.confirm));
        await tester.tap(find.text(l10n.confirm));
        await tester.pumpAndSettle();

        expect(confirmCalls, 1);
        expect(find.byType(LocationChangeDialog), findsNothing);
      });

      testWidgets('confirmar con la ciudad borrada muestra error y no confirma',
          (tester) async {
        final l10n = await pumpAsDialog(
          tester,
          stateWith(
            selectedCountry: country,
            selectedRegion: region,
            selectedCity: city,
          ),
        );

        final cityField = find.descendant(
          of: find.byType(CityAutocompleteOptimized),
          matching: find.byType(TextFormField),
        );
        await tester.enterText(cityField, '');
        await tester.pump(const Duration(milliseconds: 300));
        await tester.ensureVisible(find.text(l10n.confirm));
        await tester.tap(find.text(l10n.confirm));
        await tester.pumpAndSettle();

        expect(find.text(l10n.locationCityRequired), findsOneWidget);
        expect(confirmCalls, 0);
        expect(find.byType(LocationChangeDialog), findsOneWidget);
      });

      testWidgets('confirmar sin país muestra locationCountryRequired',
          (tester) async {
        final l10n = await pumpAsDialog(tester, stateWith(selectedCity: city));

        await tester.ensureVisible(find.text(l10n.confirm));
        await tester.tap(find.text(l10n.confirm));
        await tester.pumpAndSettle();

        expect(find.text(l10n.locationCountryRequired), findsOneWidget);
        expect(confirmCalls, 0);
        expect(find.byType(LocationChangeDialog), findsOneWidget);
      });

      testWidgets('confirmar sin región muestra locationRegionRequired',
          (tester) async {
        final l10n = await pumpAsDialog(
          tester,
          stateWith(selectedCountry: country, selectedCity: city),
        );

        await tester.ensureVisible(find.text(l10n.confirm));
        await tester.tap(find.text(l10n.confirm));
        await tester.pumpAndSettle();

        expect(find.text(l10n.locationRegionRequired), findsOneWidget);
        expect(find.text(l10n.locationCountryRequired), findsNothing);
        expect(confirmCalls, 0);
      });
    });
  });
}
