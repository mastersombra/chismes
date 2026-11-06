import 'package:flutter_test/flutter_test.dart';
import 'package:chismes/core/result/result.dart';

void main() {
  group('Result', () {
    test('success factory debe crear Success', () {
      final result = Result<String, int>.success(42);
      
      expect(result, isA<Success<String, int>>());
      expect(result.isSuccess, isTrue);
      expect(result.isFailure, isFalse);
    });

    test('failure factory debe crear ResultFailure', () {
      final result = Result<String, int>.failure('error');
      
      expect(result, isA<ResultFailure<String, int>>());
      expect(result.isFailure, isTrue);
      expect(result.isSuccess, isFalse);
    });

    test('Success debe retornar valor con successValue', () {
      final result = Result<String, int>.success(42);
      
      expect(result.successValue, 42);
      expect(result.failureValue, isNull);
    });

    test('ResultFailure debe retornar error con failureValue', () {
      final result = Result<String, int>.failure('error');
      
      expect(result.failureValue, 'error');
      expect(result.successValue, isNull);
    });

    test('when debe ejecutar onSuccess para Success', () {
      final result = Result<String, int>.success(42);
      var executed = false;
      
      result.when(
        onSuccess: (value) {
          executed = true;
          return value * 2;
        },
        onFailure: (_) => 0,
      );
      
      expect(executed, isTrue);
    });

    test('when debe ejecutar onFailure para ResultFailure', () {
      final result = Result<String, int>.failure('error');
      var executed = false;
      
      result.when(
        onSuccess: (_) => 0,
        onFailure: (error) {
          executed = true;
          return -1;
        },
      );
      
      expect(executed, isTrue);
    });

    test('when debe retornar valor de onSuccess', () {
      final result = Result<String, int>.success(42);
      
      final output = result.when(
        onSuccess: (value) => value * 2,
        onFailure: (_) => 0,
      );
      
      expect(output, 84);
    });

    test('when debe retornar valor de onFailure', () {
      final result = Result<String, int>.failure('error');
      
      final output = result.when(
        onSuccess: (_) => 0,
        onFailure: (error) => -1,
      );
      
      expect(output, -1);
    });

    test('onSuccess debe ejecutar callback solo para Success', () {
      final result = Result<String, int>.success(42);
      var callbackValue = 0;
      
      result.onSuccess((value) => callbackValue = value);
      
      expect(callbackValue, 42);
    });

    test('onSuccess no debe ejecutar callback para ResultFailure', () {
      final result = Result<String, int>.failure('error');
      var executed = false;
      
      result.onSuccess((_) => executed = true);
      
      expect(executed, isFalse);
    });

    test('onFailure debe ejecutar callback solo para ResultFailure', () {
      final result = Result<String, int>.failure('error');
      var callbackError = '';
      
      result.onFailure((error) => callbackError = error);
      
      expect(callbackError, 'error');
    });

    test('onFailure no debe ejecutar callback para Success', () {
      final result = Result<String, int>.success(42);
      var executed = false;
      
      result.onFailure((_) => executed = true);
      
      expect(executed, isFalse);
    });

    test('map debe transformar valor de Success', () {
      final result = Result<String, int>.success(42);
      
      final mapped = result.map((value) => value.toString());
      
      expect(mapped.successValue, '42');
    });

    test('map no debe transformar ResultFailure', () {
      final result = Result<String, int>.failure('error');
      
      final mapped = result.map((value) => value.toString());
      
      expect(mapped.failureValue, 'error');
      expect(mapped.successValue, isNull);
    });

    test('mapFailure debe transformar error de ResultFailure', () {
      final result = Result<String, int>.failure('error');
      
      final mapped = result.mapFailure((error) => error.length);
      
      expect(mapped.failureValue, 5);
    });

    test('mapFailure no debe transformar Success', () {
      final result = Result<String, int>.success(42);
      
      final mapped = result.mapFailure((error) => error.length);
      
      expect(mapped.successValue, 42);
      expect(mapped.failureValue, isNull);
    });

    test('Success equality debe comparar valores', () {
      final result1 = Result<String, int>.success(42);
      final result2 = Result<String, int>.success(42);
      final result3 = Result<String, int>.success(43);
      
      expect(result1, equals(result2));
      expect(result1, isNot(equals(result3)));
    });

    test('ResultFailure equality debe comparar errores', () {
      final result1 = Result<String, int>.failure('error');
      final result2 = Result<String, int>.failure('error');
      final result3 = Result<String, int>.failure('other');
      
      expect(result1, equals(result2));
      expect(result1, isNot(equals(result3)));
    });

    test('Success hashCode debe ser consistente', () {
      final result1 = Result<String, int>.success(42);
      final result2 = Result<String, int>.success(42);
      
      expect(result1.hashCode, equals(result2.hashCode));
    });

    test('ResultFailure hashCode debe ser consistente', () {
      final result1 = Result<String, int>.failure('error');
      final result2 = Result<String, int>.failure('error');
      
      expect(result1.hashCode, equals(result2.hashCode));
    });

    test('Success toString debe mostrar valor', () {
      final result = Result<String, int>.success(42);
      
      expect(result.toString(), 'Result.success(42)');
    });

    test('ResultFailure toString debe mostrar error', () {
      final result = Result<String, int>.failure('error');
      
      expect(result.toString(), 'Result.failure(error)');
    });

    test('onSuccess debe retornar el mismo Result', () {
      final result = Result<String, int>.success(42);
      
      final returned = result.onSuccess((_) {});
      
      expect(returned, same(result));
    });

    test('onFailure debe retornar el mismo Result', () {
      final result = Result<String, int>.failure('error');
      
      final returned = result.onFailure((_) {});
      
      expect(returned, same(result));
    });

    test('Success y ResultFailure nunca deben ser iguales', () {
      final success = Result<String, int>.success(42);
      final failure = Result<String, int>.failure('error');
      
      expect(success, isNot(equals(failure)));
    });

    test('pattern matching con switch debe funcionar', () {
      final success = Result<String, int>.success(42);

      final result = switch (success) {
        Success(value: final v) => v * 2,
        ResultFailure(error: _) => -1,
      };

      expect(result, 84);
    });

    test('Success con null value debe ser válido', () {
      final result = Result<String, int?>.success(null);
      
      expect(result.isSuccess, isTrue);
      expect(result.successValue, isNull);
    });

    test('chain de map debe funcionar', () {
      final result = Result<String, int>.success(10);
      
      final chained = result
          .map((v) => v * 2)
          .map((v) => v + 5)
          .map((v) => v.toString());
      
      expect(chained.successValue, '25');
    });
  });
}
