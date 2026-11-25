import 'package:flutter/widgets.dart';

/// Navegación a las pantallas de la cuenta que viven en `moderation`
/// (estado de la cuenta, apelaciones) sin que otros features lo importen.
///
/// La implementa el feature moderation (`@Singleton(as: AccountNavigator)`);
/// notifications la usa con `getIt<AccountNavigator>()`.
abstract class AccountNavigator {
  /// Abre Estado de la cuenta (sanciones, contenido rechazado, apelaciones)
  Future<void> openAccountStatus(BuildContext context);
}
