import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chismes/features/gossip/presentation/widgets/compact_location_selector.dart';
import 'package:chismes/core/theme/app_spacing.dart';

import '../helpers/widget_test_wrapper.dart';

/// Tests de accesibilidad para font scale alto
///
/// **Objetivo:** Verificar que la UI funciona correctamente con font scale de hasta 2.0x
///
/// **Criterios:**
/// - No overflow de texto
/// - Botones siguen siendo tappeable
/// - Layout se adapta correctamente
/// - Mínimo 44x44 para touch targets (WCAG)
///
/// **Prioridad:** Media-Alta (accesibilidad es crítica)
void main() {
  group('Font Scale Accessibility Tests', () {
    testWidgets('CompactLocationSelector debe manejar font scale 1.5x',
        (WidgetTester tester) async {
      // Arrange - Font scale 1.5x
      await pumpWidgetWithI18n(
        tester,
        CompactLocationSelector(
          locationText: 'Medellín, Antioquia',
          isLoading: false,
          onChangePressed: () {},
        ),
        mediaQuery: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
      );

      // Assert - No overflow
      expect(tester.takeException(), isNull);

      // Assert - Texto visible
      expect(find.text('Medellín, Antioquia'), findsOneWidget);

      // Assert - Botón cambiar visible y tappeable (puede ser IconButton con font scale alto)
      final textButton = find.byType(TextButton);
      final iconButton = find.byType(IconButton);
      // Debe haber al menos uno de los dos tipos de botón
      expect(textButton.evaluate().isNotEmpty || iconButton.evaluate().isNotEmpty, isTrue);
    });

    testWidgets('CompactLocationSelector debe manejar font scale 2.0x',
        (WidgetTester tester) async {
      // Arrange - Font scale 2.0x (máximo recomendado por WCAG)
      await pumpWidgetWithI18n(
        tester,
        CompactLocationSelector(
          locationText: 'Medellín, Antioquia',
          isLoading: false,
          onChangePressed: () {},
        ),
        mediaQuery: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
      );

      // Assert - No overflow
      expect(tester.takeException(), isNull);

      // Assert - Texto visible
      expect(find.text('Medellín, Antioquia'), findsOneWidget);
    });

    testWidgets('CompactLocationSelector debe truncar texto largo con font scale 2.0x',
        (WidgetTester tester) async {
      // Arrange - Texto muy largo + font scale 2.0x
      const longLocation = 'San Juan de los Lagos de Guadalajara, Jalisco Norte';

      await pumpWidgetWithI18n(
        tester,
        CompactLocationSelector(
          locationText: longLocation,
          isLoading: false,
          onChangePressed: () {},
        ),
        mediaQuery: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
      );

      // Assert - No overflow (texto se trunca con ellipsis)
      expect(tester.takeException(), isNull);
    });

    testWidgets('Botones deben mantener tamaño mínimo con font scale alto',
        (WidgetTester tester) async {
      // Arrange
      await pumpWidgetWithI18n(
        tester,
        CompactLocationSelector(
          locationText: 'Medellín',
          isLoading: false,
          onChangePressed: () {},
        ),
        mediaQuery: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
      );

      // Assert - Botón presente (IconButton con font scale 2.0x)
      final textButton = find.byType(TextButton);
      final iconButton = find.byType(IconButton);
      expect(textButton.evaluate().isNotEmpty || iconButton.evaluate().isNotEmpty, isTrue);

      // Assert - No overflow
      expect(tester.takeException(), isNull);

      // Assert - Tamaño mínimo de touch target (44x44)
      final button = iconButton.evaluate().isNotEmpty
          ? tester.widget<IconButton>(iconButton)
          : null;
      if (button != null) {
        expect(button.constraints?.minWidth, greaterThanOrEqualTo(44));
        expect(button.constraints?.minHeight, greaterThanOrEqualTo(44));
      }
    });
  });

  group('Font Scale - Integration Tests', () {
    testWidgets('Toda la pantalla debe manejar font scale 1.5x sin overflow',
        (WidgetTester tester) async {
      // Arrange - Simular pantalla completa con múltiples widgets
      await pumpWidgetWithI18n(
        tester,
        Scaffold(
          appBar: AppBar(title: const Text('Crear Chisme')),
          body: Padding(
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
                    labelText: 'Título',
                    hintText: 'Escribe un título...',
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Contenido',
                    hintText: 'Cuenta tu chisme...',
                  ),
                  maxLines: 5,
                ),
              ],
            ),
          ),
        ),
        mediaQuery: const MediaQueryData(
          textScaler: TextScaler.linear(1.5),
          size: Size(360, 640), // Dispositivo pequeño
        ),
        useScaffold: false, // Ya incluye Scaffold
      );

      // Assert - No overflow en toda la pantalla
      expect(tester.takeException(), isNull);
    });
  });
}
