/// Configuraciones de perfil del usuario
class ProfileSettings {
  final bool notificationsEnabled;
  final bool emailNotifications;
  final bool pushNotifications;
  final bool commentsNotifications;
  final bool likesNotifications;
  final bool followNotifications;
  final String language; // 'es' o 'en'
  final bool darkMode;
  final String privacyLevel; // 'public', 'friends', 'private'
  final bool showEmail;
  final bool showActivity;

  const ProfileSettings({
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

  /// Configuración por defecto
  factory ProfileSettings.defaultSettings() {
    return const ProfileSettings(
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
  }

  ProfileSettings copyWith({
    bool? notificationsEnabled,
    bool? emailNotifications,
    bool? pushNotifications,
    bool? commentsNotifications,
    bool? likesNotifications,
    bool? followNotifications,
    String? language,
    bool? darkMode,
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
      language: language ?? this.language,
      darkMode: darkMode ?? this.darkMode,
      privacyLevel: privacyLevel ?? this.privacyLevel,
      showEmail: showEmail ?? this.showEmail,
      showActivity: showActivity ?? this.showActivity,
    );
  }

  @override
  String toString() {
    return 'ProfileSettings(notifications: $notificationsEnabled, language: $language, '
        'privacyLevel: $privacyLevel)';
  }
}
