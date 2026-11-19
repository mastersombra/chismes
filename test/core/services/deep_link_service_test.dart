import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:chismes/l10n/app_localizations.dart';
import 'package:chismes/core/services/deep_link_service.dart';
import 'package:chismes/core/logging/logging.dart';

import 'deep_link_service_test.mocks.dart';

@GenerateMocks([AppLogger])
// ignore: unused_element
void _generateMocks() {}

void main() {
  group('DeepLinkService - Static Link Generators', () {
    group('generateGossipLink', () {
      test('debe generar link con formato chismes://gossip/{id}', () {
        const gossipId = 'abc123';
        final link = DeepLinkService.generateGossipLink(gossipId);

        expect(link, 'chismes://gossip/abc123');
      });

      test('debe incluir gossipId en el path', () {
        const gossipId = 'test-gossip-456';
        final link = DeepLinkService.generateGossipLink(gossipId);

        expect(link, contains(gossipId));
        expect(link, startsWith('chismes://gossip/'));
      });

      test('debe usar scheme "chismes"', () {
        const gossipId = 'xyz';
        final link = DeepLinkService.generateGossipLink(gossipId);

        final uri = Uri.parse(link);
        expect(uri.scheme, 'chismes');
      });

      test('debe usar host "gossip"', () {
        const gossipId = '123';
        final link = DeepLinkService.generateGossipLink(gossipId);

        final uri = Uri.parse(link);
        expect(uri.host, 'gossip');
      });

      test('debe generar URI parseable', () {
        const gossipId = 'test-id';
        final link = DeepLinkService.generateGossipLink(gossipId);

        final uri = Uri.parse(link);
        expect(uri.pathSegments.length, 1);
        expect(uri.pathSegments[0], gossipId);
      });

      test('debe manejar IDs con guiones', () {
        const gossipId = 'uuid-abc-def-123';
        final link = DeepLinkService.generateGossipLink(gossipId);

        expect(link, 'chismes://gossip/uuid-abc-def-123');
      });

      test('debe manejar IDs con underscores', () {
        const gossipId = 'gossip_test_456';
        final link = DeepLinkService.generateGossipLink(gossipId);

        expect(link, 'chismes://gossip/gossip_test_456');
      });

      test('debe manejar IDs numéricos', () {
        const gossipId = '12345678';
        final link = DeepLinkService.generateGossipLink(gossipId);

        expect(link, 'chismes://gossip/12345678');
      });

      test('debe manejar IDs alfanuméricos', () {
        const gossipId = 'abc123XYZ789';
        final link = DeepLinkService.generateGossipLink(gossipId);

        expect(link, 'chismes://gossip/abc123XYZ789');
      });

      test('debe generar links únicos por gossipId', () {
        final link1 = DeepLinkService.generateGossipLink('id1');
        final link2 = DeepLinkService.generateGossipLink('id2');

        expect(link1, isNot(equals(link2)));
      });
    });

    group('generateProfileLink', () {
      test('debe generar link con formato chismes://profile/{id}', () {
        const userId = 'user123';
        final link = DeepLinkService.generateProfileLink(userId);

        expect(link, 'chismes://profile/user123');
      });

      test('debe incluir userId en el path', () {
        const userId = 'test-user-789';
        final link = DeepLinkService.generateProfileLink(userId);

        expect(link, contains(userId));
        expect(link, startsWith('chismes://profile/'));
      });

      test('debe usar scheme "chismes"', () {
        const userId = 'abc';
        final link = DeepLinkService.generateProfileLink(userId);

        final uri = Uri.parse(link);
        expect(uri.scheme, 'chismes');
      });

      test('debe usar host "profile"', () {
        const userId = '456';
        final link = DeepLinkService.generateProfileLink(userId);

        final uri = Uri.parse(link);
        expect(uri.host, 'profile');
      });

      test('debe generar URI parseable', () {
        const userId = 'test-user';
        final link = DeepLinkService.generateProfileLink(userId);

        final uri = Uri.parse(link);
        expect(uri.pathSegments.length, 1);
        expect(uri.pathSegments[0], userId);
      });

      test('debe manejar userIds con guiones', () {
        const userId = 'uuid-user-abc-123';
        final link = DeepLinkService.generateProfileLink(userId);

        expect(link, 'chismes://profile/uuid-user-abc-123');
      });

      test('debe manejar userIds con underscores', () {
        const userId = 'user_test_456';
        final link = DeepLinkService.generateProfileLink(userId);

        expect(link, 'chismes://profile/user_test_456');
      });

      test('debe generar links únicos por userId', () {
        final link1 = DeepLinkService.generateProfileLink('user1');
        final link2 = DeepLinkService.generateProfileLink('user2');

        expect(link1, isNot(equals(link2)));
      });
    });

    group('generateFeedLink', () {
      test('debe generar link sin cityId cuando no se pasa parámetro', () {
        final link = DeepLinkService.generateFeedLink();

        expect(link, 'chismes://feed');
      });

      test('debe generar link con cityId cuando se pasa parámetro', () {
        const cityId = 'medellin';
        final link = DeepLinkService.generateFeedLink(cityId: cityId);

        expect(link, 'chismes://feed?city=medellin');
      });

      test('debe usar scheme "chismes"', () {
        final link = DeepLinkService.generateFeedLink();

        final uri = Uri.parse(link);
        expect(uri.scheme, 'chismes');
      });

      test('debe usar host "feed"', () {
        final link = DeepLinkService.generateFeedLink();

        final uri = Uri.parse(link);
        expect(uri.host, 'feed');
      });

      test('debe incluir cityId en query parameters', () {
        const cityId = 'bogota';
        final link = DeepLinkService.generateFeedLink(cityId: cityId);

        final uri = Uri.parse(link);
        expect(uri.queryParameters['city'], cityId);
      });

      test('debe generar URI sin query parameters cuando cityId es null', () {
        final link = DeepLinkService.generateFeedLink(cityId: null);

        final uri = Uri.parse(link);
        expect(uri.queryParameters, isEmpty);
        expect(link, 'chismes://feed');
      });

      test('debe manejar cityIds con guiones', () {
        const cityId = 'santa-marta';
        final link = DeepLinkService.generateFeedLink(cityId: cityId);

        expect(link, 'chismes://feed?city=santa-marta');
      });

      test('debe manejar cityIds con underscores', () {
        const cityId = 'san_andres';
        final link = DeepLinkService.generateFeedLink(cityId: cityId);

        expect(link, 'chismes://feed?city=san_andres');
      });

      test('debe generar links únicos por cityId', () {
        final link1 = DeepLinkService.generateFeedLink(cityId: 'city1');
        final link2 = DeepLinkService.generateFeedLink(cityId: 'city2');

        expect(link1, isNot(equals(link2)));
      });

      test('link sin cityId debe ser diferente a link con cityId', () {
        final linkWithoutCity = DeepLinkService.generateFeedLink();
        final linkWithCity = DeepLinkService.generateFeedLink(cityId: 'medellin');

        expect(linkWithoutCity, isNot(equals(linkWithCity)));
      });
    });

    group('Comparación entre tipos de links', () {
      test('links de gossip, profile y feed deben ser diferentes', () {
        final gossipLink = DeepLinkService.generateGossipLink('test');
        final profileLink = DeepLinkService.generateProfileLink('test');
        final feedLink = DeepLinkService.generateFeedLink();

        expect(gossipLink, isNot(equals(profileLink)));
        expect(gossipLink, isNot(equals(feedLink)));
        expect(profileLink, isNot(equals(feedLink)));
      });

      test('todos los links deben usar scheme "chismes"', () {
        final gossipLink = DeepLinkService.generateGossipLink('id1');
        final profileLink = DeepLinkService.generateProfileLink('id2');
        final feedLink = DeepLinkService.generateFeedLink(cityId: 'city1');

        expect(Uri.parse(gossipLink).scheme, 'chismes');
        expect(Uri.parse(profileLink).scheme, 'chismes');
        expect(Uri.parse(feedLink).scheme, 'chismes');
      });

      test('hosts deben ser diferentes para cada tipo', () {
        final gossipLink = DeepLinkService.generateGossipLink('id1');
        final profileLink = DeepLinkService.generateProfileLink('id2');
        final feedLink = DeepLinkService.generateFeedLink();

        final gossipUri = Uri.parse(gossipLink);
        final profileUri = Uri.parse(profileLink);
        final feedUri = Uri.parse(feedLink);

        expect(gossipUri.host, 'gossip');
        expect(profileUri.host, 'profile');
        expect(feedUri.host, 'feed');
      });
    });
  });

  group('DeepLinkService - Usage scenarios', () {
    group('Compartir chisme', () {
      test('usuario genera link y lo comparte', () {
        // Usuario 1 genera link
        const gossipId = 'chisme-viral-123';
        final link = DeepLinkService.generateGossipLink(gossipId);

        // Link se comparte (WhatsApp, Telegram, etc.)
        expect(link, isNotEmpty);
        expect(link, startsWith('chismes://'));

        // Usuario 2 lo parsea
        final uri = Uri.parse(link);
        expect(uri.scheme, 'chismes');
        expect(uri.host, 'gossip');
        expect(uri.pathSegments[0], gossipId);
      });
    });

    group('Compartir perfil', () {
      test('usuario genera link de perfil', () {
        const userId = 'usuario-123';
        final link = DeepLinkService.generateProfileLink(userId);

        expect(link, isNotEmpty);

        final uri = Uri.parse(link);
        expect(uri.scheme, 'chismes');
        expect(uri.host, 'profile');
        expect(uri.pathSegments[0], userId);
      });
    });

    group('Compartir feed filtrado', () {
      test('usuario comparte feed de su ciudad', () {
        const cityId = 'medellin';
        final link = DeepLinkService.generateFeedLink(cityId: cityId);

        expect(link, contains('city='));

        final uri = Uri.parse(link);
        expect(uri.queryParameters['city'], cityId);
      });
    });

    group('Notificaciones push', () {
      test('notificación de nuevo chisme usa deep link', () {
        // Backend genera link para notificación
        const gossipId = 'nuevo-chisme-789';
        final link = DeepLinkService.generateGossipLink(gossipId);

        // App recibe notificación con el link
        // Usuario toca notificación
        // App parsea el link
        final uri = Uri.parse(link);
        final extractedId = uri.pathSegments[0];

        expect(extractedId, gossipId);
      });
    });

    group('Links internos', () {
      test('navegación interna usando deep links', () {
        // Desde cualquier pantalla, navegar a chisme específico
        const targetGossipId = 'target-123';
        final link = DeepLinkService.generateGossipLink(targetGossipId);

        // App procesa link internamente
        final uri = Uri.parse(link);
        expect(uri.pathSegments[0], targetGossipId);
      });
    });
  });

  group('DeepLinkService - Constructor', () {
    testWidgets('debe crear instancia con navigatorKey y logger', (tester) async {
      // Arrange
      final navigatorKey = GlobalKey<NavigatorState>();
      final mockLogger = MockAppLogger();

      // Act
      final service = DeepLinkService(navigatorKey, mockLogger);

      // Assert
      expect(service, isNotNull);
      expect(service, isA<DeepLinkService>());
    });
  });

  group('DeepLinkService - Integration scenarios', () {
    test('flujo completo: generar → compartir → parsear', () {
      // 1. Generar link
      const gossipId = 'test-gossip-123';
      final link = DeepLinkService.generateGossipLink(gossipId);

      // 2. Compartir (simular)
      expect(link, isNotEmpty);

      // 3. Parsear (receptor)
      final uri = Uri.parse(link);

      // 4. Validar
      expect(uri.scheme, 'chismes');
      expect(uri.host, 'gossip');
      expect(uri.pathSegments.isNotEmpty, isTrue);

      // 5. Extraer ID
      final extractedId = uri.pathSegments[0];
      expect(extractedId, gossipId);
    });

    test('múltiples links generados son parseables', () {
      final links = [
        DeepLinkService.generateGossipLink('id1'),
        DeepLinkService.generateProfileLink('id2'),
        DeepLinkService.generateFeedLink(cityId: 'city1'),
        DeepLinkService.generateFeedLink(),
      ];

      for (final link in links) {
        final uri = Uri.parse(link);
        expect(uri.scheme, 'chismes');
        expect(uri.host, isNotEmpty);
      }
    });
  });

  group('DeepLinkService - Performance', () {
    test('generateGossipLink debe ser rápido', () {
      final stopwatch = Stopwatch()..start();

      for (var i = 0; i < 1000; i++) {
        DeepLinkService.generateGossipLink('id-$i');
      }

      stopwatch.stop();
      expect(stopwatch.elapsedMilliseconds, lessThan(100)); // <100ms para 1000 links
    });
  });

  // initialize() de punta a punta: canales de app_links simulados.
  group('DeepLinkService - manejo de links recibidos', () {
    const methodChannel = MethodChannel('com.llfbandit.app_links/messages');
    const eventChannel = EventChannel('com.llfbandit.app_links/events');

    late MockAppLogger logger;
    late GlobalKey<NavigatorState> navigatorKey;
    late DeepLinkService service;
    MockStreamHandlerEventSink? sink;
    late Object? Function() initialLink;

    setUp(() {
      logger = MockAppLogger();
      navigatorKey = GlobalKey<NavigatorState>();
      service = DeepLinkService(navigatorKey, logger);
      sink = null;
      initialLink = () => null;
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(methodChannel, (call) async {
        if (call.method == 'getInitialLink') return initialLink();
        return null;
      });
      messenger.setMockStreamHandler(
        eventChannel,
        MockStreamHandler.inline(onListen: (_, events) {
          sink = events;
        }),
      );
      addTearDown(() {
        service.dispose();
        messenger.setMockMethodCallHandler(methodChannel, null);
        messenger.setMockStreamHandler(eventChannel, null);
      });
    });

    Future<void> pumpApp(WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        navigatorKey: navigatorKey,
        locale: const Locale('es'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: Text('HOME')),
      ));
    }

    AppLocalizations l10n(WidgetTester tester) =>
        AppLocalizations.of(tester.element(find.text('HOME')))!;

    // Los eventos de plataforma se entregan en el event loop real.
    Future<void> receive(WidgetTester tester, String link) async {
      await tester.runAsync(() async {
        sink!.success(link);
        await pumpEventQueue();
      });
      await tester.pump();
    }

    testWidgets('link de chisme generado por la app muestra el snackbar',
        (tester) async {
      await pumpApp(tester);
      await service.initialize();

      await receive(tester, DeepLinkService.generateGossipLink('abc123'));

      expect(find.text(l10n(tester).deepLinkOpeningGossip('abc123')),
          findsOneWidget);
      verify(logger.i('Navigating to gossip', context: {'gossipId': 'abc123'}))
          .called(1);
      verifyNever(logger.w(any, context: anyNamed('context')));
    });

    testWidgets('acepta también el formato sin host (chismes:///gossip/id)',
        (tester) async {
      await pumpApp(tester);
      await service.initialize();

      await receive(tester, 'chismes:///gossip/xyz');

      expect(find.text(l10n(tester).deepLinkOpeningGossip('xyz')),
          findsOneWidget);
    });

    testWidgets('link de perfil generado por la app muestra el snackbar',
        (tester) async {
      await pumpApp(tester);
      await service.initialize();

      await receive(tester, DeepLinkService.generateProfileLink('user-9'));

      expect(find.text(l10n(tester).deepLinkOpeningProfile('user-9')),
          findsOneWidget);
      verify(logger.i('Navigating to profile', context: {'userId': 'user-9'}))
          .called(1);
    });

    testWidgets('link de feed con ciudad muestra el snackbar de la ciudad',
        (tester) async {
      await pumpApp(tester);
      await service.initialize();

      await receive(tester, DeepLinkService.generateFeedLink(cityId: 'medellin'));

      expect(find.text(l10n(tester).deepLinkOpeningCityFeed('medellin')),
          findsOneWidget);
    });

    testWidgets('link de feed sin ciudad vuelve a la primera ruta',
        (tester) async {
      await pumpApp(tester);
      await service.initialize();
      navigatorKey.currentState!.push(MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('DETALLE'))));
      await tester.pumpAndSettle();
      expect(find.text('DETALLE'), findsOneWidget);

      await receive(tester, DeepLinkService.generateFeedLink());
      await tester.pumpAndSettle();

      expect(find.text('DETALLE'), findsNothing);
      expect(find.text('HOME'), findsOneWidget);
      verify(logger.i('Navigating to general feed')).called(1);
    });

    testWidgets('link de auth lo deja a Supabase sin snackbar', (tester) async {
      await pumpApp(tester);
      await service.initialize();

      await receive(tester, 'chismes://auth/callback');

      expect(find.byType(SnackBar), findsNothing);
      verify(logger.i('Auth deep link (handled by Supabase)',
              context: {'uri': 'chismes://auth/callback'}))
          .called(1);
      verifyNever(logger.w(any, context: anyNamed('context')));
    });

    testWidgets('ignora links inválidos sin snackbar y loguea el motivo',
        (tester) async {
      await pumpApp(tester);
      await service.initialize();

      await receive(tester, 'https://chismes.app/gossip/1');
      await receive(tester, 'chismes://gossip');
      await receive(tester, 'chismes://profile');
      await receive(tester, 'chismes://otro/1');
      await receive(tester, 'chismes:');

      expect(find.byType(SnackBar), findsNothing);
      final warnings =
          verify(logger.w(captureAny, context: captureAnyNamed('context')))
              .captured;
      expect(warnings, [
        'Unsupported scheme', {'scheme': 'https'},
        'Gossip deep link without ID', {'uri': 'chismes://gossip'},
        'Profile deep link without ID', {'uri': 'chismes://profile'},
        'Unsupported deep link type', {'type': 'otro'},
        'Deep link without path', {'uri': 'chismes:'},
      ]);
    });

    testWidgets('sin navigator montado no muestra nada ni falla',
        (tester) async {
      await service.initialize();

      await receive(tester, DeepLinkService.generateGossipLink('a'));
      await receive(tester, DeepLinkService.generateProfileLink('b'));
      await receive(tester, DeepLinkService.generateFeedLink(cityId: 'c'));

      expect(find.byType(SnackBar), findsNothing);
      verify(logger.i('Navigating to gossip', context: {'gossipId': 'a'}))
          .called(1);
      verify(logger.i('Navigating to profile', context: {'userId': 'b'}))
          .called(1);
      verify(logger.i('Navigating to filtered feed', context: {'cityId': 'c'}))
          .called(1);
    });

    testWidgets('link inicial (app cerrada) se maneja tras 500ms',
        (tester) async {
      initialLink = () => 'chismes://gossip/inicial';
      await pumpApp(tester);
      final text = l10n(tester).deepLinkOpeningGossip('inicial');

      final init = service.initialize();
      await tester.pump(const Duration(milliseconds: 499));
      expect(find.text(text), findsNothing);
      await tester.pump(const Duration(milliseconds: 1));
      await init;
      await tester.pump();

      expect(find.text(text), findsOneWidget);
      verify(logger.i('Initial deep link (app closed)',
              context: {'uri': 'chismes://gossip/inicial'}))
          .called(1);
    });

    testWidgets('loguea error si falla obtener el link inicial',
        (tester) async {
      initialLink = () => throw PlatformException(code: 'BOOM');

      await service.initialize();

      verify(logger.e('Error getting initial deep link',
              error: argThat(isA<PlatformException>(), named: 'error')))
          .called(1);
    });

    testWidgets('loguea error si el stream de links falla', (tester) async {
      await service.initialize();

      await tester.runAsync(() async {
        sink!.error(code: 'STREAM', message: 'roto');
        await pumpEventQueue();
      });
      await tester.pump();

      verify(logger.e('Error receiving deep link',
              error: argThat(isA<PlatformException>(), named: 'error')))
          .called(1);
    });

    testWidgets('dispose deja de escuchar links', (tester) async {
      await pumpApp(tester);
      await service.initialize();
      final activeSink = sink!;

      service.dispose();
      await tester.runAsync(() async {
        activeSink.success(DeepLinkService.generateGossipLink('tarde'));
        await pumpEventQueue();
      });
      await tester.pump();

      expect(find.byType(SnackBar), findsNothing);
      verifyNever(logger.i('Deep link received (app open)',
          context: anyNamed('context')));
    });
  });
}
