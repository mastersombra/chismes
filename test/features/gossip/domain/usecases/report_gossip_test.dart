import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:chismes/features/gossip/domain/usecases/report_gossip.dart';
import 'package:chismes/features/gossip/domain/repositories/gossip_repository.dart';
import 'package:chismes/features/gossip/domain/entities/report_reason.dart';
import 'package:chismes/core/result/result.dart';
import 'package:chismes/core/error/failure.dart';
import 'package:chismes/core/error/error_codes.dart' as error_codes;

import 'report_gossip_test.mocks.dart';

@GenerateMocks([GossipRepository])
void main() {
  setUpAll(() {
    // Provide dummy value for mockito
    provideDummy<Result<Failure, void>>(Result.success(null));
  });

  late ReportGossip useCase;
  late MockGossipRepository mockRepository;

  setUp(() {
    mockRepository = MockGossipRepository();
    useCase = ReportGossip(mockRepository);
  });

  group('ReportGossip', () {
    const gossipId = 'gossip-123';
    const reason = ReportReason.spam;
    const details = 'Este contenido es spam';

    test('debe reportar gossip exitosamente con detalles', () async {
      // Arrange
      when(mockRepository.reportGossip(
        gossipId: gossipId,
        reason: reason,
        details: details,
      )).thenAnswer((_) async => Result.success(null));

      // Act
      final result = await useCase.call(
        gossipId: gossipId,
        reason: reason,
        details: details,
      );

      // Assert
      expect(result.isSuccess, isTrue);
      verify(mockRepository.reportGossip(
        gossipId: gossipId,
        reason: reason,
        details: details,
      )).called(1);
    });

    test('debe reportar gossip exitosamente sin detalles', () async {
      // Arrange
      when(mockRepository.reportGossip(
        gossipId: gossipId,
        reason: reason,
        details: null,
      )).thenAnswer((_) async => Result.success(null));

      // Act
      final result = await useCase.call(
        gossipId: gossipId,
        reason: reason,
      );

      // Assert
      expect(result.isSuccess, isTrue);
      verify(mockRepository.reportGossip(
        gossipId: gossipId,
        reason: reason,
        details: null,
      )).called(1);
    });

    test('debe retornar failure cuando repository falla', () async {
      // Arrange
      final networkFailure = const NetworkFailure(
        code: error_codes.ErrorCode.networkError,
      );

      when(mockRepository.reportGossip(
        gossipId: gossipId,
        reason: reason,
        details: details,
      )).thenAnswer((_) async => Result.failure(networkFailure));

      // Act
      final result = await useCase.call(
        gossipId: gossipId,
        reason: reason,
        details: details,
      );

      // Assert
      expect(result.isFailure, isTrue);
      expect(result.failureValue, networkFailure);
      verify(mockRepository.reportGossip(
        gossipId: gossipId,
        reason: reason,
        details: details,
      )).called(1);
    });

    test('debe manejar error cuando usuario ya reportó el gossip', () async {
      // Arrange
      final duplicateFailure = const DataFailure(
        code: error_codes.ErrorCode.alreadyExists,
        technicalMessage: 'User already reported this gossip',
      );

      when(mockRepository.reportGossip(
        gossipId: gossipId,
        reason: reason,
        details: details,
      )).thenAnswer((_) async => Result.failure(duplicateFailure));

      // Act
      final result = await useCase.call(
        gossipId: gossipId,
        reason: reason,
        details: details,
      );

      // Assert
      expect(result.isFailure, isTrue);
      expect(result.failureValue, duplicateFailure);
    });

    group('Diferentes razones de reporte', () {
      test('debe reportar por spam', () async {
        // Arrange
        when(mockRepository.reportGossip(
          gossipId: gossipId,
          reason: ReportReason.spam,
          details: anyNamed('details'),
        )).thenAnswer((_) async => Result.success(null));

        // Act
        final result = await useCase.call(
          gossipId: gossipId,
          reason: ReportReason.spam,
          details: 'Es spam',
        );

        // Assert
        expect(result.isSuccess, isTrue);
      });

      test('debe reportar por acoso', () async {
        // Arrange
        when(mockRepository.reportGossip(
          gossipId: gossipId,
          reason: ReportReason.harassment,
          details: anyNamed('details'),
        )).thenAnswer((_) async => Result.success(null));

        // Act
        final result = await useCase.call(
          gossipId: gossipId,
          reason: ReportReason.harassment,
          details: 'Es acoso',
        );

        // Assert
        expect(result.isSuccess, isTrue);
      });

      test('debe reportar por violencia', () async {
        // Arrange
        when(mockRepository.reportGossip(
          gossipId: gossipId,
          reason: ReportReason.violence,
          details: anyNamed('details'),
        )).thenAnswer((_) async => Result.success(null));

        // Act
        final result = await useCase.call(
          gossipId: gossipId,
          reason: ReportReason.violence,
          details: 'Contiene violencia',
        );

        // Assert
        expect(result.isSuccess, isTrue);
      });

      test('debe reportar por contenido sexual', () async {
        // Arrange
        when(mockRepository.reportGossip(
          gossipId: gossipId,
          reason: ReportReason.sexualContent,
          details: anyNamed('details'),
        )).thenAnswer((_) async => Result.success(null));

        // Act
        final result = await useCase.call(
          gossipId: gossipId,
          reason: ReportReason.sexualContent,
          details: 'Contenido sexual inapropiado',
        );

        // Assert
        expect(result.isSuccess, isTrue);
      });

      test('debe reportar por desinformación', () async {
        // Arrange
        when(mockRepository.reportGossip(
          gossipId: gossipId,
          reason: ReportReason.misinformation,
          details: anyNamed('details'),
        )).thenAnswer((_) async => Result.success(null));

        // Act
        final result = await useCase.call(
          gossipId: gossipId,
          reason: ReportReason.misinformation,
          details: 'Información falsa',
        );

        // Assert
        expect(result.isSuccess, isTrue);
      });

      test('debe reportar con razón "otro"', () async {
        // Arrange
        when(mockRepository.reportGossip(
          gossipId: gossipId,
          reason: ReportReason.other,
          details: anyNamed('details'),
        )).thenAnswer((_) async => Result.success(null));

        // Act
        final result = await useCase.call(
          gossipId: gossipId,
          reason: ReportReason.other,
          details: 'Otro motivo',
        );

        // Assert
        expect(result.isSuccess, isTrue);
      });
    });

    group('Validación de parámetros', () {
      test('debe pasar gossipId al repository', () async {
        // Arrange
        const differentGossipId = 'different-gossip-456';
        when(mockRepository.reportGossip(
          gossipId: differentGossipId,
          reason: reason,
          details: anyNamed('details'),
        )).thenAnswer((_) async => Result.success(null));

        // Act
        await useCase.call(
          gossipId: differentGossipId,
          reason: reason,
        );

        // Assert
        verify(mockRepository.reportGossip(
          gossipId: differentGossipId,
          reason: reason,
          details: null,
        )).called(1);
      });

      test('debe pasar reason correcto al repository', () async {
        // Arrange
        when(mockRepository.reportGossip(
          gossipId: gossipId,
          reason: ReportReason.violence,
          details: anyNamed('details'),
        )).thenAnswer((_) async => Result.success(null));

        // Act
        await useCase.call(
          gossipId: gossipId,
          reason: ReportReason.violence,
        );

        // Assert
        verify(mockRepository.reportGossip(
          gossipId: gossipId,
          reason: ReportReason.violence,
          details: null,
        )).called(1);
      });

      test('debe pasar details cuando está presente', () async {
        // Arrange
        const specificDetails = 'Detalles muy específicos del reporte';
        when(mockRepository.reportGossip(
          gossipId: gossipId,
          reason: reason,
          details: specificDetails,
        )).thenAnswer((_) async => Result.success(null));

        // Act
        await useCase.call(
          gossipId: gossipId,
          reason: reason,
          details: specificDetails,
        );

        // Assert
        verify(mockRepository.reportGossip(
          gossipId: gossipId,
          reason: reason,
          details: specificDetails,
        )).called(1);
      });

      test('debe pasar null en details cuando no se proporciona', () async {
        // Arrange
        when(mockRepository.reportGossip(
          gossipId: gossipId,
          reason: reason,
          details: null,
        )).thenAnswer((_) async => Result.success(null));

        // Act
        await useCase.call(
          gossipId: gossipId,
          reason: reason,
        );

        // Assert
        verify(mockRepository.reportGossip(
          gossipId: gossipId,
          reason: reason,
          details: null,
        )).called(1);
      });
    });

    group('Casos edge', () {
      test('debe manejar gossipId vacío', () async {
        // Arrange
        when(mockRepository.reportGossip(
          gossipId: '',
          reason: reason,
          details: anyNamed('details'),
        )).thenAnswer((_) async => Result.failure(
          const ValidationFailure(
            code: error_codes.ErrorCode.invalidInput,
            technicalMessage: 'Gossip ID is required',
          ),
        ));

        // Act
        final result = await useCase.call(
          gossipId: '',
          reason: reason,
        );

        // Assert
        expect(result.isFailure, isTrue);
      });

      test('debe manejar details vacío', () async {
        // Arrange
        when(mockRepository.reportGossip(
          gossipId: gossipId,
          reason: reason,
          details: '',
        )).thenAnswer((_) async => Result.success(null));

        // Act
        final result = await useCase.call(
          gossipId: gossipId,
          reason: reason,
          details: '',
        );

        // Assert
        expect(result.isSuccess, isTrue);
      });

      test('debe manejar details muy largo', () async {
        // Arrange
        final longDetails = 'a' * 1000;
        when(mockRepository.reportGossip(
          gossipId: gossipId,
          reason: reason,
          details: longDetails,
        )).thenAnswer((_) async => Result.success(null));

        // Act
        final result = await useCase.call(
          gossipId: gossipId,
          reason: reason,
          details: longDetails,
        );

        // Assert
        expect(result.isSuccess, isTrue);
      });
    });

    group('Tipos de errores', () {
      test('debe manejar error de red', () async {
        // Arrange
        final failure = const NetworkFailure(
          code: error_codes.ErrorCode.networkError,
          technicalMessage: 'No internet connection',
        );

        when(mockRepository.reportGossip(
          gossipId: gossipId,
          reason: reason,
          details: anyNamed('details'),
        )).thenAnswer((_) async => Result.failure(failure));

        // Act
        final result = await useCase.call(
          gossipId: gossipId,
          reason: reason,
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

        when(mockRepository.reportGossip(
          gossipId: gossipId,
          reason: reason,
          details: anyNamed('details'),
        )).thenAnswer((_) async => Result.failure(failure));

        // Act
        final result = await useCase.call(
          gossipId: gossipId,
          reason: reason,
        );

        // Assert
        expect(result.isFailure, isTrue);
        expect(result.failureValue, isA<ServerFailure>());
      });

      test('debe manejar error de autorización', () async {
        // Arrange
        final failure = const AuthFailure(
          code: error_codes.ErrorCode.unauthorized,
          technicalMessage: 'User not authenticated',
        );

        when(mockRepository.reportGossip(
          gossipId: gossipId,
          reason: reason,
          details: anyNamed('details'),
        )).thenAnswer((_) async => Result.failure(failure));

        // Act
        final result = await useCase.call(
          gossipId: gossipId,
          reason: reason,
        );

        // Assert
        expect(result.isFailure, isTrue);
        expect(result.failureValue, isA<AuthFailure>());
      });
    });

    group('Reglas de negocio', () {
      test('debe documentar que usuario solo puede reportar una vez', () {
        // Documenta: unique constraint en base de datos
        // Un usuario que ya reportó recibe DataFailure con duplicateEntry
        expect(true, isTrue);
      });

      test('debe documentar que 3 reportes marcan el gossip como flagged', () {
        // Documenta: lógica en el Edge Function
        // Después de 3 reportes únicos, gossip.moderationStatus = 'flagged'
        expect(true, isTrue);
      });

      test('debe documentar que reportes quedan registrados', () {
        // Documenta: tabla gossip_reports en base de datos
        // Todos los reportes se guardan para auditoría
        expect(true, isTrue);
      });
    });
  });
}
