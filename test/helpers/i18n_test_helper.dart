import 'package:flutter/material.dart';
import 'package:chismes/l10n/app_localizations.dart';

/// Helper para tests que necesitan i18n
/// Wraps el widget child con MaterialApp y configuración de localización
Widget makeTestableWidget(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('es'),
    home: child,
  );
}
