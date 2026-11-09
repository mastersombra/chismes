import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chismes/features/gossip/presentation/widgets/gossip_card.dart';
import 'package:chismes/features/gossip/domain/entities/gossip.dart';
import '../../../../helpers/widget_test_wrapper.dart';

void main() {
  group('GossipCard', () {
    late Gossip testGossip;

    setUp(() {
      testGossip = Gossip(
        id: 'test-123',
        countryId: '1',
        regionId: 'ant',
        cityId: 'med',
        subject: 'Test Subject',
        content: 'Test Content',
        audioUrl: null,
        imageUrl: 'https://example.com/image.jpg',
        publishedAs: PublishAs.anonymous,
        status: GossipStatus.published,
        moderationStatus: ModerationStatus.approved,
        reportedCount: 0,
        viewCount: 0,
        deletedAt: null,
        deletedBy: null,
        visibility: GossipVisibility.public,
        createdAt: DateTime.now(),
        createdBy: 'user-123',
        modifiedAt: null,
        modifiedBy: null,
      );
    });

    testWidgets('debe renderizar subject del gossip', (tester) async {
      // Act
      await tester.pumpWidget(
        testableWidget(
          child: SizedBox(
            width: 200,
            height: 300,
            child: GossipCard(gossip: testGossip),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Test Subject'), findsOneWidget);
    });

    testWidgets('debe renderizar content del gossip', (tester) async {
      // Act
      await tester.pumpWidget(
        testableWidget(
          child: SizedBox(
            width: 200,
            height: 300,
            child: GossipCard(gossip: testGossip),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Test Content'), findsOneWidget);
    });

    testWidgets('debe limitar content a 2 líneas con ellipsis', (tester) async {
      // Arrange
      final longContentGossip = Gossip(
        id: 'test-123',
        countryId: '1',
        regionId: 'ant',
        cityId: 'med',
        subject: 'Test Subject',
        content: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. '
            'Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. '
            'Ut enim ad minim veniam, quis nostrud exercitation ullamco.',
        audioUrl: null,
        imageUrl: null,
        publishedAs: PublishAs.anonymous,
        status: GossipStatus.published,
        moderationStatus: ModerationStatus.approved,
        reportedCount: 0,
        viewCount: 0,
        deletedAt: null,
        deletedBy: null,
        visibility: GossipVisibility.public,
        createdAt: DateTime.now(),
        createdBy: 'user-123',
        modifiedAt: null,
        modifiedBy: null,
      );

      // Act
      await tester.pumpWidget(
        testableWidget(
          child: SizedBox(
            width: 200,
            height: 300,
            child: GossipCard(gossip: longContentGossip),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert - Busca el Text del content y verifica sus propiedades
      final contentTexts = tester.widgetList<Text>(
        find.text(longContentGossip.content),
      );

      expect(contentTexts.length, greaterThan(0));

      final contentText = contentTexts.first;
      expect(contentText.maxLines, 2);
      expect(contentText.overflow, TextOverflow.ellipsis);
    });

    testWidgets('debe renderizar Card con bordes redondeados', (tester) async {
      // Act
      await tester.pumpWidget(
        testableWidget(
          child: SizedBox(
            width: 200,
            height: 300,
            child: GossipCard(gossip: testGossip),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      final card = tester.widget<Card>(find.byType(Card));
      final shape = card.shape as RoundedRectangleBorder;
      expect(shape.borderRadius, BorderRadius.circular(16));
    });

    testWidgets('debe tener InkWell para navegación', (tester) async {
      // Act
      await tester.pumpWidget(
        testableWidget(
          child: SizedBox(
            width: 200,
            height: 300,
            child: GossipCard(gossip: testGossip),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert - El widget puede tener múltiples InkWells (Card + elementos internos)
      expect(find.byType(InkWell), findsWidgets);
    });

    testWidgets('debe navegar a detalle cuando se toca', (tester) async {
      // Act
      await tester.pumpWidget(
        testableWidget(
          child: SizedBox(
            width: 200,
            height: 300,
            child: GossipCard(gossip: testGossip),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Act - Tocar la card
      await tester.tap(find.byType(GossipCard));
      await tester.pumpAndSettle();

      // Assert - Debería navegar a GossipDetailScreen
      // (El test se completa sin error, lo que significa que la navegación funciona)
      // En un test real, verificaríamos que GossipDetailScreen está en la pila de navegación
      expect(find.byType(GossipCard), findsNothing); // Ya no está visible porque navegó
    });

    testWidgets('debe mostrar placeholder cuando imageUrl es null', (tester) async {
      // Arrange
      final gossipWithoutImage = Gossip(
        id: 'test-123',
        countryId: '1',
        regionId: 'ant',
        cityId: 'med',
        subject: 'Test Subject',
        content: 'Test Content',
        audioUrl: null,
        imageUrl: null,
        publishedAs: PublishAs.anonymous,
        status: GossipStatus.published,
        moderationStatus: ModerationStatus.approved,
        reportedCount: 0,
        viewCount: 0,
        deletedAt: null,
        deletedBy: null,
        visibility: GossipVisibility.public,
        createdAt: DateTime.now(),
        createdBy: 'user-123',
        modifiedAt: null,
        modifiedBy: null,
      );

      // Act
      await tester.pumpWidget(
        testableWidget(
          child: SizedBox(
            width: 200,
            height: 300,
            child: GossipCard(gossip: gossipWithoutImage),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert - Debe intentar cargar imagen de placeholder
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('debe tener subject en negrita', (tester) async {
      // Act
      await tester.pumpWidget(
        testableWidget(
          child: SizedBox(
            width: 200,
            height: 300,
            child: GossipCard(gossip: testGossip),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      final subjectText = tester.widget<Text>(find.text('Test Subject'));
      expect(subjectText.style?.fontWeight, FontWeight.bold);
    });

    testWidgets('debe tener estructura Column correcta', (tester) async {
      // Act
      await tester.pumpWidget(
        testableWidget(
          child: SizedBox(
            width: 200,
            height: 300,
            child: GossipCard(gossip: testGossip),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert - Verifica que hay Columns para el layout
      expect(find.byType(Column), findsWidgets);
    });

    testWidgets('debe tener padding en el contenido', (tester) async {
      // Act
      await tester.pumpWidget(
        testableWidget(
          child: SizedBox(
            width: 200,
            height: 300,
            child: GossipCard(gossip: testGossip),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert - Verifica que hay Padding
      expect(find.byType(Padding), findsWidgets);
    });

    testWidgets('debe tener imagen en Expanded para ocupar espacio', (tester) async {
      // Act
      await tester.pumpWidget(
        testableWidget(
          child: SizedBox(
            width: 200,
            height: 300,
            child: GossipCard(gossip: testGossip),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(Expanded), findsOneWidget);
    });

    testWidgets('debe renderizar botón de compartir', (tester) async {
      await tester.pumpWidget(
        testableWidget(
          child: SizedBox(
            width: 200,
            height: 300,
            child: GossipCard(gossip: testGossip),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.share), findsOneWidget);
      expect(find.byTooltip('Compartir chisme'), findsOneWidget);
    });

    testWidgets('debe renderizar botón de reportar', (tester) async {
      await tester.pumpWidget(
        testableWidget(
          child: SizedBox(
            width: 200,
            height: 300,
            child: GossipCard(gossip: testGossip),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.flag_outlined), findsOneWidget);
      expect(find.byTooltip('Reportar chisme'), findsOneWidget);
    });

    testWidgets('debe tener Row para los botones de acción', (tester) async {
      await tester.pumpWidget(
        testableWidget(
          child: SizedBox(
            width: 200,
            height: 300,
            child: GossipCard(gossip: testGossip),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Debe haber Row con los botones
      final rows = tester.widgetList<Row>(find.byType(Row));
      expect(rows.length, greaterThan(0));

      // Verificar que hay un Row con MainAxisAlignment.end
      final actionRow = rows.firstWhere(
        (row) => row.mainAxisAlignment == MainAxisAlignment.end,
      );
      expect(actionRow, isNotNull);
    });

    testWidgets('botones deben tener constraints mínimos de 48x48', (tester) async {
      await tester.pumpWidget(
        testableWidget(
          child: SizedBox(
            width: 200,
            height: 300,
            child: GossipCard(gossip: testGossip),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final shareButton = tester.widget<IconButton>(
        find.ancestor(
          of: find.byIcon(Icons.share),
          matching: find.byType(IconButton),
        ),
      );

      expect(shareButton.constraints?.minWidth, 48);
      expect(shareButton.constraints?.minHeight, 48);

      final reportButton = tester.widget<IconButton>(
        find.ancestor(
          of: find.byIcon(Icons.flag_outlined),
          matching: find.byType(IconButton),
        ),
      );

      expect(reportButton.constraints?.minWidth, 48);
      expect(reportButton.constraints?.minHeight, 48);
    });

    testWidgets('botones deben tener iconSize de 20', (tester) async {
      await tester.pumpWidget(
        testableWidget(
          child: SizedBox(
            width: 200,
            height: 300,
            child: GossipCard(gossip: testGossip),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final shareButton = tester.widget<IconButton>(
        find.ancestor(
          of: find.byIcon(Icons.share),
          matching: find.byType(IconButton),
        ),
      );

      expect(shareButton.iconSize, 20);

      final reportButton = tester.widget<IconButton>(
        find.ancestor(
          of: find.byIcon(Icons.flag_outlined),
          matching: find.byType(IconButton),
        ),
      );

      expect(reportButton.iconSize, 20);
    });

    testWidgets('debe tener Semantics para accesibilidad', (tester) async {
      await tester.pumpWidget(
        testableWidget(
          child: SizedBox(
            width: 200,
            height: 300,
            child: GossipCard(gossip: testGossip),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verificar que hay widgets Semantics
      expect(find.byType(Semantics), findsWidgets);
    });

    testWidgets('debe usar thumbnailUrl si está disponible', (tester) async {
      final gossipWithThumbnail = Gossip(
        id: 'test-123',
        countryId: '1',
        regionId: 'ant',
        cityId: 'med',
        subject: 'Test Subject',
        content: 'Test Content',
        audioUrl: null,
        imageUrl: 'https://example.com/image.jpg',
        thumbnailUrl: 'https://example.com/thumbnail.jpg',
        publishedAs: PublishAs.anonymous,
        status: GossipStatus.published,
        moderationStatus: ModerationStatus.approved,
        reportedCount: 0,
        viewCount: 0,
        deletedAt: null,
        deletedBy: null,
        visibility: GossipVisibility.public,
        createdAt: DateTime.now(),
        createdBy: 'user-123',
        modifiedAt: null,
        modifiedBy: null,
      );

      await tester.pumpWidget(
        testableWidget(
          child: SizedBox(
            width: 200,
            height: 300,
            child: GossipCard(gossip: gossipWithThumbnail),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final image = tester.widget<Image>(find.byType(Image));
      final networkImage = image.image as NetworkImage;
      expect(networkImage.url, 'https://example.com/thumbnail.jpg');
    });

    testWidgets('debe usar imageUrl si thumbnailUrl es null', (tester) async {
      final gossipWithoutThumbnail = Gossip(
        id: 'test-123',
        countryId: '1',
        regionId: 'ant',
        cityId: 'med',
        subject: 'Test Subject',
        content: 'Test Content',
        audioUrl: null,
        imageUrl: 'https://example.com/image.jpg',
        thumbnailUrl: null,
        publishedAs: PublishAs.anonymous,
        status: GossipStatus.published,
        moderationStatus: ModerationStatus.approved,
        reportedCount: 0,
        viewCount: 0,
        deletedAt: null,
        deletedBy: null,
        visibility: GossipVisibility.public,
        createdAt: DateTime.now(),
        createdBy: 'user-123',
        modifiedAt: null,
        modifiedBy: null,
      );

      await tester.pumpWidget(
        testableWidget(
          child: SizedBox(
            width: 200,
            height: 300,
            child: GossipCard(gossip: gossipWithoutThumbnail),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final image = tester.widget<Image>(find.byType(Image));
      final networkImage = image.image as NetworkImage;
      expect(networkImage.url, 'https://example.com/image.jpg');
    });

    testWidgets('debe usar placeholder si ambas URLs son null', (tester) async {
      final gossipWithoutImages = Gossip(
        id: 'test-123',
        countryId: '1',
        regionId: 'ant',
        cityId: 'med',
        subject: 'Test Subject',
        content: 'Test Content',
        audioUrl: null,
        imageUrl: null,
        thumbnailUrl: null,
        publishedAs: PublishAs.anonymous,
        status: GossipStatus.published,
        moderationStatus: ModerationStatus.approved,
        reportedCount: 0,
        viewCount: 0,
        deletedAt: null,
        deletedBy: null,
        visibility: GossipVisibility.public,
        createdAt: DateTime.now(),
        createdBy: 'user-123',
        modifiedAt: null,
        modifiedBy: null,
      );

      await tester.pumpWidget(
        testableWidget(
          child: SizedBox(
            width: 200,
            height: 300,
            child: GossipCard(gossip: gossipWithoutImages),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final image = tester.widget<Image>(find.byType(Image));
      final networkImage = image.image as NetworkImage;
      expect(networkImage.url, 'https://via.placeholder.com/150');
    });

    testWidgets('imagen debe tener BoxFit.cover', (tester) async {
      await tester.pumpWidget(
        testableWidget(
          child: SizedBox(
            width: 200,
            height: 300,
            child: GossipCard(gossip: testGossip),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final image = tester.widget<Image>(find.byType(Image));
      expect(image.fit, BoxFit.cover);
    });

    testWidgets('imagen debe ocupar ancho completo', (tester) async {
      await tester.pumpWidget(
        testableWidget(
          child: SizedBox(
            width: 200,
            height: 300,
            child: GossipCard(gossip: testGossip),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final image = tester.widget<Image>(find.byType(Image));
      expect(image.width, double.infinity);
    });

    testWidgets('debe tener errorBuilder para manejar errores de carga', (tester) async {
      await tester.pumpWidget(
        testableWidget(
          child: SizedBox(
            width: 200,
            height: 300,
            child: GossipCard(gossip: testGossip),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final image = tester.widget<Image>(find.byType(Image));
      expect(image.errorBuilder, isNotNull);
    });

    testWidgets('debe tener espaciado correcto entre subject y content', (tester) async {
      await tester.pumpWidget(
        testableWidget(
          child: SizedBox(
            width: 200,
            height: 300,
            child: GossipCard(gossip: testGossip),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Buscar el SizedBox entre subject y content
      final sizedBoxes = tester.widgetList<SizedBox>(find.byType(SizedBox));
      final spacings = sizedBoxes.where((box) => box.height == 4.0);
      expect(spacings.length, greaterThan(0));
    });

    testWidgets('Card debe tener elevation de 6', (tester) async {
      await tester.pumpWidget(
        testableWidget(
          child: SizedBox(
            width: 200,
            height: 300,
            child: GossipCard(gossip: testGossip),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final card = tester.widget<Card>(find.byType(Card));
      expect(card.elevation, 6);
    });

    testWidgets('Card debe tener clipBehavior antiAlias', (tester) async {
      await tester.pumpWidget(
        testableWidget(
          child: SizedBox(
            width: 200,
            height: 300,
            child: GossipCard(gossip: testGossip),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final card = tester.widget<Card>(find.byType(Card));
      expect(card.clipBehavior, Clip.antiAlias);
    });

    testWidgets('debe tener Column con crossAxisAlignment.start', (tester) async {
      await tester.pumpWidget(
        testableWidget(
          child: SizedBox(
            width: 200,
            height: 300,
            child: GossipCard(gossip: testGossip),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Buscar la Column principal dentro del Card
      final columns = tester.widgetList<Column>(find.descendant(
        of: find.byType(Card),
        matching: find.byType(Column),
      ));

      // Al menos una Column debe tener crossAxisAlignment.start
      final hasStartAlignment = columns.any(
        (col) => col.crossAxisAlignment == CrossAxisAlignment.start,
      );
      expect(hasStartAlignment, isTrue);
    });
  });
}
