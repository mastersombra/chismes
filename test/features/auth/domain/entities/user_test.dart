import 'package:chismes/features/auth/domain/entities/user.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('User', () {
    const tId = 'test-id-123';
    const tEmail = 'test@example.com';
    const tUsername = 'testuser';
    const tDisplayName = 'Test User';
    const tAvatarUrl = 'https://example.com/avatar.jpg';
    const tBio = 'Test bio';
    final tCreatedAt = DateTime(2024, 1, 1);
    final tUpdatedAt = DateTime(2024, 1, 15);

    group('constructor', () {
      test('debe crear User con todos los campos', () {
        // Act
        final user = User(
          id: tId,
          email: tEmail,
          emailVerified: true,
          username: tUsername,
          displayName: tDisplayName,
          avatarUrl: tAvatarUrl,
          bio: tBio,
          profileCompleted: true,
          createdAt: tCreatedAt,
          updatedAt: tUpdatedAt,
        );

        // Assert
        expect(user.id, tId);
        expect(user.email, tEmail);
        expect(user.username, tUsername);
        expect(user.displayName, tDisplayName);
        expect(user.avatarUrl, tAvatarUrl);
        expect(user.bio, tBio);
        expect(user.profileCompleted, true);
        expect(user.createdAt, tCreatedAt);
        expect(user.updatedAt, tUpdatedAt);
      });

      test('debe crear User con campos opcionales null', () {
        // Act
        final user = User(
          id: tId,
          email: tEmail,
          emailVerified: true,
          profileCompleted: false,
          createdAt: tCreatedAt,
        );

        // Assert
        expect(user.id, tId);
        expect(user.email, tEmail);
        expect(user.username, isNull);
        expect(user.displayName, isNull);
        expect(user.avatarUrl, isNull);
        expect(user.bio, isNull);
        expect(user.profileCompleted, false);
        expect(user.createdAt, tCreatedAt);
        expect(user.updatedAt, isNull);
      });
    });

    group('displayNameOrFallback', () {
      test('debe retornar displayName cuando existe', () {
        // Arrange
        final user = User(
          id: tId,
          email: tEmail,
          emailVerified: true,
          username: tUsername,
          displayName: tDisplayName,
          profileCompleted: true,
          createdAt: tCreatedAt,
        );

        // Act & Assert
        expect(user.displayNameOrFallback, tDisplayName);
      });

      test('debe retornar username con @ cuando displayName es null', () {
        // Arrange
        final user = User(
          id: tId,
          email: tEmail,
          emailVerified: true,
          username: tUsername,
          profileCompleted: false,
          createdAt: tCreatedAt,
        );

        // Act & Assert
        expect(user.displayNameOrFallback, '@$tUsername');
      });

      test('debe retornar email cuando displayName y username son null', () {
        // Arrange
        final user = User(
          id: tId,
          email: tEmail,
          emailVerified: true,
          profileCompleted: false,
          createdAt: tCreatedAt,
        );

        // Act & Assert
        expect(user.displayNameOrFallback, tEmail);
      });

      test('debe retornar username cuando displayName es empty string', () {
        // Arrange
        final user = User(
          id: tId,
          email: tEmail,
          emailVerified: true,
          username: tUsername,
          displayName: '', // Empty string
          profileCompleted: false,
          createdAt: tCreatedAt,
        );

        // Act & Assert
        expect(user.displayNameOrFallback, '@$tUsername');
      });

      test('debe retornar email cuando username es empty string', () {
        // Arrange
        final user = User(
          id: tId,
          email: tEmail,
          emailVerified: true,
          username: '', // Empty string
          profileCompleted: false,
          createdAt: tCreatedAt,
        );

        // Act & Assert
        expect(user.displayNameOrFallback, tEmail);
      });
    });

    group('hasUsername', () {
      test('debe retornar true cuando username existe y no está vacío', () {
        // Arrange
        final user = User(
          id: tId,
          email: tEmail,
          emailVerified: true,
          username: tUsername,
          profileCompleted: false,
          createdAt: tCreatedAt,
        );

        // Act & Assert
        expect(user.hasUsername, true);
      });

      test('debe retornar false cuando username es null', () {
        // Arrange
        final user = User(
          id: tId,
          email: tEmail,
          emailVerified: true,
          profileCompleted: false,
          createdAt: tCreatedAt,
        );

        // Act & Assert
        expect(user.hasUsername, false);
      });

      test('debe retornar false cuando username es empty string', () {
        // Arrange
        final user = User(
          id: tId,
          email: tEmail,
          emailVerified: true,
          username: '',
          profileCompleted: false,
          createdAt: tCreatedAt,
        );

        // Act & Assert
        expect(user.hasUsername, false);
      });
    });

    group('hasDisplayName', () {
      test('debe retornar true cuando displayName existe y no está vacío', () {
        // Arrange
        final user = User(
          id: tId,
          email: tEmail,
          emailVerified: true,
          displayName: tDisplayName,
          profileCompleted: false,
          createdAt: tCreatedAt,
        );

        // Act & Assert
        expect(user.hasDisplayName, true);
      });

      test('debe retornar false cuando displayName es null', () {
        // Arrange
        final user = User(
          id: tId,
          email: tEmail,
          emailVerified: true,
          profileCompleted: false,
          createdAt: tCreatedAt,
        );

        // Act & Assert
        expect(user.hasDisplayName, false);
      });

      test('debe retornar false cuando displayName es empty string', () {
        // Arrange
        final user = User(
          id: tId,
          email: tEmail,
          emailVerified: true,
          displayName: '',
          profileCompleted: false,
          createdAt: tCreatedAt,
        );

        // Act & Assert
        expect(user.hasDisplayName, false);
      });
    });

    group('hasAvatar', () {
      test('debe retornar true cuando avatarUrl existe y no está vacío', () {
        // Arrange
        final user = User(
          id: tId,
          email: tEmail,
          emailVerified: true,
          avatarUrl: tAvatarUrl,
          profileCompleted: false,
          createdAt: tCreatedAt,
        );

        // Act & Assert
        expect(user.hasAvatar, true);
      });

      test('debe retornar false cuando avatarUrl es null', () {
        // Arrange
        final user = User(
          id: tId,
          email: tEmail,
          emailVerified: true,
          profileCompleted: false,
          createdAt: tCreatedAt,
        );

        // Act & Assert
        expect(user.hasAvatar, false);
      });

      test('debe retornar false cuando avatarUrl es empty string', () {
        // Arrange
        final user = User(
          id: tId,
          email: tEmail,
          emailVerified: true,
          avatarUrl: '',
          profileCompleted: false,
          createdAt: tCreatedAt,
        );

        // Act & Assert
        expect(user.hasAvatar, false);
      });
    });

    group('profileCompletionPercentage', () {
      test('debe retornar 25% cuando solo tiene email', () {
        // Arrange
        final user = User(
          id: tId,
          email: tEmail,
          emailVerified: true,
          profileCompleted: false,
          createdAt: tCreatedAt,
        );

        // Act & Assert
        expect(user.profileCompletionPercentage, 25);
      });

      test('debe retornar 50% cuando tiene email + username', () {
        // Arrange
        final user = User(
          id: tId,
          email: tEmail,
          emailVerified: true,
          username: tUsername,
          profileCompleted: false,
          createdAt: tCreatedAt,
        );

        // Act & Assert
        expect(user.profileCompletionPercentage, 50);
      });

      test('debe retornar 75% cuando tiene email + username + displayName', () {
        // Arrange
        final user = User(
          id: tId,
          email: tEmail,
          emailVerified: true,
          username: tUsername,
          displayName: tDisplayName,
          profileCompleted: false,
          createdAt: tCreatedAt,
        );

        // Act & Assert
        expect(user.profileCompletionPercentage, 75);
      });

      test('debe retornar 100% cuando tiene todos los campos', () {
        // Arrange
        final user = User(
          id: tId,
          email: tEmail,
          emailVerified: true,
          username: tUsername,
          displayName: tDisplayName,
          avatarUrl: tAvatarUrl,
          profileCompleted: true,
          createdAt: tCreatedAt,
        );

        // Act & Assert
        expect(user.profileCompletionPercentage, 100);
      });

      test('debe retornar 50% cuando tiene email + displayName (sin username)',
          () {
        // Arrange
        final user = User(
          id: tId,
          email: tEmail,
          emailVerified: true,
          displayName: tDisplayName,
          profileCompleted: false,
          createdAt: tCreatedAt,
        );

        // Act & Assert
        expect(user.profileCompletionPercentage, 50);
      });

      test('debe retornar 50% cuando tiene email + avatar (sin username/displayName)',
          () {
        // Arrange
        final user = User(
          id: tId,
          email: tEmail,
          emailVerified: true,
          avatarUrl: tAvatarUrl,
          profileCompleted: false,
          createdAt: tCreatedAt,
        );

        // Act & Assert
        expect(user.profileCompletionPercentage, 50);
      });

      test('debe ignorar campos vacíos en el cálculo', () {
        // Arrange
        final user = User(
          id: tId,
          email: tEmail,
          emailVerified: true,
          username: '', // Empty
          displayName: '', // Empty
          avatarUrl: '', // Empty
          profileCompleted: false,
          createdAt: tCreatedAt,
        );

        // Act & Assert
        expect(user.profileCompletionPercentage, 25); // Solo email
      });
    });

    group('copyWith', () {
      test('debe crear copia con todos los campos actualizados', () {
        // Arrange
        final original = User(
          id: tId,
          email: tEmail,
          emailVerified: true,
          profileCompleted: false,
          createdAt: tCreatedAt,
        );

        // Act
        final updated = original.copyWith(
          id: 'new-id',
          email: 'new@example.com',
          emailVerified: true,
          username: tUsername,
          displayName: tDisplayName,
          avatarUrl: tAvatarUrl,
          bio: tBio,
          profileCompleted: true,
          createdAt: DateTime(2024, 2, 1),
          updatedAt: tUpdatedAt,
        );

        // Assert
        expect(updated.id, 'new-id');
        expect(updated.email, 'new@example.com');
        expect(updated.username, tUsername);
        expect(updated.displayName, tDisplayName);
        expect(updated.avatarUrl, tAvatarUrl);
        expect(updated.bio, tBio);
        expect(updated.profileCompleted, true);
        expect(updated.createdAt, DateTime(2024, 2, 1));
        expect(updated.updatedAt, tUpdatedAt);
      });

      test('debe mantener campos originales cuando no se especifican', () {
        // Arrange
        final original = User(
          id: tId,
          email: tEmail,
          emailVerified: true,
          username: tUsername,
          displayName: tDisplayName,
          avatarUrl: tAvatarUrl,
          bio: tBio,
          profileCompleted: true,
          createdAt: tCreatedAt,
          updatedAt: tUpdatedAt,
        );

        // Act
        final updated = original.copyWith(
          username: 'newusername',
        );

        // Assert
        expect(updated.id, tId);
        expect(updated.email, tEmail);
        expect(updated.username, 'newusername'); // Actualizado
        expect(updated.displayName, tDisplayName); // Original
        expect(updated.avatarUrl, tAvatarUrl); // Original
        expect(updated.bio, tBio); // Original
        expect(updated.profileCompleted, true); // Original
        expect(updated.createdAt, tCreatedAt); // Original
        expect(updated.updatedAt, tUpdatedAt); // Original
      });

      test('debe crear copia sin cambios cuando no se pasan parámetros', () {
        // Arrange
        final original = User(
          id: tId,
          email: tEmail,
          emailVerified: true,
          username: tUsername,
          profileCompleted: true,
          createdAt: tCreatedAt,
        );

        // Act
        final copy = original.copyWith();

        // Assert
        expect(copy.id, original.id);
        expect(copy.email, original.email);
        expect(copy.username, original.username);
        expect(copy.profileCompleted, original.profileCompleted);
        expect(copy.createdAt, original.createdAt);
      });
    });

    group('equality', () {
      test('debe ser igual cuando tienen el mismo id', () {
        // Arrange
        final user1 = User(
          id: tId,
          email: tEmail,
          emailVerified: true,
          username: tUsername,
          profileCompleted: true,
          createdAt: tCreatedAt,
        );

        final user2 = User(
          id: tId,
          email: 'different@example.com',
          emailVerified: true, // Email diferente
          username: 'different', // Username diferente
          profileCompleted: false, // Estado diferente
          createdAt: DateTime(2024, 2, 1), // Fecha diferente
        );

        // Act & Assert
        expect(user1 == user2, true);
        expect(user1.hashCode, user2.hashCode);
      });

      test('debe ser diferente cuando tienen distinto id', () {
        // Arrange
        final user1 = User(
          id: tId,
          email: tEmail,
          emailVerified: true,
          profileCompleted: true,
          createdAt: tCreatedAt,
        );

        final user2 = User(
          id: 'different-id',
          email: tEmail,
          emailVerified: true,
          profileCompleted: true,
          createdAt: tCreatedAt,
        );

        // Act & Assert
        expect(user1 == user2, false);
        expect(user1.hashCode, isNot(user2.hashCode));
      });

      test('debe ser igual a sí mismo (identical)', () {
        // Arrange
        final user = User(
          id: tId,
          email: tEmail,
          emailVerified: true,
          profileCompleted: true,
          createdAt: tCreatedAt,
        );

        // Act & Assert
        expect(user == user, true);
        expect(identical(user, user), true);
      });

      test('debe retornar false cuando se compara con objeto de diferente tipo',
          () {
        // Arrange
        final user = User(
          id: tId,
          email: tEmail,
          emailVerified: true,
          profileCompleted: true,
          createdAt: tCreatedAt,
        );
        final otherObject = Object();

        // Act & Assert
        expect(user == otherObject, false);
      });
    });

    group('toString', () {
      test('debe retornar string representation correcta', () {
        // Arrange
        final user = User(
          id: tId,
          email: tEmail,
          emailVerified: true,
          username: tUsername,
          displayName: tDisplayName,
          profileCompleted: true,
          createdAt: tCreatedAt,
        );

        // Act
        final result = user.toString();

        // Assert
        expect(result, contains('User'));
        expect(result, contains('id: $tId'));
        expect(result, contains('email: $tEmail'));
        expect(result, contains('username: $tUsername'));
        expect(result, contains('displayName: $tDisplayName'));
        expect(result, contains('profileCompleted: true'));
      });

      test('debe retornar string representation con campos null', () {
        // Arrange
        final user = User(
          id: tId,
          email: tEmail,
          emailVerified: true,
          profileCompleted: false,
          createdAt: tCreatedAt,
        );

        // Act
        final result = user.toString();

        // Assert
        expect(result, contains('User'));
        expect(result, contains('id: $tId'));
        expect(result, contains('email: $tEmail'));
        expect(result, contains('username: null'));
        expect(result, contains('displayName: null'));
        expect(result, contains('profileCompleted: false'));
      });
    });
  });
}
