import 'package:chismes/core/services/profile_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late ProfileService service;

  setUp(() {
    service = ProfileService();
  });

  group('ProfileService', () {
    group('getFollowingCount', () {
      test('debe retornar placeholder value de 5', () async {
        // Arrange
        const userId = 'test-user-id';

        // Act
        final result = await service.getFollowingCount(userId);

        // Assert
        expect(result, 5);
      });

      test('debe retornar el mismo valor para diferentes userIds', () async {
        // Arrange
        const userId1 = 'user-1';
        const userId2 = 'user-2';

        // Act
        final result1 = await service.getFollowingCount(userId1);
        final result2 = await service.getFollowingCount(userId2);

        // Assert
        expect(result1, result2);
        expect(result1, 5);
      });

      test('debe retornar un valor no negativo', () async {
        // Arrange
        const userId = 'test-user-id';

        // Act
        final result = await service.getFollowingCount(userId);

        // Assert
        expect(result, greaterThanOrEqualTo(0));
      });
    });

    group('getFollowersCount', () {
      test('debe retornar placeholder value de 0', () async {
        // Arrange
        const userId = 'test-user-id';

        // Act
        final result = await service.getFollowersCount(userId);

        // Assert
        expect(result, 0);
      });

      test('debe retornar el mismo valor para diferentes userIds', () async {
        // Arrange
        const userId1 = 'user-1';
        const userId2 = 'user-2';

        // Act
        final result1 = await service.getFollowersCount(userId1);
        final result2 = await service.getFollowersCount(userId2);

        // Assert
        expect(result1, result2);
        expect(result1, 0);
      });

      test('debe retornar un valor no negativo', () async {
        // Arrange
        const userId = 'test-user-id';

        // Act
        final result = await service.getFollowersCount(userId);

        // Assert
        expect(result, greaterThanOrEqualTo(0));
      });
    });

    group('Integration', () {
      test('followingCount debe ser mayor o igual a followersCount en placeholder', () async {
        // Arrange
        const userId = 'test-user-id';

        // Act
        final following = await service.getFollowingCount(userId);
        final followers = await service.getFollowersCount(userId);

        // Assert
        expect(following, greaterThanOrEqualTo(followers));
      });

      test('debe completar ambas llamadas rápidamente', () async {
        // Arrange
        const userId = 'test-user-id';
        final stopwatch = Stopwatch()..start();

        // Act
        await service.getFollowingCount(userId);
        await service.getFollowersCount(userId);
        stopwatch.stop();

        // Assert
        expect(stopwatch.elapsedMilliseconds, lessThan(100));
      });
    });
  });
}
