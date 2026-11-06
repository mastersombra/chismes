/// Entidad que representa un usuario autenticado
///
/// Esta entidad representa el usuario completo con su perfil.
/// Se construye combinando datos de auth.users y public.profiles.
class User {
  final String id;
  final String email;
  final bool emailVerified;
  final String? username;
  final String? displayName;
  final String? avatarUrl;
  final String? bio;
  final bool profileCompleted;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const User({
    required this.id,
    required this.email,
    required this.emailVerified,
    this.username,
    this.displayName,
    this.avatarUrl,
    this.bio,
    required this.profileCompleted,
    required this.createdAt,
    this.updatedAt,
  });

  /// Retorna el nombre a mostrar en UI
  ///
  /// Prioridad: displayName > username > email
  String get displayNameOrFallback {
    if (displayName != null && displayName!.isNotEmpty) {
      return displayName!;
    }
    if (username != null && username!.isNotEmpty) {
      return '@$username';
    }
    return email;
  }

  /// Retorna true si el perfil tiene username
  bool get hasUsername => username != null && username!.isNotEmpty;

  /// Retorna true si el perfil tiene display name
  bool get hasDisplayName => displayName != null && displayName!.isNotEmpty;

  /// Retorna true si el perfil tiene avatar
  bool get hasAvatar => avatarUrl != null && avatarUrl!.isNotEmpty;

  /// Calcula el porcentaje de completitud del perfil
  int get profileCompletionPercentage {
    int completion = 25; // Email siempre existe

    if (hasUsername) completion += 25;
    if (hasDisplayName) completion += 25;
    if (hasAvatar) completion += 25;

    return completion;
  }

  /// Crea una copia del usuario con campos actualizados
  User copyWith({
    String? id,
    String? email,
    bool? emailVerified,
    String? username,
    String? displayName,
    String? avatarUrl,
    String? bio,
    bool? profileCompleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      emailVerified: emailVerified ?? this.emailVerified,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      profileCompleted: profileCompleted ?? this.profileCompleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'User(id: $id, email: $email, username: $username, '
        'displayName: $displayName, profileCompleted: $profileCompleted)';
  }
}
