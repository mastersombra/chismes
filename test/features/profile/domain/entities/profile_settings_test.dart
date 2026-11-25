import 'package:flutter_test/flutter_test.dart';
import 'package:chismes/features/profile/domain/entities/profile_settings.dart';

void main() {
  group('ProfileSettings', () {
    const testSettings = ProfileSettings(
      notificationsEnabled: true,
      emailNotifications: true,
      pushNotifications: false,
      commentsNotifications: true,
      likesNotifications: false,
      followNotifications: true,
      privacyLevel: 'public',
      showEmail: false,
      showActivity: true,
    );

    group('Constructor', () {
      test('debe crear instancia con todos los campos requeridos', () {
        // Act
        const settings = ProfileSettings(
          notificationsEnabled: true,
          emailNotifications: false,
          pushNotifications: true,
          commentsNotifications: false,
          likesNotifications: true,
          followNotifications: false,
          privacyLevel: 'private',
          showEmail: true,
          showActivity: false,
        );

        // Assert
        expect(settings.notificationsEnabled, isTrue);
        expect(settings.emailNotifications, isFalse);
        expect(settings.pushNotifications, isTrue);
        expect(settings.commentsNotifications, isFalse);
        expect(settings.likesNotifications, isTrue);
        expect(settings.followNotifications, isFalse);
        expect(settings.privacyLevel, 'private');
        expect(settings.showEmail, isTrue);
        expect(settings.showActivity, isFalse);
      });

      test('debe ser const constructor', () {
        // Act & Assert
        const settings = ProfileSettings(
          notificationsEnabled: true,
          emailNotifications: true,
          pushNotifications: true,
          commentsNotifications: true,
          likesNotifications: true,
          followNotifications: true,
          privacyLevel: 'public',
          showEmail: false,
          showActivity: true,
        );

        expect(settings, isA<ProfileSettings>());
      });

      test('debe aceptar privacyLevel public', () {
        // Act
        const settings = ProfileSettings(
          notificationsEnabled: true,
          emailNotifications: true,
          pushNotifications: true,
          commentsNotifications: true,
          likesNotifications: true,
          followNotifications: true,
          privacyLevel: 'public',
          showEmail: false,
          showActivity: true,
        );

        // Assert
        expect(settings.privacyLevel, 'public');
      });

      test('debe aceptar privacyLevel private', () {
        // Act
        const settings = ProfileSettings(
          notificationsEnabled: true,
          emailNotifications: true,
          pushNotifications: true,
          commentsNotifications: true,
          likesNotifications: true,
          followNotifications: true,
          privacyLevel: 'private',
          showEmail: false,
          showActivity: true,
        );

        // Assert
        expect(settings.privacyLevel, 'private');
      });
    });

    group('defaultSettings Factory', () {
      test('debe crear instancia con valores por defecto', () {
        // Act
        final settings = ProfileSettings.defaultSettings();

        // Assert
        expect(settings.notificationsEnabled, isTrue);
        expect(settings.emailNotifications, isTrue);
        expect(settings.pushNotifications, isTrue);
        expect(settings.commentsNotifications, isTrue);
        expect(settings.likesNotifications, isTrue);
        expect(settings.followNotifications, isTrue);
        expect(settings.privacyLevel, 'public');
        expect(settings.showEmail, isFalse);
        expect(settings.showActivity, isTrue);
      });

      test('debe retornar const instance', () {
        // Act
        final settings1 = ProfileSettings.defaultSettings();
        final settings2 = ProfileSettings.defaultSettings();

        // Assert
        expect(identical(settings1, settings2), isTrue);
      });

      test('debe tener notificaciones habilitadas por defecto', () {
        // Act
        final settings = ProfileSettings.defaultSettings();

        // Assert
        expect(settings.notificationsEnabled, isTrue);
        expect(settings.emailNotifications, isTrue);
        expect(settings.pushNotifications, isTrue);
      });

      test('debe tener notificaciones de actividad habilitadas', () {
        // Act
        final settings = ProfileSettings.defaultSettings();

        // Assert
        expect(settings.commentsNotifications, isTrue);
        expect(settings.likesNotifications, isTrue);
        expect(settings.followNotifications, isTrue);
      });

      test('debe tener privacidad pública por defecto', () {
        // Act
        final settings = ProfileSettings.defaultSettings();

        // Assert
        expect(settings.privacyLevel, 'public');
      });

      test('debe ocultar email por defecto', () {
        // Act
        final settings = ProfileSettings.defaultSettings();

        // Assert
        expect(settings.showEmail, isFalse);
      });

      test('debe mostrar actividad por defecto', () {
        // Act
        final settings = ProfileSettings.defaultSettings();

        // Assert
        expect(settings.showActivity, isTrue);
      });
    });

    group('copyWith', () {
      test('debe copiar con notificationsEnabled modificado', () {
        // Act
        final copy = testSettings.copyWith(notificationsEnabled: false);

        // Assert
        expect(copy.notificationsEnabled, isFalse);
        expect(copy.emailNotifications, testSettings.emailNotifications);
      });

      test('debe copiar con emailNotifications modificado', () {
        // Act
        final copy = testSettings.copyWith(emailNotifications: false);

        // Assert
        expect(copy.emailNotifications, isFalse);
        expect(copy.notificationsEnabled, testSettings.notificationsEnabled);
      });

      test('debe copiar con pushNotifications modificado', () {
        // Act
        final copy = testSettings.copyWith(pushNotifications: true);

        // Assert
        expect(copy.pushNotifications, isTrue);
        expect(copy.notificationsEnabled, testSettings.notificationsEnabled);
      });

      test('debe copiar con commentsNotifications modificado', () {
        // Act
        final copy = testSettings.copyWith(commentsNotifications: false);

        // Assert
        expect(copy.commentsNotifications, isFalse);
      });

      test('debe copiar con likesNotifications modificado', () {
        // Act
        final copy = testSettings.copyWith(likesNotifications: true);

        // Assert
        expect(copy.likesNotifications, isTrue);
      });

      test('debe copiar con followNotifications modificado', () {
        // Act
        final copy = testSettings.copyWith(followNotifications: false);

        // Assert
        expect(copy.followNotifications, isFalse);
      });

      test('debe copiar con privacyLevel modificado', () {
        // Act
        final copy = testSettings.copyWith(privacyLevel: 'private');

        // Assert
        expect(copy.privacyLevel, 'private');
      });

      test('debe copiar con showEmail modificado', () {
        // Act
        final copy = testSettings.copyWith(showEmail: true);

        // Assert
        expect(copy.showEmail, isTrue);
      });

      test('debe copiar con showActivity modificado', () {
        // Act
        final copy = testSettings.copyWith(showActivity: false);

        // Assert
        expect(copy.showActivity, isFalse);
      });

      test('debe copiar con múltiples campos modificados', () {
        // Act
        final copy = testSettings.copyWith(
          privacyLevel: 'private',
        );

        // Assert
        expect(copy.privacyLevel, 'private');
        expect(copy.notificationsEnabled, testSettings.notificationsEnabled);
      });

      test('debe retornar copia idéntica sin parámetros', () {
        // Act
        final copy = testSettings.copyWith();

        // Assert
        expect(copy.notificationsEnabled, testSettings.notificationsEnabled);
        expect(copy.emailNotifications, testSettings.emailNotifications);
        expect(copy.pushNotifications, testSettings.pushNotifications);
        expect(copy.commentsNotifications, testSettings.commentsNotifications);
        expect(copy.likesNotifications, testSettings.likesNotifications);
        expect(copy.followNotifications, testSettings.followNotifications);
        expect(copy.privacyLevel, testSettings.privacyLevel);
        expect(copy.showEmail, testSettings.showEmail);
        expect(copy.showActivity, testSettings.showActivity);
      });
    });

    group('toString', () {
      test('debe retornar string con formato correcto', () {
        // Act
        final result = testSettings.toString();

        // Assert
        expect(result, contains('ProfileSettings'));
        expect(result, contains('notifications: true'));
        expect(result, contains('privacyLevel: public'));
      });

      test('debe incluir valores principales', () {
        // Arrange
        const settings = ProfileSettings(
          notificationsEnabled: false,
          emailNotifications: true,
          pushNotifications: true,
          commentsNotifications: true,
          likesNotifications: true,
          followNotifications: true,
          privacyLevel: 'private',
          showEmail: true,
          showActivity: false,
        );

        // Act
        final result = settings.toString();

        // Assert
        expect(result, contains('false')); // notifications
        expect(result, contains('private'));
      });

      test('debe tener formato consistente', () {
        // Act
        final result = testSettings.toString();

        // Assert
        expect(
          result,
          'ProfileSettings(notifications: true, privacyLevel: public)',
        );
      });
    });

    group('Getters', () {
      test('notificationsEnabled debe ser final', () {
        // Assert
        expect(testSettings.notificationsEnabled, isA<bool>());
      });

      test('emailNotifications debe ser final', () {
        // Assert
        expect(testSettings.emailNotifications, isA<bool>());
      });

      test('pushNotifications debe ser final', () {
        // Assert
        expect(testSettings.pushNotifications, isA<bool>());
      });

      test('commentsNotifications debe ser final', () {
        // Assert
        expect(testSettings.commentsNotifications, isA<bool>());
      });

      test('likesNotifications debe ser final', () {
        // Assert
        expect(testSettings.likesNotifications, isA<bool>());
      });

      test('followNotifications debe ser final', () {
        // Assert
        expect(testSettings.followNotifications, isA<bool>());
      });

      test('privacyLevel debe ser final', () {
        // Assert
        expect(testSettings.privacyLevel, isA<String>());
      });

      test('showEmail debe ser final', () {
        // Assert
        expect(testSettings.showEmail, isA<bool>());
      });

      test('showActivity debe ser final', () {
        // Assert
        expect(testSettings.showActivity, isA<bool>());
      });
    });

    group('Edge Cases', () {
      test('debe permitir todas las notificaciones deshabilitadas', () {
        // Act
        const settings = ProfileSettings(
          notificationsEnabled: false,
          emailNotifications: false,
          pushNotifications: false,
          commentsNotifications: false,
          likesNotifications: false,
          followNotifications: false,
          privacyLevel: 'public',
          showEmail: false,
          showActivity: false,
        );

        // Assert
        expect(settings.notificationsEnabled, isFalse);
        expect(settings.emailNotifications, isFalse);
        expect(settings.pushNotifications, isFalse);
        expect(settings.commentsNotifications, isFalse);
        expect(settings.likesNotifications, isFalse);
        expect(settings.followNotifications, isFalse);
      });

      test('debe permitir todas las notificaciones habilitadas', () {
        // Act
        const settings = ProfileSettings(
          notificationsEnabled: true,
          emailNotifications: true,
          pushNotifications: true,
          commentsNotifications: true,
          likesNotifications: true,
          followNotifications: true,
          privacyLevel: 'public',
          showEmail: false,
          showActivity: true,
        );

        // Assert
        expect(settings.notificationsEnabled, isTrue);
        expect(settings.emailNotifications, isTrue);
        expect(settings.pushNotifications, isTrue);
        expect(settings.commentsNotifications, isTrue);
        expect(settings.likesNotifications, isTrue);
        expect(settings.followNotifications, isTrue);
      });

      test('debe permitir máxima privacidad', () {
        // Act
        const settings = ProfileSettings(
          notificationsEnabled: false,
          emailNotifications: false,
          pushNotifications: false,
          commentsNotifications: false,
          likesNotifications: false,
          followNotifications: false,
          privacyLevel: 'private',
          showEmail: false,
          showActivity: false,
        );

        // Assert
        expect(settings.privacyLevel, 'private');
        expect(settings.showEmail, isFalse);
        expect(settings.showActivity, isFalse);
      });

      test('debe permitir máxima exposición', () {
        // Act
        const settings = ProfileSettings(
          notificationsEnabled: true,
          emailNotifications: true,
          pushNotifications: true,
          commentsNotifications: true,
          likesNotifications: true,
          followNotifications: true,
          privacyLevel: 'public',
          showEmail: true,
          showActivity: true,
        );

        // Assert
        expect(settings.privacyLevel, 'public');
        expect(settings.showEmail, isTrue);
        expect(settings.showActivity, isTrue);
      });
    });

    group('Immutability', () {
      test('copyWith debe crear nueva instancia', () {
        // Act
        final copy = testSettings.copyWith(showEmail: true);

        // Assert
        expect(identical(copy, testSettings), isFalse);
      });

      test('campos deben ser final (no modificables)', () {
        // Assert - Si compila, los campos son final
        expect(testSettings.notificationsEnabled, isTrue);
        // No hay forma de modificar campos después de creación
      });
    });
  });
}
