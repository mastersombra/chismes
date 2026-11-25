import 'package:chismes/core/error/error_codes.dart';
import 'package:chismes/core/error/failure.dart';
import 'package:chismes/core/navigation/social_navigator.dart';
import 'package:chismes/core/result/result.dart';
import 'package:chismes/features/gossip/presentation/widgets/gossip_card.dart';
import 'package:chismes/features/social/domain/entities/follow_result.dart';
import 'package:chismes/features/social/domain/entities/user_profile.dart';
import 'package:chismes/features/social/presentation/screens/follow_list_screen.dart';
import 'package:chismes/features/social/presentation/screens/user_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../../../../helpers/fake_network_image.dart';
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
    when(repository.getUserGossips(any,
            pageSize: anyNamed('pageSize'), cursor: anyNamed('cursor')))
        .thenAnswer((_) async => Result.success(page([tProfileGossip('g1')])));
  });

  tearDown(unregisterSocialForWidgets);

  void stubProfile(UserProfile Function() profile, {String userId = kOtherUserId}) {
    when(repository.getUserProfile(userId))
        .thenAnswer((_) async => Result.success(profile()));
  }

  Future<void> pumpScreen(WidgetTester tester, {String userId = kOtherUserId}) async {
    useFakeNetworkImages(addTearDown);
    await tester.pumpWidget(testableWidget(
      useScaffold: false,
      child: UserProfileScreen(userId: userId),
    ));
    await tester.pumpAndSettle();
  }

  group('UserProfileScreen - estados', () {
    testWidgets('público que no sigo: datos, contadores, Seguir y sus chismes', (tester) async {
      stubProfile(() => tProfile(isFollowedBy: true));

      await pumpScreen(tester);

      expect(find.text('@ana'), findsWidgets); // título y header
      expect(find.text('Ana Pérez'), findsOneWidget);
      expect(find.text('Hola, soy Ana'), findsOneWidget);
      expect(find.byKey(const Key('followsYouChip')), findsOneWidget);
      expect(find.byKey(const Key('followButton')), findsOneWidget);
      expect(find.byKey(const Key('userProfileMenu')), findsOneWidget);
      expect(find.byType(GossipCard), findsOneWidget);
      // En el perfil del autor no se repite la fila de autor
      expect(find.byKey(const Key('gossipAuthorRow')), findsNothing);
    });

    testWidgets('privada que no sigo: aviso de cuenta privada, sin chismes', (tester) async {
      stubProfile(() => tProfile(isPrivate: true, canViewContent: false, gossipsCount: null));

      await pumpScreen(tester);

      expect(find.byKey(const Key('privateAccountMessage')), findsOneWidget);
      expect(find.text('Esta cuenta es privada'), findsOneWidget);
      expect(find.byType(GossipCard), findsNothing);
      // Nombre, bio y contadores sí se ven
      expect(find.text('Hola, soy Ana'), findsOneWidget);
      expect(find.text('10'), findsOneWidget);
      expect(find.text('–'), findsOneWidget); // chismes ocultos
      verifyNever(repository.getUserGossips(any,
          pageSize: anyNamed('pageSize'), cursor: anyNamed('cursor')));

      // Las listas no se abren
      await tester.tap(find.byKey(const Key('followersCount')));
      await tester.pumpAndSettle();
      expect(find.byType(FollowListScreen), findsNothing);
    });

    testWidgets('bloqueado por mí: Desbloquear, sin bio, contadores ni chismes', (tester) async {
      stubProfile(() => tProfile(hasBlocked: true));

      await pumpScreen(tester);

      expect(find.byKey(const Key('unblockButton')), findsOneWidget);
      expect(find.text('Bloqueaste esta cuenta'), findsOneWidget);
      expect(find.byKey(const Key('followersCount')), findsNothing);
      expect(find.byType(GossipCard), findsNothing);
      expect(find.byKey(const Key('followButton')), findsNothing);
    });

    testWidgets('mi propio perfil: sin botón de seguir ni menú', (tester) async {
      stubProfile(() => tProfile(id: kMyUserId, isMe: true), userId: kMyUserId);
      when(repository.getUserGossips(kMyUserId,
              pageSize: anyNamed('pageSize'), cursor: anyNamed('cursor')))
          .thenAnswer((_) async => Result.success(page([tProfileGossip('g1')])));

      await pumpScreen(tester, userId: kMyUserId);

      expect(find.byKey(const Key('followButton')), findsNothing);
      expect(find.byKey(const Key('followingButton')), findsNothing);
      expect(find.byKey(const Key('userProfileMenu')), findsNothing);
      expect(find.byType(GossipCard), findsOneWidget);
    });

    testWidgets('no disponible (me bloqueó o no existe)', (tester) async {
      when(repository.getUserProfile(kOtherUserId)).thenAnswer(
          (_) async => Result.failure(const DataFailure(code: ErrorCode.userNotAvailable)));

      await pumpScreen(tester);

      expect(find.text('Este usuario no está disponible'), findsOneWidget);
      expect(find.byKey(const Key('userProfileMenu')), findsNothing);
    });

    testWidgets('error de red: mensaje y reintentar', (tester) async {
      var fail = true;
      when(repository.getUserProfile(kOtherUserId)).thenAnswer((_) async => fail
          ? Result.failure(const NetworkFailure(code: ErrorCode.noInternetConnection))
          : Result.success(tProfile()));

      await pumpScreen(tester);
      expect(find.text('Reintentar'), findsOneWidget);

      fail = false;
      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('followButton')), findsOneWidget);
    });

    testWidgets('sin chismes con perfil: estado vacío', (tester) async {
      stubProfile(() => tProfile(gossipsCount: 0));
      when(repository.getUserGossips(any,
              pageSize: anyNamed('pageSize'), cursor: anyNamed('cursor')))
          .thenAnswer((_) async => Result.success(page(const [])));

      await pumpScreen(tester);

      expect(find.text('Todavía no hay chismes con perfil'), findsOneWidget);
    });
  });

  group('UserProfileScreen - acciones', () {
    testWidgets('Seguir en cuenta privada → Solicitado', (tester) async {
      var profile = tProfile(isPrivate: true, canViewContent: false);
      stubProfile(() => profile);
      when(repository.followUser(kOtherUserId)).thenAnswer((_) async {
        profile = tProfile(isPrivate: true, canViewContent: false, isRequested: true);
        return Result.success(FollowResult.requested);
      });
      await pumpScreen(tester);

      await tester.tap(find.byKey(const Key('followButton')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('requestedButton')), findsOneWidget);
      expect(find.text('Solicitado'), findsOneWidget);
    });

    testWidgets('Siguiendo → tocar deja de seguir', (tester) async {
      var profile = tProfile(isFollowing: true);
      stubProfile(() => profile);
      when(repository.unfollowUser(kOtherUserId)).thenAnswer((_) async {
        profile = tProfile();
        return Result.success(null);
      });
      await pumpScreen(tester);
      expect(find.text('Siguiendo'), findsWidgets);

      await tester.tap(find.byKey(const Key('followingButton')));
      await tester.pumpAndSettle();

      verify(repository.unfollowUser(kOtherUserId)).called(1);
      expect(find.byKey(const Key('followButton')), findsOneWidget);
    });

    testWidgets('límite de seguir (CS429): mensaje amigable', (tester) async {
      stubProfile(() => tProfile());
      when(repository.followUser(kOtherUserId)).thenAnswer((_) async =>
          Result.failure(const RateLimitFailure(code: ErrorCode.followRateLimited)));
      await pumpScreen(tester);

      await tester.tap(find.byKey(const Key('followButton')));
      await tester.pumpAndSettle();

      expect(
        find.text('Estás siguiendo a muchas personas muy rápido. Intenta más tarde.'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('followButton')), findsOneWidget);
    });

    testWidgets('Bloquear pide confirmación y bloquea', (tester) async {
      var profile = tProfile();
      stubProfile(() => profile);
      when(repository.blockUser(kOtherUserId)).thenAnswer((_) async {
        profile = tProfile(hasBlocked: true);
        return Result.success(null);
      });
      await pumpScreen(tester);

      await tester.tap(find.byKey(const Key('userProfileMenu')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bloquear'));
      await tester.pumpAndSettle();

      expect(find.text('¿Bloquear a Ana Pérez?'), findsOneWidget);
      verifyNever(repository.blockUser(any));

      await tester.tap(find.byKey(const Key('confirmBlockButton')));
      await tester.pumpAndSettle();

      verify(repository.blockUser(kOtherUserId)).called(1);
      expect(find.text('Bloqueaste a Ana Pérez'), findsOneWidget);
      expect(find.byKey(const Key('unblockButton')), findsOneWidget);
    });

    testWidgets('cancelar la confirmación no bloquea', (tester) async {
      stubProfile(() => tProfile());
      await pumpScreen(tester);

      await tester.tap(find.byKey(const Key('userProfileMenu')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bloquear'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      verifyNever(repository.blockUser(any));
    });

    testWidgets('Desbloquear desde el botón y desde el menú', (tester) async {
      var profile = tProfile(hasBlocked: true);
      stubProfile(() => profile);
      when(repository.unblockUser(kOtherUserId)).thenAnswer((_) async {
        profile = tProfile();
        return Result.success(null);
      });
      await pumpScreen(tester);

      await tester.tap(find.byKey(const Key('unblockButton')));
      await tester.pumpAndSettle();

      verify(repository.unblockUser(kOtherUserId)).called(1);
      expect(find.text('Desbloqueaste a Ana Pérez'), findsOneWidget);
      expect(find.byKey(const Key('followButton')), findsOneWidget);

      // Menú de un bloqueado ofrece Desbloquear
      profile = tProfile(hasBlocked: true);
      when(repository.blockUser(kOtherUserId)).thenAnswer((_) async => Result.success(null));
      await tester.tap(find.byKey(const Key('userProfileMenu')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bloquear'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirmBlockButton')));
      await tester.pumpAndSettle();
      profile = tProfile();
      await tester.tap(find.byKey(const Key('userProfileMenu')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Desbloquear').last);
      await tester.pumpAndSettle();

      verify(repository.unblockUser(kOtherUserId)).called(1);
    });

    testWidgets('tocar Seguidores abre la lista de seguidores', (tester) async {
      stubProfile(() => tProfile());
      when(repository.getFollowList(any, any,
              pageSize: anyNamed('pageSize'), cursor: anyNamed('cursor')))
          .thenAnswer((_) async => Result.success(page([tUser2])));
      await pumpScreen(tester);

      await tester.tap(find.byKey(const Key('followersCount')));
      await tester.pumpAndSettle();

      expect(find.byType(FollowListScreen), findsOneWidget);
      verify(repository.getFollowList(kOtherUserId, FollowListKind.followers,
              pageSize: anyNamed('pageSize'), cursor: null))
          .called(1);
    });
  });
}
