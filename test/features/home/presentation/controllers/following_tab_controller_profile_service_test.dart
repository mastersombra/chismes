import 'package:chismes/core/error/error_codes.dart';
import 'package:chismes/core/error/failure.dart';
import 'package:chismes/core/result/result.dart';
import 'package:chismes/features/home/domain/entities/paginated_gossips.dart';
import 'package:chismes/features/home/presentation/controllers/following_tab_controller.dart';
import 'package:chismes/features/home/presentation/states/following_tab_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'following_tab_controller_test.mocks.dart';

/// ProfileService ahora es real (get_user_profile): si falla, el tab muestra
/// error en vez de inventar un contador.
void main() {
  late MockGetFollowingFeed getFollowingFeed;
  late MockProfileService profileService;
  late FollowingTabController controller;

  provideDummy<Result<Failure, PaginatedGossips>>(
    Result.failure(const NetworkFailure(code: ErrorCode.networkError)),
  );

  setUp(() {
    getFollowingFeed = MockGetFollowingFeed();
    profileService = MockProfileService();
    final auth = MockAuthService();
    when(auth.userId).thenReturn('me');
    controller = FollowingTabController(
      getFollowingFeed,
      MockGetRecommendedFeed(),
      MockLocationManager(),
      profileService,
      auth,
      MockAppLogger(),
    );
  });

  test('si ProfileService falla, estado error y no pide el feed', () async {
    when(profileService.getFollowingCount('me'))
        .thenThrow(const NetworkFailure(code: ErrorCode.noInternetConnection));

    await controller.loadFeed();

    expect(controller.state.status, FollowingTabStatus.error);
    verifyNever(getFollowingFeed(pageSize: anyNamed('pageSize'), cursor: anyNamed('cursor')));
  });

  test('pide el feed sin user id (el servidor usa auth.uid())', () async {
    when(profileService.getFollowingCount('me')).thenAnswer((_) async => 2);
    when(getFollowingFeed(pageSize: anyNamed('pageSize'), cursor: anyNamed('cursor')))
        .thenAnswer((_) async => Result.success(const PaginatedGossips.empty()));

    await controller.loadFeed();

    verify(getFollowingFeed(pageSize: 20, cursor: null)).called(1);
  });
}
