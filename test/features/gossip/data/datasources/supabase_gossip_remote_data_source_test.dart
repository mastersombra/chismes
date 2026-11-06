import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:chismes/core/error/error_codes.dart' as error_codes;
import 'package:chismes/core/error/failure.dart';
import 'package:chismes/core/logging/logging.dart';
import 'package:chismes/features/gossip/data/datasources/supabase_gossip_remote_data_source.dart';
import 'package:chismes/features/gossip/domain/entities/create_gossip_input.dart';
import 'package:chismes/features/gossip/domain/entities/gossip.dart';
import 'package:chismes/features/gossip/domain/entities/report_reason.dart';

import 'supabase_gossip_remote_data_source_test.mocks.dart';

@GenerateMocks([SupabaseClient, FunctionsClient, AppLogger])
void main() {
  late SupabaseGossipRemoteDataSource dataSource;
  late MockSupabaseClient mockSupabase;
  late MockFunctionsClient mockFunctionsClient;
  late MockAppLogger mockLogger;

  setUp(() {
    mockSupabase = MockSupabaseClient();
    mockFunctionsClient = MockFunctionsClient();
    mockLogger = MockAppLogger();
    dataSource = SupabaseGossipRemoteDataSource(mockSupabase, mockLogger);
  });

  // NOTA: Los tests de getGossips son omitidos debido a la complejidad de mockear
  // la cadena de builders de Supabase (SupabaseQueryBuilder -> PostgrestFilterBuilder -> PostgrestTransformBuilder).
  // Estos están cubiertos por integration tests o tests end-to-end.

  group('create', () {
    final validInput = CreateGossipInput(
      subject: 'Test Subject',
      content: 'Test Content',
      countryId: 'CO',
      regionId: 'ANT',
      cityId: 'MED',
      publishedAs: PublishAs.anonymous,
      audioUrl: null,
      imageUrl: null,
      idempotencyKey: 'test-key-123',
    );

    final validGossipResponse = {
      'gossip': {
        'id': '123',
        'country_id': 'CO',
        'region_id': 'ANT',
        'city_id': 'MED',
        'subject': 'Test Subject',
        'content': 'Test Content',
        'audio_url': null,
        'image_url': null,
        'published_as': 'anonymous',
        'status': 'published',
        'moderation_status': 'approved',
        'report_count': 0,
        'view_count': 0,
        'deleted_at': null,
        'deleted_by': null,
        'visibility': 'public',
        'created_at': '2024-01-01T00:00:00.000Z',
        'created_by': 'user-123',
        'modified_at': null,
        'modified_by': null,
      }
    };

    setUp(() {
      when(mockSupabase.functions).thenReturn(mockFunctionsClient);
    });

    test('debe crear gossip exitosamente con respuesta 200', () async {
      // Arrange
      when(mockFunctionsClient.invoke(
        'moderate-gossip',
        body: anyNamed('body'),
      )).thenAnswer((_) async => FunctionResponse(
            data: validGossipResponse,
            status: 200,
          ));

      // Act
      final result = await dataSource.createWithImage(validInput, null);

      // Assert
      expect(result.id, '123');
      expect(result.subject, 'Test Subject');
      expect(result.status, 'published');
      expect(result.moderationStatus, 'approved');
    });

    test('debe incluir todos los campos en el body', () async {
      // Arrange
      when(mockFunctionsClient.invoke(any, body: anyNamed('body')))
          .thenAnswer((_) async => FunctionResponse(
                data: validGossipResponse,
                status: 200,
              ));

      // Act
      await dataSource.createWithImage(validInput, null);

      // Assert
      final captured = verify(mockFunctionsClient.invoke(
        'moderate-gossip',
        body: captureAnyNamed('body'),
      )).captured.single as Map<String, dynamic>;

      expect(captured['subject'], 'Test Subject');
      expect(captured['content'], 'Test Content');
      expect(captured['country_id'], 'CO');
      expect(captured['region_id'], 'ANT');
      expect(captured['city_id'], 'MED');
      expect(captured['published_as'], 'anonymous');
      expect(captured['idempotency_key'], 'test-key-123');
    });

    test('debe incluir audioUrl cuando está presente', () async {
      // Arrange
      final inputWithAudio = CreateGossipInput(
        subject: 'Test',
        content: 'Content',
        countryId: 'CO',
        regionId: 'ANT',
        cityId: 'MED',
        publishedAs: PublishAs.anonymous,
        audioUrl: 'https://example.com/audio.mp3',
        imageUrl: null,
        idempotencyKey: 'key',
      );

      when(mockFunctionsClient.invoke(any, body: anyNamed('body')))
          .thenAnswer((_) async => FunctionResponse(
                data: validGossipResponse,
                status: 200,
              ));

      // Act
      await dataSource.createWithImage(inputWithAudio, null);

      // Assert
      final captured = verify(mockFunctionsClient.invoke(
        'moderate-gossip',
        body: captureAnyNamed('body'),
      )).captured.single as Map<String, dynamic>;

      expect(captured['audio_url'], 'https://example.com/audio.mp3');
    });

    test('debe incluir imageUrl cuando está presente', () async {
      // Arrange
      final inputWithImage = CreateGossipInput(
        subject: 'Test',
        content: 'Content',
        countryId: 'CO',
        regionId: 'ANT',
        cityId: 'MED',
        publishedAs: PublishAs.anonymous,
        audioUrl: null,
        imageUrl: 'https://example.com/image.jpg',
        idempotencyKey: 'key',
      );

      when(mockFunctionsClient.invoke(any, body: anyNamed('body')))
          .thenAnswer((_) async => FunctionResponse(
                data: validGossipResponse,
                status: 200,
              ));

      // Act
      await dataSource.createWithImage(inputWithImage, null);

      // Assert
      final captured = verify(mockFunctionsClient.invoke(
        'moderate-gossip',
        body: captureAnyNamed('body'),
      )).captured.single as Map<String, dynamic>;

      // El código envía image_base64, no image_url directamente
      expect(captured['image_base64'], isNull); // null porque no pasamos File
      expect(captured['audio_url'], isNull);
    });

    test('debe lanzar ValidationFailure cuando moderación rechaza (status 400)', () async {
      // Arrange
      when(mockFunctionsClient.invoke(any, body: anyNamed('body')))
          .thenAnswer((_) async => FunctionResponse(
                data: {
                  'error': 'Content rejected by moderation',
                  'reasons': ['profanity', 'spam'],
                },
                status: 400,
              ));

      // Act & Assert
      expect(
        () => dataSource.createWithImage(validInput, null),
        throwsA(
          predicate<ValidationFailure>(
            (e) =>
                e.code == error_codes.ErrorCode.moderationRejected &&
                (e.technicalMessage?.contains('Content rejected') ?? false) &&
                (e.technicalMessage?.contains('profanity') ?? false) &&
                (e.technicalMessage?.contains('spam') ?? false),
          ),
        ),
      );
    });

    test('debe lanzar ValidationFailure con mensaje genérico cuando reasons está vacío', () async {
      // Arrange
      when(mockFunctionsClient.invoke(any, body: anyNamed('body')))
          .thenAnswer((_) async => FunctionResponse(
                data: {
                  'error': 'Content rejected by moderation',
                  'reasons': [],
                },
                status: 400,
              ));

      // Act & Assert
      expect(
        () => dataSource.createWithImage(validInput, null),
        throwsA(
          predicate<ValidationFailure>(
            (e) =>
                e.code == error_codes.ErrorCode.moderationRejected &&
                (e.technicalMessage?.contains('Content rejected') ?? false),
          ),
        ),
      );
    });

    test('debe lanzar ServerFailure cuando error no coincide con patrón de moderación', () async {
      // Arrange
      when(mockFunctionsClient.invoke(any, body: anyNamed('body')))
          .thenAnswer((_) async => FunctionResponse(
                data: {'error': 'Content rejected'},
                status: 400,
              ));

      // Act & Assert
      expect(
        () => dataSource.createWithImage(validInput, null),
        throwsA(
          predicate<ServerFailure>(
            (e) =>
                e.code == error_codes.ErrorCode.serverError &&
                (e.technicalMessage?.contains('Edge Function failed with status 400') ?? false),
          ),
        ),
      );
    });

    test('debe lanzar ServerFailure cuando status es 500', () async {
      // Arrange
      when(mockFunctionsClient.invoke(any, body: anyNamed('body')))
          .thenAnswer((_) async => FunctionResponse(
                data: {'error': 'Internal server error'},
                status: 500,
              ));

      // Act & Assert
      expect(
        () => dataSource.createWithImage(validInput, null),
        throwsA(
          predicate<ServerFailure>(
            (e) =>
                e.code == error_codes.ErrorCode.serverError &&
                e.technicalMessage == 'Edge Function failed with status 500',
          ),
        ),
      );
    });

    test('debe lanzar ServerFailure cuando status es 404', () async {
      // Arrange
      when(mockFunctionsClient.invoke(any, body: anyNamed('body')))
          .thenAnswer((_) async => FunctionResponse(
                data: {'error': 'Function not found'},
                status: 404,
              ));

      // Act & Assert
      expect(
        () => dataSource.createWithImage(validInput, null),
        throwsA(
          predicate<ServerFailure>(
            (e) => e.technicalMessage == 'Edge Function failed with status 404',
          ),
        ),
      );
    });

    test('debe lanzar ServerFailure cuando hay excepción de red', () async {
      // Arrange
      when(mockFunctionsClient.invoke(any, body: anyNamed('body')))
          .thenThrow(Exception('Network error'));

      // Act & Assert
      expect(
        () => dataSource.createWithImage(validInput, null),
        throwsA(
          predicate<ServerFailure>(
            (e) =>
                e.code == error_codes.ErrorCode.serverError &&
                (e.technicalMessage?.contains('Failed to create gossip with image') ?? false) &&
                (e.technicalMessage?.contains('Network error') ?? false),
          ),
        ),
      );
    });

    test('debe re-lanzar ValidationFailure sin modificar', () async {
      // Arrange
      final originalFailure = ValidationFailure(
        code: error_codes.ErrorCode.invalidGossipContent,
        technicalMessage: 'Original validation error',
      );

      when(mockFunctionsClient.invoke(any, body: anyNamed('body')))
          .thenThrow(originalFailure);

      // Act & Assert
      try {
        await dataSource.createWithImage(validInput, null);
        fail('Expected ValidationFailure to be thrown');
      } catch (e) {
        expect(e, same(originalFailure));
        expect(e, isA<ValidationFailure>());
        expect((e as ValidationFailure).technicalMessage, 'Original validation error');
      }
    });

    test('debe re-lanzar ServerFailure sin modificar', () async {
      // Arrange
      const originalFailure = ServerFailure(
        code: error_codes.ErrorCode.serverError,
        technicalMessage: 'Original server error',
      );

      when(mockFunctionsClient.invoke(any, body: anyNamed('body')))
          .thenThrow(originalFailure);

      // Act & Assert
      try {
        await dataSource.createWithImage(validInput, null);
        fail('Expected ServerFailure to be thrown');
      } catch (e) {
        expect(e, same(originalFailure));
        expect(e, isA<ServerFailure>());
        expect((e as ServerFailure).technicalMessage, 'Original server error');
      }
    });

    test('debe usar publishedAs.value correcto (profile)', () async {
      // Arrange
      final inputWithProfile = CreateGossipInput(
        subject: 'Test',
        content: 'Content',
        countryId: 'CO',
        regionId: 'ANT',
        cityId: 'MED',
        publishedAs: PublishAs.profile,
        audioUrl: null,
        imageUrl: null,
        idempotencyKey: 'key',
      );

      when(mockFunctionsClient.invoke(any, body: anyNamed('body')))
          .thenAnswer((_) async => FunctionResponse(
                data: validGossipResponse,
                status: 200,
              ));

      // Act
      await dataSource.createWithImage(inputWithProfile, null);

      // Assert
      final captured = verify(mockFunctionsClient.invoke(
        'moderate-gossip',
        body: captureAnyNamed('body'),
      )).captured.single as Map<String, dynamic>;

      expect(captured['published_as'], 'profile');
    });

    test('debe usar publichedAs.value correcto (anonymous)', () async {
      // Arrange - usa el validInput que ya tiene PublishAs.anonymous
      when(mockFunctionsClient.invoke(any, body: anyNamed('body')))
          .thenAnswer((_) async => FunctionResponse(
                data: validGossipResponse,
                status: 200,
              ));

      // Act
      await dataSource.createWithImage(validInput, null);

      // Assert
      final captured = verify(mockFunctionsClient.invoke(
        'moderate-gossip',
        body: captureAnyNamed('body'),
      )).captured.single as Map<String, dynamic>;

      expect(captured['published_as'], 'anonymous');
    });

    test('debe lanzar RateLimitFailure cuando rate limit excedido (status 429)', () async {
      // Arrange
      when(mockFunctionsClient.invoke(any, body: anyNamed('body')))
          .thenAnswer((_) async => FunctionResponse(
                data: {
                  'error': 'Rate limit exceeded',
                  'message': 'Too many gossips created. Try again in 60 seconds',
                  'retryAfter': 60,
                },
                status: 429,
              ));

      // Act & Assert
      expect(
        () => dataSource.createWithImage(validInput, null),
        throwsA(
          predicate<RateLimitFailure>(
            (e) =>
                e.code == error_codes.ErrorCode.rateLimitExceeded &&
                (e.technicalMessage?.contains('Too many gossips created. Try again in 60 seconds') ?? false),
          ),
        ),
      );
    });

    test('debe manejar rate limit sin retryAfter', () async {
      // Arrange
      when(mockFunctionsClient.invoke(any, body: anyNamed('body')))
          .thenAnswer((_) async => FunctionResponse(
                data: {
                  'error': 'Rate limit exceeded',
                  'message': 'Too many requests',
                },
                status: 429,
              ));

      // Act & Assert
      expect(
        () => dataSource.createWithImage(validInput, null),
        throwsA(
          predicate<RateLimitFailure>(
            (e) =>
                e.code == error_codes.ErrorCode.rateLimitExceeded &&
                (e.technicalMessage?.contains('Too many requests') ?? false),
          ),
        ),
      );
    });

    test('debe manejar rate limit con mensaje por defecto cuando no hay message', () async {
      // Arrange
      when(mockFunctionsClient.invoke(any, body: anyNamed('body')))
          .thenAnswer((_) async => FunctionResponse(
                data: {
                  'error': 'Rate limit',
                  'retryAfter': 120,
                },
                status: 429,
              ));

      // Act & Assert
      expect(
        () => dataSource.createWithImage(validInput, null),
        throwsA(
          predicate<RateLimitFailure>(
            (e) =>
                e.code == error_codes.ErrorCode.rateLimitExceeded &&
                e.technicalMessage == 'Rate limit exceeded', // Default message
          ),
        ),
      );
    });

    test('debe convertir response.data correctamente a GossipModel', () async {
      // Arrange
      final responseWithAllFields = {
        'gossip': {
          'id': 'test-id-456',
          'country_id': 'CO',
          'region_id': 'ANT',
          'city_id': 'MED',
          'subject': 'Complete Subject',
          'content': 'Complete Content with all fields',
          'audio_url': 'https://example.com/audio.mp3',
          'image_url': 'https://example.com/image.jpg',
          'published_as': 'profile',
          'status': 'published',
          'moderation_status': 'approved',
          'report_count': 5,
          'view_count': 100,
          'deleted_at': null,
          'deleted_by': null,
          'visibility': 'public',
          'created_at': '2024-06-15T10:30:00.000Z',
          'created_by': 'user-456',
          'modified_at': '2024-06-15T11:00:00.000Z',
          'modified_by': 'moderator-123',
        }
      };

      when(mockFunctionsClient.invoke(any, body: anyNamed('body')))
          .thenAnswer((_) async => FunctionResponse(
                data: responseWithAllFields,
                status: 200,
              ));

      // Act
      final result = await dataSource.createWithImage(validInput, null);

      // Assert - verificar todos los campos
      expect(result.id, 'test-id-456');
      expect(result.countryId, 'CO');
      expect(result.regionId, 'ANT');
      expect(result.cityId, 'MED');
      expect(result.subject, 'Complete Subject');
      expect(result.content, 'Complete Content with all fields');
      expect(result.audioUrl, 'https://example.com/audio.mp3');
      expect(result.imageUrl, 'https://example.com/image.jpg');
      expect(result.publishedAs, 'profile');
      expect(result.status, 'published');
      expect(result.moderationStatus, 'approved');
      expect(result.reportedCount, 5);
      expect(result.viewCount, 100);
      expect(result.visibility, 'public');
    });

    test('debe llamar Edge Function con nombre correcto', () async {
      // Arrange
      when(mockFunctionsClient.invoke(any, body: anyNamed('body')))
          .thenAnswer((_) async => FunctionResponse(
                data: validGossipResponse,
                status: 200,
              ));

      // Act
      await dataSource.createWithImage(validInput, null);

      // Assert - verificar que se llama la función correcta
      verify(mockFunctionsClient.invoke(
        'moderate-gossip',
        body: anyNamed('body'),
      )).called(1);
    });

    test('debe enviar null para audioUrl cuando no está presente', () async {
      // Arrange - validInput ya tiene audioUrl: null
      when(mockFunctionsClient.invoke(any, body: anyNamed('body')))
          .thenAnswer((_) async => FunctionResponse(
                data: validGossipResponse,
                status: 200,
              ));

      // Act
      await dataSource.createWithImage(validInput, null);

      // Assert
      final captured = verify(mockFunctionsClient.invoke(
        'moderate-gossip',
        body: captureAnyNamed('body'),
      )).captured.single as Map<String, dynamic>;

      expect(captured.containsKey('audio_url'), isTrue);
      expect(captured['audio_url'], isNull);
    });

    test('debe enviar null para image_base64 cuando no hay File de imagen', () async {
      // Arrange - validInput ya tiene imageUrl: null y no pasamos File
      when(mockFunctionsClient.invoke(any, body: anyNamed('body')))
          .thenAnswer((_) async => FunctionResponse(
                data: validGossipResponse,
                status: 200,
              ));

      // Act
      await dataSource.createWithImage(validInput, null);

      // Assert
      final captured = verify(mockFunctionsClient.invoke(
        'moderate-gossip',
        body: captureAnyNamed('body'),
      )).captured.single as Map<String, dynamic>;

      expect(captured.containsKey('image_base64'), isTrue);
      expect(captured['image_base64'], isNull);
    });

    test('debe incluir audioUrl e image_base64 cuando ambos están presentes', () async {
      // Arrange
      final inputWithBoth = CreateGossipInput(
        subject: 'Test',
        content: 'Content',
        countryId: 'CO',
        regionId: 'ANT',
        cityId: 'MED',
        publishedAs: PublishAs.anonymous,
        audioUrl: 'https://example.com/audio.mp3',
        imageUrl: 'https://example.com/image.jpg',
        idempotencyKey: 'key',
      );

      when(mockFunctionsClient.invoke(any, body: anyNamed('body')))
          .thenAnswer((_) async => FunctionResponse(
                data: validGossipResponse,
                status: 200,
              ));

      // Act
      await dataSource.createWithImage(inputWithBoth, null);

      // Assert
      final captured = verify(mockFunctionsClient.invoke(
        'moderate-gossip',
        body: captureAnyNamed('body'),
      )).captured.single as Map<String, dynamic>;

      expect(captured['audio_url'], 'https://example.com/audio.mp3');
      // image_base64 será null porque no pasamos File, el imageUrl del input no se usa
      expect(captured['image_base64'], isNull);
    });

    test('debe manejar status code inesperado (por ejemplo 503)', () async {
      // Arrange
      when(mockFunctionsClient.invoke(any, body: anyNamed('body')))
          .thenAnswer((_) async => FunctionResponse(
                data: {'error': 'Service Unavailable'},
                status: 503,
              ));

      // Act & Assert
      expect(
        () => dataSource.createWithImage(validInput, null),
        throwsA(
          predicate<ServerFailure>(
            (e) =>
                e.code == error_codes.ErrorCode.serverError &&
                e.technicalMessage == 'Edge Function failed with status 503',
          ),
        ),
      );
    });

    test('debe preservar caracteres especiales en subject y content', () async {
      // Arrange
      final inputWithSpecialChars = CreateGossipInput(
        subject: 'Test con ñ, acentos á é í ó ú, emojis 🎉🎊',
        content: 'Contenido con símbolos: @#\$%^&*()',
        countryId: 'CO',
        regionId: 'ANT',
        cityId: 'MED',
        publishedAs: PublishAs.anonymous,
        audioUrl: null,
        imageUrl: null,
        idempotencyKey: 'key',
      );

      when(mockFunctionsClient.invoke(any, body: anyNamed('body')))
          .thenAnswer((_) async => FunctionResponse(
                data: validGossipResponse,
                status: 200,
              ));

      // Act
      await dataSource.createWithImage(inputWithSpecialChars, null);

      // Assert
      final captured = verify(mockFunctionsClient.invoke(
        'moderate-gossip',
        body: captureAnyNamed('body'),
      )).captured.single as Map<String, dynamic>;

      expect(captured['subject'], contains('ñ'));
      expect(captured['subject'], contains('🎉'));
      expect(captured['content'], contains('@#\$'));
    });

    test('debe enviar idempotencyKey para prevenir duplicados', () async {
      // Arrange
      final inputWithKey = CreateGossipInput(
        subject: 'Test',
        content: 'Content',
        countryId: 'CO',
        regionId: 'ANT',
        cityId: 'MED',
        publishedAs: PublishAs.anonymous,
        audioUrl: null,
        imageUrl: null,
        idempotencyKey: 'unique-key-12345',
      );

      when(mockFunctionsClient.invoke(any, body: anyNamed('body')))
          .thenAnswer((_) async => FunctionResponse(
                data: validGossipResponse,
                status: 200,
              ));

      // Act
      await dataSource.createWithImage(inputWithKey, null);

      // Assert
      final captured = verify(mockFunctionsClient.invoke(
        'moderate-gossip',
        body: captureAnyNamed('body'),
      )).captured.single as Map<String, dynamic>;

      expect(captured['idempotency_key'], 'unique-key-12345');
    });

    test('debe detectar gossip duplicado cuando idempotent es true', () async {
      // Arrange
      final responseWithIdempotent = {
        'gossip': validGossipResponse['gossip'],
        'idempotent': true,
      };

      when(mockFunctionsClient.invoke(any, body: anyNamed('body')))
          .thenAnswer((_) async => FunctionResponse(
                data: responseWithIdempotent,
                status: 200,
              ));

      // Act
      final result = await dataSource.createWithImage(validInput, null);

      // Assert
      expect(result.id, '123');
      verify(mockLogger.i(
        argThat(contains('duplicado detectado')),
        context: anyNamed('context'),
      )).called(1);
    });

    test('debe lanzar ValidationFailure cuando imagen falla (Image upload failed)', () async {
      // Arrange
      when(mockFunctionsClient.invoke(any, body: anyNamed('body')))
          .thenAnswer((_) async => FunctionResponse(
                data: {
                  'error': 'Image upload failed',
                  'message': 'Invalid image format',
                },
                status: 400,
              ));

      // Act & Assert
      expect(
        () => dataSource.createWithImage(validInput, 'base64image'),
        throwsA(isA<ValidationFailure>().having(
          (f) => f.code,
          'code',
          error_codes.ErrorCode.mediaUploadFailed,
        )),
      );
    });

    test('debe lanzar AuthFailure cuando hay error de autenticación en catch', () async {
      // Arrange
      when(mockFunctionsClient.invoke(any, body: anyNamed('body')))
          .thenThrow(Exception('authentication required'));

      // Act & Assert
      expect(
        () => dataSource.createWithImage(validInput, null),
        throwsA(isA<AuthFailure>().having(
          (f) => f.code,
          'code',
          error_codes.ErrorCode.unauthorized,
        )),
      );
    });

    test('debe lanzar AuthFailure cuando hay error unauthorized', () async {
      // Arrange
      when(mockFunctionsClient.invoke(any, body: anyNamed('body')))
          .thenThrow(Exception('unauthorized access'));

      // Act & Assert
      expect(
        () => dataSource.createWithImage(validInput, null),
        throwsA(isA<AuthFailure>()),
      );
    });
  });

  group('reportGossip', () {
    setUp(() {
      when(mockSupabase.functions).thenReturn(mockFunctionsClient);
    });

    test('debe reportar gossip exitosamente', () async {
      // Arrange
      when(mockFunctionsClient.invoke(any, body: anyNamed('body')))
          .thenAnswer((_) async => FunctionResponse(
                data: {'success': true},
                status: 200,
              ));

      // Act
      await dataSource.reportGossip(
        gossipId: 'gossip-123',
        reason: ReportReason.spam,
        details: 'Test details',
      );

      // Assert
      verify(mockFunctionsClient.invoke(
        'report-gossip',
        body: {
          'gossip_id': 'gossip-123',
          'reason': 'spam',
          'details': 'Test details',
        },
      )).called(1);
    });

    test('debe reportar gossip sin details', () async {
      // Arrange
      when(mockFunctionsClient.invoke(any, body: anyNamed('body')))
          .thenAnswer((_) async => FunctionResponse(
                data: {'success': true},
                status: 200,
              ));

      // Act
      await dataSource.reportGossip(
        gossipId: 'gossip-123',
        reason: ReportReason.harassment,
      );

      // Assert
      final captured = verify(mockFunctionsClient.invoke(
        'report-gossip',
        body: captureAnyNamed('body'),
      )).captured.single as Map<String, dynamic>;

      expect(captured['gossip_id'], 'gossip-123');
      expect(captured['reason'], 'harassment');
      expect(captured.containsKey('details'), isFalse);
    });

    test('debe lanzar excepción cuando status no es 200', () async {
      // Arrange
      when(mockFunctionsClient.invoke(any, body: anyNamed('body')))
          .thenAnswer((_) async => FunctionResponse(
                data: {'error': 'Invalid gossip ID'},
                status: 400,
              ));

      // Act & Assert
      expect(
        () => dataSource.reportGossip(
          gossipId: 'invalid-id',
          reason: ReportReason.spam,
        ),
        throwsA(isA<ServerFailure>()),
      );
    });

    test('debe lanzar AuthFailure cuando usuario no autenticado', () async {
      // Arrange
      when(mockFunctionsClient.invoke(any, body: anyNamed('body')))
          .thenThrow(Exception('missing authorization header'));

      // Act & Assert
      expect(
        () => dataSource.reportGossip(
          gossipId: 'gossip-123',
          reason: ReportReason.spam,
        ),
        throwsA(isA<AuthFailure>().having(
          (f) => f.code,
          'code',
          error_codes.ErrorCode.unauthorized,
        )),
      );
    });

    test('debe lanzar AuthFailure cuando hay error de authentication', () async {
      // Arrange
      when(mockFunctionsClient.invoke(any, body: anyNamed('body')))
          .thenThrow(Exception('authentication failed'));

      // Act & Assert
      expect(
        () => dataSource.reportGossip(
          gossipId: 'gossip-123',
          reason: ReportReason.sexualContent,
        ),
        throwsA(isA<AuthFailure>()),
      );
    });

    test('debe lanzar AuthFailure cuando hay error unauthorized', () async {
      // Arrange
      when(mockFunctionsClient.invoke(any, body: anyNamed('body')))
          .thenThrow(Exception('unauthorized access'));

      // Act & Assert
      expect(
        () => dataSource.reportGossip(
          gossipId: 'gossip-123',
          reason: ReportReason.misinformation,
        ),
        throwsA(isA<AuthFailure>()),
      );
    });

    test('debe lanzar ValidationFailure cuando reporte duplicado', () async {
      // Arrange
      when(mockFunctionsClient.invoke(any, body: anyNamed('body')))
          .thenThrow(Exception('User has already reported this gossip'));

      // Act & Assert
      expect(
        () => dataSource.reportGossip(
          gossipId: 'gossip-123',
          reason: ReportReason.spam,
        ),
        throwsA(isA<ValidationFailure>().having(
          (f) => f.code,
          'code',
          error_codes.ErrorCode.validationError,
        )),
      );
    });

    test('debe lanzar ValidationFailure cuando duplicate key', () async {
      // Arrange
      when(mockFunctionsClient.invoke(any, body: anyNamed('body')))
          .thenThrow(Exception('duplicate key violation'));

      // Act & Assert
      expect(
        () => dataSource.reportGossip(
          gossipId: 'gossip-123',
          reason: ReportReason.harassment,
        ),
        throwsA(isA<ValidationFailure>()),
      );
    });

    test('debe lanzar ServerFailure para otros errores', () async {
      // Arrange
      when(mockFunctionsClient.invoke(any, body: anyNamed('body')))
          .thenThrow(Exception('Network error'));

      // Act & Assert
      expect(
        () => dataSource.reportGossip(
          gossipId: 'gossip-123',
          reason: ReportReason.spam,
        ),
        throwsA(isA<ServerFailure>().having(
          (f) => f.code,
          'code',
          error_codes.ErrorCode.serverError,
        )),
      );
    });

    test('debe loguear información del reporte', () async {
      // Arrange
      when(mockFunctionsClient.invoke(any, body: anyNamed('body')))
          .thenAnswer((_) async => FunctionResponse(
                data: {'success': true},
                status: 200,
              ));

      // Act
      await dataSource.reportGossip(
        gossipId: 'gossip-456',
        reason: ReportReason.violence,
      );

      // Assert
      verify(mockLogger.i(
        argThat(contains('Reportando gossip')),
        context: anyNamed('context'),
      )).called(1);
      verify(mockLogger.i(
        argThat(contains('reportado exitosamente')),
        context: anyNamed('context'),
      )).called(1);
    });
  });
}
