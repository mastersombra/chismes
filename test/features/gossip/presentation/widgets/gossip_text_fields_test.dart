import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chismes/features/gossip/presentation/widgets/gossip_text_fields.dart';
import '../../../../helpers/widget_test_wrapper.dart';

void main() {
  Widget makeTestableWidget(Widget child) {
    return testableWidget(child: Scaffold(body: child), useScaffold: false);
  }

  group('GossipTextFields', () {
    late TextEditingController subjectController;
    late TextEditingController contentController;

    setUp(() {
      subjectController = TextEditingController();
      contentController = TextEditingController();
    });

    tearDown(() {
      subjectController.dispose();
      contentController.dispose();
    });

    testWidgets('debe renderizar campo de subject', (tester) async {
      // Act
      await tester.pumpWidget(
        makeTestableWidget(
          GossipTextFields(
            subjectController: subjectController,
            contentController: contentController,
            onSubjectChanged: (_) {},
            onContentChanged: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('¿Sobre quién o dónde?'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2));
    });

    testWidgets('debe renderizar campo de content', (tester) async {
      // Act
      await tester.pumpWidget(
        makeTestableWidget(
          GossipTextFields(
            subjectController: subjectController,
            contentController: contentController,
            onSubjectChanged: (_) {},
            onContentChanged: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('El chisme'), findsOneWidget);
    });

    testWidgets('debe mostrar contador de caracteres en subject', (tester) async {
      // Arrange
      await tester.pumpWidget(
        makeTestableWidget(
          GossipTextFields(
            subjectController: subjectController,
            contentController: contentController,
            onSubjectChanged: (_) {},
            onContentChanged: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Act - Escribir en subject
      await tester.enterText(
        find.byType(TextFormField).first,
        'Test subject',
      );
      await tester.pump();

      // Assert - Debe mostrar contador
      expect(find.textContaining('/200'), findsOneWidget);
    });

    testWidgets('debe mostrar contador de caracteres en content', (tester) async {
      // Arrange
      await tester.pumpWidget(
        makeTestableWidget(
          GossipTextFields(
            subjectController: subjectController,
            contentController: contentController,
            onSubjectChanged: (_) {},
            onContentChanged: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Act - Escribir en content
      await tester.enterText(
        find.byType(TextFormField).last,
        'Test content',
      );
      await tester.pump();

      // Assert - Debe mostrar contador
      expect(find.textContaining('/1000'), findsOneWidget);
    });

    testWidgets('debe actualizar controllers correctamente', (tester) async {
      // Arrange
      await tester.pumpWidget(
        makeTestableWidget(
          GossipTextFields(
            subjectController: subjectController,
            contentController: contentController,
            onSubjectChanged: (_) {},
            onContentChanged: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Act
      await tester.enterText(find.byType(TextFormField).first, 'New subject');
      await tester.enterText(find.byType(TextFormField).last, 'New content');
      await tester.pump();

      // Assert
      expect(subjectController.text, 'New subject');
      expect(contentController.text, 'New content');
    });

    testWidgets('debe limitar subject a 200 caracteres', (tester) async {
      // Arrange
      await tester.pumpWidget(
        makeTestableWidget(
          GossipTextFields(
            subjectController: subjectController,
            contentController: contentController,
            onSubjectChanged: (_) {},
            onContentChanged: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Act - Intentar escribir más de 200 caracteres
      final longText = 'a' * 250;
      await tester.enterText(find.byType(TextFormField).first, longText);
      await tester.pump();

      // Assert - Debe estar truncado a 200
      expect(subjectController.text.length, lessThanOrEqualTo(200));
    });

    testWidgets('debe limitar content a 1000 caracteres', (tester) async {
      // Arrange
      await tester.pumpWidget(
        makeTestableWidget(
          GossipTextFields(
            subjectController: subjectController,
            contentController: contentController,
            onSubjectChanged: (_) {},
            onContentChanged: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Act - Intentar escribir más de 1000 caracteres
      final longText = 'a' * 1500;
      await tester.enterText(find.byType(TextFormField).last, longText);
      await tester.pump();

      // Assert - Debe estar truncado a 1000
      expect(contentController.text.length, lessThanOrEqualTo(1000));
    });
  });
}
