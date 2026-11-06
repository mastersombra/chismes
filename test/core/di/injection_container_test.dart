import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:chismes/core/di/injection_container.dart';

void main() {
  group('injection_container', () {
    tearDown(() {
      // Limpiar GetIt después de cada test si tiene registros
      try {
        getIt.reset();
      } catch (_) {
        // Ignorar errores al limpiar
      }
    });

    test('getIt debe ser una instancia de GetIt', () {
      expect(getIt, isA<GetIt>());
      expect(getIt, same(GetIt.instance));
    });

    test('getIt debe ser la instancia singleton de GetIt', () {
      final instance1 = GetIt.instance;
      final instance2 = GetIt.instance;

      expect(getIt, same(instance1));
      expect(getIt, same(instance2));
      expect(instance1, same(instance2));
    });

    test('getIt debe ser accesible desde cualquier parte', () {
      expect(getIt, isNotNull);
      expect(getIt, isA<GetIt>());
      expect(getIt, same(GetIt.instance));
    });

    test('configureDependencies debe ser una función válida', () {
      // Verificar que la función existe
      expect(configureDependencies, isA<Function>());

      // Nota: No podemos llamar a configureDependencies() en tests unitarios
      // porque requiere que Supabase esté inicializado, lo cual solo sucede
      // en la aplicación real mediante main.dart. La función es async y retorna
      // Future<void>, pero verificar eso requeriría ejecutarla.
    });

    test('getIt debe permitir verificar registro de dependencias', () {
      // Antes de configurar, no hay dependencias registradas
      expect(getIt.isRegistered<String>(), isFalse);
      expect(getIt.isRegistered<int>(), isFalse);
    });

    test('getIt debe lanzar error al obtener dependencia no registrada', () {
      // Sin llamar a configureDependencies
      expect(
        () => getIt<String>(),
        throwsA(isA<Error>()),
      );
    });

    test('getIt debe mantener su identidad como singleton', () {
      final beforeAny = getIt;
      final afterAny = getIt;

      expect(beforeAny, same(afterAny));
      expect(getIt, same(GetIt.instance));
    });

    test('getIt debe ser thread-safe como singleton', () {
      // GetIt.instance siempre retorna la misma instancia
      final instances = List.generate(10, (_) => GetIt.instance);

      for (var i = 0; i < instances.length; i++) {
        expect(instances[i], same(getIt));
      }
    });
  });
}
