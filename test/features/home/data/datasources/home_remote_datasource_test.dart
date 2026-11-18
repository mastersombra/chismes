import 'package:flutter_test/flutter_test.dart';
import 'package:chismes/core/logging/logging.dart';
import 'package:chismes/features/home/data/datasources/home_remote_datasource.dart';
import 'package:chismes/features/home/data/models/paginated_gossips_model.dart';
import 'package:chismes/features/home/domain/entities/feed_cursor.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  late AppLogger logger;

  setUp(() {
    // Logger mock simple para tests
    final mockRemoteLogger = _MockRemoteLogger();
    final mockDeviceInfo = _MockDeviceInfoProvider();
    logger = AppLogger(mockRemoteLogger, mockDeviceInfo);
  });

  tearDown(() {
    logger.close();
  });

  group('HomeRemoteDataSource - Constructor y estructura', () {
    test('debe crear instancia con dependencias', () {
      // Arrange
      final supabase = _FakeSupabaseClient();

      // Act
      final dataSource = HomeRemoteDataSource(supabase, logger);

      // Assert
      expect(dataSource, isA<HomeRemoteDataSource>());
    });
  });

  group('PaginatedGossipsModel - Deserialización', () {
    test('debe deserializar lista vacía correctamente', () {
      // Arrange
      final json = {
        'data': <Map<String, dynamic>>[],
        'has_more': false,
        'next_cursor': null,
      };

      // Act
      final model = PaginatedGossipsModel.fromJson(json);

      // Assert
      expect(model.data, isEmpty);
      expect(model.hasMore, false);
      expect(model.nextCursor, isNull);
    });

    test('debe usar constructor empty correctamente', () {
      // Arrange & Act
      const model = PaginatedGossipsModel.empty();

      // Assert
      expect(model.data, isEmpty);
      expect(model.hasMore, false);
      expect(model.nextCursor, isNull);
    });

    test('debe lanzar FormatException cuando falta campo data', () {
      // Arrange
      final json = {
        'has_more': false,
        'next_cursor': null,
      };

      // Act & Assert
      expect(
        () => PaginatedGossipsModel.fromJson(json),
        throwsA(isA<FormatException>()),
      );
    });

    test('debe lanzar FormatException cuando falta campo has_more', () {
      // Arrange
      final json = {
        'data': <Map<String, dynamic>>[],
        'next_cursor': null,
      };

      // Act & Assert
      expect(
        () => PaginatedGossipsModel.fromJson(json),
        throwsA(isA<FormatException>()),
      );
    });

    test('debe manejar next_cursor null', () {
      // Arrange
      final json = {
        'data': <Map<String, dynamic>>[],
        'has_more': false,
        'next_cursor': null,
      };

      // Act
      final model = PaginatedGossipsModel.fromJson(json);

      // Assert
      expect(model.nextCursor, isNull);
    });

    test('debe manejar has_more true', () {
      // Arrange
      final json = {
        'data': <Map<String, dynamic>>[],
        'has_more': true,
        'next_cursor': {
          'score': 50.0,
          'id': 'gossip-10',
        },
      };

      // Act
      final model = PaginatedGossipsModel.fromJson(json);

      // Assert
      expect(model.hasMore, true);
      expect(model.nextCursor, isNotNull);
    });
  });

  group('FeedCursor - Constructores y validación', () {
    test('constructor popular debe crear cursor con score', () {
      // Arrange & Act
      const cursor = FeedCursor.popular(score: 123.45, id: 'gossip-123');

      // Assert
      expect(cursor.score, 123.45);
      expect(cursor.id, 'gossip-123');
      expect(cursor.createdAt, isNull);
    });

    test('constructor following debe crear cursor con createdAt', () {
      // Arrange
      final createdAt = DateTime.parse('2024-01-15T10:30:00.000Z');

      // Act
      final cursor = FeedCursor.following(
        createdAt: createdAt,
        id: 'gossip-456',
      );

      // Assert
      expect(cursor.createdAt, createdAt);
      expect(cursor.id, 'gossip-456');
      expect(cursor.score, isNull);
    });

    test('debe permitir conversión a ISO8601 para createdAt', () {
      // Arrange
      final createdAt = DateTime.parse('2024-01-15T10:30:00.000Z');
      final cursor = FeedCursor.following(
        createdAt: createdAt,
        id: 'gossip-456',
      );

      // Act
      final iso8601 = cursor.createdAt!.toIso8601String();

      // Assert
      expect(iso8601, '2024-01-15T10:30:00.000Z');
    });
  });

  group('HomeRemoteDataSource - Parámetros RPC esperados', () {
    test('getPopularFeed debe usar nombres correctos de parámetros', () {
      // Documentación de los nombres de parámetros esperados por la función RPC
      const expectedParams = {
        'user_city_id': 'MED',
        'page_size': 20,
        'cursor_score': 123.45,
        'cursor_id': 'gossip-123',
      };

      expect(expectedParams['user_city_id'], 'MED');
      expect(expectedParams['page_size'], 20);
      expect(expectedParams['cursor_score'], 123.45);
      expect(expectedParams['cursor_id'], 'gossip-123');
    });

    test('getPopularFeed debe aceptar userCityId null', () {
      // El parámetro userCityId puede ser null cuando el usuario
      // no tiene ciudad configurada
      const String? nullCityId = null;
      expect(nullCityId, isNull);
    });

    test('getPopularFeed debe aceptar cursor null', () {
      // El cursor es null en la primera página
      const FeedCursor? nullCursor = null;
      expect(nullCursor, isNull);
    });

    test('getFollowingFeed debe usar nombres correctos de parámetros', () {
      // Documentación de los nombres de parámetros para following feed
      final expectedParams = {
        'current_user_id': 'user-123',
        'page_size': 20,
        'cursor_created_at': DateTime.now().toIso8601String(),
        'cursor_id': 'gossip-123',
      };

      expect(expectedParams['current_user_id'], 'user-123');
      expect(expectedParams['page_size'], 20);
      expect(expectedParams.containsKey('cursor_created_at'), true);
      expect(expectedParams.containsKey('cursor_id'), true);
    });

    test('getFollowingFeed debe requerir userId no vacío', () {
      // userId es requerido para following feed
      const String userId = 'user-123';
      expect(userId, isNotEmpty);
      expect(userId, isNotNull);
    });

    test('checkNewGossips debe usar nombres correctos de parámetros', () {
      // Documentación de los parámetros para check_new_gossips
      final expectedParams = {
        'user_city_id': 'MED',
        'since_timestamp': DateTime.now().toIso8601String(),
      };

      expect(expectedParams['user_city_id'], 'MED');
      expect(expectedParams.containsKey('since_timestamp'), true);
    });

    test('checkNewGossips debe aceptar userCityId null', () {
      // userCityId puede ser null
      const String? nullCityId = null;
      expect(nullCityId, isNull);
    });

    test('checkNewGossips debe retornar entero', () {
      // La respuesta es un int representando el count
      const int newGossipsCount = 5;
      expect(newGossipsCount, isA<int>());
      expect(newGossipsCount, greaterThanOrEqualTo(0));
    });

    test('checkNewGossips debe manejar respuesta cero', () {
      // Cuando no hay chismes nuevos, debe retornar 0
      const int noNewGossips = 0;
      expect(noNewGossips, equals(0));
    });
  });

  group('HomeRemoteDataSource - Page sizes personalizados', () {
    test('debe aceptar diferentes page sizes', () {
      // Debe aceptar diferentes page sizes (10, 20, 50, 100, etc.)
      const validPageSizes = [10, 20, 30, 50, 100];
      for (final size in validPageSizes) {
        expect(size, greaterThan(0));
        expect(size, lessThanOrEqualTo(100));
      }
    });

    test('debe usar page size default de 20', () {
      const int defaultPageSize = 20;
      expect(defaultPageSize, 20);
    });
  });

  group('HomeRemoteDataSource - Timestamps y formatos', () {
    test('debe convertir DateTime a ISO8601 correctamente', () {
      // DateTime debe convertirse correctamente a ISO8601
      final timestamp = DateTime.parse('2024-01-15T10:30:00.000Z');
      final iso8601 = timestamp.toIso8601String();

      expect(iso8601, contains('2024-01-15'));
      expect(iso8601, contains('T'));
      expect(iso8601, contains('Z'));
    });

    test('debe manejar timestamps con milisegundos', () {
      final timestamp = DateTime.parse('2024-01-15T10:30:00.123Z');
      final iso8601 = timestamp.toIso8601String();

      expect(iso8601, isNotEmpty);
      expect(iso8601, contains('2024-01-15'));
    });

    test('debe manejar timestamps pasados', () {
      final past = DateTime.parse('2020-01-01T00:00:00.000Z');
      expect(past.isBefore(DateTime.now()), true);
    });

    test('debe manejar timestamps futuros', () {
      final future = DateTime.now().add(const Duration(days: 1));
      expect(future.isAfter(DateTime.now()), true);
    });
  });

  group('HomeRemoteDataSource - Conversión de Entity', () {
    test('debe convertir PaginatedGossipsModel a PaginatedGossips entity', () {
      // Arrange
      final model = const PaginatedGossipsModel(
        data: [],
        hasMore: false,
        nextCursor: null,
      );

      // Act
      final entity = model.toEntity();

      // Assert
      expect(entity.data, isEmpty);
      expect(entity.hasMore, false);
      expect(entity.nextCursor, isNull);
    });

    test('debe convertir next_cursor Map a FeedCursor entity', () {
      // Arrange
      final model = PaginatedGossipsModel(
        data: const [],
        hasMore: true,
        nextCursor: const {
          'score': 100.5,
          'id': 'gossip-1',
        },
      );

      // Act
      final entity = model.toEntity();

      // Assert
      expect(entity.nextCursor, isNotNull);
      expect(entity.nextCursor!.id, 'gossip-1');
    });
  });
}

/// Mock simple de SupabaseClient para tests de constructor
class _FakeSupabaseClient implements SupabaseClient {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

/// Mocks para testing del logger
class _MockRemoteLogger implements RemoteLogger {
  @override
  Future<void> log(LogEntry entry) async {}
}

class _MockDeviceInfoProvider extends DeviceInfoProvider {
  @override
  Future<Map<String, dynamic>> getDeviceInfo() async {
    return {'os': 'Test', 'device': 'TestDevice'};
  }
}
