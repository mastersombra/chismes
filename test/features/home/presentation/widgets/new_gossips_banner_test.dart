import 'package:chismes/features/home/presentation/widgets/new_gossips_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/widget_test_wrapper.dart';

void main() {
  group('NewGossipsBanner', () {
    testWidgets('debe renderizar correctamente', (tester) async {
      // Arrange
      var tapped = false;

      // Act
      await pumpWidgetWithI18n(
        tester,
        NewGossipsBanner(
          count: 5,
          onTap: () => tapped = true,
        ),
      );

      // Assert
      expect(find.byType(NewGossipsBanner), findsOneWidget);
    });

    testWidgets('debe mostrar el ícono de fuego', (tester) async {
      // Act
      await pumpWidgetWithI18n(
        tester,
        NewGossipsBanner(
          count: 3,
          onTap: () {},
        ),
      );

      // Assert
      expect(find.byIcon(Icons.local_fire_department), findsOneWidget);
    });

    testWidgets('debe llamar onTap al presionar', (tester) async {
      // Arrange
      var tapped = false;

      // Act
      await pumpWidgetWithI18n(
        tester,
        NewGossipsBanner(
          count: 5,
          onTap: () => tapped = true,
        ),
      );

      await tester.tap(find.byType(InkWell));
      await tester.pumpAndSettle();

      // Assert
      expect(tapped, isTrue);
    });

    testWidgets('debe tener padding correcto', (tester) async {
      // Act
      await pumpWidgetWithI18n(
        tester,
        NewGossipsBanner(
          count: 1,
          onTap: () {},
        ),
      );

      // Assert - verifica que existe Padding
      expect(find.byType(Padding), findsWidgets);
    });

    testWidgets('debe centrar el contenido', (tester) async {
      // Act
      await pumpWidgetWithI18n(
        tester,
        NewGossipsBanner(
          count: 7,
          onTap: () {},
        ),
      );

      // Assert
      final row = tester.widget<Row>(find.byType(Row));
      expect(row.mainAxisAlignment, MainAxisAlignment.center);
    });

    testWidgets('debe manejar count de 0', (tester) async {
      // Act
      await pumpWidgetWithI18n(
        tester,
        NewGossipsBanner(
          count: 0,
          onTap: () {},
        ),
      );

      // Assert
      expect(find.byType(NewGossipsBanner), findsOneWidget);
      expect(find.byIcon(Icons.local_fire_department), findsOneWidget);
    });

    testWidgets('debe manejar count grande', (tester) async {
      // Act
      await pumpWidgetWithI18n(
        tester,
        NewGossipsBanner(
          count: 999,
          onTap: () {},
        ),
      );

      // Assert
      expect(find.byType(NewGossipsBanner), findsOneWidget);
      expect(find.byIcon(Icons.local_fire_department), findsOneWidget);
    });

    testWidgets('debe poder presionarse múltiples veces', (tester) async {
      // Arrange
      var tapCount = 0;

      // Act
      await pumpWidgetWithI18n(
        tester,
        NewGossipsBanner(
          count: 5,
          onTap: () => tapCount++,
        ),
      );

      await tester.tap(find.byType(InkWell));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(InkWell));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(InkWell));
      await tester.pumpAndSettle();

      // Assert
      expect(tapCount, 3);
    });

    testWidgets('debe tener InkWell para efectos de toque', (tester) async {
      // Act
      await pumpWidgetWithI18n(
        tester,
        NewGossipsBanner(
          count: 1,
          onTap: () {},
        ),
      );

      // Assert
      expect(find.byType(InkWell), findsOneWidget);
    });

    testWidgets('debe mostrar texto con el count', (tester) async {
      // Act
      await pumpWidgetWithI18n(
        tester,
        NewGossipsBanner(
          count: 42,
          onTap: () {},
        ),
      );

      // Assert - verifica que existe un Text widget
      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('debe tener estructura Row con ícono y texto', (tester) async {
      // Act
      await pumpWidgetWithI18n(
        tester,
        NewGossipsBanner(
          count: 5,
          onTap: () {},
        ),
      );

      // Assert
      expect(find.byType(Row), findsOneWidget);
      expect(find.byIcon(Icons.local_fire_department), findsOneWidget);
      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('debe ser interactivo mediante tap', (tester) async {
      // Arrange
      var wasTapped = false;

      // Act
      await pumpWidgetWithI18n(
        tester,
        NewGossipsBanner(
          count: 1,
          onTap: () => wasTapped = true,
        ),
      );

      // No tapped yet
      expect(wasTapped, isFalse);

      // Tap
      await tester.tap(find.byType(NewGossipsBanner));
      await tester.pumpAndSettle();

      // Assert
      expect(wasTapped, isTrue);
    });

    testWidgets('debe mantener funcionalidad con diferentes counts', (tester) async {
      // Test con count 0
      var tapCount = 0;
      await pumpWidgetWithI18n(
        tester,
        NewGossipsBanner(
          count: 0,
          onTap: () => tapCount++,
        ),
      );
      await tester.tap(find.byType(InkWell));
      expect(tapCount, 1);

      // Test con count 100
      await pumpWidgetWithI18n(
        tester,
        NewGossipsBanner(
          count: 100,
          onTap: () => tapCount++,
        ),
      );
      await tester.tap(find.byType(InkWell));
      expect(tapCount, 2);
    });
  });
}
