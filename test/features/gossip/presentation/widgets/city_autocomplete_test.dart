import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chismes/features/gossip/presentation/widgets/city_autocomplete.dart';
import 'package:chismes/features/location/domain/entities/city.dart';
import '../../../../helpers/widget_test_wrapper.dart';

void main() {
  group('CityAutocomplete', () {
    final cities = [
      const City(id: '1', name: 'Medellín', regionId: 'ANT'),
      const City(id: '2', name: 'Medina', regionId: 'ANT'),
      const City(id: '3', name: 'Bogotá', regionId: 'CUN'),
      const City(id: '4', name: 'Cali', regionId: 'VAL'),
    ];

    testWidgets('debe renderizar TextField con label y hint', (tester) async {
      await tester.pumpWidget(
        testableWidget(
          child: CityAutocomplete(
              cities: cities,
              onCitySelected: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ciudad'), findsOneWidget);
      expect(find.text('Buscar ciudad...'), findsOneWidget);
      expect(find.byIcon(Icons.location_on), findsOneWidget);
    });

    testWidgets('debe mostrar ciudad seleccionada en el TextField', (tester) async {
      const selectedCity = City(id: '1', name: 'Medellín', regionId: 'ANT');

      await tester.pumpWidget(
        testableWidget(
          child: CityAutocomplete(
              cities: cities,
              selectedCity: selectedCity,
              onCitySelected: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Medellín'), findsOneWidget);
    });

    testWidgets('debe mostrar sugerencias al hacer focus', (tester) async {
      await tester.pumpWidget(
        testableWidget(
          child: CityAutocomplete(
              cities: cities,
              onCitySelected: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Hacer tap en el TextField para focus
      await tester.tap(find.byType(TextFormField));
      await tester.pump();

      // Debe mostrar todas las ciudades
      expect(find.text('Medellín'), findsOneWidget);
      expect(find.text('Medina'), findsOneWidget);
      expect(find.text('Bogotá'), findsOneWidget);
      expect(find.text('Cali'), findsOneWidget);
    });

    testWidgets('debe filtrar ciudades por coincidencia parcial', (tester) async {
      await tester.pumpWidget(
        testableWidget(
          child: CityAutocomplete(
              cities: cities,
              onCitySelected: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Hacer focus
      await tester.tap(find.byType(TextFormField));
      await tester.pump();

      // Escribir "Med"
      await tester.enterText(find.byType(TextFormField), 'Med');
      await tester.pump();

      // Debe mostrar solo Medellín y Medina
      expect(find.text('Medellín'), findsOneWidget);
      expect(find.text('Medina'), findsOneWidget);
      expect(find.text('Bogotá'), findsNothing);
      expect(find.text('Cali'), findsNothing);
    });

    testWidgets('debe filtrar case-insensitive', (tester) async {
      await tester.pumpWidget(
        testableWidget(
          child: CityAutocomplete(
              cities: cities,
              onCitySelected: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(TextFormField));
      await tester.pump();

      // Escribir en minúsculas
      await tester.enterText(find.byType(TextFormField), 'medellín');
      await tester.pump();

      expect(find.text('Medellín'), findsOneWidget);
    });

    testWidgets('debe mostrar mensaje cuando no hay resultados', (tester) async {
      await tester.pumpWidget(
        testableWidget(
          child: CityAutocomplete(
              cities: cities,
              onCitySelected: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(TextFormField));
      await tester.pump();

      await tester.enterText(find.byType(TextFormField), 'XYZ');
      await tester.pump();

      expect(find.textContaining('No se encontraron ciudades'), findsOneWidget);
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
    });

    testWidgets('debe llamar onCitySelected al seleccionar ciudad', (tester) async {
      City? selectedCity;

      await tester.pumpWidget(
        testableWidget(
          child: CityAutocomplete(
              cities: cities,
              onCitySelected: (city) => selectedCity = city,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(TextFormField));
      await tester.pump();

      // Tap en Medellín
      await tester.tap(find.text('Medellín'));
      await tester.pump();

      expect(selectedCity?.id, '1');
      expect(selectedCity?.name, 'Medellín');
    });

    testWidgets('debe actualizar TextField al seleccionar ciudad', (tester) async {
      await tester.pumpWidget(
        testableWidget(
          child: CityAutocomplete(
              cities: cities,
              onCitySelected: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(TextFormField));
      await tester.pump();

      await tester.tap(find.text('Bogotá'));
      await tester.pump();

      // El TextField debe tener "Bogotá"
      final textField = tester.widget<TextFormField>(find.byType(TextFormField));
      expect(textField.controller?.text, 'Bogotá');
    });

    testWidgets('debe ocultar sugerencias al seleccionar ciudad', (tester) async {
      await tester.pumpWidget(
        testableWidget(
          child: CityAutocomplete(
              cities: cities,
              onCitySelected: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(TextFormField));
      await tester.pump();

      // Sugerencias visibles
      expect(find.text('Medellín'), findsOneWidget);

      await tester.tap(find.text('Medellín'));
      await tester.pumpAndSettle();

      // No debe haber lista de sugerencias (solo el texto en el TextField)
      // La lista tiene ListTile, el TextField no
      expect(find.byType(ListTile), findsNothing);
    });

    testWidgets('debe mostrar clear button cuando hay texto', (tester) async {
      await tester.pumpWidget(
        testableWidget(
          child: CityAutocomplete(
              cities: cities,
              onCitySelected: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Al inicio debe mostrar search icon
      expect(find.byIcon(Icons.search), findsOneWidget);
      expect(find.byIcon(Icons.clear), findsNothing);

      // Escribir texto
      await tester.enterText(find.byType(TextFormField), 'Med');
      await tester.pump();

      // Debe mostrar clear button
      expect(find.byIcon(Icons.clear), findsOneWidget);
      expect(find.byIcon(Icons.search), findsNothing);
    });

    testWidgets('debe limpiar texto y llamar onCitySelected(null) al presionar clear', (tester) async {
      City? selectedCity = const City(id: '1', name: 'Medellín', regionId: 'ANT');

      await tester.pumpWidget(
        testableWidget(
          child: CityAutocomplete(
              cities: cities,
              onCitySelected: (city) => selectedCity = city,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), 'Med');
      await tester.pump();

      // Presionar clear
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pump();

      final textField = tester.widget<TextFormField>(find.byType(TextFormField));
      expect(textField.controller?.text, '');
      expect(selectedCity, isNull);
    });

    testWidgets('debe resaltar ciudad seleccionada en la lista', (tester) async {
      const selectedCity = City(id: '1', name: 'Medellín', regionId: 'ANT');

      await tester.pumpWidget(
        testableWidget(
          child: CityAutocomplete(
              cities: cities,
              selectedCity: selectedCity,
              onCitySelected: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(TextFormField));
      await tester.pump();

      // Debe haber un check icon en la ciudad seleccionada
      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('debe mostrar todas las ciudades cuando query está vacío', (tester) async {
      await tester.pumpWidget(
        testableWidget(
          child: CityAutocomplete(
              cities: cities,
              onCitySelected: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(TextFormField));
      await tester.pump();

      // Escribir y luego borrar
      await tester.enterText(find.byType(TextFormField), 'Med');
      await tester.pump();

      await tester.enterText(find.byType(TextFormField), '');
      await tester.pump();

      // Debe mostrar todas las ciudades
      expect(find.text('Medellín'), findsOneWidget);
      expect(find.text('Medina'), findsOneWidget);
      expect(find.text('Bogotá'), findsOneWidget);
      expect(find.text('Cali'), findsOneWidget);
    });

    testWidgets('debe actualizar cuando cambian las ciudades', (tester) async {
      final newCities = [
        const City(id: '5', name: 'Cartagena', regionId: 'BOL'),
        const City(id: '6', name: 'Barranquilla', regionId: 'ATL'),
      ];

      Widget buildWidget(List<City> cities) {
        return MaterialApp(
          home: Scaffold(
            body: CityAutocomplete(
              cities: cities,
              onCitySelected: (_) {},
            ),
          ),
        );
      }

      await tester.pumpWidget(buildWidget(cities));

      await tester.tap(find.byType(TextFormField));
      await tester.pump();

      expect(find.text('Medellín'), findsOneWidget);

      // Cambiar ciudades
      await tester.pumpWidget(buildWidget(newCities));
      await tester.pump();

      // Debe mostrar nuevas ciudades
      expect(find.text('Cartagena'), findsOneWidget);
      expect(find.text('Barranquilla'), findsOneWidget);
      expect(find.text('Medellín'), findsNothing);
    });

    testWidgets('debe limpiar TextField cuando cambian las ciudades', (tester) async {
      final newCities = [
        const City(id: '5', name: 'Cartagena', regionId: 'BOL'),
      ];

      Widget buildWidget(List<City> cities, {City? selected}) {
        return MaterialApp(
          home: Scaffold(
            body: CityAutocomplete(
              cities: cities,
              selectedCity: selected,
              onCitySelected: (_) {},
            ),
          ),
        );
      }

      await tester.pumpWidget(buildWidget(
        cities,
        selected: const City(id: '1', name: 'Medellín', regionId: 'ANT'),
      ));

      expect(find.text('Medellín'), findsOneWidget);

      // Cambiar ciudades
      await tester.pumpWidget(buildWidget(newCities));
      await tester.pump();

      final textField = tester.widget<TextFormField>(find.byType(TextFormField));
      expect(textField.controller?.text, '');
    });

    testWidgets('debe actualizar TextField cuando cambia selectedCity', (tester) async {
      Widget buildWidget(City? selected) {
        return MaterialApp(
          home: Scaffold(
            body: CityAutocomplete(
              cities: cities,
              selectedCity: selected,
              onCitySelected: (_) {},
            ),
          ),
        );
      }

      await tester.pumpWidget(buildWidget(null));

      final textField = tester.widget<TextFormField>(find.byType(TextFormField));
      expect(textField.controller?.text, '');

      // Cambiar selectedCity externamente
      await tester.pumpWidget(buildWidget(
        const City(id: '3', name: 'Bogotá', regionId: 'CUN'),
      ));
      await tester.pump();

      final updatedTextField = tester.widget<TextFormField>(find.byType(TextFormField));
      expect(updatedTextField.controller?.text, 'Bogotá');
    });

    testWidgets('debe llamar validator si está definido', (tester) async {
      String? validationError;

      await tester.pumpWidget(
        testableWidget(
          child: Form(
            child: CityAutocomplete(
              cities: cities,
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
      );
      await tester.pumpAndSettle();

      // Trigger validation
      final formState = tester.state<FormState>(find.byType(Form));
      formState.validate();
      await tester.pump();

      expect(validationError, 'Campo requerido');
      expect(find.text('Campo requerido'), findsOneWidget);
    });

    testWidgets('no debe mostrar sugerencias cuando pierde focus', (tester) async {
      await tester.pumpWidget(
        testableWidget(
          child: Column(
            children: [
              CityAutocomplete(
                cities: cities,
                onCitySelected: (_) {},
              ),
              const TextField(key: Key('other')),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Hacer focus en city autocomplete
      await tester.tap(find.byType(CityAutocomplete));
      await tester.pump();

      expect(find.byType(ListTile), findsWidgets);

      // Hacer focus en otro widget
      await tester.tap(find.byKey(const Key('other')));
      await tester.pump();

      // No debe mostrar sugerencias
      expect(find.byType(ListTile), findsNothing);
    });

    testWidgets('debe tener constraints en lista de sugerencias', (tester) async {
      await tester.pumpWidget(
        testableWidget(
          child: CityAutocomplete(
              cities: cities,
              onCitySelected: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(TextFormField));
      await tester.pump();

      final container = tester.widget<Container>(
        find.ancestor(
          of: find.byType(ListView),
          matching: find.byType(Container),
        ).first,
      );

      expect(container.constraints?.maxHeight, 200);
    });

    testWidgets('debe mostrar íconos correctos en la lista', (tester) async {
      await tester.pumpWidget(
        testableWidget(
          child: CityAutocomplete(
              cities: cities,
              onCitySelected: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(TextFormField));
      await tester.pump();

      expect(find.byIcon(Icons.location_city), findsNWidgets(cities.length));
    });
  });
}
