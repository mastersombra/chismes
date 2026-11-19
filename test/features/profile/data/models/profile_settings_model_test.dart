import 'package:flutter_test/flutter_test.dart';
import 'package:chismes/features/profile/data/models/profile_settings_model.dart';
import 'package:chismes/features/profile/domain/entities/profile_settings.dart';

void main() {
  group('ProfileSettingsModel', () {
    const tProfileSettingsModel = ProfileSettingsModel(
      notificationsEnabled: true,
      emailNotifications: false,
      pushNotifications: true,
      commentsNotifications: false,
      likesNotifications: true,
      followNotifications: false,
      language: 'en',
      darkMode: true,
      privacyLevel: 'private',
      showEmail: true,
      showActivity: false,
    );

    const tDefaultSettingsModel = ProfileSettingsModel(
      notificationsEnabled: true,
      emailNotifications: true,
      pushNotifications: true,
      commentsNotifications: true,
      likesNotifications: true,
      followNotifications: true,
      language: 'es',
      darkMode: false,
      privacyLevel: 'public',
      showEmail: false,
      showActivity: true,
    );

    group('fromJson', () {
      test('debe crear modelo válido desde JSON completo', () {
        // Arrange
        final json = {
          'notifications_enabled': true,
          'email_notifications': false,
          'push_notifications': true,
          'comments_notifications': false,
          'likes_notifications': true,
          'follow_notifications': false,
          'language': 'en',
          'dark_mode': true,
          'privacy_level': 'private',
          'show_email': true,
          'show_activity': false,
        };

        // Act
        final result = ProfileSettingsModel.fromJson(json);

        // Assert
        expect(result.notificationsEnabled, true);
        expect(result.emailNotifications, false);
        expect(result.pushNotifications, true);
        expect(result.commentsNotifications, false);
        expect(result.likesNotifications, true);
        expect(result.followNotifications, false);
        expect(result.language, 'en');
        expect(result.darkMode, true);
        expect(result.privacyLevel, 'private');
        expect(result.showEmail, true);
        expect(result.showActivity, false);
      });

      test('debe usar valores por defecto cuando campos son null', () {
        // Arrange
        final json = <String, dynamic>{};

        // Act
        final result = ProfileSettingsModel.fromJson(json);

        // Assert
        expect(result.notificationsEnabled, true);
        expect(result.emailNotifications, true);
        expect(result.pushNotifications, true);
        expect(result.commentsNotifications, true);
        expect(result.likesNotifications, true);
        expect(result.followNotifications, true);
        expect(result.language, 'es');
        expect(result.darkMode, false);
        expect(result.privacyLevel, 'public');
        expect(result.showEmail, false);
        expect(result.showActivity, true);
      });

      test('debe manejar mezcla de valores null y presentes', () {
        // Arrange
        final json = {
          'notifications_enabled': false,
          'language': 'en',
          'privacy_level': 'friends',
        };

        // Act
        final result = ProfileSettingsModel.fromJson(json);

        // Assert
        expect(result.notificationsEnabled, false);
        expect(result.language, 'en');
        expect(result.privacyLevel, 'friends');
        expect(result.emailNotifications, true); // default
        expect(result.darkMode, false); // default
      });

      test('debe manejar diferentes valores de language', () {
        // Arrange
        final jsonEn = {'language': 'en'};
        final jsonEs = {'language': 'es'};

        // Act
        final resultEn = ProfileSettingsModel.fromJson(jsonEn);
        final resultEs = ProfileSettingsModel.fromJson(jsonEs);

        // Assert
        expect(resultEn.language, 'en');
        expect(resultEs.language, 'es');
      });

      test('debe manejar diferentes valores de privacyLevel', () {
        // Arrange
        final jsonPublic = {'privacy_level': 'public'};
        final jsonFriends = {'privacy_level': 'friends'};
        final jsonPrivate = {'privacy_level': 'private'};

        // Act
        final resultPublic = ProfileSettingsModel.fromJson(jsonPublic);
        final resultFriends = ProfileSettingsModel.fromJson(jsonFriends);
        final resultPrivate = ProfileSettingsModel.fromJson(jsonPrivate);

        // Assert
        expect(resultPublic.privacyLevel, 'public');
        expect(resultFriends.privacyLevel, 'friends');
        expect(resultPrivate.privacyLevel, 'private');
      });
    });

    group('toJson', () {
      test('debe convertir modelo a JSON correctamente', () {
        // Act
        final json = tProfileSettingsModel.toJson();

        // Assert
        expect(json, {
          'notifications_enabled': true,
          'email_notifications': false,
          'push_notifications': true,
          'comments_notifications': false,
          'likes_notifications': true,
          'follow_notifications': false,
          'language': 'en',
          'dark_mode': true,
          'privacy_level': 'private',
          'show_email': true,
          'show_activity': false,
        });
      });

      test('debe convertir modelo con valores por defecto a JSON', () {
        // Act
        final json = tDefaultSettingsModel.toJson();

        // Assert
        expect(json['notifications_enabled'], true);
        expect(json['language'], 'es');
        expect(json['privacy_level'], 'public');
        expect(json['dark_mode'], false);
      });

      test('debe mantener estructura de datos correcta', () {
        // Act
        final json = tProfileSettingsModel.toJson();

        // Assert
        expect(json.keys.length, 11);
        expect(json, containsPair('notifications_enabled', isA<bool>()));
        expect(json, containsPair('language', isA<String>()));
        expect(json, containsPair('privacy_level', isA<String>()));
      });
    });

    group('toEntity', () {
      test('debe convertir modelo a entidad correctamente', () {
        // Act
        final entity = tProfileSettingsModel.toEntity();

        // Assert
        expect(entity, isA<ProfileSettings>());
        expect(entity.notificationsEnabled, true);
        expect(entity.emailNotifications, false);
        expect(entity.pushNotifications, true);
        expect(entity.commentsNotifications, false);
        expect(entity.likesNotifications, true);
        expect(entity.followNotifications, false);
        expect(entity.language, 'en');
        expect(entity.darkMode, true);
        expect(entity.privacyLevel, 'private');
        expect(entity.showEmail, true);
        expect(entity.showActivity, false);
      });

      test('debe preservar todos los campos booleanos', () {
        // Act
        final entity = tProfileSettingsModel.toEntity();

        // Assert
        expect(entity.notificationsEnabled, tProfileSettingsModel.notificationsEnabled);
        expect(entity.emailNotifications, tProfileSettingsModel.emailNotifications);
        expect(entity.pushNotifications, tProfileSettingsModel.pushNotifications);
        expect(entity.commentsNotifications, tProfileSettingsModel.commentsNotifications);
        expect(entity.likesNotifications, tProfileSettingsModel.likesNotifications);
        expect(entity.followNotifications, tProfileSettingsModel.followNotifications);
        expect(entity.darkMode, tProfileSettingsModel.darkMode);
        expect(entity.showEmail, tProfileSettingsModel.showEmail);
        expect(entity.showActivity, tProfileSettingsModel.showActivity);
      });
    });

    group('fromEntity', () {
      test('debe crear modelo desde entidad correctamente', () {
        // Arrange
        const entity = ProfileSettings(
          notificationsEnabled: false,
          emailNotifications: true,
          pushNotifications: false,
          commentsNotifications: true,
          likesNotifications: false,
          followNotifications: true,
          language: 'en',
          darkMode: true,
          privacyLevel: 'friends',
          showEmail: false,
          showActivity: true,
        );

        // Act
        final model = ProfileSettingsModel.fromEntity(entity);

        // Assert
        expect(model.notificationsEnabled, false);
        expect(model.emailNotifications, true);
        expect(model.pushNotifications, false);
        expect(model.commentsNotifications, true);
        expect(model.likesNotifications, false);
        expect(model.followNotifications, true);
        expect(model.language, 'en');
        expect(model.darkMode, true);
        expect(model.privacyLevel, 'friends');
        expect(model.showEmail, false);
        expect(model.showActivity, true);
      });

      test('debe crear modelo desde entidad por defecto', () {
        // Arrange
        final entity = ProfileSettings.defaultSettings();

        // Act
        final model = ProfileSettingsModel.fromEntity(entity);

        // Assert
        expect(model.notificationsEnabled, true);
        expect(model.emailNotifications, true);
        expect(model.language, 'es');
        expect(model.privacyLevel, 'public');
        expect(model.darkMode, false);
      });
    });

    group('Serialización roundtrip', () {
      test('debe mantener datos después de JSON roundtrip', () {
        // Act
        final json = tProfileSettingsModel.toJson();
        final restored = ProfileSettingsModel.fromJson(json);

        // Assert
        expect(restored.notificationsEnabled, tProfileSettingsModel.notificationsEnabled);
        expect(restored.emailNotifications, tProfileSettingsModel.emailNotifications);
        expect(restored.pushNotifications, tProfileSettingsModel.pushNotifications);
        expect(restored.commentsNotifications, tProfileSettingsModel.commentsNotifications);
        expect(restored.likesNotifications, tProfileSettingsModel.likesNotifications);
        expect(restored.followNotifications, tProfileSettingsModel.followNotifications);
        expect(restored.language, tProfileSettingsModel.language);
        expect(restored.darkMode, tProfileSettingsModel.darkMode);
        expect(restored.privacyLevel, tProfileSettingsModel.privacyLevel);
        expect(restored.showEmail, tProfileSettingsModel.showEmail);
        expect(restored.showActivity, tProfileSettingsModel.showActivity);
      });

      test('debe mantener datos después de Entity roundtrip', () {
        // Arrange
        const entity = ProfileSettings(
          notificationsEnabled: true,
          emailNotifications: false,
          pushNotifications: true,
          commentsNotifications: false,
          likesNotifications: true,
          followNotifications: false,
          language: 'en',
          darkMode: true,
          privacyLevel: 'private',
          showEmail: true,
          showActivity: false,
        );

        // Act
        final model = ProfileSettingsModel.fromEntity(entity);
        final restored = model.toEntity();

        // Assert
        expect(restored.notificationsEnabled, entity.notificationsEnabled);
        expect(restored.emailNotifications, entity.emailNotifications);
        expect(restored.language, entity.language);
        expect(restored.privacyLevel, entity.privacyLevel);
        expect(restored.darkMode, entity.darkMode);
      });
    });

    group('Edge cases', () {
      test('debe manejar todas las notificaciones deshabilitadas', () {
        // Arrange
        const model = ProfileSettingsModel(
          notificationsEnabled: false,
          emailNotifications: false,
          pushNotifications: false,
          commentsNotifications: false,
          likesNotifications: false,
          followNotifications: false,
          language: 'es',
          darkMode: false,
          privacyLevel: 'public',
          showEmail: false,
          showActivity: false,
        );

        // Act
        final entity = model.toEntity();

        // Assert
        expect(entity.notificationsEnabled, false);
        expect(entity.emailNotifications, false);
        expect(entity.pushNotifications, false);
        expect(entity.commentsNotifications, false);
      });

      test('debe manejar configuración más restrictiva', () {
        // Arrange
        const model = ProfileSettingsModel(
          notificationsEnabled: false,
          emailNotifications: false,
          pushNotifications: false,
          commentsNotifications: false,
          likesNotifications: false,
          followNotifications: false,
          language: 'en',
          darkMode: true,
          privacyLevel: 'private',
          showEmail: false,
          showActivity: false,
        );

        // Act
        final json = model.toJson();
        final restored = ProfileSettingsModel.fromJson(json);

        // Assert
        expect(restored.privacyLevel, 'private');
        expect(restored.showEmail, false);
        expect(restored.showActivity, false);
        expect(restored.notificationsEnabled, false);
      });
    });
  });
}
