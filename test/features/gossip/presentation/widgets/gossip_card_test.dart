import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chismes/core/di/injection_container.dart';
import 'package:chismes/core/error/error_codes.dart';
import 'package:chismes/core/error/failure.dart';
import 'package:chismes/core/result/result.dart';
import 'package:chismes/features/gossip/domain/entities/report_reason.dart';
import 'package:chismes/features/gossip/domain/usecases/report_gossip.dart';
import 'package:chismes/features/gossip/presentation/widgets/report_gossip_dialog.dart';
import 'package:chismes/l10n/app_localizations.dart';
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
            width: 350,
            height: 550,
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
            width: 350,
            height: 550,
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
            width: 350,
            height: 550,
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
            width: 350,
            height: 550,
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
            width: 350,
            height: 550,
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
            width: 350,
            height: 550,
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
            width: 350,
            height: 550,
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
            width: 350,
            height: 550,
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
            width: 350,
            height: 550,
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
            width: 350,
            height: 550,
            child: GossipCard(gossip: testGossip),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert - Verifica que hay Padding
      expect(find.byType(Padding), findsWidgets);
    });

    testWidgets('debe tener imagen en AspectRatio para mantener proporción', (tester) async {
      // Act
      await tester.pumpWidget(
        testableWidget(
          child: SizedBox(
            width: 350,
            height: 550,
            child: GossipCard(gossip: testGossip),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(AspectRatio), findsOneWidget);
    });

    testWidgets('debe renderizar botón de compartir', (tester) async {
      await tester.pumpWidget(
        testableWidget(
          child: SizedBox(
            width: 350,
            height: 550,
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
            width: 350,
            height: 550,
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
            width: 350,
            height: 550,
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
            width: 350,
            height: 550,
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
            width: 350,
            height: 550,
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
            width: 350,
            height: 550,
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
            width: 350,
            height: 550,
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
            width: 350,
            height: 550,
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
            width: 350,
            height: 550,
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
            width: 350,
            height: 550,
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
            width: 350,
            height: 550,
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
            width: 350,
            height: 550,
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
            width: 350,
            height: 550,
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
            width: 350,
            height: 550,
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
            width: 350,
            height: 550,
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
            width: 350,
            height: 550,
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

    group('Compartir', () {
      final shareCalls = <MethodCall>[];

      setUp(shareCalls.clear);

      void mockShareChannel(WidgetTester tester, {bool fail = false}) {
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          _shareChannel,
          (call) async {
            shareCalls.add(call);
            if (fail) throw PlatformException(code: 'share_failed');
            return 'dev.fluttercommunity.plus/share/success';
          },
        );
        addTearDown(() => tester.binding.defaultBinaryMessenger
            .setMockMethodCallHandler(_shareChannel, null));
      }

      Future<void> pumpCard(WidgetTester tester, Gossip gossip) async {
        await tester.pumpWidget(
          testableWidget(
            child: SizedBox(
              width: 350,
              height: 550,
              child: GossipCard(gossip: gossip),
            ),
          ),
        );
        await tester.pumpAndSettle();
      }

      testWidgets('envía subject, content y deep link al share sheet',
          (tester) async {
        mockShareChannel(tester);
        await pumpCard(tester, testGossip);

        await tester.tap(find.byIcon(Icons.share));
        await tester.pumpAndSettle();

        expect(shareCalls, hasLength(1));
        expect(shareCalls.single.method, 'share');
        final text = (shareCalls.single.arguments as Map)['text'] as String;
        expect(text, contains('"Test Subject"'));
        expect(text, contains('Test Content'));
        expect(text, contains('chismes://gossip/test-123'));
        expect(text, isNot(contains('Test Content...')));
        expect(find.byType(SnackBar), findsNothing);
      });

      testWidgets('trunca el content a 100 caracteres con "..."',
          (tester) async {
        mockShareChannel(tester);
        final longContent = 'a' * 150;
        await pumpCard(
          tester,
          Gossip(
            id: 'test-123',
            countryId: '1',
            regionId: 'ant',
            cityId: 'med',
            subject: 'Test Subject',
            content: longContent,
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
          ),
        );

        await tester.tap(find.byIcon(Icons.share));
        await tester.pumpAndSettle();

        final text = (shareCalls.single.arguments as Map)['text'] as String;
        expect(text, contains('${'a' * 100}...'));
        expect(text, isNot(contains('a' * 101)));
      });

      testWidgets('muestra snackbar de error si el share falla',
          (tester) async {
        mockShareChannel(tester, fail: true);
        await pumpCard(tester, testGossip);

        await tester.tap(find.byIcon(Icons.share));
        await tester.pump();
        await tester.pump();

        final l10n =
            AppLocalizations.of(tester.element(find.byType(GossipCard)))!;
        expect(shareCalls, hasLength(1));
        expect(find.text(l10n.gossipCardShareError), findsOneWidget);
      });
    });

    group('Reportar', () {
      late _FakeReportGossip fakeReport;

      setUp(() {
        fakeReport = _FakeReportGossip();
        getIt.registerSingleton<ReportGossip>(fakeReport);
      });

      tearDown(() => getIt.unregister<ReportGossip>());

      Future<AppLocalizations> pumpCard(WidgetTester tester) async {
        await tester.pumpWidget(
          testableWidget(
            child: SizedBox(
              width: 350,
              height: 550,
              child: GossipCard(gossip: testGossip),
            ),
          ),
        );
        await tester.pumpAndSettle();
        return AppLocalizations.of(tester.element(find.byType(GossipCard)))!;
      }

      Future<void> submitReport(
        WidgetTester tester,
        AppLocalizations l10n, {
        String? details,
      }) async {
        await tester.tap(find.byIcon(Icons.flag_outlined));
        await tester.pumpAndSettle();
        await tester.tap(find.text(l10n.gossipReportReasonSpam));
        await tester.pump();
        if (details != null) {
          await tester.enterText(find.byType(TextField), details);
        }
        await tester.tap(find.text(l10n.gossipReportButton));
        await tester.pump();
      }

      testWidgets('cancelar el diálogo no llama al use case', (tester) async {
        final l10n = await pumpCard(tester);

        await tester.tap(find.byIcon(Icons.flag_outlined));
        await tester.pumpAndSettle();
        expect(find.byType(ReportGossipDialog), findsOneWidget);

        await tester.tap(find.text(l10n.cancel));
        await tester.pumpAndSettle();

        expect(find.byType(ReportGossipDialog), findsNothing);
        expect(fakeReport.calls, isEmpty);
        expect(find.byType(SnackBar), findsNothing);
      });

      testWidgets(
          'éxito: muestra loading, envía id/razón/detalles y luego snackbar',
          (tester) async {
        final completer = Completer<Result<Failure, void>>();
        fakeReport.response = completer.future;
        final l10n = await pumpCard(tester);

        await submitReport(tester, l10n, details: '  muy feo  ');
        await tester.pump();

        // Loading visible mientras el use case no responde
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(fakeReport.calls, hasLength(1));
        expect(fakeReport.calls.single.gossipId, 'test-123');
        expect(fakeReport.calls.single.reason, ReportReason.spam);
        expect(fakeReport.calls.single.details, 'muy feo');

        completer.complete(Result.success(null));
        await tester.pumpAndSettle();

        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(find.text(l10n.gossipCardReportSuccess), findsOneWidget);
        expect(find.byType(GossipCard), findsOneWidget);
      });

      testWidgets('sin detalles envía details null', (tester) async {
        fakeReport.response = Future.value(Result.success(null));
        final l10n = await pumpCard(tester);

        await submitReport(tester, l10n);
        await tester.pumpAndSettle();

        expect(fakeReport.calls.single.details, isNull);
      });

      Future<void> expectFailureMessage(
        WidgetTester tester,
        Failure failure,
        String Function(AppLocalizations) expected,
      ) async {
        fakeReport.response = Future.value(Result.failure(failure));
        final l10n = await pumpCard(tester);

        await submitReport(tester, l10n);
        await tester.pumpAndSettle();

        expect(find.byType(CircularProgressIndicator), findsNothing);
        final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
        expect((snackBar.content as Text).data, expected(l10n));
        final theme = Theme.of(tester.element(find.byType(GossipCard)));
        expect(snackBar.backgroundColor, theme.colorScheme.error);
      }

      testWidgets('ServerFailure con message muestra el message',
          (tester) async {
        await expectFailureMessage(
          tester,
          const ServerFailure(code: ErrorCode.serverError, message: 'Servidor caído'),
          (_) => 'Servidor caído',
        );
      });

      testWidgets('ServerFailure sin message usa gossipCardReportError',
          (tester) async {
        await expectFailureMessage(
          tester,
          const ServerFailure(code: ErrorCode.serverError),
          (l10n) => l10n.gossipCardReportError,
        );
      });

      testWidgets('RateLimitFailure con message muestra el message',
          (tester) async {
        await expectFailureMessage(
          tester,
          const RateLimitFailure(code: ErrorCode.tooManyRequests, message: 'Espera 5 min'),
          (_) => 'Espera 5 min',
        );
      });

      testWidgets('RateLimitFailure sin message usa gossipCardRateLimitError',
          (tester) async {
        await expectFailureMessage(
          tester,
          const RateLimitFailure(code: ErrorCode.tooManyRequests),
          (l10n) => l10n.gossipCardRateLimitError,
        );
      });

      testWidgets('otro Failure con technicalMessage lo muestra',
          (tester) async {
        await expectFailureMessage(
          tester,
          const NetworkFailure(code: ErrorCode.networkError, technicalMessage: 'timeout'),
          (_) => 'timeout',
        );
      });

      testWidgets('otro Failure sin technicalMessage usa gossipCardReportError',
          (tester) async {
        await expectFailureMessage(
          tester,
          const NetworkFailure(code: ErrorCode.networkError),
          (l10n) => l10n.gossipCardReportError,
        );
      });
    });
  });
}

const _shareChannel = MethodChannel('dev.fluttercommunity.plus/share');

class _ReportCall {
  final String gossipId;
  final ReportReason reason;
  final String? details;

  _ReportCall(this.gossipId, this.reason, this.details);
}

class _FakeReportGossip implements ReportGossip {
  final calls = <_ReportCall>[];
  Future<Result<Failure, void>> response = Future.value(Result.success(null));

  @override
  Future<Result<Failure, void>> call({
    required String gossipId,
    required ReportReason reason,
    String? details,
  }) {
    calls.add(_ReportCall(gossipId, reason, details));
    return response;
  }
}
