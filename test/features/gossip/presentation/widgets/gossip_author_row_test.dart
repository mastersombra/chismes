import 'package:chismes/core/di/injection_container.dart';
import 'package:chismes/core/navigation/social_navigator.dart';
import 'package:chismes/core/social/gossip_author.dart';
import 'package:chismes/features/gossip/domain/entities/gossip.dart';
import 'package:chismes/features/gossip/presentation/screens/gossip_detail_screen.dart'
    as gossip_detail;
import 'package:chismes/features/gossip/presentation/widgets/gossip_author_row.dart';
import 'package:chismes/features/gossip/presentation/widgets/gossip_card.dart';
import 'package:chismes/features/home/presentation/screens/gossip_detail_screen.dart'
    as home_detail;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../../../../helpers/fake_network_image.dart';
import '../../../../helpers/widget_test_wrapper.dart';
import '../../../social/social_test_mocks.mocks.dart';

const _author = GossipAuthor(userId: 'author-1', username: 'ana', displayName: 'Ana Pérez');

Gossip _gossip({required bool withProfile}) => Gossip(
      id: 'g1',
      countryId: 'CO',
      regionId: 'ant',
      cityId: 'med',
      subject: 'Asunto',
      content: 'Contenido',
      publishedAs: withProfile ? PublishAs.profile : PublishAs.anonymous,
      status: GossipStatus.published,
      moderationStatus: ModerationStatus.approved,
      visibility: GossipVisibility.public,
      createdAt: DateTime.utc(2026, 11, 20),
      createdBy: withProfile ? 'author-1' : null,
      author: withProfile ? _author : null,
    );

void main() {
  late MockSocialNavigator navigator;

  setUp(() {
    navigator = MockSocialNavigator();
    when(navigator.openUserProfile(any, any)).thenAnswer((_) async {});
    if (getIt.isRegistered<SocialNavigator>()) getIt.unregister<SocialNavigator>();
    getIt.registerSingleton<SocialNavigator>(navigator);
  });

  tearDown(() {
    if (getIt.isRegistered<SocialNavigator>()) getIt.unregister<SocialNavigator>();
  });

  final authorRow = find.byKey(const Key('gossipAuthorRow'));

  group('GossipCard - autor', () {
    testWidgets('chisme con perfil: muestra el autor y al tocarlo abre su perfil',
        (tester) async {
      useFakeNetworkImages(addTearDown);
      await tester.pumpWidget(testableWidget(
        child: SingleChildScrollView(
          child: SizedBox(width: 320, child: GossipCard(gossip: _gossip(withProfile: true))),
        ),
      ));
      await tester.pumpAndSettle();
      await tester.ensureVisible(authorRow);
      await tester.pumpAndSettle();

      expect(authorRow, findsOneWidget);
      expect(find.text('Ana Pérez'), findsOneWidget);
      expect(tester.getSize(authorRow).height, greaterThanOrEqualTo(48));

      await tester.tap(authorRow);
      await tester.pump();

      verify(navigator.openUserProfile(any, 'author-1')).called(1);
    });

    testWidgets('chisme anónimo: sin autor ni nada que tocar', (tester) async {
      useFakeNetworkImages(addTearDown);
      await tester.pumpWidget(testableWidget(
        child: SingleChildScrollView(child: GossipCard(gossip: _gossip(withProfile: false))),
      ));
      await tester.pumpAndSettle();

      expect(authorRow, findsNothing);
      expect(find.byType(GossipAuthorRow), findsNothing);
      verifyZeroInteractions(navigator);
    });

    testWidgets('showAuthor: false oculta el autor', (tester) async {
      useFakeNetworkImages(addTearDown);
      await tester.pumpWidget(testableWidget(
        child: SingleChildScrollView(
          child: GossipCard(gossip: _gossip(withProfile: true), showAuthor: false),
        ),
      ));
      await tester.pumpAndSettle();

      expect(authorRow, findsNothing);
    });

    testWidgets('en una celda de grilla de alto fijo (Buscar) no desborda', (tester) async {
      useFakeNetworkImages(addTearDown);
      final longAuthor = _gossip(withProfile: true);
      await tester.pumpWidget(testableWidget(
        child: Center(
          child: SizedBox(
            width: 140,
            height: 140 / 0.72,
            child: GossipCard(
              gossip: Gossip(
                id: longAuthor.id,
                countryId: 'CO',
                regionId: 'ant',
                cityId: 'med',
                subject: longAuthor.subject,
                content: longAuthor.content,
                publishedAs: PublishAs.profile,
                status: GossipStatus.published,
                moderationStatus: ModerationStatus.approved,
                visibility: GossipVisibility.public,
                createdAt: longAuthor.createdAt,
                createdBy: 'author-1',
                author: const GossipAuthor(
                  userId: 'author-1',
                  displayName: 'Un nombre larguísimo que no cabe en la celda',
                ),
              ),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(authorRow, findsOneWidget);
    });
  });

  group('Pantallas de detalle - autor', () {
    for (final entry in <String, Widget Function(Gossip)>{
      'gossip': (g) => gossip_detail.GossipDetailScreen(gossip: g),
      'home': (g) => home_detail.GossipDetailScreen(gossip: g),
    }.entries) {
      testWidgets('${entry.key}: con perfil muestra nombre y @usuario, abre perfil',
          (tester) async {
        useFakeNetworkImages(addTearDown);
        await tester.pumpWidget(
          testableWidget(useScaffold: false, child: entry.value(_gossip(withProfile: true))),
        );
        await tester.pumpAndSettle();

        expect(find.text('Ana Pérez'), findsOneWidget);
        expect(find.text('@ana'), findsOneWidget);
        expect(find.bySemanticsLabel('Ver perfil de Ana Pérez'), findsOneWidget);

        await tester.tap(authorRow);
        await tester.pump();
        verify(navigator.openUserProfile(any, 'author-1')).called(1);
      });

      testWidgets('${entry.key}: anónimo sin autor', (tester) async {
        useFakeNetworkImages(addTearDown);
        await tester.pumpWidget(
          testableWidget(useScaffold: false, child: entry.value(_gossip(withProfile: false))),
        );
        await tester.pumpAndSettle();

        expect(authorRow, findsNothing);
      });
    }

    testWidgets('el detalle abierto desde la card respeta showAuthor: false', (tester) async {
      useFakeNetworkImages(addTearDown);
      await tester.pumpWidget(testableWidget(
        child: SingleChildScrollView(
          child: SizedBox(
            width: 320,
            child: GossipCard(gossip: _gossip(withProfile: true), showAuthor: false),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Asunto'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Asunto'));
      await tester.pumpAndSettle();

      expect(find.byType(gossip_detail.GossipDetailScreen), findsOneWidget);
      expect(authorRow, findsNothing);
    });
  });
}
