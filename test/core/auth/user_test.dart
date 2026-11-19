import 'package:flutter_test/flutter_test.dart';
import 'package:chismes/core/auth/user.dart';

void main() {
  group('User', () {
    group('Constructor', () {
      test('debe crear instancia con campos requeridos', () {
        // Act
        const user = User(
          id: 'user123',
          email: 'test@example.com',
        );

        // Assert
        expect(user.id, equals('user123'));
        expect(user.email, equals('test@example.com'));
        expect(user.displayName, isNull);
        expect(user.photoUrl, isNull);
      });

      test('debe crear instancia con todos los campos', () {
        // Act
        const user = User(
          id: 'user123',
          email: 'test@example.com',
          displayName: 'John Doe',
          photoUrl: 'https://example.com/photo.jpg',
        );

        // Assert
        expect(user.id, equals('user123'));
        expect(user.email, equals('test@example.com'));
        expect(user.displayName, equals('John Doe'));
        expect(user.photoUrl, equals('https://example.com/photo.jpg'));
      });

      test('debe ser const constructor', () {
        // Arrange & Act
        const user1 = User(id: 'user123', email: 'test@example.com');
        const user2 = User(id: 'user123', email: 'test@example.com');

        // Assert
        expect(identical(user1, user2), isTrue);
      });

      test('debe permitir displayName null', () {
        // Act
        const user = User(
          id: 'user123',
          email: 'test@example.com',
          displayName: null,
        );

        // Assert
        expect(user.displayName, isNull);
      });

      test('debe permitir photoUrl null', () {
        // Act
        const user = User(
          id: 'user123',
          email: 'test@example.com',
          photoUrl: null,
        );

        // Assert
        expect(user.photoUrl, isNull);
      });
    });

    group('Equality', () {
      test('debe ser igual si tienen el mismo id', () {
        // Arrange
        const user1 = User(
          id: 'user123',
          email: 'test1@example.com',
          displayName: 'John',
        );
        const user2 = User(
          id: 'user123',
          email: 'test2@example.com',
          displayName: 'Jane',
        );

        // Assert
        expect(user1, equals(user2));
      });

      test('debe ser diferente si tienen distinto id', () {
        // Arrange
        const user1 = User(
          id: 'user123',
          email: 'test@example.com',
        );
        const user2 = User(
          id: 'user456',
          email: 'test@example.com',
        );

        // Assert
        expect(user1, isNot(equals(user2)));
      });

      test('debe ser igual a sí mismo', () {
        // Arrange
        const user = User(
          id: 'user123',
          email: 'test@example.com',
        );

        // Assert
        expect(user, equals(user));
        expect(identical(user, user), isTrue);
      });

      test('debe manejar comparación con null', () {
        // Arrange
        const user = User(
          id: 'user123',
          email: 'test@example.com',
        );
        const User? nullUser = null;

        // Assert
        expect(user == nullUser, isFalse);
      });

      test('debe manejar comparación con otro tipo', () {
        // Arrange
        const user = User(
          id: 'user123',
          email: 'test@example.com',
        );
        const Object other = 'not a user';

        // Assert
        expect(user == other, isFalse);
      });
    });

    group('hashCode', () {
      test('debe ser igual para usuarios con mismo id', () {
        // Arrange
        const user1 = User(
          id: 'user123',
          email: 'test1@example.com',
        );
        const user2 = User(
          id: 'user123',
          email: 'test2@example.com',
        );

        // Assert
        expect(user1.hashCode, equals(user2.hashCode));
      });

      test('debe ser diferente para usuarios con distinto id', () {
        // Arrange
        const user1 = User(
          id: 'user123',
          email: 'test@example.com',
        );
        const user2 = User(
          id: 'user456',
          email: 'test@example.com',
        );

        // Assert
        expect(user1.hashCode, isNot(equals(user2.hashCode)));
      });

      test('debe ser consistente', () {
        // Arrange
        const user = User(
          id: 'user123',
          email: 'test@example.com',
        );

        // Act
        final hash1 = user.hashCode;
        final hash2 = user.hashCode;

        // Assert
        expect(hash1, equals(hash2));
      });

      test('debe basarse en el id', () {
        // Arrange
        const user = User(
          id: 'user123',
          email: 'test@example.com',
        );

        // Assert
        expect(user.hashCode, equals('user123'.hashCode));
      });
    });

    group('toString', () {
      test('debe incluir id, email y displayName', () {
        // Arrange
        const user = User(
          id: 'user123',
          email: 'test@example.com',
          displayName: 'John Doe',
        );

        // Act
        final string = user.toString();

        // Assert
        expect(string, contains('User'));
        expect(string, contains('user123'));
        expect(string, contains('test@example.com'));
        expect(string, contains('John Doe'));
      });

      test('debe incluir null displayName', () {
        // Arrange
        const user = User(
          id: 'user123',
          email: 'test@example.com',
        );

        // Act
        final string = user.toString();

        // Assert
        expect(string, contains('User'));
        expect(string, contains('user123'));
        expect(string, contains('test@example.com'));
        expect(string, contains('null'));
      });

      test('debe tener formato User(id: ..., email: ..., displayName: ...)', () {
        // Arrange
        const user = User(
          id: 'user123',
          email: 'test@example.com',
          displayName: 'John Doe',
        );

        // Act
        final string = user.toString();

        // Assert
        expect(string, equals('User(id: user123, email: test@example.com, displayName: John Doe)'));
      });
    });

    group('Fields', () {
      test('id debe ser final', () {
        // Arrange
        const user = User(
          id: 'user123',
          email: 'test@example.com',
        );

        // Assert
        expect(user.id, isA<String>());
        // No se puede cambiar porque es final
      });

      test('email debe ser final', () {
        // Arrange
        const user = User(
          id: 'user123',
          email: 'test@example.com',
        );

        // Assert
        expect(user.email, isA<String>());
      });

      test('displayName debe ser nullable', () {
        // Arrange
        const user1 = User(
          id: 'user123',
          email: 'test@example.com',
        );
        const user2 = User(
          id: 'user123',
          email: 'test@example.com',
          displayName: 'John',
        );

        // Assert
        expect(user1.displayName, isNull);
        expect(user2.displayName, isNotNull);
      });

      test('photoUrl debe ser nullable', () {
        // Arrange
        const user1 = User(
          id: 'user123',
          email: 'test@example.com',
        );
        const user2 = User(
          id: 'user123',
          email: 'test@example.com',
          photoUrl: 'https://example.com/photo.jpg',
        );

        // Assert
        expect(user1.photoUrl, isNull);
        expect(user2.photoUrl, isNotNull);
      });
    });

    group('Edge cases', () {
      test('debe manejar id vacío', () {
        // Act
        const user = User(
          id: '',
          email: 'test@example.com',
        );

        // Assert
        expect(user.id, equals(''));
      });

      test('debe manejar email vacío', () {
        // Act
        const user = User(
          id: 'user123',
          email: '',
        );

        // Assert
        expect(user.email, equals(''));
      });

      test('debe manejar displayName vacío', () {
        // Act
        const user = User(
          id: 'user123',
          email: 'test@example.com',
          displayName: '',
        );

        // Assert
        expect(user.displayName, equals(''));
      });

      test('debe manejar photoUrl vacío', () {
        // Act
        const user = User(
          id: 'user123',
          email: 'test@example.com',
          photoUrl: '',
        );

        // Assert
        expect(user.photoUrl, equals(''));
      });

      test('debe manejar caracteres especiales en campos', () {
        // Act
        const user = User(
          id: 'user-123_abc',
          email: 'test+tag@example.com',
          displayName: 'José María Connor',
          photoUrl: 'https://example.com/photo',
        );

        // Assert
        expect(user.id, equals('user-123_abc'));
        expect(user.email, equals('test+tag@example.com'));
        expect(user.displayName, equals('José María Connor'));
        expect(user.photoUrl, equals('https://example.com/photo'));
      });
    });
  });
}
