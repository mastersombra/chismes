import 'package:chismes/core/di/injection_container.dart';
import 'package:chismes/core/navigation/social_navigator.dart';
import 'package:chismes/core/result/result.dart';
import 'package:chismes/features/social/presentation/screens/blocked_users_screen.dart';
import 'package:chismes/features/social/presentation/screens/follow_list_screen.dart';
import 'package:chismes/features/social/presentation/screens/follow_requests_screen.dart';
import 'package:chismes/features/social/presentation/screens/user_profile_screen.dart';
import 'package:chismes/features/social/presentation/widgets/user_search_results.dart';
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
    when(repository.getUserProfile(any)).thenAnswer((_) async => Result.success(tProfile()));
    when(repository.getUserGossips(any,
            pageSize: anyNamed('pageSize'), cursor: anyNamed('cursor')))
        .thenAnswer((_) async => Result.success(page(const [])));
    when(repository.getFollowList(any, any,
            pageSize: anyNamed('pageSize'), cursor: anyNamed('cursor')))
        .thenAnswer((_) async => Result.success(page(const [])));
    when(repository.getFollowRequests()).thenAnswer((_) async => Result.success(const []));
    when(repository.getBlockedUsers()).thenAnswer((_) async => Result.success(const []));
  });

  tearDown(unregisterSocialForWidgets);

  Future<void> openWith(
    WidgetTester tester,
    Future<void> Function(BuildContext context, SocialNavigator nav) open,
  ) async {
    await tester.pumpWidget(testableWidget(
      child: Builder(
        builder: (context) => TextButton(
          onPressed: () => open(context, getIt<SocialNavigator>()),
          child: const Text('abrir'),
        ),
      ),
    ));
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
  }

  testWidgets('openUserProfile abre UserProfileScreen del usuario', (tester) async {
    await openWith(tester, (c, nav) => nav.openUserProfile(c, kOtherUserId));

    final screen = tester.widget<UserProfileScreen>(find.byType(UserProfileScreen));
    expect(screen.userId, kOtherUserId);
  });

  testWidgets('openFollowList abre la lista en la pestaña pedida', (tester) async {
    await openWith(
      tester,
      (c, nav) => nav.openFollowList(c, userId: kMyUserId, kind: FollowListKind.following),
    );

    final screen = tester.widget<FollowListScreen>(find.byType(FollowListScreen));
    expect(screen.userId, kMyUserId);
    expect(screen.initialKind, FollowListKind.following);
  });

  testWidgets('openFollowRequests abre FollowRequestsScreen', (tester) async {
    await openWith(tester, (c, nav) => nav.openFollowRequests(c));

    expect(find.byType(FollowRequestsScreen), findsOneWidget);
  });

  testWidgets('openBlockedUsers abre BlockedUsersScreen', (tester) async {
    await openWith(tester, (c, nav) => nav.openBlockedUsers(c));

    expect(find.byType(BlockedUsersScreen), findsOneWidget);
  });

  test('buildUserSearchResults arma UserSearchResults con el texto', () {
    final widget = getIt<SocialNavigator>().buildUserSearchResults('ana');

    expect(widget, isA<UserSearchResults>());
    expect((widget as UserSearchResults).query, 'ana');
  });
}
