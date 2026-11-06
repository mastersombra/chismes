import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chismes/features/gossip/presentation/widgets/compact_location_selector.dart';

void main() {
  group('CompactLocationSelector', () {
    testWidgets('debe renderizar con ubicación seleccionada', (tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CompactLocationSelector(
              locationText: 'Medellín, Antioquia',
              onChangePressed: () {},
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Medellín, Antioquia'), findsOneWidget);
      expect(find.byIcon(Icons.location_on), findsOneWidget);
      expect(find.text('Cambiar'), findsOneWidget);
    });

    testWidgets('debe mostrar placeholder cuando no hay ubicación', (tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CompactLocationSelector(
              locationText: null,
              onChangePressed: () {},
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Seleccionar ubicación'), findsOneWidget);
      expect(find.text('Cambiar'), findsOneWidget);
    });

    testWidgets('debe mostrar loading state', (tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CompactLocationSelector(
              locationText: 'Medellín, Antioquia',
              onChangePressed: () {},
              isLoading: true,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Detectando ubicación...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('debe llamar onChangePressed cuando se toca el botón Cambiar', (tester) async {
      // Arrange
      var buttonPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CompactLocationSelector(
              locationText: 'Medellín, Antioquia',
              onChangePressed: () {
                buttonPressed = true;
              },
            ),
          ),
        ),
      );

      // Act
      await tester.tap(find.text('Cambiar'));
      await tester.pump();

      // Assert
      expect(buttonPressed, isTrue);
    });

    testWidgets('debe deshabilitar botón Cambiar durante loading', (tester) async {
      // Arrange
      var buttonPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CompactLocationSelector(
              locationText: 'Medellín, Antioquia',
              onChangePressed: () {
                buttonPressed = true;
              },
              isLoading: true,
            ),
          ),
        ),
      );

      // Act - Intentar tocar el botón (debería estar deshabilitado)
      await tester.tap(find.text('Cambiar'));
      await tester.pump();

      // Assert
      expect(buttonPressed, isFalse);
    });

    testWidgets('debe mostrar ícono de editar ubicación en botón', (tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CompactLocationSelector(
              locationText: 'Medellín, Antioquia',
              onChangePressed: () {},
            ),
          ),
        ),
      );

      // Assert
      expect(find.byIcon(Icons.edit_location_alt), findsOneWidget);
    });

    testWidgets('debe manejar texto largo con ellipsis', (tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CompactLocationSelector(
              locationText: 'Nombre de Ciudad Muy Largo, Nombre de Región Muy Largo',
              onChangePressed: () {},
            ),
          ),
        ),
      );

      // Assert - Verifica que el texto existe
      expect(
        find.text('Nombre de Ciudad Muy Largo, Nombre de Región Muy Largo'),
        findsOneWidget,
      );

      // Verifica que el widget Text tiene configurado TextOverflow.ellipsis
      final textWidget = tester.widget<Text>(
        find.text('Nombre de Ciudad Muy Largo, Nombre de Región Muy Largo'),
      );
      expect(textWidget.overflow, TextOverflow.ellipsis);
    });

    testWidgets('debe tener Container con bordes redondeados', (tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CompactLocationSelector(
              locationText: 'Medellín, Antioquia',
              onChangePressed: () {},
            ),
          ),
        ),
      );

      // Assert
      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.borderRadius, BorderRadius.circular(12));
    });

    testWidgets('debe estar en Row con espaciado correcto', (tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CompactLocationSelector(
              locationText: 'Medellín, Antioquia',
              onChangePressed: () {},
            ),
          ),
        ),
      );

      // Assert - Verifica que hay un Row como layout principal
      expect(find.byType(Row), findsWidgets);

      // Verifica que el texto está en un Expanded para ocupar espacio disponible
      expect(find.byType(Expanded), findsOneWidget);
    });

    testWidgets('debe cambiar de placeholder a ubicación cuando se actualiza', (tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CompactLocationSelector(
              locationText: null,
              onChangePressed: () {},
            ),
          ),
        ),
      );

      // Assert - Estado inicial
      expect(find.text('Seleccionar ubicación'), findsOneWidget);

      // Act - Actualizar con ubicación
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CompactLocationSelector(
              locationText: 'Bogotá, Cundinamarca',
              onChangePressed: () {},
            ),
          ),
        ),
      );
      await tester.pump();

      // Assert - Estado actualizado
      expect(find.text('Bogotá, Cundinamarca'), findsOneWidget);
      expect(find.text('Seleccionar ubicación'), findsNothing);
    });

    testWidgets('debe mostrar loading cuando cambia de normal a loading', (tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CompactLocationSelector(
              locationText: 'Medellín, Antioquia',
              onChangePressed: () {},
              isLoading: false,
            ),
          ),
        ),
      );

      // Assert - Estado inicial
      expect(find.text('Medellín, Antioquia'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      // Act - Cambiar a loading
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CompactLocationSelector(
              locationText: 'Medellín, Antioquia',
              onChangePressed: () {},
              isLoading: true,
            ),
          ),
        ),
      );
      await tester.pump();

      // Assert - Estado loading
      expect(find.text('Detectando ubicación...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Medellín, Antioquia'), findsNothing);
    });

    testWidgets('debe tener botón Cambiar visible', (tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CompactLocationSelector(
              locationText: 'Medellín, Antioquia',
              onChangePressed: () {},
            ),
          ),
        ),
      );

      // Assert - El botón Cambiar debe estar visible
      expect(find.text('Cambiar'), findsOneWidget);

      // Y debe tener el ícono de editar ubicación
      expect(find.byIcon(Icons.edit_location_alt), findsOneWidget);
    });
  });
}
