import 'package:chismes/core/di/injection_container.dart';
import 'package:chismes/core/l10n/locale_notifier.dart';
import 'package:chismes/core/navigation/social_navigator.dart';
import 'package:chismes/core/services/location_service.dart';
import 'package:chismes/core/theme/theme_mode_notifier.dart';
import 'package:chismes/features/auth/domain/entities/user.dart';
import 'package:chismes/features/profile/domain/entities/user_stats.dart';
import 'package:chismes/features/profile/presentation/controllers/profile_controller.dart';
import 'package:chismes/features/profile/presentation/screens/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../helpers/widget_test_wrapper.dart';
import '../../../social/social_test_mocks.mocks.dart';
import 'profile_screen_test.mocks.dart';

/// Perfil propio: contadores de seguidores/seguidos tocables y entradas a
/// solicitudes y bloqueados (vía SocialNavigator)
void main() {
  late MockProfileController controller;
  late MockSocialNavigator navigator;

  final user = User(
    id: 'me',
    email: 'me@example.com',
    emailVerified: true,
    username: 'yo',
    displayName: 'Yo',
    profileCompleted: true,
    createdAt: DateTime(2024, 1, 1),
  );

  void register<T extends Object>(T instance) {
    if (getIt.isRegistered<T>()) getIt.unregister<T>();
    getIt.registerSingleton<T>(instance);
  }

  void unregister<T extends Object>() {
    if (getIt.isRegistered<T>()) getIt.unregister<T>();
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    register<ThemeModeNotifier>(ThemeModeNotifier(await SharedPreferences.getInstance()));
    controller = MockProfileController();
    navigator = MockSocialNavigator();
    final locale = MockLocaleNotifier();
    final location = MockLocationService();
    when(location.getDefaultLocation()).thenAnswer((_) async => null);
    when(location.isAnonymousModeEnabled()).thenAnswer((_) async => false);
    when(locale.locale).thenReturn(const Locale('es'));

    when(controller.state).thenReturn(ProfileState.loaded);
    when(controller.currentUser).thenReturn(user);
    when(controller.userStats).thenReturn(const UserStats(
      gossipsCount: 1,
      commentsCount: 0,
      followersCount: 12,
      followingCount: 7,
    ));
    when(controller.settings).thenReturn(null);
    when(controller.getErrorMessage(any)).thenReturn(null);
    when(controller.loadProfile()).thenAnswer((_) async {});
    when(controller.refresh()).thenAnswer((_) async {});

    when(navigator.openFollowList(any,
            userId: anyNamed('userId'), kind: anyNamed('kind')))
        .thenAnswer((_) async {});
    when(navigator.openFollowRequests(any)).thenAnswer((_) async {});
    when(navigator.openBlockedUsers(any)).thenAnswer((_) async {});

    register<ProfileController>(controller);
    register<LocaleNotifier>(locale);
    register<LocationService>(location);
    register<SocialNavigator>(navigator);
  });

  tearDown(() {
    unregister<ThemeModeNotifier>();
    unregister<ProfileController>();
    unregister<LocaleNotifier>();
    unregister<LocationService>();
    unregister<SocialNavigator>();
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(testableWidget(useScaffold: false, child: const ProfileScreen()));
    await tester.pump();
  }

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(finder, 200, scrollable: find.byType(Scrollable).first);
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pump();
  }

  testWidgets('los contadores reales se muestran y abren mis listas', (tester) async {
    await pumpScreen(tester);

    expect(find.text('12'), findsOneWidget);
    expect(find.text('7'), findsOneWidget);

    await tapVisible(tester, find.byKey(const Key('profileFollowersStat')));
    verify(navigator.openFollowList(any, userId: 'me', kind: FollowListKind.followers))
        .called(1);

    await tapVisible(tester, find.byKey(const Key('profileFollowingStat')));
    verify(navigator.openFollowList(any, userId: 'me', kind: FollowListKind.following))
        .called(1);

    // Al volver se recargan los contadores
    verify(controller.refresh()).called(2);
  });

  testWidgets('Solicitudes de seguimiento abre la pantalla de solicitudes', (tester) async {
    await pumpScreen(tester);

    await tapVisible(tester, find.byKey(const Key('followRequestsEntry')));

    expect(find.text('Solicitudes de seguimiento'), findsOneWidget);
    verify(navigator.openFollowRequests(any)).called(1);
    verify(controller.refresh()).called(1);
  });

  testWidgets('Usuarios bloqueados abre la pantalla de bloqueados', (tester) async {
    await pumpScreen(tester);

    await tapVisible(tester, find.byKey(const Key('blockedUsersEntry')));

    verify(navigator.openBlockedUsers(any)).called(1);
  });
}
