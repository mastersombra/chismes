import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/result/result.dart';
import '../entities/follow_request.dart';
import '../repositories/social_repository.dart';

/// Solicitudes de seguimiento que me hicieron
@injectable
class GetFollowRequests {
  final SocialRepository _repository;

  GetFollowRequests(this._repository);

  Future<Result<Failure, List<FollowRequest>>> call() => _repository.getFollowRequests();
}
