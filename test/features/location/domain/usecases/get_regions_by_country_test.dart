import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:chismes/core/result/result.dart';
import 'package:chismes/core/error/failure.dart';
import 'package:chismes/core/error/error_codes.dart';
import 'package:chismes/features/location/domain/usecases/get_regions_by_country.dart';
import 'package:chismes/features/location/domain/repositories/location_repository.dart';
import 'package:chismes/features/location/domain/entities/region.dart';

import 'get_regions_by_country_test.mocks.dart';

// Genera los mocks con: flutter pub run build_runner build
@GenerateMocks([LocationRepository])
void main() {
  late GetRegionsByCountry useCase;
  late MockLocationRepository mockRepository;

  setUp(() {
    mockRepository = MockLocationRepository();
    useCase = GetRegionsByCountry(repository: mockRepository);

    // Provide dummy for Result type
    provideDummy<Result<Failure, List<Region>>>(
      Result.success([]),
    );
  });

  group('GetRegionsByCountry', () {
    group('call()', () {
      test('debe retornar Result.success con regiones del país', () async {
        final regions = [
          const Region(id: '1', countryId: 'CO', name: 'Antioquia', type: 'department'),
          const Region(id: '2', countryId: 'CO', name: 'Cundinamarca', type: 'department'),
        ];

        when(mockRepository.getRegionsByCountry('CO'))
            .thenAnswer((_) async => Result.success(regions));

        final result = await useCase.call('CO');

        expect(result.isSuccess, isTrue);
        expect(result.successValue, regions);
        expect(result.successValue?.length, 2);
        verify(mockRepository.getRegionsByCountry('CO')).called(1);
      });

      test('debe pasar el countryId correcto al repository', () async {
        when(mockRepository.getRegionsByCountry('BR'))
            .thenAnswer((_) async => Result.success([]));

        await useCase.call('BR');

        verify(mockRepository.getRegionsByCountry('BR')).called(1);
        verifyNever(mockRepository.getRegionsByCountry('CO'));
      });

      test('debe retornar lista vacía si país no tiene regiones', () async {
        when(mockRepository.getRegionsByCountry('XX'))
            .thenAnswer((_) async => Result.success([]));

        final result = await useCase.call('XX');

        expect(result.isSuccess, isTrue);
        expect(result.successValue, isEmpty);
      });

      test('debe retornar Result.failure cuando repository falla', () async {
        final failure = Failure(code: ErrorCode.networkError);

        when(mockRepository.getRegionsByCountry('CO'))
            .thenAnswer((_) async => Result.failure(failure));

        final result = await useCase.call('CO');

        expect(result.isFailure, isTrue);
        expect(result.failureValue, failure);
      });

      test('debe manejar diferentes countryIds', () async {
        final countryIds = ['CO', 'BR', 'AR', 'PE', 'EC'];

        for (final countryId in countryIds) {
          when(mockRepository.getRegionsByCountry(countryId))
              .thenAnswer((_) async => Result.success([]));

          await useCase.call(countryId);

          verify(mockRepository.getRegionsByCountry(countryId)).called(1);
        }
      });

      test('debe preservar el orden de regiones del repository', () async {
        final regions = [
          const Region(id: '1', countryId: 'CO', name: 'Antioquia', type: 'department'),
          const Region(id: '2', countryId: 'CO', name: 'Cundinamarca', type: 'department'),
          const Region(id: '3', countryId: 'CO', name: 'Valle', type: 'department'),
        ];

        when(mockRepository.getRegionsByCountry('CO'))
            .thenAnswer((_) async => Result.success(regions));

        final result = await useCase.call('CO');

        expect(result.successValue?[0].name, 'Antioquia');
        expect(result.successValue?[1].name, 'Cundinamarca');
        expect(result.successValue?[2].name, 'Valle');
      });

      test('debe manejar país con muchas regiones', () async {
        final manyRegions = List.generate(
          100,
          (i) => Region(
            id: '$i',
            countryId: 'CO',
            name: 'Region $i',
            type: 'department',
          ),
        );

        when(mockRepository.getRegionsByCountry('CO'))
            .thenAnswer((_) async => Result.success(manyRegions));

        final result = await useCase.call('CO');

        expect(result.isSuccess, isTrue);
        expect(result.successValue?.length, 100);
      });

      test('debe validar que todas las regiones pertenecen al país solicitado', () async {
        final regions = [
          const Region(id: '1', countryId: 'CO', name: 'Antioquia', type: 'department'),
          const Region(id: '2', countryId: 'CO', name: 'Cundinamarca', type: 'department'),
        ];

        when(mockRepository.getRegionsByCountry('CO'))
            .thenAnswer((_) async => Result.success(regions));

        final result = await useCase.call('CO');

        final allFromCountry = result.successValue?.every(
          (region) => region.countryId == 'CO',
        ) ?? false;

        expect(allFromCountry, isTrue);
      });

      test('debe manejar diferentes tipos de región', () async {
        final regions = [
          const Region(id: '1', countryId: 'CO', name: 'Antioquia', type: 'department'),
          const Region(id: '2', countryId: 'BR', name: 'São Paulo', type: 'state'),
          const Region(id: '3', countryId: 'EC', name: 'Pichincha', type: 'province'),
        ];

        when(mockRepository.getRegionsByCountry(any))
            .thenAnswer((invocation) async {
          final countryId = invocation.positionalArguments[0] as String;
          return Result.success(
            regions.where((r) => r.countryId == countryId).toList(),
          );
        });

        final resultCO = await useCase.call('CO');
        final resultBR = await useCase.call('BR');
        final resultEC = await useCase.call('EC');

        expect(resultCO.successValue?.first.type, 'department');
        expect(resultBR.successValue?.first.type, 'state');
        expect(resultEC.successValue?.first.type, 'province');
      });

      test('debe propagar diferentes tipos de Failure', () async {
        final failures = [
          Failure(code: ErrorCode.networkError),
          Failure(code: ErrorCode.serverError),
        ];

        for (final failure in failures) {
          when(mockRepository.getRegionsByCountry('CO'))
              .thenAnswer((_) async => Result.failure(failure));

          final result = await useCase.call('CO');

          expect(result.isFailure, isTrue);
          expect(result.failureValue?.code, failure.code);
        }
      });
    });

    group('Constructor', () {
      test('debe aceptar repository en constructor', () {
        final repository = MockLocationRepository();
        final useCase = GetRegionsByCountry(repository: repository);

        expect(useCase, isNotNull);
        expect(useCase.repository, repository);
      });
    });

    group('Comportamiento', () {
      test('no debe modificar los datos del repository', () async {
        final regions = [
          const Region(id: '1', countryId: 'CO', name: 'Antioquia', type: 'department'),
        ];

        when(mockRepository.getRegionsByCountry('CO'))
            .thenAnswer((_) async => Result.success(regions));

        final result = await useCase.call('CO');

        expect(result.successValue, same(regions));
      });

      test('no debe cachear resultados', () async {
        final regions1 = [
          const Region(id: '1', countryId: 'CO', name: 'Antioquia', type: 'department'),
        ];
        final regions2 = [
          const Region(id: '2', countryId: 'CO', name: 'Cundinamarca', type: 'department'),
        ];

        when(mockRepository.getRegionsByCountry('CO'))
            .thenAnswer((_) async => Result.success(regions1));
        final result1 = await useCase.call('CO');

        when(mockRepository.getRegionsByCountry('CO'))
            .thenAnswer((_) async => Result.success(regions2));
        final result2 = await useCase.call('CO');

        expect(result1.successValue?[0].name, 'Antioquia');
        expect(result2.successValue?[0].name, 'Cundinamarca');
      });

      test('debe ser invocable con sintaxis call()', () async {
        when(mockRepository.getRegionsByCountry('CO'))
            .thenAnswer((_) async => Result.success([]));

        final result1 = await useCase.call('CO');
        final result2 = await useCase('CO');

        expect(result1.isSuccess, isTrue);
        expect(result2.isSuccess, isTrue);
        verify(mockRepository.getRegionsByCountry('CO')).called(2);
      });

      test('debe manejar caracteres especiales en countryId', () async {
        final specialIds = ['co-colombia', 'país-ñ', 'test_id'];

        for (final id in specialIds) {
          when(mockRepository.getRegionsByCountry(id))
              .thenAnswer((_) async => Result.success([]));

          await useCase.call(id);

          verify(mockRepository.getRegionsByCountry(id)).called(1);
        }
      });
    });
  });
}
