import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chismes/features/gossip/presentation/widgets/media_attachment_section.dart';
import 'package:chismes/features/gossip/presentation/states/add_gossip_state.dart';
import 'package:chismes/features/gossip/domain/entities/gossip.dart';
import '../../../../helpers/widget_test_wrapper.dart';

void main() {
  group('MediaAttachmentSection', () {
    // Constante para usar en tests
    const testIdempotencyKey = 'test-idempotency-key';

    late bool onPickImageCalled;
    late bool onPickAudioCalled;
    late bool onRemoveImageCalled;
    late bool onRemoveAudioCalled;

    setUp(() {
      onPickImageCalled = false;
      onPickAudioCalled = false;
      onRemoveImageCalled = false;
      onRemoveAudioCalled = false;
    });

    Widget buildWidget(AddGossipState state) {
      return testableWidget(
        child: MediaAttachmentSection(
          state: state,
          onPickImage: () => onPickImageCalled = true,
          onPickAudio: () => onPickAudioCalled = true,
          onRemoveImage: () => onRemoveImageCalled = true,
          onRemoveAudio: () => onRemoveAudioCalled = true,
        ),
      );
    }

    group('Renderizado inicial', () {
      testWidgets('debe renderizar dos botones cuando no hay media', (tester) async {
        // Arrange
        const state = AddGossipState(idempotencyKey: testIdempotencyKey);

        // Act
        await tester.pumpWidget(buildWidget(state));
        await tester.pumpAndSettle();

        // Assert - Buscar botones por tipo
        expect(find.byWidgetPredicate((w) => w is OutlinedButton), findsNWidgets(2));

        // Verificar íconos
        expect(find.byIcon(Icons.image), findsOneWidget);
        expect(find.byIcon(Icons.mic), findsOneWidget);
      });

      testWidgets('botón de imagen debe tener ícono y texto correcto', (tester) async {
        // Arrange
        const state = AddGossipState(idempotencyKey: testIdempotencyKey);

        // Act
        await tester.pumpWidget(buildWidget(state));
        await tester.pumpAndSettle();

        // Assert
        expect(find.byIcon(Icons.image), findsOneWidget);
        expect(find.text('Agregar imagen'), findsOneWidget);
      });

      testWidgets('botón de audio debe tener ícono y texto correcto', (tester) async {
        // Arrange
        const state = AddGossipState(idempotencyKey: testIdempotencyKey);

        // Act
        await tester.pumpWidget(buildWidget(state));
        await tester.pumpAndSettle();

        // Assert
        expect(find.byIcon(Icons.mic), findsOneWidget);
        expect(find.text('Agregar audio'), findsOneWidget);
      });
    });

    group('Interacciones con botones', () {
      testWidgets('debe llamar onPickImage al presionar botón de imagen', (tester) async {
        // Arrange
        const state = AddGossipState(idempotencyKey: testIdempotencyKey);

        // Act
        await tester.pumpWidget(buildWidget(state));
        await tester.pumpAndSettle();

        final imageButton = find.ancestor(
          of: find.byIcon(Icons.image),
          matching: find.byWidgetPredicate((w) => w is OutlinedButton),
        );
        await tester.tap(imageButton);
        await tester.pumpAndSettle();

        // Assert
        expect(onPickImageCalled, isTrue);
      });

      testWidgets('debe llamar onPickAudio al presionar botón de audio', (tester) async {
        // Arrange
        const state = AddGossipState(idempotencyKey: testIdempotencyKey);

        // Act
        await tester.pumpWidget(buildWidget(state));
        await tester.pumpAndSettle();

        final audioButton = find.ancestor(
          of: find.byIcon(Icons.mic),
          matching: find.byWidgetPredicate((w) => w is OutlinedButton),
        );
        await tester.tap(audioButton);
        await tester.pumpAndSettle();

        // Assert
        expect(onPickAudioCalled, isTrue);
      });

      testWidgets('botones deben estar habilitados', (tester) async {
        // Arrange
        const state = AddGossipState(idempotencyKey: testIdempotencyKey);

        // Act
        await tester.pumpWidget(buildWidget(state));
        await tester.pumpAndSettle();

        // Assert
        final imageButton = tester.widget<OutlinedButton>(
          find.ancestor(
            of: find.byIcon(Icons.image),
            matching: find.byWidgetPredicate((w) => w is OutlinedButton),
          ),
        );
        expect(imageButton.onPressed, isNotNull);

        final audioButton = tester.widget<OutlinedButton>(
          find.ancestor(
            of: find.byIcon(Icons.mic),
            matching: find.byWidgetPredicate((w) => w is OutlinedButton),
          ),
        );
        expect(audioButton.onPressed, isNotNull);
      });
    });

    group('Layout y espaciado', () {
      testWidgets('debe tener spacing correcto entre imagen y audio', (tester) async {
        // Arrange
        const state = AddGossipState(idempotencyKey: testIdempotencyKey);

        // Act
        await tester.pumpWidget(buildWidget(state));
        await tester.pumpAndSettle();

        // Assert - Verificar que hay un SizedBox entre los elementos
        expect(find.byType(SizedBox), findsWidgets);

        // Verificar que el widget es una Column
        expect(find.byType(Column), findsOneWidget);
      });

      testWidgets('botones deben ocupar ancho completo', (tester) async {
        // Arrange
        const state = AddGossipState(idempotencyKey: testIdempotencyKey);

        // Act
        await tester.pumpWidget(buildWidget(state));
        await tester.pumpAndSettle();

        // Assert - Verificar que los botones tienen minimumSize
        final imageButton = tester.widget<OutlinedButton>(
          find.ancestor(
            of: find.byIcon(Icons.image),
            matching: find.byWidgetPredicate((w) => w is OutlinedButton),
          ),
        );
        expect(
          imageButton.style?.minimumSize?.resolve({}),
          const Size(double.infinity, 48),
        );

        final audioButton = tester.widget<OutlinedButton>(
          find.ancestor(
            of: find.byIcon(Icons.mic),
            matching: find.byWidgetPredicate((w) => w is OutlinedButton),
          ),
        );
        expect(
          audioButton.style?.minimumSize?.resolve({}),
          const Size(double.infinity, 48),
        );
      });
    });

    group('Estados condicionales', () {
      testWidgets('debe renderizar botones cuando URLs son null', (tester) async {
        // Arrange
        const state = AddGossipState(
          idempotencyKey: testIdempotencyKey,
          imageUrl: null,
          audioUrl: null,
        );

        // Act
        await tester.pumpWidget(buildWidget(state));
        await tester.pumpAndSettle();

        // Assert - Con URLs null, debe mostrar botones de agregar
        expect(find.byWidgetPredicate((w) => w is OutlinedButton), findsNWidgets(2));
        expect(find.text('Agregar imagen'), findsOneWidget);
        expect(find.text('Agregar audio'), findsOneWidget);
      });

      testWidgets('debe renderizar correctamente con publishedAs específico', (tester) async {
        // Arrange
        const state = AddGossipState(
          idempotencyKey: testIdempotencyKey,
          publishedAs: PublishAs.profile,
          imageUrl: null,
          audioUrl: null,
        );

        // Act
        await tester.pumpWidget(buildWidget(state));
        await tester.pumpAndSettle();

        // Assert - El widget no depende de publishedAs, debe renderizar normal
        expect(find.byWidgetPredicate((w) => w is OutlinedButton), findsNWidgets(2));
      });
    });
  });
}
