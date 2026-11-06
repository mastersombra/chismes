import '../../domain/entities/profile_settings.dart';

/// Modelo de configuraciones de perfil (Data Layer)
class ProfileSettingsModel {
  final bool notificationsEnabled;
  final bool emailNotifications;
  final bool pushNotifications;
  final bool commentsNotifications;
  final bool likesNotifications;
  final bool followNotifications;
  final String language;
  final bool darkMode;
  final String privacyLevel;
  final bool showEmail;
  final bool showActivity;

  const ProfileSettingsModel({
    required this.notificationsEnabled,
    required this.emailNotifications,
    required this.pushNotifications,
    required this.commentsNotifications,
    required this.likesNotifications,
    required this.followNotifications,
    required this.language,
    required this.darkMode,
    required this.privacyLevel,
    required this.showEmail,
    required this.showActivity,
  });

  /// Convierte el modelo a entidad de dominio
  ProfileSettings toEntity() {
    return ProfileSettings(
      notificationsEnabled: notificationsEnabled,
      emailNotifications: emailNotifications,
      pushNotifications: pushNotifications,
      commentsNotifications: commentsNotifications,
      likesNotifications: likesNotifications,
      followNotifications: followNotifications,
      language: language,
      darkMode: darkMode,
      privacyLevel: privacyLevel,
      showEmail: showEmail,
      showActivity: showActivity,
    );
  }

  /// Crea un modelo desde entidad de dominio
  factory ProfileSettingsModel.fromEntity(ProfileSettings entity) {
    return ProfileSettingsModel(
      notificationsEnabled: entity.notificationsEnabled,
      emailNotifications: entity.emailNotifications,
      pushNotifications: entity.pushNotifications,
      commentsNotifications: entity.commentsNotifications,
      likesNotifications: entity.likesNotifications,
      followNotifications: entity.followNotifications,
      language: entity.language,
      darkMode: entity.darkMode,
      privacyLevel: entity.privacyLevel,
      showEmail: entity.showEmail,
      showActivity: entity.showActivity,
    );
  }

  /// Crea un modelo desde JSON de Supabase
  factory ProfileSettingsModel.fromJson(Map<String, dynamic> json) {
    return ProfileSettingsModel(
      notificationsEnabled: json['notifications_enabled'] as bool? ?? true,
      emailNotifications: json['email_notifications'] as bool? ?? true,
      pushNotifications: json['push_notifications'] as bool? ?? true,
      commentsNotifications: json['comments_notifications'] as bool? ?? true,
      likesNotifications: json['likes_notifications'] as bool? ?? true,
      followNotifications: json['follow_notifications'] as bool? ?? true,
      language: json['language'] as String? ?? 'es',
      darkMode: json['dark_mode'] as bool? ?? false,
      privacyLevel: json['privacy_level'] as String? ?? 'public',
      showEmail: json['show_email'] as bool? ?? false,
      showActivity: json['show_activity'] as bool? ?? true,
    );
  }

  /// Convierte el modelo a JSON para Supabase
  Map<String, dynamic> toJson() {
    return {
      'notifications_enabled': notificationsEnabled,
      'email_notifications': emailNotifications,
      'push_notifications': pushNotifications,
      'comments_notifications': commentsNotifications,
      'likes_notifications': likesNotifications,
      'follow_notifications': followNotifications,
      'language': language,
      'dark_mode': darkMode,
      'privacy_level': privacyLevel,
      'show_email': showEmail,
      'show_activity': showActivity,
    };
  }
}
