import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/result/result.dart';
import '../../../../core/navigation/social_navigator.dart';
import '../entities/social_page.dart';
import '../entities/social_user.dart';
import '../repositories/social_repository.dart';

/// Seguidores o seguidos de un usuario (paginado por cursor)
@injectable
class GetFollowList {
  final SocialRepository _repository;

  GetFollowList(this._repository);

  Future<Result<Failure, SocialPage<SocialUser>>> call(
    String userId,
    FollowListKind kind, {
    int pageSize = 30,
    SocialCursor? cursor,
  }) =>
      _repository.getFollowList(userId, kind, pageSize: pageSize, cursor: cursor);
}
