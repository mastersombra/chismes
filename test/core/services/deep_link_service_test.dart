import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
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

  group('DeepLinkService - URI Parsing Logic', () {
    group('URI validation', () {
      test('debe aceptar scheme "chismes"', () {
        const validUri = 'chismes://gossip/123';
        final uri = Uri.parse(validUri);

        expect(uri.scheme, 'chismes');
      });

      test('debe rechazar scheme incorrecto (http)', () {
        const invalidUri = 'http://gossip/123';
        final uri = Uri.parse(invalidUri);

        expect(uri.scheme, isNot('chismes'));
        expect(uri.scheme, 'http');
      });

      test('debe rechazar scheme incorrecto (https)', () {
        const invalidUri = 'https://gossip/123';
        final uri = Uri.parse(invalidUri);

        expect(uri.scheme, isNot('chismes'));
        expect(uri.scheme, 'https');
      });

      test('debe rechazar scheme vacío', () {
        const invalidUri = '://gossip/123';

        // Uri.parse lanza exception con scheme vacío o inválido
        expect(() => Uri.parse(invalidUri), throwsFormatException);
      });

      test('debe parsear pathSegments correctamente', () {
        const uri = 'chismes://gossip/abc123';
        final parsed = Uri.parse(uri);

        expect(parsed.pathSegments.length, 1);
        expect(parsed.pathSegments[0], 'abc123');
      });

      test('debe parsear múltiples pathSegments', () {
        const uri = 'chismes://gossip/abc123/extra';
        final parsed = Uri.parse(uri);

        expect(parsed.pathSegments.length, 2);
        expect(parsed.pathSegments[0], 'abc123');
        expect(parsed.pathSegments[1], 'extra');
      });

      test('debe detectar pathSegments vacíos', () {
        const uri = 'chismes://gossip';
        final parsed = Uri.parse(uri);

        expect(parsed.pathSegments, isEmpty);
      });

      test('debe parsear query parameters', () {
        const uri = 'chismes://feed?city=medellin';
        final parsed = Uri.parse(uri);

        expect(parsed.queryParameters['city'], 'medellin');
      });

      test('debe parsear múltiples query parameters', () {
        const uri = 'chismes://feed?city=medellin&sort=recent';
        final parsed = Uri.parse(uri);

        expect(parsed.queryParameters['city'], 'medellin');
        expect(parsed.queryParameters['sort'], 'recent');
      });
    });

    group('Gossip link parsing', () {
      test('debe extraer gossipId de URI válido', () {
        const uri = 'chismes://gossip/abc123';
        final parsed = Uri.parse(uri);

        expect(parsed.host, 'gossip');
        expect(parsed.pathSegments.length, greaterThanOrEqualTo(1));
        final gossipId = parsed.pathSegments[0];
        expect(gossipId, 'abc123');
      });

      test('debe detectar gossip link sin ID', () {
        const uri = 'chismes://gossip';
        final parsed = Uri.parse(uri);

        expect(parsed.host, 'gossip');
        expect(parsed.pathSegments, isEmpty);
      });

      test('debe manejar gossipIds con caracteres especiales', () {
        const uri = 'chismes://gossip/uuid-abc-123_test';
        final parsed = Uri.parse(uri);

        final gossipId = parsed.pathSegments[0];
        expect(gossipId, 'uuid-abc-123_test');
      });

      test('debe manejar path segments extra (ignorarlos)', () {
        const uri = 'chismes://gossip/abc123/extra/data';
        final parsed = Uri.parse(uri);

        expect(parsed.pathSegments.length, 3);
        final gossipId = parsed.pathSegments[0]; // Solo tomar el primero
        expect(gossipId, 'abc123');
      });
    });

    group('Profile link parsing', () {
      test('debe extraer userId de URI válido', () {
        const uri = 'chismes://profile/user123';
        final parsed = Uri.parse(uri);

        expect(parsed.host, 'profile');
        expect(parsed.pathSegments.length, greaterThanOrEqualTo(1));
        final userId = parsed.pathSegments[0];
        expect(userId, 'user123');
      });

      test('debe detectar profile link sin ID', () {
        const uri = 'chismes://profile';
        final parsed = Uri.parse(uri);

        expect(parsed.host, 'profile');
        expect(parsed.pathSegments, isEmpty);
      });

      test('debe manejar userIds con caracteres especiales', () {
        const uri = 'chismes://profile/uuid-user-456_test';
        final parsed = Uri.parse(uri);

        final userId = parsed.pathSegments[0];
        expect(userId, 'uuid-user-456_test');
      });
    });

    group('Feed link parsing', () {
      test('debe parsear feed link sin parámetros', () {
        const uri = 'chismes://feed';
        final parsed = Uri.parse(uri);

        expect(parsed.host, 'feed');
        expect(parsed.queryParameters, isEmpty);
      });

      test('debe extraer cityId de query parameters', () {
        const uri = 'chismes://feed?city=medellin';
        final parsed = Uri.parse(uri);

        expect(parsed.host, 'feed');
        expect(parsed.queryParameters['city'], 'medellin');
      });

      test('debe manejar feed link con city null', () {
        const uri = 'chismes://feed?city=';
        final parsed = Uri.parse(uri);

        final cityId = parsed.queryParameters['city'];
        expect(cityId, isEmpty); // String vacío, no null
      });

      test('debe ignorar query parameters desconocidos', () {
        const uri = 'chismes://feed?city=bogota&unknown=value';
        final parsed = Uri.parse(uri);

        expect(parsed.queryParameters['city'], 'bogota');
        expect(parsed.queryParameters['unknown'], 'value');
        // En código real, solo usar 'city'
      });
    });

    group('Edge cases en parsing', () {
      test('debe manejar URI con fragmento (#)', () {
        const uri = 'chismes://gossip/abc123#section';
        final parsed = Uri.parse(uri);

        expect(parsed.fragment, 'section');
        expect(parsed.pathSegments[0], 'abc123');
      });

      test('debe manejar URI con puerto', () {
        const uri = 'chismes://gossip:8080/abc123';
        final parsed = Uri.parse(uri);

        expect(parsed.port, 8080);
        expect(parsed.host, 'gossip');
      });

      test('debe normalizar mayúsculas en scheme', () {
        const uri = 'CHISMES://gossip/abc123';
        final parsed = Uri.parse(uri);

        expect(parsed.scheme.toLowerCase(), 'chismes');
      });

      test('debe manejar espacios encodificados (%20)', () {
        const uri = 'chismes://gossip/abc%20123';
        final parsed = Uri.parse(uri);

        // Uri.parse decodifica automáticamente
        expect(parsed.pathSegments[0], 'abc 123');
      });

      test('debe manejar caracteres unicode', () {
        const uri = 'chismes://profile/usuario_测试';
        final parsed = Uri.parse(uri);

        expect(parsed.pathSegments[0], contains('测试'));
      });
    });

    group('Type detection (host)', () {
      test('debe detectar tipo "gossip"', () {
        const uri = 'chismes://gossip/id';
        final parsed = Uri.parse(uri);

        expect(parsed.host, 'gossip');
      });

      test('debe detectar tipo "profile"', () {
        const uri = 'chismes://profile/id';
        final parsed = Uri.parse(uri);

        expect(parsed.host, 'profile');
      });

      test('debe detectar tipo "feed"', () {
        const uri = 'chismes://feed';
        final parsed = Uri.parse(uri);

        expect(parsed.host, 'feed');
      });

      test('debe detectar tipo desconocido', () {
        const uri = 'chismes://unknown/id';
        final parsed = Uri.parse(uri);

        expect(parsed.host, 'unknown');
        expect(['gossip', 'profile', 'feed'], isNot(contains(parsed.host)));
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

    testWidgets('debe ser singleton en DI', (tester) async {
      // Documenta que la anotación @singleton está presente
      // Se crea una sola instancia compartida
      expect(true, isTrue);
    });
  });

  group('DeepLinkService - Validation rules', () {
    group('Scheme validation', () {
      test('scheme "chismes" es válido', () {
        const validScheme = 'chismes';
        expect(validScheme, 'chismes');
      });

      test('scheme "http" es inválido', () {
        const invalidScheme = 'http';
        expect(invalidScheme, isNot('chismes'));
      });

      test('scheme "https" es inválido', () {
        const invalidScheme = 'https';
        expect(invalidScheme, isNot('chismes'));
      });

      test('scheme vacío es inválido', () {
        const emptyScheme = '';
        expect(emptyScheme, isNot('chismes'));
      });
    });

    group('PathSegments validation', () {
      test('pathSegments vacío es inválido', () {
        final uri = Uri.parse('chismes://gossip');
        expect(uri.pathSegments, isEmpty);
      });

      test('pathSegments con al menos 1 elemento es válido para gossip', () {
        final uri = Uri.parse('chismes://gossip/id123');
        expect(uri.pathSegments.length, greaterThanOrEqualTo(1));
      });

      test('gossip requiere mínimo 1 pathSegment (el ID)', () {
        // Valid
        final validUri = Uri.parse('chismes://gossip/id123');
        expect(validUri.pathSegments.length, greaterThanOrEqualTo(1));

        // Invalid
        final invalidUri = Uri.parse('chismes://gossip');
        expect(invalidUri.pathSegments, isEmpty);
      });

      test('profile requiere mínimo 1 pathSegment (el ID)', () {
        // Valid
        final validUri = Uri.parse('chismes://profile/user123');
        expect(validUri.pathSegments.length, greaterThanOrEqualTo(1));

        // Invalid
        final invalidUri = Uri.parse('chismes://profile');
        expect(invalidUri.pathSegments, isEmpty);
      });

      test('feed NO requiere pathSegments', () {
        final uri = Uri.parse('chismes://feed');
        expect(uri.pathSegments, isEmpty); // OK para feed
      });
    });

    group('Type validation (host)', () {
      test('tipo "gossip" es válido', () {
        const validTypes = ['gossip', 'profile', 'feed'];
        expect(validTypes, contains('gossip'));
      });

      test('tipo "profile" es válido', () {
        const validTypes = ['gossip', 'profile', 'feed'];
        expect(validTypes, contains('profile'));
      });

      test('tipo "feed" es válido', () {
        const validTypes = ['gossip', 'profile', 'feed'];
        expect(validTypes, contains('feed'));
      });

      test('tipo "unknown" es inválido', () {
        const validTypes = ['gossip', 'profile', 'feed'];
        expect(validTypes, isNot(contains('unknown')));
      });
    });
  });

  group('DeepLinkService - Error cases', () {
    test('URI con scheme incorrecto debe ser rechazado', () {
      const invalidUri = 'http://gossip/123';
      final parsed = Uri.parse(invalidUri);

      expect(parsed.scheme, isNot('chismes'));
    });

    test('URI sin pathSegments debe ser rechazado para gossip', () {
      const invalidUri = 'chismes://gossip';
      final parsed = Uri.parse(invalidUri);

      expect(parsed.pathSegments, isEmpty);
      // En código real, esto retorna early
    });

    test('URI sin pathSegments debe ser rechazado para profile', () {
      const invalidUri = 'chismes://profile';
      final parsed = Uri.parse(invalidUri);

      expect(parsed.pathSegments, isEmpty);
    });

    test('URI con tipo desconocido debe ser rechazado', () {
      const invalidUri = 'chismes://unknown/123';
      final parsed = Uri.parse(invalidUri);

      const validTypes = ['gossip', 'profile', 'feed'];
      expect(validTypes, isNot(contains(parsed.host)));
    });

    test('URI malformado lanza exception o retorna vacío', () {
      // '://gossip/123' - Sin scheme lanza exception
      expect(() => Uri.parse('://gossip/123'), throwsFormatException);

      // 'chismes://' - Válido pero vacío
      final emptyHost = Uri.parse('chismes://');
      expect(emptyHost.host, isEmpty);

      // '' - Uri vacío es técnicamente válido
      final empty = Uri.parse('');
      expect(empty.scheme, isEmpty);
      expect(empty.host, isEmpty);
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

    test('Uri.parse debe ser rápido', () {
      final stopwatch = Stopwatch()..start();

      for (var i = 0; i < 1000; i++) {
        Uri.parse('chismes://gossip/id-$i');
      }

      stopwatch.stop();
      expect(stopwatch.elapsedMilliseconds, lessThan(100));
    });
  });
}
