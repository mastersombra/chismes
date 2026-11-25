import 'package:chismes/core/error/error_codes.dart';
import 'package:chismes/core/error/failure.dart';
import 'package:chismes/core/result/result.dart';
import 'package:chismes/features/social/domain/entities/social_user.dart';
import 'package:chismes/features/social/presentation/controllers/user_search_controller.dart';
import 'package:chismes/features/social/presentation/screens/user_profile_screen.dart';
import 'package:chismes/features/social/presentation/widgets/user_search_results.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../../../../helpers/widget_test_wrapper.dart';
import '../../social_di_helper.dart';
import '../../social_fixtures.dart';
import '../../social_test_mocks.mocks.dart';

void main() {
  late MockSocialRepository repository;

  setUpAll(provideSocialDummies);

  setUp(() {
    repository = MockSocialRepository();
    registerSocialForWidgets(repository);
  });

  tearDown(unregisterSocialForWidgets);

  Widget host(ValueNotifier<String> query) => testableWidget(
        child: ValueListenableBuilder<String>(
          valueListenable: query,
          builder: (_, q, _) => UserSearchResults(query: q),
        ),
      );

  testWidgets('texto corto: pide escribir más; sin llamadas', (tester) async {
    await tester.pumpWidget(host(ValueNotifier('a')));
    await tester.pump();

    expect(find.text('Escribe al menos 2 letras para buscar personas'), findsOneWidget);
    verifyZeroInteractions(repository);
  });

  testWidgets('busca con debounce al cambiar el texto y lista resultados', (tester) async {
    when(repository.searchUsers('ana', limit: anyNamed('limit')))
        .thenAnswer((_) async => Result.success([tUser]));
    final query = ValueNotifier('');
    await tester.pumpWidget(host(query));

    query.value = 'ana';
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pump(UserSearchController.debounce);
    await tester.pumpAndSettle();

    expect(find.byKey(Key('userTile_${tUser.id}')), findsOneWidget);
    verify(repository.searchUsers('ana', limit: 20)).called(1);
  });

  testWidgets('sin resultados', (tester) async {
    when(repository.searchUsers(any, limit: anyNamed('limit')))
        .thenAnswer((_) async => Result.success(<SocialUser>[]));

    await tester.pumpWidget(host(ValueNotifier('zzz')));
    await tester.pump(UserSearchController.debounce);
    await tester.pumpAndSettle();

    expect(find.text('No encontramos usuarios'), findsOneWidget);
  });

  testWidgets('error con reintentar', (tester) async {
    var fail = true;
    when(repository.searchUsers(any, limit: anyNamed('limit'))).thenAnswer((_) async => fail
        ? Result.failure(const NetworkFailure(code: ErrorCode.noInternetConnection))
        : Result.success([tUser2]));

    await tester.pumpWidget(host(ValueNotifier('beto')));
    await tester.pump(UserSearchController.debounce);
    await tester.pumpAndSettle();
    fail = false;
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();

    expect(find.byKey(Key('userTile_${tUser2.id}')), findsOneWidget);
  });

  testWidgets('tocar un resultado abre su perfil', (tester) async {
    when(repository.searchUsers(any, limit: anyNamed('limit')))
        .thenAnswer((_) async => Result.success([tUser]));
    when(repository.getUserProfile(tUser.id)).thenAnswer((_) async => Result.success(tProfile()));
    when(repository.getUserGossips(any,
            pageSize: anyNamed('pageSize'), cursor: anyNamed('cursor')))
        .thenAnswer((_) async => Result.success(page(const [])));

    await tester.pumpWidget(host(ValueNotifier('ana')));
    await tester.pump(UserSearchController.debounce);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(Key('userTile_${tUser.id}')));
    await tester.pumpAndSettle();

    expect(find.byType(UserProfileScreen), findsOneWidget);
  });
}
