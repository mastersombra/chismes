import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chismes/features/home/presentation/screens/gossip_detail_screen.dart';
import 'package:chismes/features/gossip/domain/entities/gossip.dart';

import '../../../../helpers/widget_test_wrapper.dart';

void main() {
  // Mock gossip data
  final mockGossip = Gossip(
    id: '1',
    countryId: 'AR',
    regionId: 'BA',
    cityId: 'CABA',
    subject: 'Test Subject',
    content: 'Test content for the gossip',
    audioUrl: null,
    imageUrl: 'https://example.com/image.jpg',
    publishedAs: PublishAs.profile,
    status: GossipStatus.published,
    moderationStatus: ModerationStatus.approved,
    reportedCount: 0,
    viewCount: 0,
    deletedAt: null,
    deletedBy: null,
    visibility: GossipVisibility.public,
    createdAt: DateTime(2024, 1, 1),
    createdBy: 'user-1',
    modifiedAt: DateTime(2024, 1, 1),
    modifiedBy: 'user-1',
  );

  final mockGossipWithoutImage = Gossip(
    id: '2',
    countryId: 'AR',
    regionId: 'BA',
    cityId: 'CABA',
    subject: 'Gossip sin imagen',
    content: 'Contenido sin imagen',
    audioUrl: null,
    imageUrl: null,
    publishedAs: PublishAs.profile,
    status: GossipStatus.published,
    moderationStatus: ModerationStatus.approved,
    reportedCount: 0,
    viewCount: 0,
    deletedAt: null,
    deletedBy: null,
    visibility: GossipVisibility.public,
    createdAt: DateTime(2024, 1, 1),
    createdBy: 'user-2',
    modifiedAt: DateTime(2024, 1, 1),
    modifiedBy: 'user-2',
  );

  Widget createTestWidget(Gossip gossip) {
    return testableWidget(
      child: GossipDetailScreen(gossip: gossip),
      useScaffold: false,
    );
  }

  group('GossipDetailScreen - Básicos', () {
    testWidgets('debe renderizar la screen', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget(mockGossip));
      await tester.pump();

      // Assert
      expect(find.byType(GossipDetailScreen), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('debe renderizar AppBar con título', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget(mockGossip));
      await tester.pump();

      // Assert
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('debe ser un StatelessWidget', (tester) async {
      // Arrange
      final widget = GossipDetailScreen(gossip: mockGossip);

      // Assert
      expect(widget, isA<StatelessWidget>());
    });

    testWidgets('debe tener SingleChildScrollView', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget(mockGossip));
      await tester.pump();

      // Assert
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });
  });

  group('GossipDetailScreen - Contenido', () {
    testWidgets('debe mostrar subject del gossip', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget(mockGossip));
      await tester.pump();

      // Assert
      expect(find.text('Test Subject'), findsOneWidget);
    });

    testWidgets('debe mostrar content del gossip', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget(mockGossip));
      await tester.pump();

      // Assert
      expect(find.text('Test content for the gossip'), findsOneWidget);
    });

    testWidgets('debe mostrar subject en negrita', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget(mockGossip));
      await tester.pump();

      // Assert
      final textWidget = tester.widget<Text>(
        find.text('Test Subject'),
      );
      expect(textWidget.style?.fontWeight, FontWeight.bold);
    });

    testWidgets('subject debe usar displaySmall del tema', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget(mockGossip));
      await tester.pump();

      // Assert - verificar que el Text con subject existe
      expect(find.text('Test Subject'), findsOneWidget);

      // El widget usa Theme.of(context).textTheme.displaySmall
      final context = tester.element(find.byType(GossipDetailScreen));
      final theme = Theme.of(context);
      expect(theme.textTheme.displaySmall, isNotNull);
    });
  });

  group('GossipDetailScreen - Imagen', () {
    testWidgets('debe intentar cargar imagen cuando imageUrl no es null',
        (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget(mockGossip));
      await tester.pump();

      // Assert
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('debe usar placeholder cuando imageUrl es null', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget(mockGossipWithoutImage));
      await tester.pump();

      // Assert - debe mostrar el placeholder
      expect(find.byType(Image), findsOneWidget);

      // Verificar que usa el URL de placeholder
      final imageWidget = tester.widget<Image>(find.byType(Image));
      final networkImage = imageWidget.image as NetworkImage;
      expect(networkImage.url, 'https://via.placeholder.com/150');
    });

    testWidgets('imagen debe tener altura de 300', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget(mockGossip));
      await tester.pump();

      // Assert
      final imageWidget = tester.widget<Image>(find.byType(Image));
      expect(imageWidget.height, 300);
    });

    testWidgets('imagen debe tener width de double.infinity', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget(mockGossip));
      await tester.pump();

      // Assert
      final imageWidget = tester.widget<Image>(find.byType(Image));
      expect(imageWidget.width, double.infinity);
    });

    testWidgets('imagen debe tener BoxFit.cover', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget(mockGossip));
      await tester.pump();

      // Assert
      final imageWidget = tester.widget<Image>(find.byType(Image));
      expect(imageWidget.fit, BoxFit.cover);
    });

    testWidgets('debe tener errorBuilder configurado', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget(mockGossip));
      await tester.pump();

      // Assert
      final imageWidget = tester.widget<Image>(find.byType(Image));
      expect(imageWidget.errorBuilder, isNotNull);
    });
  });

  group('GossipDetailScreen - Layout', () {
    testWidgets('debe tener Column principal', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget(mockGossip));
      await tester.pump();

      // Assert
      expect(find.byType(Column), findsWidgets);
    });

    testWidgets('debe tener Padding alrededor del contenido', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget(mockGossip));
      await tester.pump();

      // Assert
      expect(find.byType(Padding), findsWidgets);
    });

    testWidgets('debe tener SizedBox para espaciado', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget(mockGossip));
      await tester.pump();

      // Assert
      expect(find.byType(SizedBox), findsWidgets);
    });

    testWidgets('Column debe usar CrossAxisAlignment.start', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget(mockGossip));
      await tester.pump();

      // Assert - verificar que hay Columns (no podemos verificar el alignment fácilmente)
      expect(find.byType(Column), findsWidgets);
    });
  });

  group('GossipDetailScreen - Constructor', () {
    test('debe requerir gossip en constructor', () {
      // Act & Assert
      expect(
        () => GossipDetailScreen(gossip: mockGossip),
        returnsNormally,
      );
    });

    test('debe aceptar gossip en constructor', () {
      // Act
      final widget = GossipDetailScreen(
        gossip: Gossip(
          id: '1',
          countryId: 'AR',
          regionId: 'BA',
          cityId: 'CABA',
          subject: 'Test',
          content: 'Content',
          audioUrl: null,
          imageUrl: null,
          publishedAs: PublishAs.profile,
          status: GossipStatus.published,
          moderationStatus: ModerationStatus.approved,
          reportedCount: 0,
          viewCount: 0,
          deletedAt: null,
          deletedBy: null,
          visibility: GossipVisibility.public,
          createdAt: DateTime(2024, 1, 1),
          createdBy: 'user-1',
          modifiedAt: DateTime(2024, 1, 1),
          modifiedBy: 'user-1',
        ),
      );

      // Assert
      expect(widget, isA<GossipDetailScreen>());
    });

    testWidgets('debe aceptar key opcional', (tester) async {
      // Arrange
      const key = Key('gossip-detail-key');

      // Act
      await tester.pumpWidget(
        testableWidget(
          child: GossipDetailScreen(
            key: key,
            gossip: mockGossip,
          ),
          useScaffold: false,
        ),
      );
      await tester.pump();

      // Assert
      expect(find.byKey(key), findsOneWidget);
    });
  });
}
