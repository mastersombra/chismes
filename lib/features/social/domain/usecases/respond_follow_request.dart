import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/result/result.dart';
import '../repositories/social_repository.dart';

/// Acepta o rechaza una solicitud de seguimiento que me hicieron
@injectable
class RespondFollowRequest {
  final SocialRepository _repository;

  RespondFollowRequest(this._repository);

  Future<Result<Failure, void>> call(String requesterId, {required bool accept}) => _repository.respondFollowRequest(requesterId, accept: accept);
}
