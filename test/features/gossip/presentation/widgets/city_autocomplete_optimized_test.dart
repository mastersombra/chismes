import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:chismes/features/gossip/presentation/widgets/city_autocomplete_optimized.dart';
import 'package:chismes/features/location/domain/entities/city.dart';
import 'package:chismes/features/location/domain/usecases/search_cities.dart';
import 'package:chismes/core/result/result.dart';
import 'package:chismes/core/error/failure.dart';
import 'package:chismes/core/error/error_codes.dart';

import 'city_autocomplete_optimized_test.mocks.dart';

@GenerateMocks([SearchCities])
void main() {
  group('CityAutocompleteOptimized', () {
    late MockSearchCities mockSearchCities;

    const testCities = [
      City(id: '1', name: 'Medellín', regionId: 'co-antioquia'),
      City(id: '2', name: 'Medina', regionId: 'co-antioquia'),
    ];

    setUp(() {
      mockSearchCities = MockSearchCities();

      // Proporcionar dummy value para Result<Failure, List<City>>
      provideDummy<Result<Failure, List<City>>>(
        Result.success(<City>[]),
      );
    });

    Widget buildWidget({
      String regionId = 'co-antioquia',
      City? selectedCity,
      void Function(City?)? onCitySelected,
      String? Function(String?)? validator,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: CityAutocompleteOptimized(
            regionId: regionId,
            searchCities: mockSearchCities,
            selectedCity: selectedCity,
            onCitySelected: onCitySelected ?? (_) {},
            validator: validator,
          ),
        ),
      );
    }

    testWidgets('debe renderizar TextField con label y hint', (tester) async {
      await tester.pumpWidget(buildWidget());

      expect(find.text('Ciudad'), findsOneWidget);
      expect(find.textContaining('Buscar ciudad...'), findsOneWidget);
      expect(find.byIcon(Icons.location_on), findsOneWidget);
    });

    testWidgets('debe mostrar ciudad seleccionada en el TextField', (tester) async {
      await tester.pumpWidget(
        buildWidget(
          selectedCity: const City(id: '1', name: 'Medellín', regionId: 'co-antioquia'),
        ),
      );

      expect(find.text('Medellín'), findsOneWidget);
    });

    testWidgets('debe mostrar mensaje de mínimo de caracteres cuando query < 2', (tester) async {
      await tester.pumpWidget(buildWidget());

      // Hacer focus
      await tester.tap(find.byType(TextFormField));
      await tester.pump();

      // Escribir 1 carácter
      await tester.enterText(find.byType(TextFormField), 'M');
      await tester.pump();

      expect(find.textContaining('al menos 2 caracteres'), findsOneWidget);
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
    });

    testWidgets('debe buscar ciudades después de debounce', (tester) async {
      when(mockSearchCities.call(
        query: anyNamed('query'),
        regionId: anyNamed('regionId'),
        maxResults: anyNamed('maxResults'),
      )).thenAnswer((_) async => Result.success(testCities));

      await tester.pumpWidget(buildWidget());

      // Hacer focus y escribir
      await tester.tap(find.byType(TextFormField));
      await tester.enterText(find.byType(TextFormField), 'Med');
      await tester.pump();

      // Verificar que NO se llama inmediatamente
      verifyNever(mockSearchCities.call(
        query: anyNamed('query'),
        regionId: anyNamed('regionId'),
        maxResults: anyNamed('maxResults'),
      ));

      // Esperar debounce (300ms)
      await tester.pump(const Duration(milliseconds: 300));

      // Verificar que SÍ se llama después del debounce
      verify(mockSearchCities.call(
        query: 'Med',
        regionId: 'co-antioquia',
        maxResults: 20,
      )).called(1);
    });

    testWidgets('debe mostrar loading indicator mientras busca', (tester) async {
      when(mockSearchCities.call(
        query: anyNamed('query'),
        regionId: anyNamed('regionId'),
        maxResults: anyNamed('maxResults'),
      )).thenAnswer((_) async {
        // Simular delay
        await Future.delayed(const Duration(milliseconds: 100));
        return Result.success(testCities);
      });

      await tester.pumpWidget(buildWidget());

      await tester.tap(find.byType(TextFormField));
      await tester.enterText(find.byType(TextFormField), 'Med');
      await tester.pump();

      // Esperar debounce
      await tester.pump(const Duration(milliseconds: 300));

      // Debe mostrar loading
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Esperar respuesta
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump();

      // Ya no debe mostrar loading
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('debe mostrar resultados de búsqueda exitosa', (tester) async {
      when(mockSearchCities.call(
        query: anyNamed('query'),
        regionId: anyNamed('regionId'),
        maxResults: anyNamed('maxResults'),
      )).thenAnswer((_) async => Result.success(testCities));

      await tester.pumpWidget(buildWidget());

      await tester.tap(find.byType(TextFormField));
      await tester.enterText(find.byType(TextFormField), 'Med');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();

      expect(find.text('Medellín'), findsOneWidget);
      expect(find.text('Medina'), findsOneWidget);
    });

    testWidgets('debe mostrar mensaje de error en búsqueda fallida', (tester) async {
      when(mockSearchCities.call(
        query: anyNamed('query'),
        regionId: anyNamed('regionId'),
        maxResults: anyNamed('maxResults'),
      )).thenAnswer((_) async => Result.failure(
            const NetworkFailure(
              code: ErrorCode.networkError,
              technicalMessage: 'Error de red',
            ),
          ));

      await tester.pumpWidget(buildWidget());

      await tester.tap(find.byType(TextFormField));
      await tester.enterText(find.byType(TextFormField), 'Med');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();

      expect(find.textContaining('Error al buscar ciudades'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('debe usar cache en segunda búsqueda', (tester) async {
      when(mockSearchCities.call(
        query: anyNamed('query'),
        regionId: anyNamed('regionId'),
        maxResults: anyNamed('maxResults'),
      )).thenAnswer((_) async => Result.success(testCities));

      await tester.pumpWidget(buildWidget());

      // Primera búsqueda
      await tester.tap(find.byType(TextFormField));
      await tester.enterText(find.byType(TextFormField), 'Med');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();

      // Borrar y volver a escribir lo mismo
      await tester.enterText(find.byType(TextFormField), '');
      await tester.pump();
      await tester.enterText(find.byType(TextFormField), 'Med');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();

      // Solo debe haber llamado 1 vez (segunda vez usa cache)
      verify(mockSearchCities.call(
        query: 'Med',
        regionId: 'co-antioquia',
        maxResults: 20,
      )).called(1);
    });

    testWidgets('debe limpiar resultados cuando query está vacío', (tester) async {
      when(mockSearchCities.call(
        query: anyNamed('query'),
        regionId: anyNamed('regionId'),
        maxResults: anyNamed('maxResults'),
      )).thenAnswer((_) async => Result.success(testCities));

      await tester.pumpWidget(buildWidget());

      // Buscar
      await tester.tap(find.byType(TextFormField));
      await tester.enterText(find.byType(TextFormField), 'Med');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();

      expect(find.text('Medellín'), findsOneWidget);

      // Limpiar
      await tester.enterText(find.byType(TextFormField), '');
      await tester.pump();

      expect(find.text('Medellín'), findsNothing);
    });

    testWidgets('debe mostrar clear button cuando hay texto', (tester) async {
      await tester.pumpWidget(buildWidget());

      // Escribir texto corto (< 2 chars) para que NO inicie búsqueda
      await tester.tap(find.byType(TextFormField));
      await tester.enterText(find.byType(TextFormField), 'M');
      await tester.pump();

      // Debe mostrar clear button (no está buscando porque es < 2 chars)
      expect(find.byIcon(Icons.clear), findsOneWidget);
    });

    testWidgets('debe limpiar texto y llamar onCitySelected(null) al presionar clear', (tester) async {
      City? selectedCity = const City(id: '1', name: 'Medellín', regionId: 'co-antioquia');

      await tester.pumpWidget(
        buildWidget(onCitySelected: (city) => selectedCity = city),
      );

      // Escribir texto corto para que NO inicie búsqueda
      await tester.tap(find.byType(TextFormField));
      await tester.enterText(find.byType(TextFormField), 'M');
      await tester.pump();

      // Presionar clear
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pump();

      final textField = tester.widget<TextFormField>(find.byType(TextFormField));
      expect(textField.controller?.text, '');
      expect(selectedCity, isNull);
    });

    testWidgets('debe llamar onCitySelected y unfocus al seleccionar ciudad', (tester) async {
      when(mockSearchCities.call(
        query: anyNamed('query'),
        regionId: anyNamed('regionId'),
        maxResults: anyNamed('maxResults'),
      )).thenAnswer((_) async => Result.success(testCities));

      City? selectedCity;

      await tester.pumpWidget(
        buildWidget(onCitySelected: (city) => selectedCity = city),
      );

      // Buscar
      await tester.tap(find.byType(TextFormField));
      await tester.enterText(find.byType(TextFormField), 'Med');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();

      // Seleccionar Medellín
      await tester.tap(find.text('Medellín'));
      await tester.pumpAndSettle();

      expect(selectedCity?.id, '1');
      expect(selectedCity?.name, 'Medellín');

      // Verificar que no hay lista visible (unfocus)
      expect(find.byType(ListTile), findsNothing);
    });

    testWidgets('debe actualizar TextField al seleccionar ciudad', (tester) async {
      when(mockSearchCities.call(
        query: anyNamed('query'),
        regionId: anyNamed('regionId'),
        maxResults: anyNamed('maxResults'),
      )).thenAnswer((_) async => Result.success(testCities));

      await tester.pumpWidget(buildWidget());

      await tester.tap(find.byType(TextFormField));
      await tester.enterText(find.byType(TextFormField), 'Med');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();

      await tester.tap(find.text('Medina'));
      await tester.pump();

      final textField = tester.widget<TextFormField>(find.byType(TextFormField));
      expect(textField.controller?.text, 'Medina');
    });

    testWidgets('debe resaltar ciudad seleccionada en la lista', (tester) async {
      when(mockSearchCities.call(
        query: anyNamed('query'),
        regionId: anyNamed('regionId'),
        maxResults: anyNamed('maxResults'),
      )).thenAnswer((_) async => Result.success(testCities));

      await tester.pumpWidget(
        buildWidget(
          selectedCity: const City(id: '1', name: 'Medellín', regionId: 'co-antioquia'),
        ),
      );

      await tester.tap(find.byType(TextFormField));
      await tester.enterText(find.byType(TextFormField), 'Med');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();

      // Debe haber un check icon en la ciudad seleccionada
      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('debe mostrar mensaje cuando no hay resultados', (tester) async {
      when(mockSearchCities.call(
        query: anyNamed('query'),
        regionId: anyNamed('regionId'),
        maxResults: anyNamed('maxResults'),
      )).thenAnswer((_) async => Result.success([]));

      await tester.pumpWidget(buildWidget());

      await tester.tap(find.byType(TextFormField));
      await tester.enterText(find.byType(TextFormField), 'XYZ');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();

      expect(find.textContaining('No se encontraron ciudades'), findsOneWidget);
      expect(find.byIcon(Icons.search_off), findsOneWidget);
    });

    testWidgets('debe limpiar búsqueda y cache al cambiar región', (tester) async {
      when(mockSearchCities.call(
        query: anyNamed('query'),
        regionId: anyNamed('regionId'),
        maxResults: anyNamed('maxResults'),
      )).thenAnswer((_) async => Result.success(testCities));

      Widget buildWithRegion(String regionId) {
        return MaterialApp(
          home: Scaffold(
            body: CityAutocompleteOptimized(
              regionId: regionId,
              searchCities: mockSearchCities,
              onCitySelected: (_) {},
            ),
          ),
        );
      }

      await tester.pumpWidget(buildWithRegion('co-antioquia'));

      // Buscar en región 1
      await tester.tap(find.byType(TextFormField));
      await tester.enterText(find.byType(TextFormField), 'Med');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();

      expect(find.text('Medellín'), findsOneWidget);

      // Cambiar región
      await tester.pumpWidget(buildWithRegion('co-cundinamarca'));
      await tester.pump();

      // TextField debe estar vacío
      final textField = tester.widget<TextFormField>(find.byType(TextFormField));
      expect(textField.controller?.text, '');

      // No debe haber resultados visibles
      expect(find.text('Medellín'), findsNothing);
    });

    testWidgets('debe actualizar TextField cuando cambia selectedCity externamente', (tester) async {
      Widget buildWithSelected(City? selected) {
        return MaterialApp(
          home: Scaffold(
            body: CityAutocompleteOptimized(
              regionId: 'co-antioquia',
              searchCities: mockSearchCities,
              selectedCity: selected,
              onCitySelected: (_) {},
            ),
          ),
        );
      }

      await tester.pumpWidget(buildWithSelected(null));

      final textField = tester.widget<TextFormField>(find.byType(TextFormField));
      expect(textField.controller?.text, '');

      // Cambiar selectedCity externamente
      await tester.pumpWidget(
        buildWithSelected(
          const City(id: '2', name: 'Medina', regionId: 'co-antioquia'),
        ),
      );
      await tester.pump();

      final updatedTextField = tester.widget<TextFormField>(find.byType(TextFormField));
      expect(updatedTextField.controller?.text, 'Medina');
    });

    testWidgets('debe llamar validator si está definido', (tester) async {
      String? validationError;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Form(
              child: CityAutocompleteOptimized(
                regionId: 'co-antioquia',
                searchCities: mockSearchCities,
                onCitySelected: (_) {},
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    validationError = 'Campo requerido';
                    return 'Campo requerido';
                  }
                  return null;
                },
              ),
            ),
          ),
        ),
      );

      // Trigger validation
      final formState = tester.state<FormState>(find.byType(Form));
      formState.validate();
      await tester.pump();

      expect(validationError, 'Campo requerido');
      expect(find.text('Campo requerido'), findsOneWidget);
    });

    testWidgets('no debe mostrar sugerencias cuando pierde focus', (tester) async {
      when(mockSearchCities.call(
        query: anyNamed('query'),
        regionId: anyNamed('regionId'),
        maxResults: anyNamed('maxResults'),
      )).thenAnswer((_) async => Result.success(testCities));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                CityAutocompleteOptimized(
                  regionId: 'co-antioquia',
                  searchCities: mockSearchCities,
                  onCitySelected: (_) {},
                ),
                const TextField(key: Key('other')),
              ],
            ),
          ),
        ),
      );

      // Buscar
      await tester.tap(find.byType(CityAutocompleteOptimized));
      await tester.enterText(find.byType(TextFormField).first, 'Med');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();

      expect(find.byType(ListTile), findsWidgets);

      // Hacer focus en otro widget
      await tester.tap(find.byKey(const Key('other')));
      await tester.pump();

      // No debe mostrar sugerencias
      expect(find.byType(ListTile), findsNothing);
    });

    testWidgets('debe cancelar requests obsoletos', (tester) async {
      final Future<Result<Failure, List<City>>> completer1 = Future.delayed(
        const Duration(milliseconds: 500),
        () => Result.success(testCities),
      );

      final Future<Result<Failure, List<City>>> completer2 = Future.value(Result.success([
        const City(id: '3', name: 'Bogotá', regionId: 'co-cundinamarca'),
      ]));

      when(mockSearchCities.call(
        query: 'Med',
        regionId: anyNamed('regionId'),
        maxResults: anyNamed('maxResults'),
      )).thenAnswer((_) => completer1);

      when(mockSearchCities.call(
        query: 'Bog',
        regionId: anyNamed('regionId'),
        maxResults: anyNamed('maxResults'),
      )).thenAnswer((_) => completer2);

      await tester.pumpWidget(buildWidget());

      // Primera búsqueda (lenta)
      await tester.tap(find.byType(TextFormField));
      await tester.enterText(find.byType(TextFormField), 'Med');
      await tester.pump(const Duration(milliseconds: 300));

      // Segunda búsqueda (rápida) - antes de que complete la primera
      await tester.enterText(find.byType(TextFormField), 'Bog');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();

      // Esperar a que complete la primera
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();

      // Solo debe mostrar resultados de la segunda búsqueda
      expect(find.text('Bogotá'), findsOneWidget);
      expect(find.text('Medellín'), findsNothing);
    });

    testWidgets('debe limitar cache a 50 entradas (FIFO)', (tester) async {
      await tester.pumpWidget(buildWidget());

      // Simular 51 búsquedas diferentes
      for (int i = 0; i <= 50; i++) {
        when(mockSearchCities.call(
          query: 'query$i',
          regionId: anyNamed('regionId'),
          maxResults: anyNamed('maxResults'),
        )).thenAnswer((_) async => Result.success([
              City(id: '$i', name: 'City$i', regionId: 'co-antioquia'),
            ]));

        await tester.tap(find.byType(TextFormField));
        await tester.enterText(find.byType(TextFormField), 'query$i');
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump();
      }

      // La primera búsqueda (query0) debería haber sido eliminada del cache
      // Buscar de nuevo query0
      await tester.enterText(find.byType(TextFormField), '');
      await tester.pump();
      await tester.enterText(find.byType(TextFormField), 'query0');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();

      // Debe llamar de nuevo (no está en cache)
      verify(mockSearchCities.call(
        query: 'query0',
        regionId: 'co-antioquia',
        maxResults: 20,
      )).called(2); // Primera vez + después de ser eliminado del cache
    });

    testWidgets('debe mostrar íconos correctos en la lista', (tester) async {
      when(mockSearchCities.call(
        query: anyNamed('query'),
        regionId: anyNamed('regionId'),
        maxResults: anyNamed('maxResults'),
      )).thenAnswer((_) async => Result.success(testCities));

      await tester.pumpWidget(buildWidget());

      await tester.tap(find.byType(TextFormField));
      await tester.enterText(find.byType(TextFormField), 'Med');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();

      expect(find.byIcon(Icons.location_city), findsNWidgets(testCities.length));
    });

    testWidgets('debe tener constraints en lista de sugerencias', (tester) async {
      when(mockSearchCities.call(
        query: anyNamed('query'),
        regionId: anyNamed('regionId'),
        maxResults: anyNamed('maxResults'),
      )).thenAnswer((_) async => Result.success(testCities));

      await tester.pumpWidget(buildWidget());

      await tester.tap(find.byType(TextFormField));
      await tester.enterText(find.byType(TextFormField), 'Med');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();

      final container = tester.widget<Container>(
        find.ancestor(
          of: find.byType(ListView),
          matching: find.byType(Container),
        ).first,
      );

      expect(container.constraints?.maxHeight, 200);
    });

    testWidgets('debe cancelar debounce timer en dispose', (tester) async {
      await tester.pumpWidget(buildWidget());

      await tester.tap(find.byType(TextFormField));
      await tester.enterText(find.byType(TextFormField), 'Med');
      await tester.pump();

      // Dispose antes de que complete el debounce
      await tester.pumpWidget(const MaterialApp(home: Scaffold()));

      // Esperar más que el debounce
      await tester.pump(const Duration(milliseconds: 400));

      // No debe haberse llamado (timer cancelado)
      verifyNever(mockSearchCities.call(
        query: anyNamed('query'),
        regionId: anyNamed('regionId'),
        maxResults: anyNamed('maxResults'),
      ));
    });

    testWidgets('debe manejar excepciones en búsqueda', (tester) async {
      when(mockSearchCities.call(
        query: anyNamed('query'),
        regionId: anyNamed('regionId'),
        maxResults: anyNamed('maxResults'),
      )).thenThrow(Exception('Unexpected error'));

      await tester.pumpWidget(buildWidget());

      await tester.tap(find.byType(TextFormField));
      await tester.enterText(find.byType(TextFormField), 'Med');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();

      expect(find.textContaining('Error inesperado'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });
  });
}
