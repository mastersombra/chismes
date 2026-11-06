/// Sistema de espaciado consistente para toda la aplicación
///
/// Basado en el sistema de Material Design de 4px (0.5rem) como unidad base.
/// Esto asegura consistencia visual y facilita cambios globales de espaciado.
///
/// Uso:
/// ```dart
/// padding: const EdgeInsets.all(AppSpacing.lg)
/// SizedBox(height: AppSpacing.md)
/// ```
class AppSpacing {
  /// 4px - Espaciado muy pequeño
  static const double xs = 4;

  /// 8px - Espaciado pequeño
  static const double sm = 8;

  /// 12px - Espaciado mediano
  static const double md = 12;

  /// 16px - Espaciado grande (base)
  static const double lg = 16;

  /// 24px - Espaciado extra grande
  static const double xl = 24;

  /// 32px - Espaciado muy grande
  static const double xxl = 32;

  /// 48px - Espaciado enorme
  static const double xxxl = 48;

  /// Espaciado horizontal estándar para contenido
  static const double horizontalContent = lg;

  /// Espaciado vertical estándar entre elementos
  static const double verticalElements = md;

  /// Espaciado para secciones principales
  static const double sectionGap = xl;
}
