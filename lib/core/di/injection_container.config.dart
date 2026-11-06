// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:flutter/material.dart' as _i409;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;
import 'package:supabase_flutter/supabase_flutter.dart' as _i454;

import '../../features/auth/data/datasources/supabase_auth_datasource.dart'
    as _i76;
import '../../features/auth/data/datasources/supabase_auth_datasource_impl.dart'
    as _i743;
import '../../features/auth/data/repositories/auth_repository_impl.dart'
    as _i153;
import '../../features/auth/domain/repositories/auth_repository.dart' as _i787;
import '../../features/auth/domain/usecases/get_current_user.dart' as _i111;
import '../../features/auth/domain/usecases/is_username_available.dart'
    as _i910;
import '../../features/auth/domain/usecases/reset_password.dart' as _i1066;
import '../../features/auth/domain/usecases/sign_in_with_apple.dart' as _i263;
import '../../features/auth/domain/usecases/sign_in_with_email.dart' as _i485;
import '../../features/auth/domain/usecases/sign_in_with_google.dart' as _i692;
import '../../features/auth/domain/usecases/sign_out.dart' as _i568;
import '../../features/auth/domain/usecases/sign_up_with_email.dart' as _i460;
import '../../features/auth/domain/usecases/update_password_usecase.dart'
    as _i387;
import '../../features/auth/domain/usecases/update_profile.dart' as _i340;
import '../../features/auth/presentation/controllers/login_controller.dart'
    as _i729;
import '../../features/auth/presentation/controllers/otp_verification_controller.dart'
    as _i604;
import '../../features/auth/presentation/controllers/profile_setup_controller.dart'
    as _i1052;
import '../../features/auth/presentation/controllers/reset_password_controller.dart'
    as _i597;
import '../../features/auth/presentation/controllers/signup_controller.dart'
    as _i166;
import '../../features/gossip/data/datasources/gossip_local_data_source.dart'
    as _i302;
import '../../features/gossip/data/datasources/gossip_remote_data_source.dart'
    as _i979;
import '../../features/gossip/data/datasources/shared_prefs_gossip_local_data_source.dart'
    as _i837;
import '../../features/gossip/data/datasources/supabase_gossip_remote_data_source.dart'
    as _i1045;
import '../../features/gossip/data/repositories/gossip_repository_impl.dart'
    as _i263;
import '../../features/gossip/di/gossip_module.dart' as _i1060;
import '../../features/gossip/domain/repositories/gossip_repository.dart'
    as _i865;
import '../../features/gossip/domain/services/mvp_content_moderator.dart'
    as _i110;
import '../../features/gossip/domain/usecases/create_gossip.dart' as _i458;
import '../../features/gossip/domain/usecases/get_gossips.dart' as _i821;
import '../../features/gossip/domain/usecases/report_gossip.dart' as _i535;
import '../../features/gossip/presentation/controllers/add_gossip_controller.dart'
    as _i541;
import '../../features/home/data/datasources/home_remote_datasource.dart'
    as _i278;
import '../../features/home/data/repositories/home_repository_impl.dart'
    as _i76;
import '../../features/home/domain/repositories/home_repository.dart' as _i0;
import '../../features/home/domain/usecases/check_new_gossips.dart' as _i155;
import '../../features/home/domain/usecases/get_following_feed.dart' as _i760;
import '../../features/home/domain/usecases/get_popular_feed.dart' as _i214;
import '../../features/home/domain/usecases/get_recommended_feed.dart' as _i890;
import '../../features/home/presentation/controllers/following_tab_controller.dart'
    as _i527;
import '../../features/home/presentation/controllers/popular_tab_controller.dart'
    as _i840;
import '../../features/location/data/datasources/supabase_location_remote_data_source.dart'
    as _i852;
import '../../features/location/data/repositories/mock_location_repository.dart'
    as _i42;
import '../../features/location/data/repositories/supabase_location_repository.dart'
    as _i859;
import '../../features/location/domain/repositories/location_repository.dart'
    as _i332;
import '../../features/location/domain/usecases/get_cities_by_region.dart'
    as _i913;
import '../../features/location/domain/usecases/get_countries.dart' as _i552;
import '../../features/location/domain/usecases/get_regions_by_country.dart'
    as _i819;
import '../../features/location/domain/usecases/search_cities.dart' as _i108;
import '../../features/location/presentation/managers/location_manager.dart'
    as _i491;
import '../../features/profile/data/datasources/profile_remote_datasource.dart'
    as _i327;
import '../../features/profile/data/repositories/profile_repository_impl.dart'
    as _i334;
import '../../features/profile/domain/repositories/profile_repository.dart'
    as _i894;
import '../../features/profile/domain/usecases/get_settings.dart' as _i729;
import '../../features/profile/domain/usecases/get_user_stats.dart' as _i669;
import '../../features/profile/domain/usecases/sign_out.dart' as _i487;
import '../../features/profile/domain/usecases/update_settings.dart' as _i862;
import '../../features/profile/presentation/controllers/profile_controller.dart'
    as _i658;
import '../id/id_generator.dart' as _i1000;
import '../id/timestamp_id_generator.dart' as _i458;
import '../logging/app_logger.dart' as _i354;
import '../logging/device_info_provider.dart' as _i966;
import '../logging/logging.dart' as _i482;
import '../logging/remote_logger.dart' as _i332;
import '../media/supabase_storage_service.dart' as _i710;
import '../services/auth_service.dart' as _i745;
import '../services/deep_link_service.dart' as _i391;
import '../services/location_service.dart' as _i669;

// initializes the registration of main-scope dependencies inside of GetIt
_i174.GetIt $initGetIt(
  _i174.GetIt getIt, {
  String? environment,
  _i526.EnvironmentFilter? environmentFilter,
}) {
  final gh = _i526.GetItHelper(getIt, environment, environmentFilter);
  final gossipModule = _$GossipModule();
  gh.singleton<_i966.DeviceInfoProvider>(() => _i966.DeviceInfoProvider());
  gh.singleton<_i110.MvpModerationPolicy>(() => gossipModule.moderationPolicy);
  gh.lazySingleton<_i454.SupabaseClient>(() => gossipModule.supabaseClient);
  gh.singleton<_i1000.IdGenerator>(() => _i458.TimestampIdGenerator());
  gh.singleton<_i332.LocationRepository>(
    () => _i42.MockLocationRepository(),
    instanceName: 'mock',
  );
  gh.singleton<_i332.RemoteLogger>(
    () => _i332.SupabaseRemoteLogger(gh<_i454.SupabaseClient>()),
  );
  gh.singleton<_i354.AppLogger>(
    () => _i354.AppLogger(
      gh<_i332.RemoteLogger>(),
      gh<_i966.DeviceInfoProvider>(),
    ),
  );
  gh.singleton<_i979.GossipRemoteDataSource>(
    () => _i1045.SupabaseGossipRemoteDataSource(
      gh<_i454.SupabaseClient>(),
      gh<_i482.AppLogger>(),
    ),
  );
  gh.lazySingleton<_i710.SupabaseStorageService>(
    () => _i710.SupabaseStorageService(
      gh<_i454.SupabaseClient>(),
      gh<_i482.AppLogger>(),
    ),
  );
  gh.singleton<_i852.SupabaseLocationRemoteDataSource>(
    () => _i852.SupabaseLocationRemoteDataSource(
      gh<_i454.SupabaseClient>(),
      gh<_i482.AppLogger>(),
    ),
  );
  gh.singleton<_i391.DeepLinkService>(
    () => _i391.DeepLinkService(
      gh<_i409.GlobalKey<_i409.NavigatorState>>(instanceName: 'navigatorKey'),
      gh<_i482.AppLogger>(),
    ),
  );
  gh.singleton<_i669.LocationService>(
    () => _i669.LocationService(gh<_i482.AppLogger>()),
  );
  gh.singleton<_i278.HomeRemoteDataSource>(
    () => _i278.HomeRemoteDataSource(gh<_i482.AppLogger>()),
  );
  gh.singleton<_i327.ProfileRemoteDataSource>(
    () => _i327.ProfileRemoteDataSource(gh<_i482.AppLogger>()),
  );
  gh.singleton<_i0.HomeRepository>(
    () => _i76.HomeRepositoryImpl(
      gh<_i278.HomeRemoteDataSource>(),
      gh<_i482.AppLogger>(),
    ),
  );
  gh.singleton<_i76.SupabaseAuthDataSource>(
    () => _i743.SupabaseAuthDataSourceImpl(gh<_i482.AppLogger>()),
  );
  gh.singleton<_i302.GossipLocalDataSource>(
    () => _i837.SharedPrefsGossipLocalDataSource(gh<_i482.AppLogger>()),
  );
  gh.singleton<_i894.ProfileRepository>(
    () => _i334.ProfileRepositoryImpl(
      gh<_i327.ProfileRemoteDataSource>(),
      gh<_i482.AppLogger>(),
    ),
  );
  gh.singleton<_i332.LocationRepository>(
    () => _i859.SupabaseLocationRepository(
      gh<_i852.SupabaseLocationRemoteDataSource>(),
    ),
  );
  gh.singleton<_i865.GossipRepository>(
    () => _i263.GossipRepositoryImpl(
      remoteDataSource: gh<_i979.GossipRemoteDataSource>(),
      localDataSource: gh<_i302.GossipLocalDataSource>(),
      logger: gh<_i482.AppLogger>(),
    ),
  );
  gh.singleton<_i787.AuthRepository>(
    () => _i153.AuthRepositoryImpl(
      gh<_i76.SupabaseAuthDataSource>(),
      gh<_i482.AppLogger>(),
    ),
  );
  gh.factory<_i155.CheckNewGossips>(
    () => _i155.CheckNewGossips(gh<_i0.HomeRepository>()),
  );
  gh.factory<_i760.GetFollowingFeed>(
    () => _i760.GetFollowingFeed(gh<_i0.HomeRepository>()),
  );
  gh.factory<_i214.GetPopularFeed>(
    () => _i214.GetPopularFeed(gh<_i0.HomeRepository>()),
  );
  gh.factory<_i890.GetRecommendedFeed>(
    () => _i890.GetRecommendedFeed(gh<_i0.HomeRepository>()),
  );
  gh.factory<_i729.GetSettings>(
    () => _i729.GetSettings(gh<_i894.ProfileRepository>()),
  );
  gh.factory<_i669.GetUserStats>(
    () => _i669.GetUserStats(gh<_i894.ProfileRepository>()),
  );
  gh.factory<_i487.SignOut>(() => _i487.SignOut(gh<_i894.ProfileRepository>()));
  gh.factory<_i862.UpdateSettings>(
    () => _i862.UpdateSettings(gh<_i894.ProfileRepository>()),
  );
  gh.factory<_i458.CreateGossip>(
    () => _i458.CreateGossip(
      repository: gh<_i865.GossipRepository>(),
      authRepository: gh<_i787.AuthRepository>(),
      logger: gh<_i482.AppLogger>(),
    ),
  );
  gh.factory<_i108.SearchCities>(
    () => _i108.SearchCities(gh<_i332.LocationRepository>()),
  );
  gh.factory<_i913.GetCitiesByRegion>(
    () => _i913.GetCitiesByRegion(repository: gh<_i332.LocationRepository>()),
  );
  gh.factory<_i552.GetCountries>(
    () => _i552.GetCountries(repository: gh<_i332.LocationRepository>()),
  );
  gh.factory<_i819.GetRegionsByCountry>(
    () => _i819.GetRegionsByCountry(repository: gh<_i332.LocationRepository>()),
  );
  gh.factory<_i821.GetGossips>(
    () => _i821.GetGossips(repository: gh<_i865.GossipRepository>()),
  );
  gh.factory<_i111.GetCurrentUserUseCase>(
    () => _i111.GetCurrentUserUseCase(gh<_i787.AuthRepository>()),
  );
  gh.factory<_i910.IsUsernameAvailableUseCase>(
    () => _i910.IsUsernameAvailableUseCase(gh<_i787.AuthRepository>()),
  );
  gh.factory<_i1066.ResetPasswordUseCase>(
    () => _i1066.ResetPasswordUseCase(gh<_i787.AuthRepository>()),
  );
  gh.factory<_i263.SignInWithAppleUseCase>(
    () => _i263.SignInWithAppleUseCase(gh<_i787.AuthRepository>()),
  );
  gh.factory<_i485.SignInWithEmailUseCase>(
    () => _i485.SignInWithEmailUseCase(gh<_i787.AuthRepository>()),
  );
  gh.factory<_i692.SignInWithGoogleUseCase>(
    () => _i692.SignInWithGoogleUseCase(gh<_i787.AuthRepository>()),
  );
  gh.factory<_i568.SignOutUseCase>(
    () => _i568.SignOutUseCase(gh<_i787.AuthRepository>()),
  );
  gh.factory<_i460.SignUpWithEmailUseCase>(
    () => _i460.SignUpWithEmailUseCase(gh<_i787.AuthRepository>()),
  );
  gh.factory<_i387.UpdatePasswordUseCase>(
    () => _i387.UpdatePasswordUseCase(gh<_i787.AuthRepository>()),
  );
  gh.factory<_i340.UpdateProfileUseCase>(
    () => _i340.UpdateProfileUseCase(gh<_i787.AuthRepository>()),
  );
  gh.factory<_i535.ReportGossip>(
    () => _i535.ReportGossip(gh<_i865.GossipRepository>()),
  );
  gh.factory<_i1052.ProfileSetupController>(
    () => _i1052.ProfileSetupController(
      gh<_i340.UpdateProfileUseCase>(),
      gh<_i910.IsUsernameAvailableUseCase>(),
      gh<_i482.AppLogger>(),
    ),
  );
  gh.factory<_i166.SignupController>(
    () => _i166.SignupController(
      gh<_i460.SignUpWithEmailUseCase>(),
      gh<_i482.AppLogger>(),
    ),
  );
  gh.factory<_i604.OtpVerificationController>(
    () => _i604.OtpVerificationController(
      authRepository: gh<_i787.AuthRepository>(),
      logger: gh<_i482.AppLogger>(),
      email: gh<String>(),
    ),
  );
  gh.singleton<_i745.AuthService>(
    () => _i745.AuthService(gh<_i787.AuthRepository>(), gh<_i482.AppLogger>()),
  );
  gh.factory<_i491.LocationManager>(
    () => _i491.LocationManager(
      gh<_i552.GetCountries>(),
      gh<_i819.GetRegionsByCountry>(),
      gh<_i913.GetCitiesByRegion>(),
      gh<_i669.LocationService>(),
      gh<_i354.AppLogger>(),
    ),
  );
  gh.factory<_i541.AddGossipController>(
    () => _i541.AddGossipController(
      createGossip: gh<_i458.CreateGossip>(),
      locationManager: gh<_i491.LocationManager>(),
      logger: gh<_i482.AppLogger>(),
    ),
  );
  gh.factory<_i527.FollowingTabController>(
    () => _i527.FollowingTabController(
      gh<_i760.GetFollowingFeed>(),
      gh<_i890.GetRecommendedFeed>(),
      gh<_i491.LocationManager>(),
      gh<_i482.AppLogger>(),
    ),
  );
  gh.factory<_i840.PopularTabController>(
    () => _i840.PopularTabController(
      gh<_i214.GetPopularFeed>(),
      gh<_i155.CheckNewGossips>(),
      gh<_i491.LocationManager>(),
      gh<_i482.AppLogger>(),
    ),
  );
  gh.factory<_i597.ResetPasswordController>(
    () => _i597.ResetPasswordController(
      gh<_i387.UpdatePasswordUseCase>(),
      gh<_i482.AppLogger>(),
    ),
  );
  gh.factory<_i729.LoginController>(
    () => _i729.LoginController(
      gh<_i485.SignInWithEmailUseCase>(),
      gh<_i692.SignInWithGoogleUseCase>(),
      gh<_i263.SignInWithAppleUseCase>(),
      gh<_i1066.ResetPasswordUseCase>(),
      gh<_i482.AppLogger>(),
    ),
  );
  gh.factory<_i658.ProfileController>(
    () => _i658.ProfileController(
      gh<_i669.GetUserStats>(),
      gh<_i729.GetSettings>(),
      gh<_i862.UpdateSettings>(),
      gh<_i487.SignOut>(),
      gh<_i745.AuthService>(),
      gh<_i482.AppLogger>(),
    ),
  );
  return getIt;
}

class _$GossipModule extends _i1060.GossipModule {}
