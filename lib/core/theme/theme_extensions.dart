import 'package:flutter/material.dart';
import 'app_theme.dart';

/// Extension methods para acceder fácilmente a semantic colors y typography
///
/// **Uso:**
/// ```dart
/// // En lugar de:
/// Colors.red.shade50 // ❌
///
/// // Usar:
/// context.colors.error // ✅
/// Theme.of(context).colorScheme.error // ✅
/// ```
extension ThemeExtensions on BuildContext {
  /// Acceso rápido a ColorScheme
  ColorScheme get colors => Theme.of(this).colorScheme;

  /// Acceso rápido a TextTheme
  TextTheme get textTheme => Theme.of(this).textTheme;

  /// Semantic colors específicos (light/dark aware)
  Color get errorColor => colors.error;
  Color get successColor => _isLightMode
      ? AppTheme.successLight
      : AppTheme.successDark;
  Color get warningColor => _isLightMode
      ? AppTheme.warningLight
      : AppTheme.warningDark;
  Color get surfaceColor => colors.surface;
  Color get borderColor => colors.outline;

  /// Helper para verificar si está en modo claro
  bool get _isLightMode => Theme.of(this).brightness == Brightness.light;

  /// Background colors con opacidades comunes
  Color get errorBackground => errorColor.withValues(alpha: 0.1);
  Color get successBackground => successColor.withValues(alpha: 0.1);
  Color get warningBackground => warningColor.withValues(alpha: 0.1);

  /// Border colors con opacidades comunes
  Color get errorBorder => errorColor.withValues(alpha: 0.3);
  Color get successBorder => successColor.withValues(alpha: 0.3);
  Color get warningBorder => warningColor.withValues(alpha: 0.3);
}
