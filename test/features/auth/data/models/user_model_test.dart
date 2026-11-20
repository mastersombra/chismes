import 'package:chismes/features/auth/data/models/user_model.dart';
import 'package:chismes/features/auth/domain/entities/user.dart' as domain;
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import 'user_model_test.mocks.dart';

@GenerateMocks([supabase.User])
void main() {
  group('UserModel', () {
    const tId = 'test-id-123';
    const tEmail = 'test@example.com';
    const tUsername = 'testuser';
    const tDisplayName = 'Test User';
    const tAvatarUrl = 'https://example.com/avatar.jpg';
    const tBio = 'Test bio';
    const tProfileCompleted = true;
    final tCreatedAt = DateTime(2024, 1, 1);
    final tUpdatedAt = DateTime(2024, 1, 15);

    group('toEntity', () {
      test('debe convertir UserModel a User entity con todos los campos', () {
        final userModel = UserModel(
          id: tId,
          email: tEmail,
          emailVerified: true,
          username: tUsername,
          displayName: tDisplayName,
          profileCompleted: tProfileCompleted,
          createdAt: tCreatedAt,
        );

        final entity = userModel.toEntity();

        expect(entity, isA<domain.User>());
        expect(entity.id, tId);
        expect(entity.email, tEmail);
        expect(entity.emailVerified, true);
        expect(entity.username, tUsername);
        expect(entity.displayName, tDisplayName);
        expect(entity.profileCompleted, tProfileCompleted);
      });

      test('debe convertir UserModel con campos null a User entity', () {
        final userModel = UserModel(
          id: tId,
          email: tEmail,
          emailVerified: false,
          profileCompleted: false,
          createdAt: tCreatedAt,
        );

        final entity = userModel.toEntity();

        expect(entity, isA<domain.User>());
        expect(entity.id, tId);
        expect(entity.email, tEmail);
        expect(entity.emailVerified, false);
        expect(entity.username, null);
        expect(entity.displayName, null);
        expect(entity.profileCompleted, false);
      });
    });

    group('fromEntity', () {
      test('debe crear UserModel desde User entity', () {
        final entity = domain.User(
          id: tId,
          email: tEmail,
          emailVerified: true,
          username: tUsername,
          displayName: tDisplayName,
          profileCompleted: tProfileCompleted,
          createdAt: tCreatedAt,
        );

        final model = UserModel.fromEntity(entity);

        expect(model, isA<UserModel>());
        expect(model.id, tId);
        expect(model.email, tEmail);
        expect(model.emailVerified, true);
        expect(model.username, tUsername);
      });

      test('debe preservar todos los campos opcionales', () {
        final entity = domain.User(
          id: tId,
          email: tEmail,
          emailVerified: true,
          username: tUsername,
          displayName: tDisplayName,
          avatarUrl: tAvatarUrl,
          bio: tBio,
          profileCompleted: tProfileCompleted,
          createdAt: tCreatedAt,
          updatedAt: tUpdatedAt,
        );

        final model = UserModel.fromEntity(entity);

        expect(model.avatarUrl, tAvatarUrl);
        expect(model.bio, tBio);
        expect(model.updatedAt, tUpdatedAt);
      });
    });

    group('fromSupabase', () {
      late MockUser mockSupabaseUser;

      setUp(() {
        mockSupabaseUser = MockUser();
        when(mockSupabaseUser.id).thenReturn(tId);
        when(mockSupabaseUser.email).thenReturn(tEmail);
        when(mockSupabaseUser.createdAt).thenReturn(tCreatedAt.toIso8601String());
        when(mockSupabaseUser.appMetadata).thenReturn({});
      });

      test('debe crear UserModel con profile data completo', () {
        // Arrange
        when(mockSupabaseUser.emailConfirmedAt).thenReturn(tCreatedAt.toIso8601String());

        final profileData = {
          'username': tUsername,
          'display_name': tDisplayName,
          'avatar_url': tAvatarUrl,
          'bio': tBio,
          'profile_completed': true,
          'updated_at': tUpdatedAt.toIso8601String(),
        };

        // Act
        final model = UserModel.fromSupabase(
          supabaseUser: mockSupabaseUser,
          profileData: profileData,
        );

        // Assert
        expect(model.id, tId);
        expect(model.email, tEmail);
        expect(model.emailVerified, true);
        expect(model.username, tUsername);
        expect(model.displayName, tDisplayName);
        expect(model.avatarUrl, tAvatarUrl);
        expect(model.bio, tBio);
        expect(model.profileCompleted, true);
        expect(model.updatedAt, tUpdatedAt);
      });

      test('debe manejar profileData null', () {
        // Arrange
        when(mockSupabaseUser.emailConfirmedAt).thenReturn(null);

        // Act
        final model = UserModel.fromSupabase(
          supabaseUser: mockSupabaseUser,
          profileData: null,
        );

        // Assert
        expect(model.id, tId);
        expect(model.email, tEmail);
        expect(model.emailVerified, false);
        expect(model.username, null);
        expect(model.displayName, null);
        expect(model.avatarUrl, null);
        expect(model.bio, null);
        expect(model.profileCompleted, false);
        expect(model.updatedAt, null);
      });

      test('debe manejar profileData vacío', () {
        // Arrange
        when(mockSupabaseUser.emailConfirmedAt).thenReturn(tCreatedAt.toIso8601String());

        // Act
        final model = UserModel.fromSupabase(
          supabaseUser: mockSupabaseUser,
          profileData: {},
        );

        // Assert
        expect(model.emailVerified, true);
        expect(model.username, null);
        expect(model.profileCompleted, false);
      });

      test('debe usar email vacío cuando supabaseUser.email es null', () {
        // Arrange
        when(mockSupabaseUser.email).thenReturn(null);
        when(mockSupabaseUser.emailConfirmedAt).thenReturn(null);

        // Act
        final model = UserModel.fromSupabase(
          supabaseUser: mockSupabaseUser,
          profileData: null,
        );

        // Assert
        expect(model.email, '');
      });

      test('debe manejar updated_at null en profileData', () {
        // Arrange
        when(mockSupabaseUser.emailConfirmedAt).thenReturn(null);

        final profileData = {
          'username': tUsername,
          'updated_at': null,
        };

        // Act
        final model = UserModel.fromSupabase(
          supabaseUser: mockSupabaseUser,
          profileData: profileData,
        );

        // Assert
        expect(model.updatedAt, null);
      });

      test('debe parsear profile_completed como false cuando es null', () {
        // Arrange
        when(mockSupabaseUser.emailConfirmedAt).thenReturn(null);

        final profileData = {
          'username': tUsername,
          'profile_completed': null,
        };

        // Act
        final model = UserModel.fromSupabase(
          supabaseUser: mockSupabaseUser,
          profileData: profileData,
        );

        // Assert
        expect(model.profileCompleted, false);
      });

      test('no es moderador sin rol en app_metadata', () {
        when(mockSupabaseUser.emailConfirmedAt).thenReturn(null);

        final model = UserModel.fromSupabase(supabaseUser: mockSupabaseUser, profileData: null);

        expect(model.isModerator, isFalse);
        expect(model.toEntity().isModerator, isFalse);
      });

      test('es moderador con app_metadata.role = moderator', () {
        when(mockSupabaseUser.emailConfirmedAt).thenReturn(null);
        when(mockSupabaseUser.appMetadata).thenReturn({'provider': 'google', 'role': 'moderator'});

        final model = UserModel.fromSupabase(supabaseUser: mockSupabaseUser, profileData: null);

        expect(model.isModerator, isTrue);
        expect(model.toEntity().isModerator, isTrue);
        expect(UserModel.fromEntity(model.toEntity()).isModerator, isTrue);
      });

      test('otro rol en app_metadata no es moderador', () {
        when(mockSupabaseUser.emailConfirmedAt).thenReturn(null);
        when(mockSupabaseUser.appMetadata).thenReturn({'role': 'admin'});

        final model = UserModel.fromSupabase(supabaseUser: mockSupabaseUser, profileData: null);

        expect(model.isModerator, isFalse);
      });
    });

    group('fromJson', () {
      test('debe crear UserModel desde JSON completo', () {
        // Arrange
        final json = {
          'id': tId,
          'email': tEmail,
          'email_verified': true,
          'username': tUsername,
          'display_name': tDisplayName,
          'avatar_url': tAvatarUrl,
          'bio': tBio,
          'profile_completed': true,
          'created_at': tCreatedAt.toIso8601String(),
          'updated_at': tUpdatedAt.toIso8601String(),
        };

        // Act
        final model = UserModel.fromJson(json);

        // Assert
        expect(model.id, tId);
        expect(model.email, tEmail);
        expect(model.emailVerified, true);
        expect(model.username, tUsername);
        expect(model.displayName, tDisplayName);
        expect(model.avatarUrl, tAvatarUrl);
        expect(model.bio, tBio);
        expect(model.profileCompleted, true);
        expect(model.createdAt, tCreatedAt);
        expect(model.updatedAt, tUpdatedAt);
      });

      test('debe manejar campos opcionales null', () {
        // Arrange
        final json = {
          'id': tId,
          'email': tEmail,
          'created_at': tCreatedAt.toIso8601String(),
        };

        // Act
        final model = UserModel.fromJson(json);

        // Assert
        expect(model.id, tId);
        expect(model.email, tEmail);
        expect(model.emailVerified, false);
        expect(model.username, null);
        expect(model.displayName, null);
        expect(model.avatarUrl, null);
        expect(model.bio, null);
        expect(model.profileCompleted, false);
        expect(model.updatedAt, null);
      });

      test('debe parsear email_verified como false cuando es null', () {
        // Arrange
        final json = {
          'id': tId,
          'email': tEmail,
          'email_verified': null,
          'created_at': tCreatedAt.toIso8601String(),
        };

        // Act
        final model = UserModel.fromJson(json);

        // Assert
        expect(model.emailVerified, false);
      });

      test('debe parsear profile_completed como false cuando es null', () {
        // Arrange
        final json = {
          'id': tId,
          'email': tEmail,
          'profile_completed': null,
          'created_at': tCreatedAt.toIso8601String(),
        };

        // Act
        final model = UserModel.fromJson(json);

        // Assert
        expect(model.profileCompleted, false);
      });
    });

    group('toJson', () {
      test('debe convertir UserModel a JSON con todos los campos', () {
        // Arrange
        final model = UserModel(
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
        final json = model.toJson();

        // Assert
        expect(json['id'], tId);
        expect(json['username'], tUsername);
        expect(json['display_name'], tDisplayName);
        expect(json['avatar_url'], tAvatarUrl);
        expect(json['bio'], tBio);
        expect(json['profile_completed'], true);
      });

      test('debe incluir campos null en JSON', () {
        // Arrange
        final model = UserModel(
          id: tId,
          email: tEmail,
          emailVerified: false,
          profileCompleted: false,
          createdAt: tCreatedAt,
        );

        // Act
        final json = model.toJson();

        // Assert
        expect(json['id'], tId);
        expect(json['username'], null);
        expect(json['display_name'], null);
        expect(json['avatar_url'], null);
        expect(json['bio'], null);
        expect(json['profile_completed'], false);
      });

      test('NO debe incluir email ni emailVerified en JSON', () {
        // Arrange
        final model = UserModel(
          id: tId,
          email: tEmail,
          emailVerified: true,
          profileCompleted: false,
          createdAt: tCreatedAt,
        );

        // Act
        final json = model.toJson();

        // Assert
        expect(json.containsKey('email'), false);
        expect(json.containsKey('email_verified'), false);
        expect(json.containsKey('created_at'), false);
        expect(json.containsKey('updated_at'), false);
      });
    });

    group('toString', () {
      test('debe retornar representación en string con campos principales', () {
        // Arrange
        final model = UserModel(
          id: tId,
          email: tEmail,
          emailVerified: true,
          username: tUsername,
          displayName: tDisplayName,
          profileCompleted: true,
          createdAt: tCreatedAt,
        );

        // Act
        final string = model.toString();

        // Assert
        expect(string, contains('UserModel'));
        expect(string, contains('id: $tId'));
        expect(string, contains('email: $tEmail'));
        expect(string, contains('username: $tUsername'));
        expect(string, contains('displayName: $tDisplayName'));
        expect(string, contains('profileCompleted: true'));
      });

      test('debe manejar campos null en toString', () {
        // Arrange
        final model = UserModel(
          id: tId,
          email: tEmail,
          emailVerified: false,
          profileCompleted: false,
          createdAt: tCreatedAt,
        );

        // Act
        final string = model.toString();

        // Assert
        expect(string, contains('username: null'));
        expect(string, contains('displayName: null'));
        expect(string, contains('profileCompleted: false'));
      });
    });

    // Note: UserModel no implementa == ni hashCode porque no se usa
    // para comparaciones en el código de producción. Si se necesita en el
    // futuro, se puede agregar Equatable o implementar manualmente.
  });
}
