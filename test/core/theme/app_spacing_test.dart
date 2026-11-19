import 'package:flutter_test/flutter_test.dart';
import 'package:chismes/core/theme/app_spacing.dart';

void main() {
  group('AppSpacing', () {
    group('Valores de espaciado', () {
      test('xs debe ser 4.0', () {
        expect(AppSpacing.xs, 4.0);
      });

      test('sm debe ser 8.0', () {
        expect(AppSpacing.sm, 8.0);
      });

      test('md debe ser 12.0', () {
        expect(AppSpacing.md, 12.0);
      });

      test('lg debe ser 16.0 (base)', () {
        expect(AppSpacing.lg, 16.0);
      });

      test('xl debe ser 24.0', () {
        expect(AppSpacing.xl, 24.0);
      });

      test('xxl debe ser 32.0', () {
        expect(AppSpacing.xxl, 32.0);
      });

      test('xxxl debe ser 48.0', () {
        expect(AppSpacing.xxxl, 48.0);
      });
    });

    group('Progresión de valores', () {
      test('valores deben estar en orden ascendente', () {
        expect(AppSpacing.xs, lessThan(AppSpacing.sm));
        expect(AppSpacing.sm, lessThan(AppSpacing.md));
        expect(AppSpacing.md, lessThan(AppSpacing.lg));
        expect(AppSpacing.lg, lessThan(AppSpacing.xl));
        expect(AppSpacing.xl, lessThan(AppSpacing.xxl));
        expect(AppSpacing.xxl, lessThan(AppSpacing.xxxl));
      });

      test('todos los valores deben ser múltiplos de 4', () {
        expect(AppSpacing.xs % 4, 0);
        expect(AppSpacing.sm % 4, 0);
        expect(AppSpacing.md % 4, 0);
        expect(AppSpacing.lg % 4, 0);
        expect(AppSpacing.xl % 4, 0);
        expect(AppSpacing.xxl % 4, 0);
        expect(AppSpacing.xxxl % 4, 0);
      });

      test('todos los valores deben ser positivos', () {
        expect(AppSpacing.xs, greaterThan(0));
        expect(AppSpacing.sm, greaterThan(0));
        expect(AppSpacing.md, greaterThan(0));
        expect(AppSpacing.lg, greaterThan(0));
        expect(AppSpacing.xl, greaterThan(0));
        expect(AppSpacing.xxl, greaterThan(0));
        expect(AppSpacing.xxxl, greaterThan(0));
      });
    });

    group('Uso típico', () {
      test('lg debe ser el valor base recomendado', () {
        // lg (16) es el espaciado estándar más común
        expect(AppSpacing.lg, 16.0);
      });

      test('sm debe ser la mitad de lg', () {
        expect(AppSpacing.sm, AppSpacing.lg / 2);
      });

      test('xxl debe ser el doble de lg', () {
        expect(AppSpacing.xxl, AppSpacing.lg * 2);
      });

      test('xxxl debe ser 3x el valor de lg', () {
        expect(AppSpacing.xxxl, AppSpacing.lg * 3);
      });
    });

    group('Valores extremos', () {
      test('xs debe ser el espaciado más pequeño', () {
        final allValues = [
          AppSpacing.xs,
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.xl,
          AppSpacing.xxl,
          AppSpacing.xxxl,
        ];
        expect(AppSpacing.xs, equals(allValues.reduce((a, b) => a < b ? a : b)));
      });

      test('xxxl debe ser el espaciado más grande', () {
        final allValues = [
          AppSpacing.xs,
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.xl,
          AppSpacing.xxl,
          AppSpacing.xxxl,
        ];
        expect(AppSpacing.xxxl,
            equals(allValues.reduce((a, b) => a > b ? a : b)));
      });
    });

    group('Ratios y proporciones', () {
      test('sm debe ser 2x xs', () {
        expect(AppSpacing.sm, AppSpacing.xs * 2);
      });

      test('md debe ser 1.5x sm', () {
        expect(AppSpacing.md, AppSpacing.sm * 1.5);
      });

      test('lg debe ser aproximadamente 1.33x md', () {
        expect(AppSpacing.lg / AppSpacing.md,
            closeTo(1.33, 0.01)); // 16/12 = 1.33
      });

      test('xl debe ser 1.5x lg', () {
        expect(AppSpacing.xl, AppSpacing.lg * 1.5);
      });

      test('xxl debe ser aproximadamente 1.33x xl', () {
        expect(AppSpacing.xxl / AppSpacing.xl,
            closeTo(1.33, 0.01)); // 32/24 = 1.33
      });

      test('xxxl debe ser 1.5x xxl', () {
        expect(AppSpacing.xxxl, AppSpacing.xxl * 1.5);
      });
    });

    group('Casos de uso documentados', () {
      test('debe tener exactamente 7 niveles de espaciado', () {
        // Documentar que tenemos 7 niveles: xs, sm, md, lg, xl, xxl, xxxl
        final spacingLevels = [
          AppSpacing.xs,
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.xl,
          AppSpacing.xxl,
          AppSpacing.xxxl,
        ];
        expect(spacingLevels.length, 7);
        expect(spacingLevels.toSet().length,
            7); // Todos son únicos
      });

      test('rango completo debe ser de 4 a 48', () {
        expect(AppSpacing.xs, 4.0);
        expect(AppSpacing.xxxl, 48.0);
        expect(AppSpacing.xxxl - AppSpacing.xs, 44.0);
      });
    });

    group('Constantes de uso específico', () {
      test('horizontalContent debe ser igual a lg', () {
        expect(AppSpacing.horizontalContent, AppSpacing.lg);
        expect(AppSpacing.horizontalContent, 16.0);
      });

      test('verticalElements debe ser igual a md', () {
        expect(AppSpacing.verticalElements, AppSpacing.md);
        expect(AppSpacing.verticalElements, 12.0);
      });

      test('sectionGap debe ser igual a xl', () {
        expect(AppSpacing.sectionGap, AppSpacing.xl);
        expect(AppSpacing.sectionGap, 24.0);
      });

      test('constantes específicas deben tener relación lógica', () {
        // sectionGap (xl) debe ser mayor que horizontalContent (lg)
        expect(AppSpacing.sectionGap, greaterThan(AppSpacing.horizontalContent));

        // horizontalContent (lg) debe ser mayor que verticalElements (md)
        expect(
            AppSpacing.horizontalContent, greaterThan(AppSpacing.verticalElements));
      });
    });
  });
}
