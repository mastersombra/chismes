import 'package:flutter_test/flutter_test.dart';
import 'package:chismes/features/profile/domain/entities/user_stats.dart';

void main() {
  group('UserStats', () {
    const testStats = UserStats(
      gossipsCount: 10,
      commentsCount: 25,
      followersCount: 100,
      followingCount: 50,
      lastActivityAt: null,
    );

    final testStatsWithDate = UserStats(
      gossipsCount: 5,
      commentsCount: 15,
      followersCount: 75,
      followingCount: 30,
      lastActivityAt: DateTime(2024, 1, 1),
    );

    group('Constructor', () {
      test('debe crear instancia con valores requeridos', () {
        // Arrange & Act
        const stats = UserStats(
          gossipsCount: 1,
          commentsCount: 2,
          followersCount: 3,
          followingCount: 4,
        );

        // Assert
        expect(stats.gossipsCount, 1);
        expect(stats.commentsCount, 2);
        expect(stats.followersCount, 3);
        expect(stats.followingCount, 4);
        expect(stats.lastActivityAt, isNull);
      });

      test('debe crear instancia con lastActivityAt opcional', () {
        // Arrange
        final date = DateTime(2024, 1, 1);

        // Act
        final stats = UserStats(
          gossipsCount: 1,
          commentsCount: 2,
          followersCount: 3,
          followingCount: 4,
          lastActivityAt: date,
        );

        // Assert
        expect(stats.lastActivityAt, date);
      });

      test('debe ser const constructor', () {
        // Act & Assert
        const stats = UserStats(
          gossipsCount: 0,
          commentsCount: 0,
          followersCount: 0,
          followingCount: 0,
        );

        expect(stats, isA<UserStats>());
      });

      test('debe permitir valores en 0', () {
        // Act
        const stats = UserStats(
          gossipsCount: 0,
          commentsCount: 0,
          followersCount: 0,
          followingCount: 0,
        );

        // Assert
        expect(stats.gossipsCount, 0);
        expect(stats.commentsCount, 0);
        expect(stats.followersCount, 0);
        expect(stats.followingCount, 0);
      });

      test('debe permitir valores grandes', () {
        // Act
        const stats = UserStats(
          gossipsCount: 999999,
          commentsCount: 888888,
          followersCount: 777777,
          followingCount: 666666,
        );

        // Assert
        expect(stats.gossipsCount, 999999);
        expect(stats.commentsCount, 888888);
        expect(stats.followersCount, 777777);
        expect(stats.followingCount, 666666);
      });
    });

    group('copyWith', () {
      test('debe retornar copia con gossipsCount modificado', () {
        // Act
        final copy = testStats.copyWith(gossipsCount: 20);

        // Assert
        expect(copy.gossipsCount, 20);
        expect(copy.commentsCount, testStats.commentsCount);
        expect(copy.followersCount, testStats.followersCount);
        expect(copy.followingCount, testStats.followingCount);
      });

      test('debe retornar copia con commentsCount modificado', () {
        // Act
        final copy = testStats.copyWith(commentsCount: 50);

        // Assert
        expect(copy.commentsCount, 50);
        expect(copy.gossipsCount, testStats.gossipsCount);
      });

      test('debe retornar copia con followersCount modificado', () {
        // Act
        final copy = testStats.copyWith(followersCount: 200);

        // Assert
        expect(copy.followersCount, 200);
        expect(copy.gossipsCount, testStats.gossipsCount);
      });

      test('debe retornar copia con followingCount modificado', () {
        // Act
        final copy = testStats.copyWith(followingCount: 75);

        // Assert
        expect(copy.followingCount, 75);
        expect(copy.gossipsCount, testStats.gossipsCount);
      });

      test('debe retornar copia con lastActivityAt modificado', () {
        // Arrange
        final newDate = DateTime(2024, 6, 15);

        // Act
        final copy = testStats.copyWith(lastActivityAt: newDate);

        // Assert
        expect(copy.lastActivityAt, newDate);
        expect(copy.gossipsCount, testStats.gossipsCount);
      });

      test('debe retornar copia con múltiples campos modificados', () {
        // Act
        final copy = testStats.copyWith(
          gossipsCount: 30,
          followersCount: 150,
        );

        // Assert
        expect(copy.gossipsCount, 30);
        expect(copy.followersCount, 150);
        expect(copy.commentsCount, testStats.commentsCount);
        expect(copy.followingCount, testStats.followingCount);
      });

      test('debe retornar copia idéntica sin parámetros', () {
        // Act
        final copy = testStats.copyWith();

        // Assert
        expect(copy.gossipsCount, testStats.gossipsCount);
        expect(copy.commentsCount, testStats.commentsCount);
        expect(copy.followersCount, testStats.followersCount);
        expect(copy.followingCount, testStats.followingCount);
        expect(copy.lastActivityAt, testStats.lastActivityAt);
      });

      test('debe mantener valores originales cuando null es pasado', () {
        // Act
        final copy = testStatsWithDate.copyWith();

        // Assert
        expect(copy.lastActivityAt, testStatsWithDate.lastActivityAt);
      });
    });

    group('toString', () {
      test('debe retornar string con formato correcto', () {
        // Act
        final result = testStats.toString();

        // Assert
        expect(result, contains('UserStats'));
        expect(result, contains('gossips: 10'));
        expect(result, contains('comments: 25'));
        expect(result, contains('followers: 100'));
        expect(result, contains('following: 50'));
      });

      test('debe incluir todos los counts', () {
        // Act
        final result = testStats.toString();

        // Assert
        expect(result, contains('10')); // gossipsCount
        expect(result, contains('25')); // commentsCount
        expect(result, contains('100')); // followersCount
        expect(result, contains('50')); // followingCount
      });

      test('debe tener formato consistente', () {
        // Arrange
        const stats = UserStats(
          gossipsCount: 1,
          commentsCount: 2,
          followersCount: 3,
          followingCount: 4,
        );

        // Act
        final result = stats.toString();

        // Assert
        expect(
          result,
          'UserStats(gossips: 1, comments: 2, followers: 3, following: 4)',
        );
      });
    });

    group('Getters', () {
      test('gossipsCount debe ser final', () {
        // Assert
        expect(testStats.gossipsCount, isA<int>());
        expect(testStats.gossipsCount, 10);
      });

      test('commentsCount debe ser final', () {
        // Assert
        expect(testStats.commentsCount, isA<int>());
        expect(testStats.commentsCount, 25);
      });

      test('followersCount debe ser final', () {
        // Assert
        expect(testStats.followersCount, isA<int>());
        expect(testStats.followersCount, 100);
      });

      test('followingCount debe ser final', () {
        // Assert
        expect(testStats.followingCount, isA<int>());
        expect(testStats.followingCount, 50);
      });

      test('lastActivityAt debe ser final y nullable', () {
        // Assert
        expect(testStats.lastActivityAt, isNull);
        expect(testStatsWithDate.lastActivityAt, isA<DateTime>());
      });
    });

    group('Edge Cases', () {
      test('debe manejar valores negativos (si se pasan)', () {
        // Act
        const stats = UserStats(
          gossipsCount: -1,
          commentsCount: -2,
          followersCount: -3,
          followingCount: -4,
        );

        // Assert
        expect(stats.gossipsCount, -1);
        expect(stats.commentsCount, -2);
      });

      test('debe manejar todos los valores en 0', () {
        // Act
        const stats = UserStats(
          gossipsCount: 0,
          commentsCount: 0,
          followersCount: 0,
          followingCount: 0,
        );

        // Assert
        expect(stats.gossipsCount, 0);
        expect(stats.commentsCount, 0);
        expect(stats.followersCount, 0);
        expect(stats.followingCount, 0);
      });

      test('copyWith debe poder cambiar a 0', () {
        // Act
        final copy = testStats.copyWith(gossipsCount: 0);

        // Assert
        expect(copy.gossipsCount, 0);
      });

      test('lastActivityAt puede ser null en constructor', () {
        // Act
        const stats = UserStats(
          gossipsCount: 1,
          commentsCount: 1,
          followersCount: 1,
          followingCount: 1,
          lastActivityAt: null,
        );

        // Assert
        expect(stats.lastActivityAt, isNull);
      });

      test('copyWith con null mantiene valor original (no setea a null)', () {
        // Act
        final copy = testStatsWithDate.copyWith(lastActivityAt: null);

        // Assert
        // copyWith usa ?? operator, por lo que null mantiene el valor original
        expect(copy.lastActivityAt, testStatsWithDate.lastActivityAt);
      });
    });

    group('Immutability', () {
      test('copyWith debe crear nueva instancia', () {
        // Act
        final copy = testStats.copyWith(gossipsCount: 20);

        // Assert
        expect(identical(copy, testStats), isFalse);
        expect(copy.gossipsCount, isNot(testStats.gossipsCount));
      });

      test('campos deben ser final (no modificables)', () {
        // Assert - Si compila, los campos son final
        expect(testStats.gossipsCount, 10);
        // No hay forma de modificar testStats.gossipsCount después de creación
      });
    });
  });
}
