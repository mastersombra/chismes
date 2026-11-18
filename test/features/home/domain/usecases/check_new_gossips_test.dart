import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:chismes/features/home/domain/usecases/check_new_gossips.dart';
import 'package:chismes/features/home/domain/repositories/home_repository.dart';
import 'package:chismes/core/result/result.dart';
import 'package:chismes/core/error/failure.dart';
import 'package:chismes/core/error/error_codes.dart' as error_codes;

import 'check_new_gossips_test.mocks.dart';

@GenerateMocks([HomeRepository])
void main() {
  setUpAll(() {
    // Provide dummy value for mockito
    provideDummy<Result<Failure, int>>(
      Result.success(0),
    );
  });

  late CheckNewGossips useCase;
  late MockHomeRepository mockRepository;

  setUp(() {
    mockRepository = MockHomeRepository();
    useCase = CheckNewGossips(mockRepository);
  });

  group('CheckNewGossips', () {
    const userId = 'user-123';
    const cityId = 'city-456';
    final since = DateTime(2024, 1, 1, 10, 0);

    group('Success cases', () {
      test('debe retornar 0 cuando no hay gossips nuevos', () async {
        // Arrange
        when(mockRepository.checkNewGossips(
          userId: userId,
          cityId: cityId,
          since: since,
        )).thenAnswer((_) async => Result.success(0));

        // Act
        final result = await useCase(
          userId: userId,
          cityId: cityId,
          since: since,
        );

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.successValue, 0);
        verify(mockRepository.checkNewGossips(
          userId: userId,
          cityId: cityId,
          since: since,
        )).called(1);
      });

      test('debe retornar cantidad de gossips nuevos', () async {
        // Arrange
        const newGossipsCount = 5;
        when(mockRepository.checkNewGossips(
          userId: userId,
          cityId: cityId,
          since: since,
        )).thenAnswer((_) async => Result.success(newGossipsCount));

        // Act
        final result = await useCase(
          userId: userId,
          cityId: cityId,
          since: since,
        );

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.successValue, newGossipsCount);
        verify(mockRepository.checkNewGossips(
          userId: userId,
          cityId: cityId,
          since: since,
        )).called(1);
      });

      test('debe retornar cantidad grande de gossips nuevos', () async {
        // Arrange
        const newGossipsCount = 42;
        when(mockRepository.checkNewGossips(
          userId: userId,
          cityId: cityId,
          since: since,
        )).thenAnswer((_) async => Result.success(newGossipsCount));

        // Act
        final result = await useCase(
          userId: userId,
          cityId: cityId,
          since: since,
        );

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.successValue, 42);
      });

      test('debe funcionar con diferentes timestamps', () async {
        // Arrange
        final differentSince = DateTime(2024, 1, 2, 15, 30);
        when(mockRepository.checkNewGossips(
          userId: userId,
          cityId: cityId,
          since: differentSince,
        )).thenAnswer((_) async => Result.success(3));

        // Act
        final result = await useCase(
          userId: userId,
          cityId: cityId,
          since: differentSince,
        );

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.successValue, 3);
        verify(mockRepository.checkNewGossips(
          userId: userId,
          cityId: cityId,
          since: differentSince,
        )).called(1);
      });
    });

    group('Parámetros opcionales', () {
      test('debe funcionar con userId null (usuario no autenticado)', () async {
        // Arrange
        when(mockRepository.checkNewGossips(
          userId: null,
          cityId: cityId,
          since: since,
        )).thenAnswer((_) async => Result.success(5));

        // Act
        final result = await useCase(
          userId: null,
          cityId: cityId,
          since: since,
        );

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.successValue, 5);
        verify(mockRepository.checkNewGossips(
          userId: null,
          cityId: cityId,
          since: since,
        )).called(1);
      });

      test('debe funcionar con cityId null (ciudad no configurada)', () async {
        // Arrange
        when(mockRepository.checkNewGossips(
          userId: userId,
          cityId: null,
          since: since,
        )).thenAnswer((_) async => Result.success(3));

        // Act
        final result = await useCase(
          userId: userId,
          cityId: null,
          since: since,
        );

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.successValue, 3);
        verify(mockRepository.checkNewGossips(
          userId: userId,
          cityId: null,
          since: since,
        )).called(1);
      });

      test('debe funcionar con ambos null', () async {
        // Arrange
        when(mockRepository.checkNewGossips(
          userId: null,
          cityId: null,
          since: since,
        )).thenAnswer((_) async => Result.success(10));

        // Act
        final result = await useCase(
          userId: null,
          cityId: null,
          since: since,
        );

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.successValue, 10);
      });
    });

    group('Failure cases', () {
      test('debe retornar failure cuando repository falla', () async {
        // Arrange
        final networkFailure = const NetworkFailure(
          code: error_codes.ErrorCode.networkError,
          technicalMessage: 'No internet connection',
        );

        when(mockRepository.checkNewGossips(
          userId: userId,
          cityId: cityId,
          since: since,
        )).thenAnswer((_) async => Result.failure(networkFailure));

        // Act
        final result = await useCase(
          userId: userId,
          cityId: cityId,
          since: since,
        );

        // Assert
        expect(result.isFailure, isTrue);
        expect(result.failureValue, networkFailure);
        verify(mockRepository.checkNewGossips(
          userId: userId,
          cityId: cityId,
          since: since,
        )).called(1);
      });

      test('debe manejar error de red', () async {
        // Arrange
        final failure = const NetworkFailure(
          code: error_codes.ErrorCode.networkError,
        );

        when(mockRepository.checkNewGossips(
          userId: anyNamed('userId'),
          cityId: anyNamed('cityId'),
          since: anyNamed('since'),
        )).thenAnswer((_) async => Result.failure(failure));

        // Act
        final result = await useCase(
          userId: userId,
          cityId: cityId,
          since: since,
        );

        // Assert
        expect(result.isFailure, isTrue);
        expect(result.failureValue, isA<NetworkFailure>());
      });

      test('debe manejar error de servidor', () async {
        // Arrange
        final failure = const ServerFailure(
          code: error_codes.ErrorCode.serverError,
          technicalMessage: 'Internal server error',
        );

        when(mockRepository.checkNewGossips(
          userId: anyNamed('userId'),
          cityId: anyNamed('cityId'),
          since: anyNamed('since'),
        )).thenAnswer((_) async => Result.failure(failure));

        // Act
        final result = await useCase(
          userId: userId,
          cityId: cityId,
          since: since,
        );

        // Assert
        expect(result.isFailure, isTrue);
        expect(result.failureValue, isA<ServerFailure>());
      });

      test('debe fallar silenciosamente en caso de error', () async {
        // Documenta: en el controller, checkNewGossips debe fallar silenciosamente
        // No debe mostrar error al usuario, solo log
        final failure = const NetworkFailure(
          code: error_codes.ErrorCode.networkError,
        );

        when(mockRepository.checkNewGossips(
          userId: anyNamed('userId'),
          cityId: anyNamed('cityId'),
          since: anyNamed('since'),
        )).thenAnswer((_) async => Result.failure(failure));

        // Act
        final result = await useCase(
          userId: userId,
          cityId: cityId,
          since: since,
        );

        // Assert
        expect(result.isFailure, isTrue);
        // El controller debe manejar con: onFailure: (_) {} (silently fail)
      });
    });

    group('Polling behavior', () {
      test('debe permitir llamadas repetidas (polling)', () async {
        // Arrange
        when(mockRepository.checkNewGossips(
          userId: userId,
          cityId: cityId,
          since: since,
        )).thenAnswer((_) async => Result.success(0));

        // Act - Simular 3 llamadas de polling
        await useCase(userId: userId, cityId: cityId, since: since);
        await useCase(userId: userId, cityId: cityId, since: since);
        await useCase(userId: userId, cityId: cityId, since: since);

        // Assert
        verify(mockRepository.checkNewGossips(
          userId: userId,
          cityId: cityId,
          since: since,
        )).called(3);
      });

      test('debe documentar intervalo de polling (60 segundos)', () {
        // Documenta: polling cada 60 segundos
        // Solo cuando app está en foreground y usuario en home screen
      });
    });

    group('Timestamp handling', () {
      test('debe usar timestamp de última carga', () async {
        // Arrange
        final lastLoadTime = DateTime.now().subtract(Duration(minutes: 5));
        when(mockRepository.checkNewGossips(
          userId: userId,
          cityId: cityId,
          since: lastLoadTime,
        )).thenAnswer((_) async => Result.success(2));

        // Act
        final result = await useCase(
          userId: userId,
          cityId: cityId,
          since: lastLoadTime,
        );

        // Assert
        expect(result.isSuccess, isTrue);
        verify(mockRepository.checkNewGossips(
          userId: userId,
          cityId: cityId,
          since: lastLoadTime,
        )).called(1);
      });

      test('debe manejar timestamp muy antiguo', () async {
        // Arrange
        final oldTimestamp = DateTime(2020, 1, 1);
        when(mockRepository.checkNewGossips(
          userId: userId,
          cityId: cityId,
          since: oldTimestamp,
        )).thenAnswer((_) async => Result.success(999));

        // Act
        final result = await useCase(
          userId: userId,
          cityId: cityId,
          since: oldTimestamp,
        );

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.successValue, 999);
      });

      test('debe manejar timestamp muy reciente', () async {
        // Arrange
        final recentTimestamp = DateTime.now().subtract(Duration(seconds: 10));
        when(mockRepository.checkNewGossips(
          userId: userId,
          cityId: cityId,
          since: recentTimestamp,
        )).thenAnswer((_) async => Result.success(0));

        // Act
        final result = await useCase(
          userId: userId,
          cityId: cityId,
          since: recentTimestamp,
        );

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.successValue, 0);
      });
    });

    group('Documentación', () {
      test('debe documentar uso del banner', () {
        // Documenta: usado para mostrar banner "X nuevos chismes · Tap aquí"
        // El banner se muestra solo si count > 0
      });

      test('debe documentar condiciones de polling', () {
        // Documenta: polling solo cuando:
        // - App en foreground
        // - Usuario en home screen
        // - No hay operaciones en progreso
      });

      test('debe documentar filtros aplicados', () {
        // Documenta: cuenta solo chismes que cumplen:
        // - created_at > since
        // - status: published
        // - moderationStatus: approved
        // - Algoritmo de ciudad aplicado (igual que Popular feed)
      });
    });
  });
}
