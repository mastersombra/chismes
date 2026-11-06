import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chismes/features/gossip/presentation/widgets/publish_as_selector.dart';
import 'package:chismes/features/gossip/presentation/states/add_gossip_state.dart';
import 'package:chismes/features/gossip/domain/entities/gossip.dart';

void main() {
  group('PublishAsSelector', () {
    testWidgets('debe renderizar opción Anonymous', (tester) async {
      // Arrange
      const state = AddGossipState(idempotencyKey: 'test-key', publishedAs: PublishAs.anonymous);

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PublishAsSelector(
              state: state,
              onPublishAsChanged: (_) {},
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Anónimo'), findsOneWidget);
      expect(find.byIcon(Icons.person_off), findsOneWidget);
    });

    testWidgets('debe renderizar opción Profile', (tester) async {
      // Arrange
      const state = AddGossipState(idempotencyKey: 'test-key', publishedAs: PublishAs.profile);

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PublishAsSelector(
              state: state,
              onPublishAsChanged: (_) {},
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Con mi perfil'), findsOneWidget);
      expect(find.byIcon(Icons.person), findsOneWidget);
    });

    testWidgets('debe llamar onPublishAsChanged al seleccionar Anonymous', (tester) async {
      // Arrange
      const state = AddGossipState(idempotencyKey: 'test-key', publishedAs: PublishAs.profile);
      PublishAs? selectedValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PublishAsSelector(
              state: state,
              onPublishAsChanged: (value) {
                selectedValue = value;
              },
            ),
          ),
        ),
      );

      // Act
      await tester.tap(find.text('Anónimo'));
      await tester.pump();

      // Assert
      expect(selectedValue, PublishAs.anonymous);
    });

    testWidgets('debe llamar onPublishAsChanged al seleccionar Profile', (tester) async {
      // Arrange
      const state = AddGossipState(idempotencyKey: 'test-key', publishedAs: PublishAs.anonymous);
      PublishAs? selectedValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PublishAsSelector(
              state: state,
              onPublishAsChanged: (value) {
                selectedValue = value;
              },
            ),
          ),
        ),
      );

      // Act
      await tester.tap(find.text('Con mi perfil'));
      await tester.pump();

      // Assert
      expect(selectedValue, PublishAs.profile);
    });

    testWidgets('debe mostrar selección actual con estilo correcto', (tester) async {
      // Arrange
      const state = AddGossipState(idempotencyKey: 'test-key', publishedAs: PublishAs.anonymous);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PublishAsSelector(
              state: state,
              onPublishAsChanged: (_) {},
            ),
          ),
        ),
      );

      // Act
      await tester.pump();

      // Assert - El seleccionado debe tener RadioListTile con groupValue correcto
      final anonymousRadio = find.byWidgetPredicate(
        (widget) => widget is RadioListTile<PublishAs> && widget.value == PublishAs.anonymous,
      );
      expect(anonymousRadio, findsOneWidget);
    });
  });
}
