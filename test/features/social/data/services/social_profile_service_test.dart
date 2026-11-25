import 'package:chismes/core/error/error_codes.dart';
import 'package:chismes/core/error/failure.dart';
import 'package:chismes/core/result/result.dart';
import 'package:chismes/features/social/data/services/social_profile_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../../social_fixtures.dart';
import '../../social_test_mocks.mocks.dart';

void main() {
  setUpAll(provideSocialDummies);

  late MockSocialRepository repository;
  late SocialProfileService service;

  setUp(() {
    repository = MockSocialRepository();
    service = SocialProfileService(repository);
  });

  test('getFollowingCount devuelve following_count de get_user_profile', () async {
    when(repository.getUserProfile(kMyUserId))
        .thenAnswer((_) async => Result.success(tProfile(id: kMyUserId, isMe: true, followingCount: 8)));

    expect(await service.getFollowingCount(kMyUserId), 8);
  });

  test('si falla, lanza el Failure (el tab Siguiendo muestra error)', () async {
    const failure = NetworkFailure(code: ErrorCode.noInternetConnection);
    when(repository.getUserProfile(kMyUserId)).thenAnswer((_) async => Result.failure(failure));

    await expectLater(service.getFollowingCount(kMyUserId), throwsA(failure));
  });
}
