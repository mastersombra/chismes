import 'dart:async';
import 'dart:io';

import 'package:chismes/core/di/injection_container.dart';
import 'package:chismes/core/error/error_codes.dart';
import 'package:chismes/core/error/failure.dart';
import 'package:chismes/core/result/result.dart';
import 'package:chismes/core/services/auth_service.dart';
import 'package:chismes/features/auth/domain/entities/user.dart';
import 'package:chismes/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:chismes/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../../../../helpers/fake_image_compress.dart';
import '../../../../helpers/fake_network_image.dart';
import 'edit_profile_screen_test.mocks.dart';

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
  final tPng = Uint8List.fromList(kTransparentPng);

  provideDummy<Result<Failure, User>>(Result.success(tUser));

  setUp(() {
    mockAuthService = MockAuthService();
    if (getIt.isRegistered<AuthService>()) getIt.unregister<AuthService>();
    getIt.registerSingleton<AuthService>(mockAuthService);
  });

  tearDown(() {
    if (getIt.isRegistered<AuthService>()) getIt.unregister<AuthService>();
  });

  void stubUpdate(Future<Result<Failure, User>> Function() answer) {
    when(mockAuthService.updateProfile(
      username: anyNamed('username'),
      displayName: anyNamed('displayName'),
      bio: anyNamed('bio'),
      avatar: anyNamed('avatar'),
      removeAvatar: anyNamed('removeAvatar'),
    )).thenAnswer((_) => answer());
  }

  /// Abre EditProfileScreen sobre una pantalla base y guarda lo que devuelve
  Future<List<bool?>> open(
    WidgetTester tester, {
    User? user,
    AvatarPicker? picker,
  }) async {
    useFakeNetworkImages(addTearDown);
    final results = <bool?>[];
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('es'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () async {
              results.add(await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => EditProfileScreen(user: user ?? tUser, avatarPicker: picker),
                ),
              ));
            },
            child: const Text('abrir'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    return results;
  }

  TextButton saveButton(WidgetTester tester) =>
      tester.widget<TextButton>(find.byKey(const Key('editProfileSave')));

  Future<void> tapSave(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('editProfileSave')));
    await tester.pumpAndSettle();
  }

  Future<void> chooseInSheet(WidgetTester tester, String key) async {
    await tester.tap(find.byKey(const Key('editProfileAvatar')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(Key(key)));
    await tester.pumpAndSettle();
  }

  group('EditProfileScreen - renderizado', () {
    testWidgets('muestra los datos actuales del perfil', (tester) async {
      // Act
      await open(tester);

      // Assert
      expect(find.text('Editar perfil'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Chismoso Mayor'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'chismoso'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Me entero de todo'), findsOneWidget);
      expect(find.text('Puedes cambiarlo una vez cada 30 días'), findsOneWidget);
      final avatar = tester.widget<CircleAvatar>(find.descendant(
        of: find.byKey(const Key('editProfileAvatar')),
        matching: find.byType(CircleAvatar),
      ).first);
      expect(avatar.backgroundImage, isA<NetworkImage>());
    });

    testWidgets('usuario sin foto muestra el ícono de persona', (tester) async {
      // Act
      await open(tester, user: tUserNoAvatar);

      // Assert
      expect(find.byIcon(Icons.person), findsOneWidget);
    });

    testWidgets('Guardar está deshabilitado hasta que hay cambios', (tester) async {
      // Arrange
      await open(tester);
      expect(saveButton(tester).onPressed, isNull);

      // Act
      await tester.enterText(find.byKey(const Key('editProfileBio')), 'Bio nueva');
      await tester.pump();

      // Assert
      expect(saveButton(tester).onPressed, isNotNull);

      // Act - volver al valor original
      await tester.enterText(find.byKey(const Key('editProfileBio')), 'Me entero de todo');
      await tester.pump();

      // Assert
      expect(saveButton(tester).onPressed, isNull);
    });
  });

  group('EditProfileScreen - guardar', () {
    testWidgets('guarda solo lo que cambió, avisa y cierra con true', (tester) async {
      // Arrange
      stubUpdate(() async => Result.success(tUser));
      final results = await open(tester);

      // Act
      await tester.enterText(find.byKey(const Key('editProfileDisplayName')), 'Nuevo Nombre');
      await tester.pump();
      await tapSave(tester);

      // Assert
      verify(mockAuthService.updateProfile(
        username: null,
        displayName: 'Nuevo Nombre',
        bio: null,
        avatar: null,
        removeAvatar: false,
      )).called(1);
      expect(find.byType(EditProfileScreen), findsNothing);
      expect(results, [true]);
      expect(find.text('Perfil actualizado'), findsOneWidget);
    });

    testWidgets('muestra un spinner y bloquea los campos mientras guarda', (tester) async {
      // Arrange
      final completer = Completer<Result<Failure, User>>();
      stubUpdate(() => completer.future);
      await open(tester);
      await tester.enterText(find.byKey(const Key('editProfileBio')), 'Otra bio');
      await tester.pump();

      // Act
      await tester.tap(find.byKey(const Key('editProfileSave')));
      await tester.pump();

      // Assert
      expect(find.byKey(const Key('editProfileSave')), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      final field = tester.widget<TextField>(find.descendant(
        of: find.byKey(const Key('editProfileBio')),
        matching: find.byType(TextField),
      ));
      expect(field.enabled, isFalse);

      // Cleanup
      completer.complete(Result.success(tUser));
      await tester.pumpAndSettle();
    });

    testWidgets('no guarda si el @usuario no pasa la validación local', (tester) async {
      // Arrange
      await open(tester);

      // Act
      await tester.enterText(find.byKey(const Key('editProfileUsername')), 'Con Mayus');
      await tester.pump();
      await tapSave(tester);

      // Assert
      expect(
        find.text('El nombre de usuario solo puede contener letras minúsculas, números y guiones bajos'),
        findsOneWidget,
      );
      verifyNever(mockAuthService.updateProfile(
        username: anyNamed('username'),
        displayName: anyNamed('displayName'),
        bio: anyNamed('bio'),
        avatar: anyNamed('avatar'),
        removeAvatar: anyNamed('removeAvatar'),
      ));
      expect(find.byType(EditProfileScreen), findsOneWidget);
    });

    Future<void> saveUsernameWith(WidgetTester tester, Failure failure) async {
      stubUpdate(() async => Result.failure(failure));
      await open(tester);
      await tester.enterText(find.byKey(const Key('editProfileUsername')), 'nuevo_user');
      await tester.pump();
      await tapSave(tester);
    }

    testWidgets('@usuario tomado: error bajo el campo, sin SnackBar', (tester) async {
      // Act
      await saveUsernameWith(tester, const DataFailure(code: ErrorCode.usernameAlreadyTaken));

      // Assert
      expect(find.text('Este nombre de usuario ya está en uso'), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
      expect(find.byType(EditProfileScreen), findsOneWidget);
    });

    testWidgets('@usuario en cooldown: muestra la fecha bajo el campo', (tester) async {
      // Arrange
      final at = DateTime(2026, 12, 20, 12);

      // Act
      await saveUsernameWith(tester, UsernameCooldownFailure(availableAt: at));

      // Assert
      final context = tester.element(find.byType(EditProfileScreen));
      final date = MaterialLocalizations.of(context).formatMediumDate(at);
      expect(
        find.text('Ya cambiaste tu usuario hace poco. Podrás cambiarlo de nuevo el $date.'),
        findsOneWidget,
      );
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('@usuario reservado: error bajo el campo', (tester) async {
      // Act
      await saveUsernameWith(tester, const ValidationFailure(code: ErrorCode.usernameReserved));

      // Assert
      expect(find.text('Ese nombre de usuario no está disponible.'), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('otros errores se muestran en un SnackBar', (tester) async {
      // Arrange
      stubUpdate(() async =>
          Result.failure(const ServerFailure(code: ErrorCode.moderationUnavailable)));
      await open(tester);
      await tester.enterText(find.byKey(const Key('editProfileBio')), 'Otra bio');
      await tester.pump();

      // Act
      await tapSave(tester);

      // Assert
      expect(find.byType(SnackBar), findsOneWidget);
      expect(
        find.text('No pudimos revisar el cambio ahora. Intenta de nuevo en unos minutos.'),
        findsOneWidget,
      );
      expect(find.byType(EditProfileScreen), findsOneWidget);
    });
  });

  group('EditProfileScreen - foto', () {
    testWidgets('galería: usa la foto elegida y la envía al guardar', (tester) async {
      // Arrange
      final sources = <ImageSource>[];
      stubUpdate(() async => Result.success(tUser));
      await open(tester, picker: (source) async {
        sources.add(source);
        return tPng;
      });

      // Act
      await chooseInSheet(tester, 'editProfilePhotoGallery');

      // Assert
      expect(sources, [ImageSource.gallery]);
      final avatar = tester.widget<CircleAvatar>(find.descendant(
        of: find.byKey(const Key('editProfileAvatar')),
        matching: find.byType(CircleAvatar),
      ).first);
      expect(avatar.backgroundImage, isA<MemoryImage>());
      expect(saveButton(tester).onPressed, isNotNull);

      // Act
      await tapSave(tester);

      // Assert
      verify(mockAuthService.updateProfile(
        username: null,
        displayName: null,
        bio: null,
        avatar: tPng,
        removeAvatar: false,
      )).called(1);
    });

    testWidgets('cámara: pide la foto a la cámara', (tester) async {
      // Arrange
      final sources = <ImageSource>[];
      await open(tester, picker: (source) async {
        sources.add(source);
        return tPng;
      });

      // Act
      await chooseInSheet(tester, 'editProfilePhotoCamera');

      // Assert
      expect(sources, [ImageSource.camera]);
    });

    testWidgets('si cancela la elección no cambia nada', (tester) async {
      // Arrange
      await open(tester, picker: (_) async => null);

      // Act
      await chooseInSheet(tester, 'editProfilePhotoGallery');

      // Assert
      expect(saveButton(tester).onPressed, isNull);
    });

    testWidgets('si la foto falla muestra un aviso', (tester) async {
      // Arrange
      await open(tester, picker: (_) async => throw Exception('heic'));

      // Act
      await chooseInSheet(tester, 'editProfilePhotoGallery');

      // Assert
      expect(find.text('No se pudo usar esa foto. Prueba con otra.'), findsOneWidget);
      expect(saveButton(tester).onPressed, isNull);
    });

    testWidgets('quitar foto: la quita y envía removeAvatar', (tester) async {
      // Arrange
      stubUpdate(() async => Result.success(tUser));
      await open(tester);

      // Act
      await chooseInSheet(tester, 'editProfilePhotoRemove');

      // Assert
      expect(find.byIcon(Icons.person), findsOneWidget);
      await tapSave(tester);
      verify(mockAuthService.updateProfile(
        username: null,
        displayName: null,
        bio: null,
        avatar: null,
        removeAvatar: true,
      )).called(1);
    });

    testWidgets('sin foto no ofrece "Quitar foto"', (tester) async {
      // Arrange
      await open(tester, user: tUserNoAvatar);

      // Act
      await tester.tap(find.byKey(const Key('editProfileAvatar')));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byKey(const Key('editProfilePhotoGallery')), findsOneWidget);
      expect(find.byKey(const Key('editProfilePhotoCamera')), findsOneWidget);
      expect(find.byKey(const Key('editProfilePhotoRemove')), findsNothing);
    });

    testWidgets('cerrar el menú sin elegir no cambia nada', (tester) async {
      // Arrange
      await open(tester);
      await tester.tap(find.byKey(const Key('editProfileAvatar')));
      await tester.pumpAndSettle();

      // Act - tocar fuera del sheet
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byKey(const Key('editProfilePhotoGallery')), findsNothing);
      expect(saveButton(tester).onPressed, isNull);
    });

    testWidgets('picker por defecto: elige con image_picker y comprime', (tester) async {
      // Arrange - image_picker (canal) devuelve un archivo y el compresor, bytes
      final dir = Directory.systemTemp.createTempSync('edit_profile_test');
      addTearDown(() => dir.deleteSync(recursive: true));
      final picked = File('${dir.path}/foto.jpg')..writeAsBytesSync([1, 2, 3]);
      final compress = FakeImageCompress.install();
      addTearDown(compress.uninstall);
      compress.outputData = (_) => tPng;
      final pickCalls = <MethodCall>[];
      const channel = MethodChannel('plugins.flutter.io/image_picker');
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
        pickCalls.add(call);
        return picked.path;
      });
      addTearDown(() =>
          tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null));
      await open(tester, user: tUserNoAvatar);

      // Act
      await chooseInSheet(tester, 'editProfilePhotoGallery');
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pumpAndSettle();

      // Assert
      expect(pickCalls.single.method, 'pickImage');
      expect(pickCalls.single.arguments['maxWidth'], 1920);
      expect(pickCalls.single.arguments['imageQuality'], 85);
      expect(compress.calls.single.path, picked.absolute.path);
      expect(compress.calls.single.minWidth, 400);
      expect(saveButton(tester).onPressed, isNotNull);
    });
  });

  group('EditProfileScreen - salir', () {
    testWidgets('sin cambios vuelve atrás directamente', (tester) async {
      // Arrange
      final results = await open(tester);

      // Act
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(EditProfileScreen), findsNothing);
      expect(find.byType(AlertDialog), findsNothing);
      expect(results, [null]);
    });

    testWidgets('con cambios pregunta antes de descartar; Cancelar se queda',
        (tester) async {
      // Arrange
      await open(tester);
      await tester.enterText(find.byKey(const Key('editProfileBio')), 'Otra bio');
      await tester.pump();

      // Act
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('¿Descartar los cambios?'), findsOneWidget);

      // Act
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.byType(EditProfileScreen), findsOneWidget);
    });

    testWidgets('con cambios, Descartar cierra con false', (tester) async {
      // Arrange
      final results = await open(tester);
      await tester.enterText(find.byKey(const Key('editProfileBio')), 'Otra bio');
      await tester.pump();

      // Act
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('editProfileDiscardConfirm')));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(EditProfileScreen), findsNothing);
      expect(results, [false]);
      verifyZeroInteractions(mockAuthService);
    });
  });
}
