import 'package:chismes/core/di/injection_container.dart';
import 'package:chismes/core/result/result.dart';
import 'package:chismes/features/moderation/domain/usecases/get_account_status.dart';
import 'package:chismes/features/moderation/domain/usecases/submit_appeal.dart';
import 'package:chismes/features/moderation/presentation/controllers/account_status_controller.dart';
import 'package:chismes/features/moderation/presentation/navigation/account_navigator_impl.dart';
import 'package:chismes/features/moderation/presentation/screens/account_status_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/mock_app_logger_helper.dart';
import '../../../../helpers/widget_test_wrapper.dart';
import '../../sanctions_fixtures.dart';

void main() {
  late FakeAccountStatusRepository repo;

  setUp(() {
    repo = FakeAccountStatusRepository();
    repo.statusResults.add(Result.success(accountStatus()));
    if (getIt.isRegistered<AccountStatusController>()) getIt.unregister<AccountStatusController>();
    getIt.registerFactory(
      () => AccountStatusController(GetAccountStatus(repo), SubmitAppeal(repo), MockAppLogger()),
    );
  });

  tearDown(() => getIt.unregister<AccountStatusController>());

  testWidgets('openAccountStatus abre AccountStatusScreen', (tester) async {
    await tester.pumpWidget(testableWidget(
      child: Builder(
        builder: (context) => TextButton(
          onPressed: () => AccountNavigatorImpl().openAccountStatus(context),
          child: const Text('abrir'),
        ),
      ),
    ));
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    expect(find.byType(AccountStatusScreen), findsOneWidget);
  });
}
