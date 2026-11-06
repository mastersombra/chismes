import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:chismes/core/result/result.dart';
import 'package:chismes/core/error/failure.dart';
import 'package:chismes/core/error/error_codes.dart';
import 'package:chismes/features/location/domain/usecases/get_countries.dart';
import 'package:chismes/features/location/domain/repositories/location_repository.dart';
import 'package:chismes/features/location/domain/entities/country.dart';

import 'get_countries_test.mocks.dart';

// Genera los mocks con: flutter pub run build_runner build
@GenerateMocks([LocationRepository])
void main() {
  late GetCountries useCase;
  late MockLocationRepository mockRepository;

  setUp(() {
    mockRepository = MockLocationRepository();
    useCase = GetCountries(repository: mockRepository);

    // Provide dummy for Result type
    provideDummy<Result<Failure, List<Country>>>(
      Result.success([]),
    );
  });

  group('GetCountries', () {
    group('call()', () {
      test('debe retornar Result.success con lista de países del repository', () async {
        final countries = [
          const Country(id: '1', code: 'CO', name: 'Colombia'),
          const Country(id: '2', code: 'BR', name: 'Brasil'),
        ];

        when(mockRepository.getCountries())
            .thenAnswer((_) async => Result.success(countries));

        final result = await useCase.call();

        expect(result.isSuccess, isTrue);
        expect(result.successValue, countries);
        expect(result.successValue?.length, 2);
        verify(mockRepository.getCountries()).called(1);
      });

      test('debe retornar lista vacía si repository retorna lista vacía', () async {
        when(mockRepository.getCountries())
            .thenAnswer((_) async => Result.success([]));

        final result = await useCase.call();

        expect(result.isSuccess, isTrue);
        expect(result.successValue, isEmpty);
      });

      test('debe retornar Result.failure cuando repository falla', () async {
        final failure = Failure(code: ErrorCode.networkError);

        when(mockRepository.getCountries())
            .thenAnswer((_) async => Result.failure(failure));

        final result = await useCase.call();

        expect(result.isFailure, isTrue);
        expect(result.failureValue, failure);
        verify(mockRepository.getCountries()).called(1);
      });

      test('debe llamar a repository.getCountries() exactamente', () async {
        when(mockRepository.getCountries())
            .thenAnswer((_) async => Result.success([]));

        await useCase.call();

        verify(mockRepository.getCountries()).called(1);
        verifyNoMoreInteractions(mockRepository);
      });

      test('debe preservar el orden de países del repository', () async {
        final countries = [
          const Country(id: '1', code: 'CO', name: 'Colombia'),
          const Country(id: '2', code: 'BR', name: 'Brasil'),
          const Country(id: '3', code: 'AR', name: 'Argentina'),
        ];

        when(mockRepository.getCountries())
            .thenAnswer((_) async => Result.success(countries));

        final result = await useCase.call();

        expect(result.successValue?[0].code, 'CO');
        expect(result.successValue?[1].code, 'BR');
        expect(result.successValue?[2].code, 'AR');
      });

      test('debe manejar lista grande de países', () async {
        final manyCountries = List.generate(
          50,
          (i) => Country(id: '$i', code: 'C$i', name: 'Country $i'),
        );

        when(mockRepository.getCountries())
            .thenAnswer((_) async => Result.success(manyCountries));

        final result = await useCase.call();

        expect(result.isSuccess, isTrue);
        expect(result.successValue?.length, 50);
      });

      test('debe retornar nuevo Result en cada llamada', () async {
        when(mockRepository.getCountries())
            .thenAnswer((_) async => Result.success([]));

        final result1 = await useCase.call();
        final result2 = await useCase.call();

        expect(identical(result1, result2), isFalse);
        verify(mockRepository.getCountries()).called(2);
      });

      test('debe propagar diferentes tipos de Failure', () async {
        final failures = [
          Failure(code: ErrorCode.networkError),
          Failure(code: ErrorCode.serverError),
          Failure(code: ErrorCode.unknownError),
        ];

        for (final failure in failures) {
          when(mockRepository.getCountries())
              .thenAnswer((_) async => Result.failure(failure));

          final result = await useCase.call();

          expect(result.isFailure, isTrue);
          expect(result.failureValue?.code, failure.code);
        }
      });
    });

    group('Constructor', () {
      test('debe aceptar repository en constructor', () {
        final repository = MockLocationRepository();
        final useCase = GetCountries(repository: repository);

        expect(useCase, isNotNull);
        expect(useCase.repository, repository);
      });

      test('debe ser reutilizable con múltiples llamadas', () async {
        when(mockRepository.getCountries())
            .thenAnswer((_) async => Result.success([]));

        await useCase.call();
        await useCase.call();
        await useCase.call();

        verify(mockRepository.getCountries()).called(3);
      });
    });

    group('Comportamiento', () {
      test('no debe modificar los datos del repository', () async {
        final countries = [
          const Country(id: '1', code: 'CO', name: 'Colombia'),
        ];

        when(mockRepository.getCountries())
            .thenAnswer((_) async => Result.success(countries));

        final result = await useCase.call();

        expect(result.successValue, same(countries));
      });

      test('no debe cachear resultados', () async {
        final countries1 = [const Country(id: '1', code: 'CO', name: 'Colombia')];
        final countries2 = [const Country(id: '2', code: 'BR', name: 'Brasil')];

        when(mockRepository.getCountries())
            .thenAnswer((_) async => Result.success(countries1));
        final result1 = await useCase.call();

        when(mockRepository.getCountries())
            .thenAnswer((_) async => Result.success(countries2));
        final result2 = await useCase.call();

        expect(result1.successValue?[0].code, 'CO');
        expect(result2.successValue?[0].code, 'BR');
      });

      test('debe ser invocable con sintaxis call()', () async {
        // Verifica que el use case es callable
        when(mockRepository.getCountries())
            .thenAnswer((_) async => Result.success([]));

        // Estas dos formas son equivalentes:
        final result1 = await useCase.call();
        final result2 = await useCase();

        expect(result1.isSuccess, isTrue);
        expect(result2.isSuccess, isTrue);
        verify(mockRepository.getCountries()).called(2);
      });
    });
  });
}
