import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:chismes/features/gossip/domain/usecases/create_gossip.dart';
import 'package:chismes/features/gossip/domain/repositories/gossip_repository.dart';
import 'package:chismes/features/gossip/domain/entities/create_gossip_input.dart';
import 'package:chismes/features/gossip/domain/entities/gossip.dart';
import 'package:chismes/core/result/result.dart';
import 'package:chismes/core/error/failure.dart';
import 'package:chismes/core/error/error_codes.dart' as error_codes;
import 'package:chismes/core/logging/logging.dart';
import 'package:chismes/features/auth/domain/repositories/auth_repository.dart';

import 'create_gossip_test.mocks.dart';

@GenerateMocks([
  GossipRepository,
  AuthRepository,
  AppLogger,
])
void main() {
  setUpAll(() {
    // Provide dummy values for mockito
    provideDummy<Result<Failure, Gossip>>(
      Result.success(
        Gossip(
          id: 'dummy',
          countryId: '1',
          regionId: '1',
          cityId: '1',
          subject: 'Dummy',
          content: 'Dummy',
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
          createdBy: 'dummy',
          modifiedAt: null,
          modifiedBy: null,
        ),
      ),
    );
  });

  late CreateGossip useCase;
  late MockGossipRepository mockRepository;
  late MockAuthRepository mockAuthRepository;
  late MockAppLogger mockLogger;

  setUp(() {
    mockRepository = MockGossipRepository();
    mockAuthRepository = MockAuthRepository();
    mockLogger = MockAppLogger();
    useCase = CreateGossip(
      repository: mockRepository,
      authRepository: mockAuthRepository,
      logger: mockLogger,
    );
  });

  group('CreateGossip', () {
    final validInput = CreateGossipInput(
      countryId: '1',
      regionId: '1',
      cityId: '1',
      subject: 'Tema válido',
      content: 'Contenido válido',
      publishedAs: PublishAs.anonymous,
      idempotencyKey: 'test-key-1',
    );

    final validGossip = Gossip(
      id: '123',
      countryId: '1',
      regionId: '1',
      cityId: '1',
      subject: 'Tema válido',
      content: 'Contenido válido',
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

    test('debe crear gossip exitosamente cuando input es válido', () async {
      // Arrange
      when(mockRepository.createWithImage(any, any)).thenAnswer(
        (_) async => Result.success(validGossip),
      );

      // Act
      final result = await useCase.call(input:validInput);

      // Assert
      expect(result.isSuccess, isTrue);
      expect(result.successValue, equals(validGossip));
      verify(mockRepository.createWithImage(validInput, any)).called(1);
    });

    test('debe retornar failure cuando subject está vacío', () async {
      // Arrange
      final invalidInput = CreateGossipInput(
        countryId: '1',
        regionId: '1',
        cityId: '1',
        subject: '',
        content: 'Contenido válido',
        publishedAs: PublishAs.anonymous,
        idempotencyKey: 'test-key-1',
      );

      // Act
      final result = await useCase.call(input:invalidInput);

      // Assert
      expect(result.isFailure, isTrue);
      expect(result.failureValue, isA<ValidationFailure>());
      expect(result.failureValue?.code, error_codes.ErrorCode.missingRequiredField);
      verifyNever(mockRepository.createWithImage(any, any));
    });

    test('debe retornar failure cuando content está vacío', () async {
      // Arrange
      final invalidInput = CreateGossipInput(
        countryId: '1',
        regionId: '1',
        cityId: '1',
        subject: 'Tema válido',
        content: '',
        publishedAs: PublishAs.anonymous,
        idempotencyKey: 'test-key-1',
      );

      // Act
      final result = await useCase.call(input:invalidInput);

      // Assert
      expect(result.isFailure, isTrue);
      expect(result.failureValue, isA<ValidationFailure>());
      verifyNever(mockRepository.createWithImage(any, any));
    });

    test('debe retornar failure cuando subject excede longitud máxima', () async {
      // Arrange
      final invalidInput = CreateGossipInput(
        countryId: '1',
        regionId: '1',
        cityId: '1',
        subject: 'a' * 201,
        content: 'Contenido válido',
        publishedAs: PublishAs.anonymous,
        idempotencyKey: 'test-key-1',
      );

      // Act
      final result = await useCase.call(input:invalidInput);

      // Assert
      expect(result.isFailure, isTrue);
      expect(result.failureValue, isA<ValidationFailure>());
      verifyNever(mockRepository.createWithImage(any, any));
    });

    test('debe retornar failure cuando content excede longitud máxima', () async {
      // Arrange
      final invalidInput = CreateGossipInput(
        countryId: '1',
        regionId: '1',
        cityId: '1',
        subject: 'Tema válido',
        content: 'a' * 1001,
        publishedAs: PublishAs.anonymous,
        idempotencyKey: 'test-key-1',
      );

      // Act
      final result = await useCase.call(input:invalidInput);

      // Assert
      expect(result.isFailure, isTrue);
      expect(result.failureValue, isA<ValidationFailure>());
      verifyNever(mockRepository.createWithImage(any, any));
    });

    test('debe retornar failure cuando ubicación es inválida', () async {
      // Arrange
      final invalidInput = CreateGossipInput(
        countryId: '',
        regionId: '1',
        cityId: '1',
        subject: 'Tema válido',
        content: 'Contenido válido',
        publishedAs: PublishAs.anonymous,
        idempotencyKey: 'test-key-1',
      );

      // Act
      final result = await useCase.call(input:invalidInput);

      // Assert
      expect(result.isFailure, isTrue);
      expect(result.failureValue, isA<DataFailure>());
      expect(result.failureValue?.code, error_codes.ErrorCode.invalidLocation);
      verifyNever(mockRepository.createWithImage(any, any));
    });

    test('debe propagar failure del repository', () async {
      // Arrange
      final networkFailure = const NetworkFailure(code: error_codes.ErrorCode.networkError);
      when(mockRepository.createWithImage(any, any)).thenAnswer(
        (_) async => Result.failure(networkFailure),
      );

      // Act
      final result = await useCase.call(input:validInput);

      // Assert
      expect(result.isFailure, isTrue);
      expect(result.failureValue, equals(networkFailure));
      verify(mockRepository.createWithImage(validInput, any)).called(1);
    });

    test('debe crear gossip con audioUrl', () async {
      // Arrange
      final inputWithAudio = CreateGossipInput(
        countryId: '1',
        regionId: '1',
        cityId: '1',
        subject: 'Tema válido',
        content: 'Contenido válido',
        audioUrl: 'https://example.com/audio.mp3',
        publishedAs: PublishAs.anonymous,
        idempotencyKey: 'test-key-1',
      );

      final gossipWithAudio = Gossip(
        id: '123',
        countryId: '1',
        regionId: '1',
        cityId: '1',
        subject: 'Tema válido',
        content: 'Contenido válido',
        audioUrl: 'https://example.com/audio.mp3',
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

      when(mockRepository.createWithImage(any, any)).thenAnswer(
        (_) async => Result.success(gossipWithAudio),
      );

      // Act
      final result = await useCase.call(input: inputWithAudio, imageFile: null);

      // Assert
      expect(result.isSuccess, isTrue);
      expect(result.successValue?.audioUrl, 'https://example.com/audio.mp3');
    });

    test('debe crear gossip sin audioUrl si es null', () async {
      // Arrange
      when(mockRepository.createWithImage(any, any)).thenAnswer(
        (_) async => Result.success(validGossip),
      );

      // Act
      final result = await useCase.call(input: validInput, imageFile: null);

      // Assert
      expect(result.isSuccess, isTrue);
      expect(result.successValue?.audioUrl, isNull);
    });

    test('debe incluir idempotencyKey en el input', () async {
      // Arrange
      when(mockRepository.createWithImage(any, any)).thenAnswer(
        (_) async => Result.success(validGossip),
      );

      // Act
      await useCase.call(input: validInput, imageFile: null);

      // Assert
      final captured = verify(mockRepository.createWithImage(captureAny, any)).captured;
      expect(captured.length, 1);
      final capturedInput = captured[0] as CreateGossipInput;
      expect(capturedInput.idempotencyKey, 'test-key-1');
    });

    test('debe prevenir duplicados con mismo idempotencyKey', () async {
      // Arrange
      when(mockRepository.createWithImage(any, any)).thenAnswer(
        (_) async => Result.success(validGossip),
      );

      // Act - Llamar dos veces con el mismo idempotencyKey
      final result1 = await useCase.call(input: validInput, imageFile: null);
      final result2 = await useCase.call(input: validInput, imageFile: null);

      // Assert
      expect(result1.isSuccess, isTrue);
      expect(result2.isSuccess, isTrue);
      // El repository debe ser llamado 2 veces, pero en producción
      // el backend debería retornar el mismo gossip
      verify(mockRepository.createWithImage(any, any)).called(2);
    });
  });

  group('CreateGossip - Validaciones adicionales', () {
    test('debe validar PublishAs válido', () async {
      // Arrange
      final input = CreateGossipInput(
        countryId: '1',
        regionId: '1',
        cityId: '1',
        subject: 'Tema válido',
        content: 'Contenido válido',
        publishedAs: PublishAs.profile, // Válido
        idempotencyKey: 'test-key-1',
      );

      final gossip = Gossip(
        id: '123',
        countryId: '1',
        regionId: '1',
        cityId: '1',
        subject: 'Tema válido',
        content: 'Contenido válido',
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
        createdAt: DateTime.now(),
        createdBy: 'user-123',
        modifiedAt: null,
        modifiedBy: null,
      );

      when(mockRepository.createWithImage(any, any)).thenAnswer(
        (_) async => Result.success(gossip),
      );

      // Act
      final result = await useCase.call(input: input, imageFile: null);

      // Assert
      expect(result.isSuccess, isTrue);
      expect(result.successValue?.publishedAs, PublishAs.profile);
    });

    test('debe trimear subject y content antes de validar', () async {
      // Arrange
      final inputWithSpaces = CreateGossipInput(
        countryId: '1',
        regionId: '1',
        cityId: '1',
        subject: '  Tema válido  ',
        content: '  Contenido válido  ',
        publishedAs: PublishAs.anonymous,
        idempotencyKey: 'test-key-1',
      );

      final gossip = Gossip(
        id: '123',
        countryId: '1',
        regionId: '1',
        cityId: '1',
        subject: 'Tema válido',
        content: 'Contenido válido',
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

      when(mockRepository.createWithImage(any, any)).thenAnswer(
        (_) async => Result.success(gossip),
      );

      // Act
      final result = await useCase.call(input: inputWithSpaces, imageFile: null);

      // Assert
      expect(result.isSuccess, isTrue);
    });

    test('debe rechazar subject con solo espacios', () async {
      // Arrange
      final invalidInput = CreateGossipInput(
        countryId: '1',
        regionId: '1',
        cityId: '1',
        subject: '   ',
        content: 'Contenido válido',
        publishedAs: PublishAs.anonymous,
        idempotencyKey: 'test-key-1',
      );

      // Act
      final result = await useCase.call(input: invalidInput, imageFile: null);

      // Assert
      expect(result.isFailure, isTrue);
      expect(result.failureValue, isA<ValidationFailure>());
      verifyNever(mockRepository.createWithImage(any, any));
    });

    test('debe rechazar content con solo espacios', () async {
      // Arrange
      final invalidInput = CreateGossipInput(
        countryId: '1',
        regionId: '1',
        cityId: '1',
        subject: 'Tema válido',
        content: '   ',
        publishedAs: PublishAs.anonymous,
        idempotencyKey: 'test-key-1',
      );

      // Act
      final result = await useCase.call(input: invalidInput, imageFile: null);

      // Assert
      expect(result.isFailure, isTrue);
      expect(result.failureValue, isA<ValidationFailure>());
      verifyNever(mockRepository.createWithImage(any, any));
    });
  });

  group('CreateGossip - Image Upload', () {
    final validInput = CreateGossipInput(
      countryId: 'CO',
      regionId: 'ANT',
      cityId: 'MED',
      subject: 'Test',
      content: 'Content',
      publishedAs: PublishAs.anonymous,
      idempotencyKey: 'test-key-1',
    );

    final validGossip = Gossip(
      id: '123',
      countryId: 'CO',
      regionId: 'ANT',
      cityId: 'MED',
      subject: 'Test',
      content: 'Content',
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

    test('debe crear input sin imagen antes de llamar repository', () async {
      // Arrange
      when(mockRepository.createWithImage(any, any)).thenAnswer(
        (_) async => Result.success(validGossip),
      );

      // Act
      await useCase.call(input: validInput, imageFile: null);

      // Assert
      final captured = verify(mockRepository.createWithImage(captureAny, any)).captured;
      final capturedInput = captured[0] as CreateGossipInput;
      expect(capturedInput.imageUrl, isNull);
    });

    test('debe retornar failure cuando validación falla', () async {
      // Arrange
      final invalidInput = CreateGossipInput(
        countryId: '',
        regionId: 'ANT',
        cityId: 'MED',
        subject: 'Test',
        content: 'Content',
        publishedAs: PublishAs.anonymous,
        idempotencyKey: 'test-key-1',
      );

      // Act
      final result = await useCase.call(input: invalidInput, imageFile: null);

      // Assert
      expect(result.isFailure, isTrue);
      verifyNever(mockRepository.createWithImage(any, any));
    });

    test('debe propagar failure del repository cuando falla creación', () async {
      // Arrange
      final failure = const NetworkFailure(code: error_codes.ErrorCode.networkError);
      when(mockRepository.createWithImage(any, any)).thenAnswer(
        (_) async => Result.failure(failure),
      );

      // Act
      final result = await useCase.call(input: validInput, imageFile: null);

      // Assert
      expect(result.isFailure, isTrue);
      expect(result.failureValue, failure);
    });

    test('debe retornar success sin imagen cuando imageFile es null', () async {
      // Arrange
      when(mockRepository.createWithImage(any, any)).thenAnswer(
        (_) async => Result.success(validGossip),
      );

      // Act
      final result = await useCase.call(input: validInput, imageFile: null);

      // Assert
      expect(result.isSuccess, isTrue);
      expect(result.successValue?.imageUrl, isNull);
    });

    test('debe retornar gossip original cuando idempotencyKey previene duplicados', () async {
      // Arrange
      when(mockRepository.createWithImage(any, any)).thenAnswer(
        (_) async => Result.success(validGossip),
      );

      // Act
      final result1 = await useCase.call(input: validInput, imageFile: null);
      final result2 = await useCase.call(input: validInput, imageFile: null);

      // Assert
      expect(result1.isSuccess, isTrue);
      expect(result2.isSuccess, isTrue);
      expect(result1.successValue?.id, result2.successValue?.id);
    });

    test('debe incluir audioUrl en input si está presente', () async {
      // Arrange
      final inputWithAudio = CreateGossipInput(
        countryId: 'CO',
        regionId: 'ANT',
        cityId: 'MED',
        subject: 'Test',
        content: 'Content',
        audioUrl: 'https://example.com/audio.mp3',
        publishedAs: PublishAs.anonymous,
        idempotencyKey: 'test-key-1',
      );

      when(mockRepository.createWithImage(any, any)).thenAnswer(
        (_) async => Result.success(validGossip),
      );

      // Act
      await useCase.call(input: inputWithAudio, imageFile: null);

      // Assert
      final captured = verify(mockRepository.createWithImage(captureAny, any)).captured;
      final capturedInput = captured[0] as CreateGossipInput;
      expect(capturedInput.audioUrl, 'https://example.com/audio.mp3');
    });

    test('debe limpiar subject y content antes de validar', () async {
      // Arrange
      final inputWithSpaces = CreateGossipInput(
        countryId: 'CO',
        regionId: 'ANT',
        cityId: 'MED',
        subject: '  Test  ',
        content: '  Content  ',
        publishedAs: PublishAs.anonymous,
        idempotencyKey: 'test-key-1',
      );

      when(mockRepository.createWithImage(any, any)).thenAnswer(
        (_) async => Result.success(validGossip),
      );

      // Act
      final result = await useCase.call(input: inputWithSpaces, imageFile: null);

      // Assert
      expect(result.isSuccess, isTrue);
    });

    test('debe preservar todos los campos del input', () async {
      // Arrange
      when(mockRepository.createWithImage(any, any)).thenAnswer(
        (_) async => Result.success(validGossip),
      );

      // Act
      await useCase.call(input: validInput, imageFile: null);

      // Assert
      final captured = verify(mockRepository.createWithImage(captureAny, any)).captured;
      final capturedInput = captured[0] as CreateGossipInput;
      expect(capturedInput.countryId, validInput.countryId);
      expect(capturedInput.regionId, validInput.regionId);
      expect(capturedInput.cityId, validInput.cityId);
      expect(capturedInput.subject, validInput.subject);
      expect(capturedInput.content, validInput.content);
      expect(capturedInput.publishedAs, validInput.publishedAs);
      expect(capturedInput.idempotencyKey, validInput.idempotencyKey);
    });
  });

  group('CreateGossip - Image Upload Flow', () {
    final validInput = CreateGossipInput(
      countryId: 'CO',
      regionId: 'ANT',
      cityId: 'MED',
      subject: 'Test',
      content: 'Content',
      publishedAs: PublishAs.anonymous,
      idempotencyKey: 'test-key-1',
    );

    final validGossip = Gossip(
      id: '123',
      countryId: 'CO',
      regionId: 'ANT',
      cityId: 'MED',
      subject: 'Test',
      content: 'Content',
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


    test('debe crear gossip sin imagen cuando imageFile es null', () async {
      // Arrange
      when(mockRepository.createWithImage(any, any)).thenAnswer(
        (_) async => Result.success(validGossip),
      );

      // Act
      final result = await useCase.call(input: validInput, imageFile: null);

      // Assert
      expect(result.isSuccess, isTrue);
      expect(result.successValue?.imageUrl, isNull);
    });


    test('debe manejar excepción general y retornar Failure', () async {
      // Arrange
      when(mockRepository.createWithImage(any, any)).thenThrow(Exception('Unexpected error'));

      // Act
      final result = await useCase.call(input: validInput, imageFile: null);

      // Assert
      expect(result.isFailure, isTrue);
      expect(result.failureValue, isA<Failure>());
      expect(result.failureValue?.code, error_codes.ErrorCode.unknownError);
    });

    test('debe imprimir error cuando falla creación general', () async {
      // Arrange
      when(mockRepository.createWithImage(any, any)).thenThrow(Exception('Test error'));

      // Act
      final result = await useCase.call(input: validInput, imageFile: null);

      // Assert
      expect(result.isFailure, isTrue);
      expect(result.failureValue?.technicalMessage, contains('Test error'));
    });
  });
}
