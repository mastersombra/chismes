import 'dart:typed_data';

import 'package:chismes/core/error/error_codes.dart';
import 'package:chismes/core/error/failure.dart';
import 'package:chismes/core/result/result.dart';
import 'package:chismes/core/services/auth_service.dart';
import 'package:chismes/features/auth/domain/entities/user.dart';
import 'package:chismes/features/profile/presentation/controllers/edit_profile_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'edit_profile_controller_test.mocks.dart';

@GenerateMocks([AuthService])
void main() {
  late MockAuthService mockAuthService;

  final tUser = User(
    id: 'u1',
    email: 'a@test.com',
    emailVerified: true,
    username: 'chismoso',
    displayName: 'Chismoso Mayor',
    bio: 'Me entero de todo',
    avatarUrl: 'https://cdn.test/a.jpg',
    profileCompleted: true,
    createdAt: DateTime(2024, 1, 1),
  );
  final tUserNoAvatar = tUser.copyWith(avatarUrl: '');

  provideDummy<Result<Failure, User>>(Result.success(tUser));

  setUp(() {
    mockAuthService = MockAuthService();
  });

  EditProfileController create([User? user]) =>
      EditProfileController(mockAuthService, user ?? tUser);

  void stubUpdate(Result<Failure, User> result) {
    when(mockAuthService.updateProfile(
      username: anyNamed('username'),
      displayName: anyNamed('displayName'),
      bio: anyNamed('bio'),
      avatar: anyNamed('avatar'),
      removeAvatar: anyNamed('removeAvatar'),
    )).thenAnswer((_) async => result);
  }

  group('EditProfileController - estado inicial', () {
    test('sin cambios, sin foto nueva y con la foto actual', () {
      // Act
      final controller = create();

      // Assert
      expect(controller.saving, isFalse);
      expect(controller.failure, isNull);
      expect(controller.newAvatar, isNull);
      expect(controller.removeAvatar, isFalse);
      expect(controller.hasAvatar, isTrue);
      expect(
        controller.hasChanges(
          username: 'chismoso',
          displayName: 'Chismoso Mayor',
          bio: 'Me entero de todo',
        ),
        isFalse,
      );
    });

    test('usuario sin foto → hasAvatar false', () {
      expect(create(tUserNoAvatar).hasAvatar, isFalse);
    });
  });

  group('EditProfileController - hasChanges', () {
    test('detecta cambios en cada campo de texto', () {
      // Arrange
      final controller = create();

      // Act & Assert
      expect(controller.hasChanges(username: 'otro', displayName: 'Chismoso Mayor', bio: 'Me entero de todo'), isTrue);
      expect(controller.hasChanges(username: 'chismoso', displayName: 'Otro', bio: 'Me entero de todo'), isTrue);
      expect(controller.hasChanges(username: 'chismoso', displayName: 'Chismoso Mayor', bio: ''), isTrue);
    });

    test('ignora espacios alrededor', () {
      // Arrange
      final controller = create();

      // Act & Assert
      expect(
        controller.hasChanges(username: ' chismoso ', displayName: 'Chismoso Mayor  ', bio: ' Me entero de todo'),
        isFalse,
      );
    });

    test('campos null en el usuario equivalen a vacío', () {
      // Arrange
      final controller = create(User(
        id: 'u2',
        email: 'b@test.com',
        emailVerified: true,
        profileCompleted: false,
        createdAt: DateTime(2024),
      ));

      // Act & Assert
      expect(controller.hasChanges(username: '', displayName: '', bio: ''), isFalse);
      expect(controller.hasChanges(username: '', displayName: 'Nuevo', bio: ''), isTrue);
    });

    test('una foto nueva o quitar la foto cuentan como cambio', () {
      // Arrange
      final withNew = create()..setNewAvatar(Uint8List.fromList([1]));
      final removed = create()..clearAvatar();

      // Act & Assert
      expect(withNew.hasChanges(username: 'chismoso', displayName: 'Chismoso Mayor', bio: 'Me entero de todo'), isTrue);
      expect(removed.hasChanges(username: 'chismoso', displayName: 'Chismoso Mayor', bio: 'Me entero de todo'), isTrue);
    });
  });

  group('EditProfileController - foto', () {
    test('setNewAvatar guarda los bytes, cancela el quitar y notifica', () {
      // Arrange
      final controller = create()..clearAvatar();
      var notifications = 0;
      controller.addListener(() => notifications++);
      final bytes = Uint8List.fromList([1, 2, 3]);

      // Act
      controller.setNewAvatar(bytes);

      // Assert
      expect(controller.newAvatar, bytes);
      expect(controller.removeAvatar, isFalse);
      expect(controller.hasAvatar, isTrue);
      expect(notifications, 1);
    });

    test('clearAvatar con foto actual marca removeAvatar', () {
      // Arrange
      final controller = create()..setNewAvatar(Uint8List.fromList([1]));

      // Act
      controller.clearAvatar();

      // Assert
      expect(controller.newAvatar, isNull);
      expect(controller.removeAvatar, isTrue);
      expect(controller.hasAvatar, isFalse);
    });

    test('clearAvatar sin foto actual solo descarta la nueva', () {
      // Arrange
      final controller = create(tUserNoAvatar)..setNewAvatar(Uint8List.fromList([1]));

      // Act
      controller.clearAvatar();

      // Assert
      expect(controller.newAvatar, isNull);
      expect(controller.removeAvatar, isFalse);
      expect(
        controller.hasChanges(username: 'chismoso', displayName: 'Chismoso Mayor', bio: 'Me entero de todo'),
        isFalse,
      );
    });

    test('elegir o quitar foto limpia el error anterior', () async {
      // Arrange
      stubUpdate(Result.failure(const ServerFailure(code: ErrorCode.moderationUnavailable)));
      final controller = create();
      await controller.save(username: 'otro', displayName: 'Chismoso Mayor', bio: 'Me entero de todo');
      expect(controller.failure, isNotNull);

      // Act
      controller.setNewAvatar(Uint8List.fromList([1]));
      final afterSet = controller.failure;
      await controller.save(username: 'otro', displayName: 'Chismoso Mayor', bio: 'Me entero de todo');
      controller.clearAvatar();

      // Assert
      expect(afterSet, isNull);
      expect(controller.failure, isNull);
    });
  });

  group('EditProfileController - save', () {
    test('sin cambios no llama al servidor y retorna true', () async {
      // Arrange
      final controller = create();

      // Act
      final saved = await controller.save(
        username: 'chismoso',
        displayName: 'Chismoso Mayor',
        bio: 'Me entero de todo',
      );

      // Assert
      expect(saved, isTrue);
      verifyZeroInteractions(mockAuthService);
    });

    test('envía solo los campos que cambiaron, sin espacios', () async {
      // Arrange
      stubUpdate(Result.success(tUser));
      final controller = create();

      // Act
      final saved = await controller.save(
        username: 'chismoso',
        displayName: '  Nuevo Nombre ',
        bio: 'Me entero de todo',
      );

      // Assert
      expect(saved, isTrue);
      expect(controller.saving, isFalse);
      expect(controller.failure, isNull);
      verify(mockAuthService.updateProfile(
        username: null,
        displayName: 'Nuevo Nombre',
        bio: null,
        avatar: null,
        removeAvatar: false,
      )).called(1);
    });

    test('un campo vaciado se envía como "" para borrarlo', () async {
      // Arrange
      stubUpdate(Result.success(tUser));
      final controller = create();

      // Act
      await controller.save(username: 'chismoso', displayName: '', bio: '   ');

      // Assert
      verify(mockAuthService.updateProfile(
        username: null,
        displayName: '',
        bio: '',
        avatar: null,
        removeAvatar: false,
      )).called(1);
    });

    test('envía la foto nueva y el username cambiado', () async {
      // Arrange
      stubUpdate(Result.success(tUser));
      final bytes = Uint8List.fromList([9, 9]);
      final controller = create()..setNewAvatar(bytes);

      // Act
      await controller.save(username: 'nuevo_user', displayName: 'Chismoso Mayor', bio: 'Me entero de todo');

      // Assert
      verify(mockAuthService.updateProfile(
        username: 'nuevo_user',
        displayName: null,
        bio: null,
        avatar: bytes,
        removeAvatar: false,
      )).called(1);
    });

    test('quitar la foto envía removeAvatar', () async {
      // Arrange
      stubUpdate(Result.success(tUser));
      final controller = create()..clearAvatar();

      // Act
      await controller.save(username: 'chismoso', displayName: 'Chismoso Mayor', bio: 'Me entero de todo');

      // Assert
      verify(mockAuthService.updateProfile(
        username: null,
        displayName: null,
        bio: null,
        avatar: null,
        removeAvatar: true,
      )).called(1);
    });

    test('si falla guarda la Failure y retorna false', () async {
      // Arrange
      const failure = DataFailure(code: ErrorCode.usernameAlreadyTaken);
      stubUpdate(Result.failure(failure));
      final controller = create();

      // Act
      final saved = await controller.save(username: 'tomado', displayName: 'Chismoso Mayor', bio: 'Me entero de todo');

      // Assert
      expect(saved, isFalse);
      expect(controller.failure, failure);
      expect(controller.saving, isFalse);
    });

    test('marca saving mientras guarda y notifica al empezar y al terminar', () async {
      // Arrange
      stubUpdate(Result.success(tUser));
      final controller = create();
      final savingStates = <bool>[];
      controller.addListener(() => savingStates.add(controller.saving));

      // Act
      await controller.save(username: 'otro', displayName: 'Chismoso Mayor', bio: 'Me entero de todo');

      // Assert
      expect(savingStates, [true, false]);
    });

    test('ignora un segundo save mientras guarda', () async {
      // Arrange
      stubUpdate(Result.success(tUser));
      final controller = create();

      // Act
      final first = controller.save(username: 'otro', displayName: 'Chismoso Mayor', bio: 'Me entero de todo');
      final second = await controller.save(username: 'otro', displayName: 'Chismoso Mayor', bio: 'Me entero de todo');
      await first;

      // Assert
      expect(second, isFalse);
      verify(mockAuthService.updateProfile(
        username: anyNamed('username'),
        displayName: anyNamed('displayName'),
        bio: anyNamed('bio'),
        avatar: anyNamed('avatar'),
        removeAvatar: anyNamed('removeAvatar'),
      )).called(1);
    });
  });
}
