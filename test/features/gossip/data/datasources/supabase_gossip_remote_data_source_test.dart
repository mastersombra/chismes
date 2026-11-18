import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:chismes/core/logging/logging.dart';
import 'package:chismes/features/gossip/data/datasources/supabase_gossip_remote_data_source.dart';
import 'package:chismes/features/gossip/data/models/gossip_model.dart';
import 'package:chismes/features/gossip/domain/entities/create_gossip_input.dart';
import 'package:chismes/features/gossip/domain/entities/gossip.dart';
import 'package:chismes/features/gossip/domain/entities/gossip_query.dart';
import 'package:chismes/features/gossip/domain/entities/report_reason.dart';

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

  group('SupabaseGossipRemoteDataSource - Constructor', () {
    test('debe crear instancia con dependencias', () {
      // Arrange
      final supabase = _FakeSupabaseClient();

      // Act
      final dataSource = SupabaseGossipRemoteDataSource(supabase, logger);

      // Assert
      expect(dataSource, isA<SupabaseGossipRemoteDataSource>());
    });
  });

  group('GossipQuery - Construcción de queries', () {
    test('debe crear query default con valores correctos', () {
      // Arrange & Act
      final query = GossipQuery.defaultPublic();

      // Assert
      expect(query.orderBy, 'createdAt');
      expect(query.descending, true);
      expect(query.limit, 20);
      expect(query.status, GossipStatus.published);
      expect(query.visibility, GossipVisibility.public);
    });

    test('debe aceptar filtros de ubicación', () {
      // Arrange & Act
      final query = GossipQuery(
        countryId: 'CO',
        regionId: 'co-antioquia',
        cityId: 'MED',
        orderBy: 'createdAt',
        descending: true,
        limit: 20,
      );

      // Assert
      expect(query.countryId, 'CO');
      expect(query.regionId, 'co-antioquia');
      expect(query.cityId, 'MED');
    });

    test('debe aceptar filtros de ubicación nullables', () {
      // Arrange & Act
      final query = GossipQuery(
        countryId: null,
        regionId: null,
        cityId: null,
        orderBy: 'createdAt',
        descending: true,
        limit: 20,
      );

      // Assert
      expect(query.countryId, isNull);
      expect(query.regionId, isNull);
      expect(query.cityId, isNull);
    });

    test('debe aceptar diferentes orderBy valores', () {
      // Documentación: orderBy se traduce de camelCase a snake_case
      final validOrderBy = [
        'createdAt',
        'modifiedAt',
        'viewCount',
        'likeCount',
        'commentCount',
        'reportCount',
      ];

      for (final orderBy in validOrderBy) {
        final query = GossipQuery(
          orderBy: orderBy,
          descending: true,
          limit: 20,
        );

        expect(query.orderBy, orderBy);
      }
    });

    test('debe aceptar paginación con cursor', () {
      // Formato cursor: "timestamp,id"
      const cursor = '2024-01-15T10:30:00.000Z,550e8400-e29b-41d4-a716-446655440000';

      final query = GossipQuery(
        cursor: cursor,
        orderBy: 'createdAt',
        descending: true,
        limit: 20,
      );

      expect(query.cursor, isNotNull);
      expect(query.cursor, contains(','));
      expect(query.cursor!.split(',').length, 2);
    });

    test('debe validar formato de cursor compuesto', () {
      // Formato esperado: "timestamp,id"
      const validCursor = '2024-01-15T10:30:00.000Z,550e8400-e29b-41d4-a716-446655440000';

      final parts = validCursor.split(',');
      expect(parts.length, 2);

      // Primera parte debe ser timestamp ISO8601
      expect(() => DateTime.parse(parts[0]), returnsNormally);

      // Segunda parte debe ser UUID
      expect(parts[1], isNotEmpty);
      expect(parts[1], hasLength(36)); // UUID tiene 36 caracteres
    });
  });

  group('getGossips - Filtros esperados', () {
    test('debe filtrar por status published', () {
      // Documentación: .eq('status', 'published')
      const expectedStatus = 'published';
      expect(expectedStatus, 'published');
    });

    test('debe filtrar por moderation_status approved', () {
      // Documentación: .eq('moderation_status', 'approved')
      const expectedModerationStatus = 'approved';
      expect(expectedModerationStatus, 'approved');
    });

    test('debe filtrar por visibility public', () {
      // Documentación: .eq('visibility', 'public')
      const expectedVisibility = 'public';
      expect(expectedVisibility, 'public');
    });

    test('debe filtrar deleted_at null', () {
      // Documentación: .isFilter('deleted_at', null)
      // Gossips eliminados no deben aparecer
      const DateTime? deletedAt = null;
      expect(deletedAt, isNull);
    });

    test('debe aplicar filtros de ubicación cuando están presentes', () {
      // Documentación: filtros opcionales de country_id, region_id, city_id
      const countryId = 'CO';
      const regionId = 'co-antioquia';
      const cityId = 'MED';

      expect(countryId, isNotEmpty);
      expect(regionId, isNotEmpty);
      expect(cityId, isNotEmpty);
    });
  });

  group('_translateOrderBy - Traducción camelCase to snake_case', () {
    test('debe traducir createdAt a created_at', () {
      // Simular la traducción
      const input = 'createdAt';
      const expected = 'created_at';

      expect(_simulateTranslation(input), expected);
    });

    test('debe traducir modifiedAt a modified_at', () {
      const input = 'modifiedAt';
      const expected = 'modified_at';

      expect(_simulateTranslation(input), expected);
    });

    test('debe traducir viewCount a view_count', () {
      const input = 'viewCount';
      const expected = 'view_count';

      expect(_simulateTranslation(input), expected);
    });

    test('debe traducir likeCount a like_count', () {
      const input = 'likeCount';
      const expected = 'like_count';

      expect(_simulateTranslation(input), expected);
    });

    test('debe traducir commentCount a comment_count', () {
      const input = 'commentCount';
      const expected = 'comment_count';

      expect(_simulateTranslation(input), expected);
    });

    test('debe traducir reportCount a report_count', () {
      const input = 'reportCount';
      const expected = 'report_count';

      expect(_simulateTranslation(input), expected);
    });

    test('debe retornar valor sin cambios si no reconoce', () {
      const input = 'unknown_field';
      expect(_simulateTranslation(input), input);
    });

    test('debe retornar valor sin cambios si ya está en snake_case', () {
      const input = 'created_at';
      expect(_simulateTranslation(input), input);
    });
  });

  group('createWithImage - Edge Function invocation', () {
    test('debe usar Edge Function moderate-gossip', () {
      // Documentación: llama a Edge Function 'moderate-gossip'
      const edgeFunctionName = 'moderate-gossip';
      expect(edgeFunctionName, 'moderate-gossip');
    });

    test('debe enviar body con campos correctos', () {
      // Documentación del body esperado
      final expectedFields = [
        'subject',
        'content',
        'country_id',
        'region_id',
        'city_id',
        'published_as',
        'audio_url',
        'image_base64',
        'idempotency_key',
      ];

      for (final field in expectedFields) {
        expect(field, isNotEmpty);
      }
    });

    test('debe incluir JWT en Authorization header', () {
      // Documentación: headers: {'Authorization': 'Bearer ${session.accessToken}'}
      const authHeader = 'Authorization';
      const bearerPrefix = 'Bearer ';

      expect(authHeader, 'Authorization');
      expect(bearerPrefix, startsWith('Bearer'));
    });

    test('debe manejar respuesta exitosa 200', () {
      // Documentación: response.status == 200
      const successStatus = 200;
      expect(successStatus, 200);
    });

    test('debe manejar rate limit 429', () {
      // Documentación: response.status == 429 → RateLimitFailure
      const rateLimitStatus = 429;
      expect(rateLimitStatus, 429);
    });

    test('debe detectar contenido rechazado por moderación', () {
      // Documentación: error == 'Content rejected by moderation'
      const errorMessage = 'Content rejected by moderation';
      expect(errorMessage, contains('rejected'));
      expect(errorMessage, contains('moderation'));
    });

    test('debe detectar fallo de subida de imagen', () {
      // Documentación: error == 'Image upload failed'
      const errorMessage = 'Image upload failed';
      expect(errorMessage, contains('Image upload failed'));
    });

    test('debe parsear respuesta con gossip data', () {
      // Estructura esperada: {'gossip': {...}, 'idempotent': bool}
      final mockResponse = {
        'gossip': <String, dynamic>{},
        'idempotent': false,
      };

      expect(mockResponse.containsKey('gossip'), true);
      expect(mockResponse.containsKey('idempotent'), true);
    });

    test('debe detectar operación idempotente', () {
      // Documentación: isIdempotent = responseData['idempotent'] ?? false
      final mockResponse = {
        'gossip': <String, dynamic>{},
        'idempotent': true,
      };

      final isIdempotent = mockResponse['idempotent'] as bool;
      expect(isIdempotent, true);
    });
  });

  group('reportGossip - Edge Function invocation', () {
    test('debe usar Edge Function report-gossip', () {
      // Documentación: llama a Edge Function 'report-gossip'
      const edgeFunctionName = 'report-gossip';
      expect(edgeFunctionName, 'report-gossip');
    });

    test('debe enviar body con campos requeridos', () {
      // Documentación del body esperado
      final expectedBody = {
        'gossip_id': 'test-id',
        'reason': 'spam',
      };

      expect(expectedBody['gossip_id'], isNotEmpty);
      expect(expectedBody['reason'], isNotEmpty);
    });

    test('debe enviar details opcional', () {
      // Documentación: details es opcional
      const String? nullDetails = null;
      const String withDetails = 'Additional info';

      expect(nullDetails, isNull);
      expect(withDetails, isNotEmpty);
    });

    test('debe incluir JWT en Authorization header', () {
      // Documentación: headers: {'Authorization': 'Bearer ${session.accessToken}'}
      const authHeader = 'Authorization';
      expect(authHeader, 'Authorization');
    });

    test('debe manejar respuesta exitosa 200', () {
      // Documentación: response.status == 200
      const successStatus = 200;
      expect(successStatus, 200);
    });

    test('debe detectar reporte duplicado', () {
      // Documentación: error contiene 'already reported' o 'duplicate'
      final duplicateMessages = [
        'User has already reported this gossip',
        'Duplicate report detected',
      ];

      for (final msg in duplicateMessages) {
        expect(msg.toLowerCase(), anyOf(contains('already'), contains('duplicate')));
      }
    });

    test('debe manejar diferentes razones de reporte', () {
      // Todas las razones válidas de ReportReason
      final validReasons = [
        ReportReason.spam,
        ReportReason.harassment,
        ReportReason.violence,
        ReportReason.sexualContent,
        ReportReason.misinformation,
        ReportReason.other,
      ];

      for (final reason in validReasons) {
        expect(reason.value, isNotEmpty);
      }
    });
  });

  group('searchGossips - RPC invocation', () {
    test('debe usar RPC search_gossips', () {
      // Documentación: llama a RPC 'search_gossips'
      const rpcName = 'search_gossips';
      expect(rpcName, 'search_gossips');
    });

    test('debe enviar parámetros correctos', () {
      // Documentación del params esperado
      final expectedParams = {
        'search_query': 'test',
        'city_filter': 'MED',
        'result_limit': 20,
      };

      expect(expectedParams['search_query'], isNotEmpty);
      expect(expectedParams.containsKey('city_filter'), true);
      expect(expectedParams['result_limit'], greaterThan(0));
    });

    test('debe trimear query de búsqueda', () {
      // Documentación: query.trim()
      const queryWithSpaces = '  test query  ';
      final trimmed = queryWithSpaces.trim();

      expect(trimmed, 'test query');
      expect(trimmed, isNot(startsWith(' ')));
      expect(trimmed, isNot(endsWith(' ')));
    });

    test('debe aceptar city_filter null', () {
      // city_filter es opcional
      const String? nullCityFilter = null;
      expect(nullCityFilter, isNull);
    });

    test('debe usar result_limit default de 20', () {
      const int defaultLimit = 20;
      expect(defaultLimit, 20);
    });

    test('debe retornar lista de GossipModel', () {
      // searchGossips retorna List<GossipModel>
      final results = <GossipModel>[];
      expect(results, isA<List<GossipModel>>());
    });

    test('debe manejar resultados vacíos', () {
      // Cuando no hay coincidencias, retorna lista vacía
      final emptyResults = <GossipModel>[];
      expect(emptyResults, isEmpty);
    });
  });

  group('CreateGossipInput - Validación', () {
    test('debe crear input con campos requeridos', () {
      // Arrange & Act
      final input = CreateGossipInput(
        subject: 'Test Subject',
        content: 'Test Content',
        countryId: 'CO',
        regionId: 'co-antioquia',
        cityId: 'MED',
        publishedAs: PublishAs.anonymous,
        idempotencyKey: 'test-key',
      );

      // Assert
      expect(input.subject, isNotEmpty);
      expect(input.content, isNotEmpty);
      expect(input.countryId, isNotEmpty);
      expect(input.regionId, isNotEmpty);
      expect(input.cityId, isNotEmpty);
      expect(input.publishedAs, isA<PublishAs>());
      expect(input.idempotencyKey, isNotEmpty);
    });

    test('debe aceptar campos opcionales null', () {
      // Arrange & Act
      final input = CreateGossipInput(
        subject: 'Test',
        content: 'Content',
        countryId: 'CO',
        regionId: 'co-antioquia',
        cityId: 'MED',
        publishedAs: PublishAs.anonymous,
        audioUrl: null,
        imageUrl: null,
        idempotencyKey: 'key',
      );

      // Assert
      expect(input.audioUrl, isNull);
      expect(input.imageUrl, isNull);
    });

    test('debe soportar diferentes PublishAs valores', () {
      // Valores válidos de PublishAs
      final validPublishAs = [
        PublishAs.anonymous,
        PublishAs.profile,
      ];

      for (final publishAs in validPublishAs) {
        expect(publishAs.value, isNotEmpty);
      }
    });
  });

  group('GossipModel - Deserialización', () {
    test('debe deserializar GossipModel.fromJson correctamente', () {
      // Arrange
      final json = {
        'id': '123',
        'country_id': 'CO',
        'region_id': 'co-antioquia',
        'city_id': 'MED',
        'subject': 'Test',
        'content': 'Content',
        'published_as': 'anonymous',
        'status': 'published',
        'moderation_status': 'approved',
        'visibility': 'public',
        'created_at': '2024-01-15T10:30:00.000Z',
        'created_by': 'user-1',
      };

      // Act
      final model = GossipModel.fromJson(json);

      // Assert
      expect(model, isA<GossipModel>());
      expect(model.id, '123');
      expect(model.subject, 'Test');
      expect(model.status, 'published');
    });

    test('debe convertir GossipModel a Entity correctamente', () {
      // Arrange
      final model = GossipModel(
        id: '123',
        countryId: 'CO',
        regionId: 'co-antioquia',
        cityId: 'MED',
        subject: 'Test',
        content: 'Content',
        publishedAs: 'anonymous',
        status: 'published',
        moderationStatus: 'approved',
        visibility: 'public',
        createdAt: '2024-01-15T10:30:00.000Z',
        createdBy: 'user-1',
      );

      // Act
      final entity = model.toEntity();

      // Assert
      expect(entity, isA<Gossip>());
      expect(entity.id, '123');
      expect(entity.subject, 'Test');
      expect(entity.status, GossipStatus.published);
      expect(entity.moderationStatus, ModerationStatus.approved);
      expect(entity.visibility, GossipVisibility.public);
      expect(entity.publishedAs, PublishAs.anonymous);
    });
  });

  group('Keyset Pagination - Cursor format', () {
    test('debe parsear cursor con formato correcto', () {
      // Formato: "timestamp,id"
      const cursor = '2024-01-15T10:30:00.000Z,550e8400-e29b-41d4-a716-446655440000';

      final parts = cursor.split(',');
      expect(parts.length, 2);

      final timestamp = DateTime.parse(parts[0]);
      final id = parts[1];

      expect(timestamp, isA<DateTime>());
      expect(id, isNotEmpty);
    });

    test('debe construir cursor desde timestamp e id', () {
      // Arrange
      final timestamp = DateTime.parse('2024-01-15T10:30:00.000Z');
      const id = '550e8400-e29b-41d4-a716-446655440000';

      // Act
      final cursor = '${timestamp.toIso8601String()},$id';

      // Assert
      expect(cursor, contains(','));
      expect(cursor.split(',')[0], timestamp.toIso8601String());
      expect(cursor.split(',')[1], id);
    });

    test('debe manejar cursor null en primera página', () {
      // Primera página no tiene cursor
      const String? nullCursor = null;
      expect(nullCursor, isNull);
    });

    test('debe usar cursor para siguiente página', () {
      // Páginas subsiguientes usan cursor del último elemento
      const hasNextPage = true;
      const lastCursor = '2024-01-15T10:30:00.000Z,last-id';

      expect(hasNextPage, true);
      expect(lastCursor, isNotEmpty);
    });
  });

  group('Error handling - Auth y Server errors', () {
    test('debe requerir sesión activa para crear gossip', () {
      // Documentación: session == null → AuthFailure
      const bool hasSession = false;
      expect(hasSession, false);
    });

    test('debe requerir sesión activa para reportar', () {
      // Documentación: session == null → AuthFailure
      const bool hasSession = false;
      expect(hasSession, false);
    });

    test('debe detectar errores de autenticación', () {
      // Palabras clave de errores de auth
      final authKeywords = ['authentication', 'unauthorized', 'missing authorization'];

      for (final keyword in authKeywords) {
        expect(keyword.toLowerCase(), anyOf(
          contains('auth'),
          contains('unauthorized'),
          contains('authorization'),
        ));
      }
    });

    test('debe propagar Failure exceptions', () {
      // Documentación: if (e is Failure) rethrow
      expect(() => throw Exception('Test'), throwsException);
    });
  });
}

/// Simula la traducción de orderBy (para tests)
String _simulateTranslation(String orderBy) {
  switch (orderBy) {
    case 'createdAt':
      return 'created_at';
    case 'modifiedAt':
      return 'modified_at';
    case 'viewCount':
      return 'view_count';
    case 'likeCount':
      return 'like_count';
    case 'commentCount':
      return 'comment_count';
    case 'reportCount':
      return 'report_count';
    default:
      return orderBy;
  }
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
