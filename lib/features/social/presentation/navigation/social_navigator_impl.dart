import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/navigation/social_navigator.dart';
import '../screens/blocked_users_screen.dart';
import '../screens/follow_list_screen.dart';
import '../screens/follow_requests_screen.dart';
import '../screens/user_profile_screen.dart';
import '../widgets/user_search_results.dart';

/// [SocialNavigator] del feature social: abre sus pantallas
@Singleton(as: SocialNavigator)
class SocialNavigatorImpl implements SocialNavigator {
  @override
  Future<void> openUserProfile(BuildContext context, String userId) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => UserProfileScreen(userId: userId)),
    );
  }

  @override
  Future<void> openFollowList(
    BuildContext context, {
    required String userId,
    required FollowListKind kind,
  }) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => FollowListScreen(userId: userId, initialKind: kind),
      ),
    );
  }

  @override
  Future<void> openFollowRequests(BuildContext context) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => const FollowRequestsScreen()),
    );
  }

  @override
  Future<void> openBlockedUsers(BuildContext context) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => const BlockedUsersScreen()),
    );
  }

  @override
  Widget buildUserSearchResults(String query) => UserSearchResults(query: query);
}
