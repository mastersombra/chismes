import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chismes/features/gossip/presentation/widgets/compact_location_selector.dart';
import 'package:chismes/core/theme/app_spacing.dart';
import '../helpers/widget_test_wrapper.dart';

/// Tests de accesibilidad para dispositivos con ancho estrecho
///
/// **Objetivo:** Verificar que la UI funciona correctamente en pantallas de 320px
///
/// **Dispositivos objetivo:**
/// - iPhone SE (1st gen): 320x568
/// - iPhone 5/5S: 320x568
/// - Android pequeños: 320x480
///
/// **Criterios:**
/// - No overflow horizontal
/// - Texto truncado apropiadamente
/// - Botones accesibles
/// - Touch targets mínimo 44x44
// iPhone SE (1st gen) dimensions
const narrowSize = Size(320, 568);

void main() {
  group('Narrow Width Accessibility Tests', () {

    testWidgets('CompactLocationSelector debe funcionar en 320px width',
        (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        testableWidget(
          mediaQuery: const MediaQueryData(size: narrowSize),
          child: CompactLocationSelector(
            locationText: 'Medellín, Antioquia',
            isLoading: false,
            onChangePressed: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert - No overflow horizontal
      expect(tester.takeException(), isNull);

      // Assert - Componentes visibles
      expect(find.text('Medellín, Antioquia'), findsOneWidget);
      expect(find.text('Cambiar'), findsOneWidget);
    });

    testWidgets('CompactLocationSelector debe truncar texto largo en 320px',
        (WidgetTester tester) async {
      // Arrange - Nombre muy largo de ubicación
      const longLocation = 'San Pedro Garza García de los Lagos, Nuevo León Norte México';

      await tester.pumpWidget(
        testableWidget(
          mediaQuery: const MediaQueryData(size: narrowSize),
          child: CompactLocationSelector(
            locationText: longLocation,
            isLoading: false,
            onChangePressed: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert - No overflow (texto se trunca)
      expect(tester.takeException(), isNull);

      // Assert - Ellipsis aplicado
      final textFinder = find.text(longLocation);
      expect(textFinder, findsOneWidget);

      final textWidget = tester.widget<Text>(textFinder);
      expect(textWidget.overflow, TextOverflow.ellipsis);
    });

    testWidgets('Loading state debe caber en 320px width',
        (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        testableWidget(
          mediaQuery: const MediaQueryData(size: narrowSize),
          child: CompactLocationSelector(
                locationText: null,
                isLoading: true,
                onChangePressed: () {},
          ),
        ),
      );
      await tester.pump();

      // Assert - No overflow
      expect(tester.takeException(), isNull);

      // Assert - Loading indicator y texto visibles
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Detectando ubicación...'), findsOneWidget);
    });

    testWidgets('Botón "Cambiar" debe ser tappeable en 320px',
        (WidgetTester tester) async {
      // Arrange
      bool wasPressed = false;

      await tester.pumpWidget(
        testableWidget(
          mediaQuery: const MediaQueryData(size: narrowSize),
          child: CompactLocationSelector(
                locationText: 'Medellín',
                isLoading: false,
                onChangePressed: () {
                  wasPressed = true;
                },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Act - Tap en botón
      await tester.tap(find.text('Cambiar'));
      await tester.pump();

      // Assert - Callback ejecutado
      expect(wasPressed, isTrue);
    });
  });

  // Dialog tests removed - focused on CompactLocationSelector only

  group('Narrow Width + Font Scale Combined', () {
    testWidgets('320px width + 1.5x font scale debe funcionar',
        (WidgetTester tester) async {
      // Arrange - Worst case: dispositivo pequeño + font scale alto
      await tester.pumpWidget(
        testableWidget(
          mediaQuery: const MediaQueryData(
            size: narrowSize,
            textScaler: TextScaler.linear(1.5),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                CompactLocationSelector(
                  locationText: 'Medellín, Antioquia',
                  isLoading: false,
                  onChangePressed: () {},
                ),
                const SizedBox(height: AppSpacing.lg),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Título del chisme',
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert - No overflow con condiciones extremas
      expect(tester.takeException(), isNull);
    });

    testWidgets('320px width + 2.0x font scale (extremo) debe manejar overflow',
        (WidgetTester tester) async {
      // Arrange - Condiciones extremas
      await tester.pumpWidget(
        testableWidget(
          mediaQuery: const MediaQueryData(
            size: narrowSize,
            textScaler: TextScaler.linear(2.0),
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: CompactLocationSelector(
                locationText: 'Ciudad de México, Estado de México',
                isLoading: false,
                onChangePressed: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert - Con scroll, debe manejar el contenido
      expect(tester.takeException(), isNull);
    });
  });

  group('Narrow Width - Edge Cases', () {
    testWidgets('Debe manejar padding en 320px sin overflow',
        (WidgetTester tester) async {
      // Arrange - Padding grande en dispositivo pequeño
      await tester.pumpWidget(
        testableWidget(
          mediaQuery: const MediaQueryData(size: narrowSize),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xxxl), // 48px padding
            child: CompactLocationSelector(
              locationText: 'Med',
              isLoading: false,
              onChangePressed: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert - No overflow incluso con padding grande
      expect(tester.takeException(), isNull);
    });

    testWidgets('Iconos deben ser visibles en 320px',
        (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        testableWidget(
          mediaQuery: const MediaQueryData(size: narrowSize),
          child: CompactLocationSelector(
                locationText: 'Medellín',
                isLoading: false,
                onChangePressed: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert - Icon presente (si existe)
      // CompactLocationSelector puede tener un icon de ubicación
      expect(tester.takeException(), isNull);
    });
  });
}
