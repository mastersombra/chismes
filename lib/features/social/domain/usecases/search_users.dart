import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/result/result.dart';
import '../entities/social_user.dart';
import '../repositories/social_repository.dart';

/// Busca usuarios por @usuario o nombre.
///
/// Mismas reglas que el servidor (`search_users`): se ignoran los espacios
/// y la @ inicial, y con menos de [minQueryLength] caracteres no se busca
/// (lista vacía, sin llamar al servidor).
@injectable
class SearchUsers {
  static const minQueryLength = 2;

  final SocialRepository _repository;

  SearchUsers(this._repository);

  Future<Result<Failure, List<SocialUser>>> call(
    String query, {
    int limit = 20,
  }) async {
    final normalized = normalize(query);
    if (normalized.length < minQueryLength) {
      return Result.success(const []);
    }
    return _repository.searchUsers(normalized, limit: limit);
  }

  /// Texto que se manda al servidor: sin espacios a los lados ni @ inicial
  static String normalize(String query) =>
      query.trim().replaceFirst(RegExp(r'^@+'), '').trim();
}
