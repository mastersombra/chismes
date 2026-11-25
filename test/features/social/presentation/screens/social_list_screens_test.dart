import 'package:chismes/core/error/error_codes.dart';
import 'package:chismes/core/error/failure.dart';
import 'package:chismes/core/navigation/social_navigator.dart';
import 'package:chismes/core/result/result.dart';
import 'package:chismes/features/social/domain/entities/follow_request.dart';
import 'package:chismes/features/social/presentation/screens/blocked_users_screen.dart';
import 'package:chismes/features/social/presentation/screens/follow_list_screen.dart';
import 'package:chismes/features/social/presentation/screens/follow_requests_screen.dart';
import 'package:chismes/features/social/presentation/screens/user_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../../../../helpers/widget_test_wrapper.dart';
import '../../social_di_helper.dart';
import '../../social_fixtures.dart';
import '../../social_test_mocks.mocks.dart';

void main() {
  late MockSocialRepository repository;

  setUpAll(provideSocialDummies);

  setUp(() {
    repository = MockSocialRepository();
    registerSocialForWidgets(repository);
    // Abrir un perfil desde una lista no debe romper
    when(repository.getUserProfile(any)).thenAnswer((_) async => Result.success(tProfile()));
    when(repository.getUserGossips(any,
            pageSize: anyNamed('pageSize'), cursor: anyNamed('cursor')))
        .thenAnswer((_) async => Result.success(page(const [])));
  });

  tearDown(unregisterSocialForWidgets);

  Future<void> pump(WidgetTester tester, Widget screen) async {
    await tester.pumpWidget(testableWidget(useScaffold: false, child: screen));
    await tester.pumpAndSettle();
  }

  void stubList(String userId, FollowListKind kind, List users) {
    when(repository.getFollowList(userId, kind,
            pageSize: anyNamed('pageSize'), cursor: anyNamed('cursor')))
        .thenAnswer((_) async => Result.success(page(users.cast())));
  }

  group('FollowListScreen', () {
    testWidgets('mis seguidores: muestra Quitar y quita tras confirmar', (tester) async {
      stubList(kMyUserId, FollowListKind.followers, [tUser, tUser2]);
      stubList(kMyUserId, FollowListKind.following, []);
      when(repository.removeFollower(tUser.id)).thenAnswer((_) async => Result.success(null));

      await pump(tester, const FollowListScreen(userId: kMyUserId));

      expect(find.text('Ana Pérez'), findsOneWidget);
      expect(find.text('@ana'), findsOneWidget);
      expect(find.byKey(Key('removeFollower_${tUser.id}')), findsOneWidget);

      await tester.tap(find.byKey(Key('removeFollower_${tUser.id}')));
      await tester.pumpAndSettle();
      expect(find.text('¿Quitar a Ana Pérez de tus seguidores?'), findsOneWidget);
      await tester.tap(find.byKey(const Key('confirmRemoveFollowerButton')));
      await tester.pumpAndSettle();

      verify(repository.removeFollower(tUser.id)).called(1);
      expect(find.text('Quitaste a Ana Pérez de tus seguidores'), findsOneWidget);
      expect(find.byKey(Key('userTile_${tUser.id}')), findsNothing);
      expect(find.byKey(Key('userTile_${tUser2.id}')), findsOneWidget);
    });

    testWidgets('seguidores de otro: sin Quitar; abre en la pestaña pedida', (tester) async {
      stubList(kOtherUserId, FollowListKind.followers, [tUser2]);
      stubList(kOtherUserId, FollowListKind.following, [tUser]);

      await pump(
        tester,
        const FollowListScreen(userId: kOtherUserId, initialKind: FollowListKind.following),
      );

      // Pestaña Siguiendo
      expect(find.byKey(Key('userTile_${tUser.id}')), findsOneWidget);
      expect(find.text('Quitar'), findsNothing);

      await tester.tap(find.text('Seguidores'));
      await tester.pumpAndSettle();
      expect(find.byKey(Key('userTile_${tUser2.id}')), findsOneWidget);
      expect(find.text('Quitar'), findsNothing);
    });

    testWidgets('lista vacía y cuenta privada', (tester) async {
      stubList(kOtherUserId, FollowListKind.followers, []);
      when(repository.getFollowList(kOtherUserId, FollowListKind.following,
              pageSize: anyNamed('pageSize'), cursor: anyNamed('cursor')))
          .thenAnswer((_) async =>
              Result.failure(const DataFailure(code: ErrorCode.userNotAvailable)));

      await pump(tester, const FollowListScreen(userId: kOtherUserId));
      expect(find.text('Todavía no hay seguidores'), findsOneWidget);

      await tester.tap(find.text('Siguiendo'));
      await tester.pumpAndSettle();
      expect(find.text('Esta cuenta es privada'), findsOneWidget);
    });

    testWidgets('tocar un usuario abre su perfil', (tester) async {
      stubList(kOtherUserId, FollowListKind.followers, [tUser2]);
      stubList(kOtherUserId, FollowListKind.following, []);

      await pump(tester, const FollowListScreen(userId: kOtherUserId));
      await tester.tap(find.byKey(Key('userTile_${tUser2.id}')));
      await tester.pumpAndSettle();

      expect(find.byType(UserProfileScreen), findsOneWidget);
      verify(repository.getUserProfile(tUser2.id)).called(1);
    });

    testWidgets('error con reintentar', (tester) async {
      var fail = true;
      when(repository.getFollowList(any, any,
              pageSize: anyNamed('pageSize'), cursor: anyNamed('cursor')))
          .thenAnswer((_) async => fail
              ? Result.failure(const NetworkFailure(code: ErrorCode.noInternetConnection))
              : Result.success(page([tUser])));

      await pump(tester, const FollowListScreen(userId: kOtherUserId));
      fail = false;
      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();

      expect(find.byKey(Key('userTile_${tUser.id}')), findsOneWidget);
    });
  });

  group('FollowRequestsScreen', () {
    final request2 = FollowRequest(user: tUser2, createdAt: DateTime.utc(2026, 11, 20));

    testWidgets('Aceptar y Rechazar responden y quitan la solicitud', (tester) async {
      when(repository.getFollowRequests())
          .thenAnswer((_) async => Result.success([tRequest, request2]));
      when(repository.respondFollowRequest(any, accept: anyNamed('accept')))
          .thenAnswer((_) async => Result.success(null));

      await pump(tester, const FollowRequestsScreen());
      expect(find.text('Solicitudes de seguimiento'), findsOneWidget);

      await tester.tap(find.byKey(Key('acceptRequest_${tUser.id}')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(Key('rejectRequest_${tUser2.id}')));
      await tester.pumpAndSettle();

      verify(repository.respondFollowRequest(tUser.id, accept: true)).called(1);
      verify(repository.respondFollowRequest(tUser2.id, accept: false)).called(1);
      expect(find.text('No tienes solicitudes pendientes'), findsOneWidget);
    });

    testWidgets('error al responder: snackbar y la solicitud queda', (tester) async {
      when(repository.getFollowRequests()).thenAnswer((_) async => Result.success([tRequest]));
      when(repository.respondFollowRequest(any, accept: anyNamed('accept'))).thenAnswer(
          (_) async => Result.failure(const NetworkFailure(code: ErrorCode.noInternetConnection)));

      await pump(tester, const FollowRequestsScreen());
      await tester.tap(find.byKey(Key('acceptRequest_${tUser.id}')));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.byKey(Key('userTile_${tUser.id}')), findsOneWidget);
    });

    testWidgets('error al cargar: reintentar', (tester) async {
      when(repository.getFollowRequests()).thenAnswer(
          (_) async => Result.failure(const NetworkFailure(code: ErrorCode.noInternetConnection)));

      await pump(tester, const FollowRequestsScreen());

      expect(find.text('Reintentar'), findsOneWidget);
    });
  });

  group('BlockedUsersScreen', () {
    testWidgets('Desbloquear lo quita de la lista', (tester) async {
      when(repository.getBlockedUsers()).thenAnswer((_) async => Result.success([tUser]));
      when(repository.unblockUser(tUser.id)).thenAnswer((_) async => Result.success(null));

      await pump(tester, const BlockedUsersScreen());
      expect(find.text('Usuarios bloqueados'), findsOneWidget);

      await tester.tap(find.byKey(Key('unblock_${tUser.id}')));
      await tester.pumpAndSettle();

      verify(repository.unblockUser(tUser.id)).called(1);
      expect(find.text('Desbloqueaste a Ana Pérez'), findsOneWidget);
      expect(find.text('No has bloqueado a nadie'), findsOneWidget);
    });

    testWidgets('error al desbloquear: snackbar y queda en la lista', (tester) async {
      when(repository.getBlockedUsers()).thenAnswer((_) async => Result.success([tUser]));
      when(repository.unblockUser(tUser.id)).thenAnswer(
          (_) async => Result.failure(const NetworkFailure(code: ErrorCode.noInternetConnection)));

      await pump(tester, const BlockedUsersScreen());
      await tester.tap(find.byKey(Key('unblock_${tUser.id}')));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.byKey(Key('userTile_${tUser.id}')), findsOneWidget);
    });

    testWidgets('error al cargar: reintentar recarga', (tester) async {
      var fail = true;
      when(repository.getBlockedUsers()).thenAnswer((_) async => fail
          ? Result.failure(const NetworkFailure(code: ErrorCode.noInternetConnection))
          : Result.success([tUser2]));

      await pump(tester, const BlockedUsersScreen());
      fail = false;
      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();

      expect(find.byKey(Key('userTile_${tUser2.id}')), findsOneWidget);
    });
  });
}
