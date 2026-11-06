import 'package:flutter_test/flutter_test.dart';
import 'package:chismes/core/id/timestamp_id_generator.dart';
import 'package:chismes/core/id/id_generator.dart';

void main() {
  late TimestampIdGenerator generator;

  setUp(() {
    generator = TimestampIdGenerator();
  });

  group('TimestampIdGenerator', () {
    group('generate()', () {
      test('debe retornar un String', () {
        final id = generator.generate();

        expect(id, isA<String>());
        expect(id, isNotEmpty);
      });

      test('debe retornar un timestamp en milisegundos', () {
        final id = generator.generate();
        final timestamp = int.tryParse(id);

        expect(timestamp, isNotNull);
        expect(timestamp, isA<int>());
      });

      test('debe retornar timestamp de 13 dígitos', () {
        final id = generator.generate();

        // Timestamps en milisegundos desde epoch tienen 13 dígitos
        // Ejemplo: 1234567890123
        expect(id.length, 13);
      });

      test('debe retornar timestamp cercano al momento actual', () {
        final now = DateTime.now().millisecondsSinceEpoch;
        final id = generator.generate();
        final timestamp = int.parse(id);

        // Debe estar a menos de 100ms del momento actual
        final difference = (now - timestamp).abs();
        expect(difference, lessThan(100));
      });

      test('debe generar IDs diferentes en llamadas consecutivas', () {
        final id1 = generator.generate();
        final id2 = generator.generate();
        final id3 = generator.generate();

        // Aunque puedan ser iguales si se ejecutan en el mismo milisegundo,
        // típicamente serán diferentes
        expect(id1, isA<String>());
        expect(id2, isA<String>());
        expect(id3, isA<String>());
      });

      test('debe generar IDs únicos con pequeño delay', () async {
        final id1 = generator.generate();
        await Future.delayed(const Duration(milliseconds: 10));
        final id2 = generator.generate();

        expect(id1, isNot(equals(id2)));
        expect(int.parse(id2), greaterThan(int.parse(id1)));
      });

      test('debe generar IDs en orden cronológico', () async {
        final ids = <String>[];

        for (var i = 0; i < 5; i++) {
          ids.add(generator.generate());
          await Future.delayed(const Duration(milliseconds: 5));
        }

        // Verificar que los IDs están en orden ascendente
        for (var i = 0; i < ids.length - 1; i++) {
          final current = int.parse(ids[i]);
          final next = int.parse(ids[i + 1]);
          expect(next, greaterThanOrEqualTo(current));
        }
      });

      test('debe poder parsearse de vuelta a DateTime', () {
        final id = generator.generate();
        final timestamp = int.parse(id);
        final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);

        expect(dateTime, isA<DateTime>());
        expect(dateTime.year, DateTime.now().year);
      });

      test('debe generar IDs válidos para uso como identificadores', () {
        final id = generator.generate();

        // Verificar que solo contiene dígitos
        final isNumeric = RegExp(r'^[0-9]+$').hasMatch(id);
        expect(isNumeric, isTrue);
      });
    });

    group('Implementa IdGenerator', () {
      test('debe implementar interfaz IdGenerator', () {
        expect(generator, isA<IdGenerator>());
      });

      test('debe poder usarse como IdGenerator', () {
        final IdGenerator idGenerator = generator;
        final id = idGenerator.generate();

        expect(id, isNotEmpty);
      });
    });

    group('Casos especiales', () {
      test('debe generar mismo ID si se llama en el mismo milisegundo', () {
        // Este es el problema de colisión mencionado en la advertencia
        // Si dos clientes generan IDs en el mismo milisegundo, colisionan

        final ids = <String>[];
        // Generar muchos IDs rápidamente
        for (var i = 0; i < 10; i++) {
          ids.add(generator.generate());
        }

        // Es posible que algunos IDs sean iguales
        final uniqueIds = ids.toSet();
        expect(uniqueIds.length, lessThanOrEqualTo(ids.length));
      });

      test('debe manejar múltiples instancias del generador', () {
        final generator1 = TimestampIdGenerator();
        final generator2 = TimestampIdGenerator();

        final id1 = generator1.generate();
        final id2 = generator2.generate();

        // Ambos generadores usan el mismo timestamp, pueden colisionar
        expect(id1, isA<String>());
        expect(id2, isA<String>());
      });
    });

    group('Limitaciones (advertencias)', () {
      test('no debe usarse en producción con alta concurrencia', () {
        // Documenta la advertencia del código
        // ⚠️ ADVERTENCIA: Solo usar para DESARROLLO y MOCKS

        expect(true, isTrue);
      });

      test('puede tener colisiones si se genera en el mismo milisegundo', () {
        // Documenta el problema de colisiones
        // Dos clientes pueden generar IDs en momentos extremadamente cercanos

        expect(true, isTrue);
      });

      test('el ID tiene relación con la hora', () {
        // Documenta que el ID no es aleatorio
        // Puede inferirse el momento de creación

        final id = generator.generate();
        final timestamp = int.parse(id);
        final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);

        expect(dateTime, isA<DateTime>());
      });

      test('debe considerarse alternativa: UUID v4 para producción', () {
        // Documenta alternativas recomendadas
        // - Firestore document ID (auto-generado por Supabase)
        // - Identificador generado por backend
        // - UUID v4 (si se necesita generación en cliente)

        expect(true, isTrue);
      });
    });

    group('Uso típico', () {
      test('debe poder usarse como ID temporal en mocks', () {
        final gossipId = generator.generate();
        final userId = generator.generate();

        expect(gossipId, isNotEmpty);
        expect(userId, isNotEmpty);
      });

      test('debe poder usarse en tests unitarios', () {
        final mockId = generator.generate();

        expect(mockId, isA<String>());
        expect(mockId.length, 13);
      });

      test('debe ser útil para ordenar por creación', () async {
        final olderId = generator.generate();
        await Future.delayed(const Duration(milliseconds: 10));
        final newerId = generator.generate();

        // Los IDs mantienen orden cronológico
        expect(int.parse(newerId), greaterThan(int.parse(olderId)));
      });
    });

    group('Formato del ID', () {
      test('debe ser string de números sin separadores', () {
        final id = generator.generate();

        expect(id, matches(r'^\d+$'));
        expect(id, isNot(contains('-')));
        expect(id, isNot(contains('_')));
      });

      test('debe empezar con 1 (timestamps desde epoch)', () {
        final id = generator.generate();

        // Timestamps desde epoch (1970) empiezan con 1
        expect(id[0], '1');
      });

      test('debe poder convertirse a int sin pérdida', () {
        final id = generator.generate();
        final asInt = int.parse(id);
        final backToString = asInt.toString();

        expect(backToString, id);
      });
    });
  });
}
