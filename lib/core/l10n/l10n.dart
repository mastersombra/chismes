/// Localization utilities for Chismes app
///
/// Provides extension for clean access to AppLocalizations
library;

import 'package:flutter/widgets.dart';
import '../../l10n/app_localizations.dart';

export '../../l10n/app_localizations.dart';

/// Extension para obtener AppLocalizations desde BuildContext
extension L10nContext on BuildContext {
  /// Obtiene la instancia de AppLocalizations del contexto actual
  ///
  /// Lanza excepción si AppLocalizations no está disponible
  /// (MaterialApp debe tener los delegates configurados)
  AppLocalizations get l10n {
    final localizations = AppLocalizations.of(this);

    assert(
      localizations != null,
      'AppLocalizations not found in context. '
      'Make sure MaterialApp has AppLocalizations.localizationsDelegates configured.',
    );

    return localizations!;
  }
}
