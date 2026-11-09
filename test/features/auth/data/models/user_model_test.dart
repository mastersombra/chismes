import 'package:chismes/features/auth/data/models/user_model.dart';
import 'package:chismes/features/auth/domain/entities/user.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UserModel', () {
    const tId = 'test-id-123';
    const tEmail = 'test@example.com';
    const tUsername = 'testuser';
    const tDisplayName = 'Test User';
    const tProfileCompleted = true;
    final tCreatedAt = DateTime(2024, 1, 1);

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

        expect(entity, isA<User>());
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

        expect(entity, isA<User>());
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
        final entity = User(
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
    });

    // Note: UserModel no implementa == ni hashCode porque no se usa
    // para comparaciones en el código de producción. Si se necesita en el
    // futuro, se puede agregar Equatable o implementar manualmente.
  });
}
