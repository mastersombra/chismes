import 'package:chismes/core/di/injection_container.dart';
import 'package:chismes/core/navigation/social_navigator.dart';
import 'package:chismes/features/social/domain/usecases/block_user.dart';
import 'package:chismes/features/social/domain/usecases/follow_user.dart';
import 'package:chismes/features/social/domain/usecases/get_blocked_users.dart';
import 'package:chismes/features/social/domain/usecases/get_follow_list.dart';
import 'package:chismes/features/social/domain/usecases/get_follow_requests.dart';
import 'package:chismes/features/social/domain/usecases/get_user_gossips.dart';
import 'package:chismes/features/social/domain/usecases/get_user_profile.dart';
import 'package:chismes/features/social/domain/usecases/remove_follower.dart';
import 'package:chismes/features/social/domain/usecases/respond_follow_request.dart';
import 'package:chismes/features/social/domain/usecases/search_users.dart';
import 'package:chismes/features/social/domain/usecases/unblock_user.dart';
import 'package:chismes/features/social/domain/usecases/unfollow_user.dart';
import 'package:chismes/features/social/presentation/controllers/blocked_users_controller.dart';
import 'package:chismes/features/social/presentation/controllers/follow_list_controller.dart';
import 'package:chismes/features/social/presentation/controllers/follow_requests_controller.dart';
import 'package:chismes/features/social/presentation/controllers/user_profile_controller.dart';
import 'package:chismes/features/social/presentation/controllers/user_search_controller.dart';
import 'package:chismes/features/social/presentation/navigation/social_navigator_impl.dart';
import 'package:mockito/mockito.dart';

import 'social_fixtures.dart';
import 'social_test_mocks.mocks.dart';

/// Registra en GetIt los controllers REALES del feature social sobre un
/// [repository] mockeado (como factories: cada pantalla crea el suyo y lo
/// libera al cerrarse) y el [SocialNavigatorImpl] real.
void registerSocialForWidgets(
  MockSocialRepository repository, {
  String myUserId = kMyUserId,
}) {
  unregisterSocialForWidgets();
  final auth = MockAuthService();
  when(auth.userId).thenReturn(myUserId);
  final logger = MockAppLogger();

  getIt.registerFactory<UserProfileController>(() => UserProfileController(
        GetUserProfile(repository),
        GetUserGossips(repository),
        FollowUser(repository),
        UnfollowUser(repository),
        BlockUser(repository),
        UnblockUser(repository),
        logger,
      ));
  getIt.registerFactory<FollowListController>(() => FollowListController(
        GetFollowList(repository),
        RemoveFollower(repository),
        auth,
        logger,
      ));
  getIt.registerFactory<FollowRequestsController>(() => FollowRequestsController(
        GetFollowRequests(repository),
        RespondFollowRequest(repository),
      ));
  getIt.registerFactory<BlockedUsersController>(
      () => BlockedUsersController(GetBlockedUsers(repository), UnblockUser(repository)));
  getIt.registerFactory<UserSearchController>(
      () => UserSearchController(SearchUsers(repository)));
  getIt.registerSingleton<SocialNavigator>(SocialNavigatorImpl());
}

void unregisterSocialForWidgets() {
  for (final unregister in [
    () => getIt.isRegistered<UserProfileController>()
        ? getIt.unregister<UserProfileController>()
        : null,
    () => getIt.isRegistered<FollowListController>()
        ? getIt.unregister<FollowListController>()
        : null,
    () => getIt.isRegistered<FollowRequestsController>()
        ? getIt.unregister<FollowRequestsController>()
        : null,
    () => getIt.isRegistered<BlockedUsersController>()
        ? getIt.unregister<BlockedUsersController>()
        : null,
    () => getIt.isRegistered<UserSearchController>()
        ? getIt.unregister<UserSearchController>()
        : null,
    () => getIt.isRegistered<SocialNavigator>() ? getIt.unregister<SocialNavigator>() : null,
  ]) {
    unregister();
  }
}
