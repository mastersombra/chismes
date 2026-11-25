import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/result/result.dart';
import '../../../gossip/domain/entities/gossip.dart';
import '../entities/social_page.dart';
import '../repositories/social_repository.dart';

/// Chismes con perfil de un usuario (paginado por cursor)
@injectable
class GetUserGossips {
  final SocialRepository _repository;

  GetUserGossips(this._repository);

  Future<Result<Failure, SocialPage<Gossip>>> call(
    String userId, {
    int pageSize = 20,
    SocialCursor? cursor,
  }) =>
      _repository.getUserGossips(userId, pageSize: pageSize, cursor: cursor);
}
