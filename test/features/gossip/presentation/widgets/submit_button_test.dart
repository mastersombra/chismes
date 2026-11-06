import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chismes/features/gossip/presentation/widgets/submit_button.dart';
import 'package:chismes/features/gossip/presentation/states/add_gossip_state.dart';

void main() {
  group('SubmitButton', () {
    testWidgets('debe estar habilitado cuando isSubmitting = false', (tester) async {
      // Arrange
      const state = AddGossipState(idempotencyKey: 'test-key', isSubmitting: false);

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SubmitButton(
              state: state,
              onSubmit: () {},
            ),
          ),
        ),
      );

      // Assert
      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNotNull);
    });

    testWidgets('debe estar deshabilitado cuando isSubmitting = true', (tester) async {
      // Arrange
      const state = AddGossipState(idempotencyKey: 'test-key', isSubmitting: true);

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SubmitButton(
              state: state,
              onSubmit: () {},
            ),
          ),
        ),
      );

      // Assert
      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('debe mostrar CircularProgressIndicator cuando isSubmitting = true', (tester) async {
      // Arrange
      const state = AddGossipState(idempotencyKey: 'test-key', isSubmitting: true);

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SubmitButton(
              state: state,
              onSubmit: () {},
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Publicar chisme'), findsNothing);
    });

    testWidgets('debe mostrar texto "Publicar chisme" cuando isSubmitting = false', (tester) async {
      // Arrange
      const state = AddGossipState(idempotencyKey: 'test-key', isSubmitting: false);

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SubmitButton(
              state: state,
              onSubmit: () {},
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Publicar chisme'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('debe llamar onSubmit cuando se hace tap y está habilitado', (tester) async {
      // Arrange
      const state = AddGossipState(idempotencyKey: 'test-key', isSubmitting: false);
      var wasPressed = false;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SubmitButton(
              state: state,
              onSubmit: () {
                wasPressed = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      // Assert
      expect(wasPressed, isTrue);
    });

    testWidgets('no debe llamar onSubmit cuando está deshabilitado', (tester) async {
      // Arrange
      const state = AddGossipState(idempotencyKey: 'test-key', isSubmitting: true);
      var wasPressed = false;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SubmitButton(
              state: state,
              onSubmit: () {
                wasPressed = true;
              },
            ),
          ),
        ),
      );

      // Intentar hacer tap (no debería funcionar)
      await tester.tap(find.byType(ElevatedButton), warnIfMissed: false);
      await tester.pump();

      // Assert
      expect(wasPressed, isFalse);
    });

    testWidgets('debe tener el ancho completo', (tester) async {
      // Arrange
      const state = AddGossipState(idempotencyKey: 'test-key', isSubmitting: false);

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SubmitButton(
              state: state,
              onSubmit: () {},
            ),
          ),
        ),
      );

      // Assert
      final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox).first);
      expect(sizedBox.width, double.infinity);
    });
  });
}
