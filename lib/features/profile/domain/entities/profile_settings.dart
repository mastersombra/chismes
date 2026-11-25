/// Preferencias del usuario guardadas en el servidor (`user_settings`,
/// 017_profile_editing.sql). Idioma y tema son del teléfono: ver
/// LocaleNotifier y ThemeModeNotifier.
class ProfileSettings {
  final bool notificationsEnabled;
  final bool emailNotifications;
  final bool pushNotifications;
  final bool commentsNotifications;
  final bool likesNotifications;
  final bool followNotifications;
  final String privacyLevel; // 'public' | 'private' (privada: seguir requiere aprobación)
  final bool showEmail;
  final bool showActivity;

  const ProfileSettings({
    required this.notificationsEnabled,
    required this.emailNotifications,
    required this.pushNotifications,
    required this.commentsNotifications,
    required this.likesNotifications,
    required this.followNotifications,
    required this.privacyLevel,
    required this.showEmail,
    required this.showActivity,
  });

  /// Configuración por defecto
  factory ProfileSettings.defaultSettings() {
    return const ProfileSettings(
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
  }

  ProfileSettings copyWith({
    bool? notificationsEnabled,
    bool? emailNotifications,
    bool? pushNotifications,
    bool? commentsNotifications,
    bool? likesNotifications,
    bool? followNotifications,
    String? privacyLevel,
    bool? showEmail,
    bool? showActivity,
  }) {
    return ProfileSettings(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      emailNotifications: emailNotifications ?? this.emailNotifications,
      pushNotifications: pushNotifications ?? this.pushNotifications,
      commentsNotifications: commentsNotifications ?? this.commentsNotifications,
      likesNotifications: likesNotifications ?? this.likesNotifications,
      followNotifications: followNotifications ?? this.followNotifications,
      privacyLevel: privacyLevel ?? this.privacyLevel,
      showEmail: showEmail ?? this.showEmail,
      showActivity: showActivity ?? this.showActivity,
    );
  }

  @override
  String toString() {
    return 'ProfileSettings(notifications: $notificationsEnabled, '
        'privacyLevel: $privacyLevel)';
  }
}
