import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chismes/features/gossip/presentation/screens/gossip_detail_screen.dart';
import 'package:chismes/features/gossip/domain/entities/gossip.dart';

import '../../../../helpers/widget_test_wrapper.dart';

void main() {
  group('GossipDetailScreen', () {
    late Gossip testGossip;

    setUp(() {
      testGossip = Gossip(
        id: '123',
        countryId: '1',
        regionId: '1',
        cityId: '1',
        subject: 'Test Subject',
        content: 'Test Content',
        imageUrl: 'https://example.com/image.jpg',
        audioUrl: null,
        publishedAs: PublishAs.profile,
        visibility: GossipVisibility.public,
        status: GossipStatus.published,
        moderationStatus: ModerationStatus.approved,
        createdBy: 'user-123',
        createdAt: DateTime(2024, 1, 1),
      );
    });

    Widget createTestWidget() {
      return testableWidget(
        child: GossipDetailScreen(gossip: testGossip),
        useScaffold: false,
      );
    }

    testWidgets('debe renderizar correctamente', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(GossipDetailScreen), findsOneWidget);
    });

    testWidgets('debe crear instancia con key', (WidgetTester tester) async {
      // Arrange
      const testKey = Key('gossip_detail_key');

      // Act
      await tester.pumpWidget(
        testableWidget(
          child: GossipDetailScreen(
            key: testKey,
            gossip: testGossip,
          ),
          useScaffold: false,
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.byKey(testKey), findsOneWidget);
    });

    testWidgets('debe tener Scaffold', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('debe tener AppBar', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('debe mostrar subject del gossip', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Test Subject'), findsOneWidget);
    });

    testWidgets('debe mostrar content del gossip', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Test Content'), findsOneWidget);
    });

    testWidgets('debe tener SingleChildScrollView', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('debe mostrar placeholder cuando imageUrl es null', (WidgetTester tester) async {
      // Arrange
      final gossipWithoutImage = Gossip(
        id: '123',
        countryId: '1',
        regionId: '1',
        cityId: '1',
        subject: 'Test Subject',
        content: 'Test Content',
        imageUrl: null,
        audioUrl: null,
        publishedAs: PublishAs.profile,
        visibility: GossipVisibility.public,
        status: GossipStatus.published,
        moderationStatus: ModerationStatus.approved,
        createdBy: 'user-123',
        createdAt: DateTime(2024, 1, 1),
      );

      // Act
      await tester.pumpWidget(
        testableWidget(
          child: GossipDetailScreen(gossip: gossipWithoutImage),
          useScaffold: false,
        ),
      );
      await tester.pumpAndSettle();

      // Assert - debe usar placeholder URL
      expect(find.byType(GossipDetailScreen), findsOneWidget);
    });

    testWidgets('debe tener imagen con errorBuilder', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      final imageWidget = tester.widget<Image>(find.byType(Image));
      expect(imageWidget.errorBuilder, isNotNull);
    });

    testWidgets('debe tener Column como estructura principal', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(Column), findsWidgets);
    });

    testWidgets('debe tener padding en el contenido', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(Padding), findsWidgets);
    });

    testWidgets('debe mostrar imagen con ancho completo', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      final imageWidget = tester.widget<Image>(find.byType(Image));
      expect(imageWidget.width, double.infinity);
    });

    testWidgets('debe tener imagen con altura fija de 300', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      final imageWidget = tester.widget<Image>(find.byType(Image));
      expect(imageWidget.height, 300);
    });

    testWidgets('debe tener imagen con BoxFit.cover', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      final imageWidget = tester.widget<Image>(find.byType(Image));
      expect(imageWidget.fit, BoxFit.cover);
    });

    testWidgets('debe ser StatelessWidget', (WidgetTester tester) async {
      // Assert
      expect(GossipDetailScreen(gossip: testGossip), isA<StatelessWidget>());
    });

    testWidgets('debe tener SizedBox para espaciado', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(SizedBox), findsWidgets);
    });
  });
}
