import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:chismes/core/result/result.dart';
import 'package:chismes/core/error/failure.dart';
import 'package:chismes/core/error/error_codes.dart';
import 'package:chismes/features/location/domain/usecases/get_cities_by_region.dart';
import 'package:chismes/features/location/domain/repositories/location_repository.dart';
import 'package:chismes/features/location/domain/entities/city.dart';

import 'get_cities_by_region_test.mocks.dart';

// Genera los mocks con: flutter pub run build_runner build
@GenerateMocks([LocationRepository])
void main() {
  late GetCitiesByRegion useCase;
  late MockLocationRepository mockRepository;

  setUp(() {
    mockRepository = MockLocationRepository();
    useCase = GetCitiesByRegion(repository: mockRepository);

    // Provide dummy for Result type
    provideDummy<Result<Failure, List<City>>>(
      Result.success([]),
    );
  });

  group('GetCitiesByRegion', () {
    group('call()', () {
      test('debe retornar Result.success con ciudades de la región', () async {
        final cities = [
          const City(id: '1', regionId: 'antioquia', name: 'Medellín'),
          const City(id: '2', regionId: 'antioquia', name: 'Envigado'),
        ];

        when(mockRepository.getCitiesByRegion('antioquia'))
            .thenAnswer((_) async => Result.success(cities));

        final result = await useCase.call('antioquia');

        expect(result.isSuccess, isTrue);
        expect(result.successValue, cities);
        expect(result.successValue?.length, 2);
        verify(mockRepository.getCitiesByRegion('antioquia')).called(1);
      });

      test('debe pasar el regionId correcto al repository', () async {
        when(mockRepository.getCitiesByRegion('cundinamarca'))
            .thenAnswer((_) async => Result.success([]));

        await useCase.call('cundinamarca');

        verify(mockRepository.getCitiesByRegion('cundinamarca')).called(1);
        verifyNever(mockRepository.getCitiesByRegion('antioquia'));
      });

      test('debe retornar lista vacía si región no tiene ciudades', () async {
        when(mockRepository.getCitiesByRegion('empty-region'))
            .thenAnswer((_) async => Result.success([]));

        final result = await useCase.call('empty-region');

        expect(result.isSuccess, isTrue);
        expect(result.successValue, isEmpty);
      });

      test('debe retornar Result.failure cuando repository falla', () async {
        final failure = Failure(code: ErrorCode.networkError);

        when(mockRepository.getCitiesByRegion('antioquia'))
            .thenAnswer((_) async => Result.failure(failure));

        final result = await useCase.call('antioquia');

        expect(result.isFailure, isTrue);
        expect(result.failureValue, failure);
      });

      test('debe manejar diferentes regionIds', () async {
        final regionIds = ['antioquia', 'cundinamarca', 'valle', 'atlantico'];

        for (final regionId in regionIds) {
          when(mockRepository.getCitiesByRegion(regionId))
              .thenAnswer((_) async => Result.success([]));

          await useCase.call(regionId);

          verify(mockRepository.getCitiesByRegion(regionId)).called(1);
        }
      });

      test('debe preservar el orden de ciudades del repository', () async {
        final cities = [
          const City(id: '1', regionId: 'antioquia', name: 'Medellín'),
          const City(id: '2', regionId: 'antioquia', name: 'Envigado'),
          const City(id: '3', regionId: 'antioquia', name: 'Bello'),
        ];

        when(mockRepository.getCitiesByRegion('antioquia'))
            .thenAnswer((_) async => Result.success(cities));

        final result = await useCase.call('antioquia');

        expect(result.successValue?[0].name, 'Medellín');
        expect(result.successValue?[1].name, 'Envigado');
        expect(result.successValue?[2].name, 'Bello');
      });

      test('debe manejar región con muchas ciudades', () async {
        final manyCities = List.generate(
          200,
          (i) => City(
            id: '$i',
            regionId: 'antioquia',
            name: 'City $i',
          ),
        );

        when(mockRepository.getCitiesByRegion('antioquia'))
            .thenAnswer((_) async => Result.success(manyCities));

        final result = await useCase.call('antioquia');

        expect(result.isSuccess, isTrue);
        expect(result.successValue?.length, 200);
      });

      test('debe validar que todas las ciudades pertenecen a la región solicitada', () async {
        final cities = [
          const City(id: '1', regionId: 'antioquia', name: 'Medellín'),
          const City(id: '2', regionId: 'antioquia', name: 'Bello'),
        ];

        when(mockRepository.getCitiesByRegion('antioquia'))
            .thenAnswer((_) async => Result.success(cities));

        final result = await useCase.call('antioquia');

        final allFromRegion = result.successValue?.every(
          (city) => city.regionId == 'antioquia',
        ) ?? false;

        expect(allFromRegion, isTrue);
      });

      test('debe manejar ciudades con caracteres especiales en nombres', () async {
        final cities = [
          const City(id: '1', regionId: 'test', name: 'Bogotá'),
          const City(id: '2', regionId: 'test', name: 'São Paulo'),
          const City(id: '3', regionId: 'test', name: 'Córdoba'),
        ];

        when(mockRepository.getCitiesByRegion('test'))
            .thenAnswer((_) async => Result.success(cities));

        final result = await useCase.call('test');

        expect(result.successValue?[0].name, 'Bogotá');
        expect(result.successValue?[1].name, 'São Paulo');
        expect(result.successValue?[2].name, 'Córdoba');
      });

      test('debe propagar diferentes tipos de Failure', () async {
        final failures = [
          Failure(code: ErrorCode.networkError),
          Failure(code: ErrorCode.serverError),
          Failure(code: ErrorCode.unknownError),
        ];

        for (final failure in failures) {
          when(mockRepository.getCitiesByRegion('antioquia'))
              .thenAnswer((_) async => Result.failure(failure));

          final result = await useCase.call('antioquia');

          expect(result.isFailure, isTrue);
          expect(result.failureValue?.code, failure.code);
        }
      });
    });

    group('Constructor', () {
      test('debe aceptar repository en constructor', () {
        final repository = MockLocationRepository();
        final useCase = GetCitiesByRegion(repository: repository);

        expect(useCase, isNotNull);
        expect(useCase.repository, repository);
      });

      test('debe ser reutilizable con múltiples llamadas', () async {
        when(mockRepository.getCitiesByRegion('antioquia'))
            .thenAnswer((_) async => Result.success([]));

        await useCase.call('antioquia');
        await useCase.call('antioquia');
        await useCase.call('antioquia');

        verify(mockRepository.getCitiesByRegion('antioquia')).called(3);
      });
    });

    group('Comportamiento', () {
      test('no debe modificar los datos del repository', () async {
        final cities = [
          const City(id: '1', regionId: 'antioquia', name: 'Medellín'),
        ];

        when(mockRepository.getCitiesByRegion('antioquia'))
            .thenAnswer((_) async => Result.success(cities));

        final result = await useCase.call('antioquia');

        expect(result.successValue, same(cities));
      });

      test('no debe cachear resultados', () async {
        final cities1 = [
          const City(id: '1', regionId: 'antioquia', name: 'Medellín'),
        ];
        final cities2 = [
          const City(id: '2', regionId: 'antioquia', name: 'Bello'),
        ];

        when(mockRepository.getCitiesByRegion('antioquia'))
            .thenAnswer((_) async => Result.success(cities1));
        final result1 = await useCase.call('antioquia');

        when(mockRepository.getCitiesByRegion('antioquia'))
            .thenAnswer((_) async => Result.success(cities2));
        final result2 = await useCase.call('antioquia');

        expect(result1.successValue?[0].name, 'Medellín');
        expect(result2.successValue?[0].name, 'Bello');
      });

      test('debe ser invocable con sintaxis call()', () async {
        when(mockRepository.getCitiesByRegion('antioquia'))
            .thenAnswer((_) async => Result.success([]));

        final result1 = await useCase.call('antioquia');
        final result2 = await useCase('antioquia');

        expect(result1.isSuccess, isTrue);
        expect(result2.isSuccess, isTrue);
        verify(mockRepository.getCitiesByRegion('antioquia')).called(2);
      });

      test('debe manejar caracteres especiales en regionId', () async {
        final specialIds = ['region-id', 'región_ñ', 'test.id'];

        for (final id in specialIds) {
          when(mockRepository.getCitiesByRegion(id))
              .thenAnswer((_) async => Result.success([]));

          await useCase.call(id);

          verify(mockRepository.getCitiesByRegion(id)).called(1);
        }
      });

      test('debe manejar regionIds muy largos', () async {
        const longId = 'very-long-region-id-with-many-characters-for-testing';

        when(mockRepository.getCitiesByRegion(longId))
            .thenAnswer((_) async => Result.success([]));

        await useCase.call(longId);

        verify(mockRepository.getCitiesByRegion(longId)).called(1);
      });

      test('debe retornar nuevo Result en cada llamada', () async {
        when(mockRepository.getCitiesByRegion('antioquia'))
            .thenAnswer((_) async => Result.success([]));

        final result1 = await useCase.call('antioquia');
        final result2 = await useCase.call('antioquia');

        expect(identical(result1, result2), isFalse);
        verify(mockRepository.getCitiesByRegion('antioquia')).called(2);
      });
    });
  });
}
