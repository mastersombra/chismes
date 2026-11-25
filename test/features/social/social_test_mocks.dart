import 'package:chismes/core/logging/app_logger.dart';
import 'package:chismes/core/navigation/social_navigator.dart';
import 'package:chismes/core/services/auth_service.dart';
import 'package:chismes/features/social/data/datasources/supabase_social_remote_data_source.dart';
import 'package:chismes/features/social/domain/repositories/social_repository.dart';
import 'package:mockito/annotations.dart';

/// Mocks compartidos por los tests del feature social (y por los tests de
/// otros features que usan [SocialNavigator]).
@GenerateMocks([
  SocialRepository,
  SupabaseSocialRemoteDataSource,
  AppLogger,
  AuthService,
  SocialNavigator,
])
void main() {}
