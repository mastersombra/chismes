import 'dart:async';

import 'package:chismes/core/error/error_codes.dart';
import 'package:chismes/core/error/failure.dart';
import 'package:chismes/core/result/result.dart';
import 'package:chismes/features/social/domain/entities/social_user.dart';
import 'package:chismes/features/social/domain/usecases/search_users.dart';
import 'package:chismes/features/social/presentation/controllers/user_search_controller.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../../social_fixtures.dart';
import '../../social_test_mocks.mocks.dart';

void main() {
  late MockSocialRepository repository;
  late UserSearchController controller;

  setUpAll(provideSocialDummies);

  setUp(() {
    repository = MockSocialRepository();
    controller = UserSearchController(SearchUsers(repository));
  });

  test('searchNow: loaded con los usuarios', () async {
    when(repository.searchUsers('ana', limit: anyNamed('limit')))
        .thenAnswer((_) async => Result.success([tUser]));

    await controller.searchNow('ana');

    expect(controller.status, UserSearchStatus.loaded);
    expect(controller.users, [tUser]);
    expect(controller.query, 'ana');
  });

  test('texto muy corto → idle sin llamar al servidor', () async {
    await controller.searchNow('a');
    controller.search('@');

    expect(controller.status, UserSearchStatus.idle);
    expect(controller.users, isEmpty);
    verifyZeroInteractions(repository);
  });

  test('error → error con el Failure', () async {
    when(repository.searchUsers(any, limit: anyNamed('limit'))).thenAnswer(
        (_) async => Result.failure(const NetworkFailure(code: ErrorCode.networkError)));

    await controller.searchNow('ana');

    expect(controller.status, UserSearchStatus.error);
    expect(controller.failure!.code, ErrorCode.networkError);
  });

  test('search espera el debounce y solo busca el último texto', () {
    fakeAsync((async) {
      when(repository.searchUsers(any, limit: anyNamed('limit')))
          .thenAnswer((_) async => Result.success([tUser]));

      controller.search('an');
      async.elapse(const Duration(milliseconds: 100));
      controller.search('ana');
      expect(controller.status, UserSearchStatus.loading);
      async.elapse(UserSearchController.debounce);
      async.flushMicrotasks();

      verify(repository.searchUsers('ana', limit: 20)).called(1);
      verifyNever(repository.searchUsers('an', limit: anyNamed('limit')));
      expect(controller.status, UserSearchStatus.loaded);
    });
  });

  test('una respuesta vieja no pisa la búsqueda nueva', () async {
    final slow = Completer<Result<Failure, List<SocialUser>>>();
    when(repository.searchUsers('an', limit: anyNamed('limit'))).thenAnswer((_) => slow.future);
    when(repository.searchUsers('beto', limit: anyNamed('limit')))
        .thenAnswer((_) async => Result.success([tUser2]));

    final first = controller.searchNow('an');
    await controller.searchNow('beto');
    slow.complete(Result.success([tUser]));
    await first;

    expect(controller.users, [tUser2]);
    expect(controller.query, 'beto');
  });

  test('borrar el texto vuelve a idle y descarta la búsqueda en curso', () async {
    final slow = Completer<Result<Failure, List<SocialUser>>>();
    when(repository.searchUsers('ana', limit: anyNamed('limit'))).thenAnswer((_) => slow.future);

    final pending = controller.searchNow('ana');
    controller.search('');
    slow.complete(Result.success([tUser]));
    await pending;

    expect(controller.status, UserSearchStatus.idle);
    expect(controller.users, isEmpty);
  });
}
