import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../../domain/entities/user.dart';

/// Modelo de datos para User
///
/// Convierte entre:
/// - JSON (Supabase response)
/// - User entity (dominio)
class UserModel {
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

  const UserModel({
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

  /// Crea UserModel desde Supabase User + Profile data
  ///
  /// Combina datos de auth.users (supabaseUser) y public.profiles (profileData)
  factory UserModel.fromSupabase({
    required supabase.User supabaseUser,
    required Map<String, dynamic>? profileData,
  }) {
    return UserModel(
      id: supabaseUser.id,
      email: supabaseUser.email ?? '',
      emailVerified: supabaseUser.emailConfirmedAt != null,
      username: profileData?['username'] as String?,
      displayName: profileData?['display_name'] as String?,
      avatarUrl: profileData?['avatar_url'] as String?,
      bio: profileData?['bio'] as String?,
      profileCompleted: (profileData?['profile_completed'] as bool?) ?? false,
      createdAt: DateTime.parse(supabaseUser.createdAt),
      updatedAt: profileData?['updated_at'] != null
          ? DateTime.parse(profileData!['updated_at'] as String)
          : null,
    );
  }

  /// Crea UserModel desde JSON (profile completo)
  ///
  /// Usado cuando se obtiene el profile directamente de la tabla profiles
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      emailVerified: (json['email_verified'] as bool?) ?? false,
      username: json['username'] as String?,
      displayName: json['display_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      bio: json['bio'] as String?,
      profileCompleted: (json['profile_completed'] as bool?) ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  /// Convierte UserModel a JSON
  ///
  /// Usado para actualizar profile en Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'display_name': displayName,
      'avatar_url': avatarUrl,
      'bio': bio,
      'profile_completed': profileCompleted,
    };
  }

  /// Convierte UserModel a User entity (domain)
  User toEntity() {
    return User(
      id: id,
      email: email,
      emailVerified: emailVerified,
      username: username,
      displayName: displayName,
      avatarUrl: avatarUrl,
      bio: bio,
      profileCompleted: profileCompleted,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Crea UserModel desde User entity
  factory UserModel.fromEntity(User user) {
    return UserModel(
      id: user.id,
      email: user.email,
      emailVerified: user.emailVerified,
      username: user.username,
      displayName: user.displayName,
      avatarUrl: user.avatarUrl,
      bio: user.bio,
      profileCompleted: user.profileCompleted,
      createdAt: user.createdAt,
      updatedAt: user.updatedAt,
    );
  }

  @override
  String toString() {
    return 'UserModel(id: $id, email: $email, username: $username, '
        'displayName: $displayName, profileCompleted: $profileCompleted)';
  }
}
