/// Tokens de border radius centralizados
///
/// **Uso:**
/// ```dart
/// BorderRadius.circular(AppRadius.md)
/// ```
///
/// **NO hacer:**
/// ```dart
/// BorderRadius.circular(12) // ❌ Hardcoded
/// ```
class AppRadius {
  AppRadius._(); // Private constructor para prevenir instanciación

  /// Radio extra pequeño - 4px
  /// Uso: Tags, chips pequeños
  static const double xs = 4;

  /// Radio pequeño - 8px
  /// Uso: Botones pequeños, inputs
  static const double sm = 8;

  /// Radio mediano - 12px
  /// Uso: Cards, containers, botones (DEFAULT)
  static const double md = 12;

  /// Radio grande - 16px
  /// Uso: Dialogs, bottom sheets
  static const double lg = 16;

  /// Radio extra grande - 20px
  /// Uso: Modals grandes
  static const double xl = 20;

  /// Radio muy grande - 24px
  /// Uso: Componentes especiales
  static const double xxl = 24;

  /// Radio completo (circular) - 999px
  /// Uso: Avatares, badges circulares
  static const double full = 999;
}
