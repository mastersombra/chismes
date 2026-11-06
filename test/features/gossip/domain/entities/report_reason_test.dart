import 'package:flutter_test/flutter_test.dart';
import 'package:chismes/features/gossip/domain/entities/report_reason.dart';

void main() {
  group('ReportReason', () {
    group('Valores del enum', () {
      test('spam debe tener valores correctos', () {
        // Act & Assert
        expect(ReportReason.spam.value, 'spam');
        expect(ReportReason.spam.displayName, 'Spam');
      });

      test('harassment debe tener valores correctos', () {
        // Act & Assert
        expect(ReportReason.harassment.value, 'harassment');
        expect(ReportReason.harassment.displayName, 'Acoso o intimidación');
      });

      test('violence debe tener valores correctos', () {
        // Act & Assert
        expect(ReportReason.violence.value, 'violence');
        expect(ReportReason.violence.displayName, 'Violencia o amenazas');
      });

      test('sexualContent debe tener valores correctos', () {
        // Act & Assert
        expect(ReportReason.sexualContent.value, 'sexual_content');
        expect(ReportReason.sexualContent.displayName, 'Contenido sexual');
      });

      test('misinformation debe tener valores correctos', () {
        // Act & Assert
        expect(ReportReason.misinformation.value, 'misinformation');
        expect(ReportReason.misinformation.displayName, 'Desinformación');
      });

      test('other debe tener valores correctos', () {
        // Act & Assert
        expect(ReportReason.other.value, 'other');
        expect(ReportReason.other.displayName, 'Otro motivo');
      });

      test('debe tener todos los valores esperados', () {
        // Act & Assert
        expect(ReportReason.values.length, 6);
        expect(ReportReason.values, contains(ReportReason.spam));
        expect(ReportReason.values, contains(ReportReason.harassment));
        expect(ReportReason.values, contains(ReportReason.violence));
        expect(ReportReason.values, contains(ReportReason.sexualContent));
        expect(ReportReason.values, contains(ReportReason.misinformation));
        expect(ReportReason.values, contains(ReportReason.other));
      });
    });

    group('fromValue', () {
      test('debe retornar spam para valor "spam"', () {
        // Act
        final result = ReportReason.fromValue('spam');

        // Assert
        expect(result, ReportReason.spam);
      });

      test('debe retornar harassment para valor "harassment"', () {
        // Act
        final result = ReportReason.fromValue('harassment');

        // Assert
        expect(result, ReportReason.harassment);
      });

      test('debe retornar violence para valor "violence"', () {
        // Act
        final result = ReportReason.fromValue('violence');

        // Assert
        expect(result, ReportReason.violence);
      });

      test('debe retornar sexualContent para valor "sexual_content"', () {
        // Act
        final result = ReportReason.fromValue('sexual_content');

        // Assert
        expect(result, ReportReason.sexualContent);
      });

      test('debe retornar misinformation para valor "misinformation"', () {
        // Act
        final result = ReportReason.fromValue('misinformation');

        // Assert
        expect(result, ReportReason.misinformation);
      });

      test('debe retornar other para valor "other"', () {
        // Act
        final result = ReportReason.fromValue('other');

        // Assert
        expect(result, ReportReason.other);
      });

      test('debe retornar other para valor desconocido', () {
        // Act
        final result = ReportReason.fromValue('unknown');

        // Assert
        expect(result, ReportReason.other);
      });

      test('debe retornar other para valor vacío', () {
        // Act
        final result = ReportReason.fromValue('');

        // Assert
        expect(result, ReportReason.other);
      });

      test('debe retornar other para valor con mayúsculas', () {
        // Act
        final result = ReportReason.fromValue('SPAM');

        // Assert - Es case-sensitive, así que retorna other
        expect(result, ReportReason.other);
      });
    });

    group('Conversión bidireccional', () {
      test('todos los valores deben ser recuperables con fromValue', () {
        // Arrange & Act & Assert - Verifica que fromValue(reason.value) == reason
        for (final reason in ReportReason.values) {
          final recovered = ReportReason.fromValue(reason.value);
          expect(recovered, reason,
              reason: 'fromValue("${reason.value}") debe retornar $reason');
        }
      });

      test('los valores deben ser únicos', () {
        // Arrange
        final values = ReportReason.values.map((r) => r.value).toList();

        // Act
        final uniqueValues = values.toSet();

        // Assert
        expect(uniqueValues.length, values.length,
            reason: 'Todos los valores deben ser únicos');
      });
    });

    group('Casos de uso', () {
      test('debe poder usarse en un switch statement', () {
        // Arrange
        final reason = ReportReason.spam;
        String message = '';

        // Act
        switch (reason) {
          case ReportReason.spam:
            message = 'Spam detectado';
            break;
          case ReportReason.harassment:
            message = 'Acoso detectado';
            break;
          case ReportReason.violence:
            message = 'Violencia detectada';
            break;
          case ReportReason.sexualContent:
            message = 'Contenido sexual detectado';
            break;
          case ReportReason.misinformation:
            message = 'Desinformación detectada';
            break;
          case ReportReason.other:
            message = 'Otro motivo';
            break;
        }

        // Assert
        expect(message, 'Spam detectado');
      });

      test('displayName debe ser útil para mostrar al usuario', () {
        // Act & Assert - Todos los displayName deben ser no vacíos y legibles
        for (final reason in ReportReason.values) {
          expect(reason.displayName.isNotEmpty, isTrue,
              reason: '${reason.name} debe tener displayName no vacío');
          expect(reason.displayName.length, greaterThan(3),
              reason: '${reason.name} debe tener displayName descriptivo');
        }
      });

      test('value debe ser útil para serialización', () {
        // Act & Assert - Todos los values deben ser snake_case o lowercase
        for (final reason in ReportReason.values) {
          expect(reason.value.isNotEmpty, isTrue,
              reason: '${reason.name} debe tener value no vacío');
          expect(reason.value, isNot(contains(' ')),
              reason: '${reason.name}.value no debe contener espacios');
          expect(reason.value, isNot(contains(RegExp(r'[A-Z]'))),
              reason: '${reason.name}.value debe ser lowercase');
        }
      });
    });
  });
}
