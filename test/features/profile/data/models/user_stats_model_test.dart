import 'package:flutter_test/flutter_test.dart';
import 'package:chismes/features/profile/data/models/user_stats_model.dart';
import 'package:chismes/features/profile/domain/entities/user_stats.dart';

void main() {
  group('UserStatsModel', () {
    const tUserStatsModel = UserStatsModel(
      gossipsCount: 42,
      commentsCount: 15,
      followersCount: 100,
      followingCount: 75,
      lastActivityAt: '2024-01-15T10:30:00Z',
    );

    const tUserStatsModelWithoutActivity = UserStatsModel(
      gossipsCount: 10,
      commentsCount: 5,
      followersCount: 20,
      followingCount: 15,
      lastActivityAt: null,
    );

    group('fromJson', () {
      test('debe crear modelo válido desde JSON completo', () {
        // Arrange
        final json = {
          'gossips_count': 42,
          'comments_count': 15,
          'followers_count': 100,
          'following_count': 75,
          'last_activity_at': '2024-01-15T10:30:00Z',
        };

        // Act
        final result = UserStatsModel.fromJson(json);

        // Assert
        expect(result.gossipsCount, 42);
        expect(result.commentsCount, 15);
        expect(result.followersCount, 100);
        expect(result.followingCount, 75);
        expect(result.lastActivityAt, '2024-01-15T10:30:00Z');
      });

      test('debe usar valores por defecto cuando campos son null', () {
        // Arrange
        final json = <String, dynamic>{
          'last_activity_at': null,
        };

        // Act
        final result = UserStatsModel.fromJson(json);

        // Assert
        expect(result.gossipsCount, 0);
        expect(result.commentsCount, 0);
        expect(result.followersCount, 0);
        expect(result.followingCount, 0);
        expect(result.lastActivityAt, null);
      });

      test('debe manejar JSON con campos faltantes', () {
        // Arrange
        final json = <String, dynamic>{};

        // Act
        final result = UserStatsModel.fromJson(json);

        // Assert
        expect(result.gossipsCount, 0);
        expect(result.commentsCount, 0);
        expect(result.followersCount, 0);
        expect(result.followingCount, 0);
        expect(result.lastActivityAt, null);
      });

      test('debe manejar last_activity_at como null explícito', () {
        // Arrange
        final json = {
          'gossips_count': 5,
          'comments_count': 2,
          'followers_count': 10,
          'following_count': 8,
          'last_activity_at': null,
        };

        // Act
        final result = UserStatsModel.fromJson(json);

        // Assert
        expect(result.lastActivityAt, null);
      });
    });

    group('toJson', () {
      test('debe convertir modelo a JSON correctamente', () {
        // Act
        final json = tUserStatsModel.toJson();

        // Assert
        expect(json, {
          'gossips_count': 42,
          'comments_count': 15,
          'followers_count': 100,
          'following_count': 75,
          'last_activity_at': '2024-01-15T10:30:00Z',
        });
      });

      test('debe convertir modelo sin lastActivityAt a JSON', () {
        // Act
        final json = tUserStatsModelWithoutActivity.toJson();

        // Assert
        expect(json, {
          'gossips_count': 10,
          'comments_count': 5,
          'followers_count': 20,
          'following_count': 15,
          'last_activity_at': null,
        });
      });

      test('debe mantener estructura de datos correcta', () {
        // Act
        final json = tUserStatsModel.toJson();

        // Assert
        expect(json.keys.length, 5);
        expect(json, containsPair('gossips_count', isA<int>()));
        expect(json, containsPair('comments_count', isA<int>()));
        expect(json, containsPair('followers_count', isA<int>()));
        expect(json, containsPair('following_count', isA<int>()));
      });
    });

    group('toEntity', () {
      test('debe convertir modelo a entidad correctamente', () {
        // Act
        final entity = tUserStatsModel.toEntity();

        // Assert
        expect(entity, isA<UserStats>());
        expect(entity.gossipsCount, 42);
        expect(entity.commentsCount, 15);
        expect(entity.followersCount, 100);
        expect(entity.followingCount, 75);
        expect(entity.lastActivityAt, DateTime.parse('2024-01-15T10:30:00Z'));
      });

      test('debe convertir modelo sin lastActivityAt a entidad', () {
        // Act
        final entity = tUserStatsModelWithoutActivity.toEntity();

        // Assert
        expect(entity, isA<UserStats>());
        expect(entity.gossipsCount, 10);
        expect(entity.commentsCount, 5);
        expect(entity.followersCount, 20);
        expect(entity.followingCount, 15);
        expect(entity.lastActivityAt, null);
      });

      test('debe parsear correctamente fecha ISO 8601', () {
        // Arrange
        const model = UserStatsModel(
          gossipsCount: 1,
          commentsCount: 1,
          followersCount: 1,
          followingCount: 1,
          lastActivityAt: '2024-12-31T23:59:59.999Z',
        );

        // Act
        final entity = model.toEntity();

        // Assert
        expect(entity.lastActivityAt, isNotNull);
        expect(entity.lastActivityAt!.year, 2024);
        expect(entity.lastActivityAt!.month, 12);
        expect(entity.lastActivityAt!.day, 31);
      });
    });

    group('Serialización roundtrip', () {
      test('debe mantener datos después de JSON roundtrip', () {
        // Act
        final json = tUserStatsModel.toJson();
        final restored = UserStatsModel.fromJson(json);

        // Assert
        expect(restored.gossipsCount, tUserStatsModel.gossipsCount);
        expect(restored.commentsCount, tUserStatsModel.commentsCount);
        expect(restored.followersCount, tUserStatsModel.followersCount);
        expect(restored.followingCount, tUserStatsModel.followingCount);
        expect(restored.lastActivityAt, tUserStatsModel.lastActivityAt);
      });

      test('debe mantener null en lastActivityAt después de roundtrip', () {
        // Act
        final json = tUserStatsModelWithoutActivity.toJson();
        final restored = UserStatsModel.fromJson(json);

        // Assert
        expect(restored.lastActivityAt, null);
      });
    });

    group('Edge cases', () {
      test('debe manejar contadores en cero', () {
        // Arrange
        const model = UserStatsModel(
          gossipsCount: 0,
          commentsCount: 0,
          followersCount: 0,
          followingCount: 0,
          lastActivityAt: null,
        );

        // Act
        final entity = model.toEntity();

        // Assert
        expect(entity.gossipsCount, 0);
        expect(entity.commentsCount, 0);
        expect(entity.followersCount, 0);
        expect(entity.followingCount, 0);
      });

      test('debe manejar números grandes', () {
        // Arrange
        const model = UserStatsModel(
          gossipsCount: 999999,
          commentsCount: 888888,
          followersCount: 777777,
          followingCount: 666666,
          lastActivityAt: null,
        );

        // Act
        final json = model.toJson();
        final restored = UserStatsModel.fromJson(json);

        // Assert
        expect(restored.gossipsCount, 999999);
        expect(restored.commentsCount, 888888);
        expect(restored.followersCount, 777777);
        expect(restored.followingCount, 666666);
      });
    });
  });
}
