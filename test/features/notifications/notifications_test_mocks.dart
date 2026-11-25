import 'package:chismes/core/logging/app_logger.dart';
import 'package:chismes/core/navigation/account_navigator.dart';
import 'package:chismes/core/navigation/notifications_navigator.dart';
import 'package:chismes/core/navigation/social_navigator.dart';
import 'package:chismes/core/services/auth_service.dart';
import 'package:chismes/features/notifications/data/datasources/supabase_notifications_remote_data_source.dart';
import 'package:chismes/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:mockito/annotations.dart';

/// Mocks compartidos por los tests del feature notifications (y por los de
/// home, que usan [NotificationsNavigator]).
@GenerateMocks([
  NotificationsRepository,
  SupabaseNotificationsRemoteDataSource,
  AppLogger,
  AuthService,
  NotificationsNavigator,
  SocialNavigator,
  AccountNavigator,
])
void main() {}
