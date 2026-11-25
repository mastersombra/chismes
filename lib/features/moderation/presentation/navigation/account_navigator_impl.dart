import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/navigation/account_navigator.dart';
import '../screens/account_status_screen.dart';

/// [AccountNavigator] del feature moderation: abre sus pantallas
@Singleton(as: AccountNavigator)
class AccountNavigatorImpl implements AccountNavigator {
  @override
  Future<void> openAccountStatus(BuildContext context) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => const AccountStatusScreen()),
    );
  }
}
