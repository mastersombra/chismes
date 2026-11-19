import 'package:flutter_test/flutter_test.dart';
import 'package:chismes/core/logging/log_level.dart';

void main() {
  group('LogLevel', () {
    group('Enum Values', () {
      test('debe tener 5 valores', () {
        // Assert
        expect(LogLevel.values.length, 5);
      });

      test('debe tener valor debug', () {
        // Assert
        expect(LogLevel.debug, isA<LogLevel>());
        expect(LogLevel.debug.value, 'debug');
      });

      test('debe tener valor info', () {
        // Assert
        expect(LogLevel.info, isA<LogLevel>());
        expect(LogLevel.info.value, 'info');
      });

      test('debe tener valor warning', () {
        // Assert
        expect(LogLevel.warning, isA<LogLevel>());
        expect(LogLevel.warning.value, 'warning');
      });

      test('debe tener valor error', () {
        // Assert
        expect(LogLevel.error, isA<LogLevel>());
        expect(LogLevel.error.value, 'error');
      });

      test('debe tener valor fatal', () {
        // Assert
        expect(LogLevel.fatal, isA<LogLevel>());
        expect(LogLevel.fatal.value, 'fatal');
      });

      test('values debe contener todos los niveles en orden', () {
        // Assert
        expect(LogLevel.values, [
          LogLevel.debug,
          LogLevel.info,
          LogLevel.warning,
          LogLevel.error,
          LogLevel.fatal,
        ]);
      });
    });

    group('fromString', () {
      test('debe convertir "debug" a LogLevel.debug', () {
        // Act
        final result = LogLevel.fromString('debug');

        // Assert
        expect(result, LogLevel.debug);
      });

      test('debe convertir "info" a LogLevel.info', () {
        // Act
        final result = LogLevel.fromString('info');

        // Assert
        expect(result, LogLevel.info);
      });

      test('debe convertir "warning" a LogLevel.warning', () {
        // Act
        final result = LogLevel.fromString('warning');

        // Assert
        expect(result, LogLevel.warning);
      });

      test('debe convertir "error" a LogLevel.error', () {
        // Act
        final result = LogLevel.fromString('error');

        // Assert
        expect(result, LogLevel.error);
      });

      test('debe convertir "fatal" a LogLevel.fatal', () {
        // Act
        final result = LogLevel.fromString('fatal');

        // Assert
        expect(result, LogLevel.fatal);
      });

      test('debe retornar info para string inválido', () {
        // Act
        final result = LogLevel.fromString('invalid');

        // Assert
        expect(result, LogLevel.info);
      });

      test('debe retornar info para string vacío', () {
        // Act
        final result = LogLevel.fromString('');

        // Assert
        expect(result, LogLevel.info);
      });

      test('debe retornar info para string con mayúsculas', () {
        // Act
        final result = LogLevel.fromString('DEBUG');

        // Assert
        expect(result, LogLevel.info);
      });

      test('debe ser case-sensitive', () {
        // Act & Assert
        expect(LogLevel.fromString('Error'), LogLevel.info);
        expect(LogLevel.fromString('ERROR'), LogLevel.info);
        expect(LogLevel.fromString('error'), LogLevel.error);
      });
    });

    group('shouldPersist', () {
      test('debug NO debe persistir', () {
        // Assert
        expect(LogLevel.debug.shouldPersist, isFalse);
      });

      test('info NO debe persistir', () {
        // Assert
        expect(LogLevel.info.shouldPersist, isFalse);
      });

      test('warning NO debe persistir', () {
        // Assert
        expect(LogLevel.warning.shouldPersist, isFalse);
      });

      test('error SI debe persistir', () {
        // Assert
        expect(LogLevel.error.shouldPersist, isTrue);
      });

      test('fatal SI debe persistir', () {
        // Assert
        expect(LogLevel.fatal.shouldPersist, isTrue);
      });

      test('solo error y fatal deben persistir', () {
        // Arrange
        final shouldPersist = LogLevel.values
            .where((level) => level.shouldPersist)
            .toList();

        // Assert
        expect(shouldPersist, [LogLevel.error, LogLevel.fatal]);
      });

      test('debug, info y warning NO deben persistir', () {
        // Arrange
        final shouldNotPersist = LogLevel.values
            .where((level) => !level.shouldPersist)
            .toList();

        // Assert
        expect(shouldNotPersist, [
          LogLevel.debug,
          LogLevel.info,
          LogLevel.warning,
        ]);
      });
    });

    group('emoji', () {
      test('debug debe tener emoji 🔍', () {
        // Assert
        expect(LogLevel.debug.emoji, '🔍');
      });

      test('info debe tener emoji ℹ️', () {
        // Assert
        expect(LogLevel.info.emoji, 'ℹ️');
      });

      test('warning debe tener emoji ⚠️', () {
        // Assert
        expect(LogLevel.warning.emoji, '⚠️');
      });

      test('error debe tener emoji ❌', () {
        // Assert
        expect(LogLevel.error.emoji, '❌');
      });

      test('fatal debe tener emoji 💥', () {
        // Assert
        expect(LogLevel.fatal.emoji, '💥');
      });

      test('todos los niveles deben tener emoji único', () {
        // Arrange
        final emojis = LogLevel.values.map((level) => level.emoji).toList();
        final uniqueEmojis = emojis.toSet();

        // Assert
        expect(uniqueEmojis.length, emojis.length);
      });

      test('todos los emojis deben ser non-empty', () {
        // Assert
        for (final level in LogLevel.values) {
          expect(level.emoji.isNotEmpty, isTrue);
        }
      });
    });

    group('value Field', () {
      test('debug.value debe ser "debug"', () {
        // Assert
        expect(LogLevel.debug.value, 'debug');
      });

      test('info.value debe ser "info"', () {
        // Assert
        expect(LogLevel.info.value, 'info');
      });

      test('warning.value debe ser "warning"', () {
        // Assert
        expect(LogLevel.warning.value, 'warning');
      });

      test('error.value debe ser "error"', () {
        // Assert
        expect(LogLevel.error.value, 'error');
      });

      test('fatal.value debe ser "fatal"', () {
        // Assert
        expect(LogLevel.fatal.value, 'fatal');
      });

      test('value debe ser final', () {
        // Assert - Si compila, value es final
        expect(LogLevel.debug.value, isA<String>());
      });
    });

    group('Integration', () {
      test('fromString debe ser inverso de value', () {
        // Assert
        for (final level in LogLevel.values) {
          expect(LogLevel.fromString(level.value), level);
        }
      });

      test('debe poder usar en switch statement', () {
        // Arrange
        final level = LogLevel.error;
        String result;

        // Act
        switch (level) {
          case LogLevel.debug:
            result = 'debug';
            break;
          case LogLevel.info:
            result = 'info';
            break;
          case LogLevel.warning:
            result = 'warning';
            break;
          case LogLevel.error:
            result = 'error';
            break;
          case LogLevel.fatal:
            result = 'fatal';
            break;
        }

        // Assert
        expect(result, 'error');
      });

      test('debe poder comparar con ==', () {
        // Assert
        expect(LogLevel.debug == LogLevel.debug, isTrue);
        expect(LogLevel.debug == LogLevel.info, isFalse);
      });

      test('debe tener orden correcto de severidad', () {
        // Assert - debug es el menos severo, fatal el más severo
        expect(LogLevel.debug.index < LogLevel.info.index, isTrue);
        expect(LogLevel.info.index < LogLevel.warning.index, isTrue);
        expect(LogLevel.warning.index < LogLevel.error.index, isTrue);
        expect(LogLevel.error.index < LogLevel.fatal.index, isTrue);
      });
    });
  });
}
