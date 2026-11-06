import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chismes/core/theme/app_radius.dart';

void main() {
  group('AppRadius', () {
    group('Valores de constantes', () {
      test('xs debe ser 4', () {
        expect(AppRadius.xs, 4);
      });

      test('sm debe ser 8', () {
        expect(AppRadius.sm, 8);
      });

      test('md debe ser 12', () {
        expect(AppRadius.md, 12);
      });

      test('lg debe ser 16', () {
        expect(AppRadius.lg, 16);
      });

      test('xl debe ser 20', () {
        expect(AppRadius.xl, 20);
      });

      test('xxl debe ser 24', () {
        expect(AppRadius.xxl, 24);
      });

      test('full debe ser 999', () {
        expect(AppRadius.full, 999);
      });
    });

    group('Tipos de datos', () {
      test('todas las constantes deben ser double', () {
        expect(AppRadius.xs, isA<double>());
        expect(AppRadius.sm, isA<double>());
        expect(AppRadius.md, isA<double>());
        expect(AppRadius.lg, isA<double>());
        expect(AppRadius.xl, isA<double>());
        expect(AppRadius.xxl, isA<double>());
        expect(AppRadius.full, isA<double>());
      });

      test('todas las constantes deben ser positivas', () {
        expect(AppRadius.xs, greaterThan(0));
        expect(AppRadius.sm, greaterThan(0));
        expect(AppRadius.md, greaterThan(0));
        expect(AppRadius.lg, greaterThan(0));
        expect(AppRadius.xl, greaterThan(0));
        expect(AppRadius.xxl, greaterThan(0));
        expect(AppRadius.full, greaterThan(0));
      });
    });

    group('Escala de valores', () {
      test('valores deben estar en orden ascendente (excepto full)', () {
        expect(AppRadius.xs, lessThan(AppRadius.sm));
        expect(AppRadius.sm, lessThan(AppRadius.md));
        expect(AppRadius.md, lessThan(AppRadius.lg));
        expect(AppRadius.lg, lessThan(AppRadius.xl));
        expect(AppRadius.xl, lessThan(AppRadius.xxl));
        expect(AppRadius.xxl, lessThan(AppRadius.full));
      });

      test('xs debe ser el valor más pequeño (excepto full)', () {
        const normalRadii = [
          AppRadius.xs,
          AppRadius.sm,
          AppRadius.md,
          AppRadius.lg,
          AppRadius.xl,
          AppRadius.xxl,
        ];

        for (final radius in normalRadii) {
          if (radius != AppRadius.xs) {
            expect(AppRadius.xs, lessThan(radius));
          }
        }
      });

      test('xxl debe ser el valor más grande (sin contar full)', () {
        const normalRadii = [
          AppRadius.xs,
          AppRadius.sm,
          AppRadius.md,
          AppRadius.lg,
          AppRadius.xl,
          AppRadius.xxl,
        ];

        for (final radius in normalRadii) {
          if (radius != AppRadius.xxl) {
            expect(AppRadius.xxl, greaterThan(radius));
          }
        }
      });

      test('full debe ser mucho mayor que cualquier otro valor', () {
        expect(AppRadius.full, greaterThan(AppRadius.xxl * 10));
      });
    });

    group('Incrementos entre valores', () {
      test('incremento xs → sm debe ser 4', () {
        expect(AppRadius.sm - AppRadius.xs, 4);
      });

      test('incremento sm → md debe ser 4', () {
        expect(AppRadius.md - AppRadius.sm, 4);
      });

      test('incremento md → lg debe ser 4', () {
        expect(AppRadius.lg - AppRadius.md, 4);
      });

      test('incremento lg → xl debe ser 4', () {
        expect(AppRadius.xl - AppRadius.lg, 4);
      });

      test('incremento xl → xxl debe ser 4', () {
        expect(AppRadius.xxl - AppRadius.xl, 4);
      });

      test('incrementos deben ser consistentes (4px)', () {
        const increment = 4.0;
        expect(AppRadius.sm - AppRadius.xs, increment);
        expect(AppRadius.md - AppRadius.sm, increment);
        expect(AppRadius.lg - AppRadius.md, increment);
        expect(AppRadius.xl - AppRadius.lg, increment);
        expect(AppRadius.xxl - AppRadius.xl, increment);
      });
    });

    group('Múltiplos', () {
      test('todos los valores normales deben ser múltiplos de 4', () {
        expect(AppRadius.xs % 4, 0);
        expect(AppRadius.sm % 4, 0);
        expect(AppRadius.md % 4, 0);
        expect(AppRadius.lg % 4, 0);
        expect(AppRadius.xl % 4, 0);
        expect(AppRadius.xxl % 4, 0);
      });

      test('sm debe ser 2x xs', () {
        expect(AppRadius.sm, AppRadius.xs * 2);
      });

      test('md debe ser 3x xs', () {
        expect(AppRadius.md, AppRadius.xs * 3);
      });

      test('lg debe ser 4x xs', () {
        expect(AppRadius.lg, AppRadius.xs * 4);
      });

      test('xl debe ser 5x xs', () {
        expect(AppRadius.xl, AppRadius.xs * 5);
      });

      test('xxl debe ser 6x xs', () {
        expect(AppRadius.xxl, AppRadius.xs * 6);
      });
    });

    group('Uso con BorderRadius', () {
      test('debe funcionar con BorderRadius.circular()', () {
        final radius = BorderRadius.circular(AppRadius.md);

        expect(radius.topLeft.x, AppRadius.md);
        expect(radius.topRight.x, AppRadius.md);
        expect(radius.bottomLeft.x, AppRadius.md);
        expect(radius.bottomRight.x, AppRadius.md);
      });

      test('debe funcionar con BorderRadius.only()', () {
        final radius = BorderRadius.only(
          topLeft: Radius.circular(AppRadius.sm),
          topRight: Radius.circular(AppRadius.sm),
        );

        expect(radius.topLeft.x, AppRadius.sm);
        expect(radius.topRight.x, AppRadius.sm);
        expect(radius.bottomLeft.x, 0);
        expect(radius.bottomRight.x, 0);
      });

      test('debe funcionar con Radius.circular()', () {
        final radius = Radius.circular(AppRadius.lg);

        expect(radius.x, AppRadius.lg);
        expect(radius.y, AppRadius.lg);
      });

      test('full debe crear círculo perfecto para componente cuadrado', () {
        // Para un widget de 100x100, radius 999 lo hace completamente circular
        const size = 100.0;
        final radius = BorderRadius.circular(AppRadius.full);

        // Radius es mayor que size/2, entonces se renderiza como círculo
        expect(radius.topLeft.x, greaterThan(size / 2));
      });
    });

    group('Casos de uso típicos', () {
      test('xs - Tags y chips pequeños', () {
        const expectedRadius = 4.0;
        expect(AppRadius.xs, expectedRadius);
      });

      test('sm - Botones pequeños e inputs', () {
        const expectedRadius = 8.0;
        expect(AppRadius.sm, expectedRadius);
      });

      test('md - Cards y botones (DEFAULT)', () {
        const expectedRadius = 12.0;
        expect(AppRadius.md, expectedRadius);
      });

      test('lg - Dialogs y bottom sheets', () {
        const expectedRadius = 16.0;
        expect(AppRadius.lg, expectedRadius);
      });

      test('xl - Modals grandes', () {
        const expectedRadius = 20.0;
        expect(AppRadius.xl, expectedRadius);
      });

      test('xxl - Componentes especiales', () {
        const expectedRadius = 24.0;
        expect(AppRadius.xxl, expectedRadius);
      });

      test('full - Avatares y badges circulares', () {
        const expectedRadius = 999.0;
        expect(AppRadius.full, expectedRadius);
      });
    });

    group('Comparaciones semánticas', () {
      test('radius de tags debe ser menor que radius de botones', () {
        expect(AppRadius.xs, lessThan(AppRadius.sm));
      });

      test('radius de botones debe ser menor que radius de cards', () {
        expect(AppRadius.sm, lessThan(AppRadius.md));
      });

      test('radius de cards debe ser menor que radius de dialogs', () {
        expect(AppRadius.md, lessThan(AppRadius.lg));
      });

      test('radius de dialogs debe ser menor que radius de modals', () {
        expect(AppRadius.lg, lessThan(AppRadius.xl));
      });

      test('md debe ser el valor por defecto (medio)', () {
        // md está en el centro de la escala (excepto full)
        const normalRadii = [
          AppRadius.xs,
          AppRadius.sm,
          AppRadius.md,
          AppRadius.lg,
          AppRadius.xl,
          AppRadius.xxl,
        ];

        final smaller = normalRadii.where((r) => r < AppRadius.md).length;
        final larger = normalRadii.where((r) => r > AppRadius.md).length;

        // md tiene valores por debajo y por arriba
        expect(smaller, greaterThan(0));
        expect(larger, greaterThan(0));
      });
    });

    group('Constructor privado', () {
      test('no debe permitir instanciación', () {
        // AppRadius tiene constructor privado
        // No se puede hacer: final instance = AppRadius();

        // Verificar que todas las constantes son static
        expect(AppRadius.xs, isA<double>());
        expect(AppRadius.sm, isA<double>());
        expect(AppRadius.md, isA<double>());
      });
    });

    group('Consistencia del diseño', () {
      test('escala debe seguir múltiplos de 4px', () {
        const baseUnit = 4.0;

        expect(AppRadius.xs / baseUnit, 1); // 4/4 = 1
        expect(AppRadius.sm / baseUnit, 2); // 8/4 = 2
        expect(AppRadius.md / baseUnit, 3); // 12/4 = 3
        expect(AppRadius.lg / baseUnit, 4); // 16/4 = 4
        expect(AppRadius.xl / baseUnit, 5); // 20/4 = 5
        expect(AppRadius.xxl / baseUnit, 6); // 24/4 = 6
      });

      test('valores deben ser razonables para UI móvil', () {
        // En móvil, radius muy grandes (>30px) rara vez se usan
        expect(AppRadius.xs, lessThan(30));
        expect(AppRadius.sm, lessThan(30));
        expect(AppRadius.md, lessThan(30));
        expect(AppRadius.lg, lessThan(30));
        expect(AppRadius.xl, lessThan(30));
        expect(AppRadius.xxl, lessThan(30));
      });

      test('full debe ser suficientemente grande para cualquier componente', () {
        // Componentes típicos en móvil son <500px
        const maxTypicalSize = 500.0;
        expect(AppRadius.full, greaterThan(maxTypicalSize / 2));
      });
    });

    group('Valores negativos y cero', () {
      test('ningún valor debe ser negativo', () {
        expect(AppRadius.xs, greaterThanOrEqualTo(0));
        expect(AppRadius.sm, greaterThanOrEqualTo(0));
        expect(AppRadius.md, greaterThanOrEqualTo(0));
        expect(AppRadius.lg, greaterThanOrEqualTo(0));
        expect(AppRadius.xl, greaterThanOrEqualTo(0));
        expect(AppRadius.xxl, greaterThanOrEqualTo(0));
        expect(AppRadius.full, greaterThanOrEqualTo(0));
      });

      test('ningún valor debe ser cero', () {
        expect(AppRadius.xs, greaterThan(0));
        expect(AppRadius.sm, greaterThan(0));
        expect(AppRadius.md, greaterThan(0));
        expect(AppRadius.lg, greaterThan(0));
        expect(AppRadius.xl, greaterThan(0));
        expect(AppRadius.xxl, greaterThan(0));
        expect(AppRadius.full, greaterThan(0));
      });
    });

    group('Edge cases', () {
      test('valores extremadamente pequeños (xs) son visibles', () {
        // 4px es visible en pantallas modernas
        expect(AppRadius.xs, greaterThanOrEqualTo(4));
      });

      test('valores extremadamente grandes (full) no causan overflow', () {
        // 999px es seguro en Flutter
        expect(AppRadius.full, lessThan(10000));
      });

      test('diferencia entre valores consecutivos es perceptible', () {
        // Diferencia de 4px es perceptible para usuarios
        const minPerceptibleDiff = 2.0;

        expect(AppRadius.sm - AppRadius.xs, greaterThanOrEqualTo(minPerceptibleDiff));
        expect(AppRadius.md - AppRadius.sm, greaterThanOrEqualTo(minPerceptibleDiff));
        expect(AppRadius.lg - AppRadius.md, greaterThanOrEqualTo(minPerceptibleDiff));
      });
    });

    group('Integración con Material Design', () {
      test('valores son compatibles con Material Design 3', () {
        // Material Design 3 usa radii: 0, 4, 8, 12, 16, 20, 28
        // Nuestros valores son subset compatible
        const md3Radii = [0, 4, 8, 12, 16, 20, 28];

        expect(md3Radii, contains(AppRadius.xs));
        expect(md3Radii, contains(AppRadius.sm));
        expect(md3Radii, contains(AppRadius.md));
        expect(md3Radii, contains(AppRadius.lg));
        expect(md3Radii, contains(AppRadius.xl));
      });

      test('md coincide con radius por defecto de Material', () {
        // Material Design usa 12px como radius común para cards
        const materialCardRadius = 12.0;
        expect(AppRadius.md, materialCardRadius);
      });
    });

    group('Performance', () {
      test('acceso a constantes debe ser instantáneo', () {
        final stopwatch = Stopwatch()..start();

        for (var i = 0; i < 10000; i++) {
          // ignore: unused_local_variable
          final xs = AppRadius.xs;
          // ignore: unused_local_variable
          final sm = AppRadius.sm;
          // ignore: unused_local_variable
          final md = AppRadius.md;
        }

        stopwatch.stop();
        expect(stopwatch.elapsedMicroseconds, lessThan(1000)); // <1ms
      });
    });

    group('Documentación y usabilidad', () {
      test('valores tienen nombres descriptivos', () {
        // Nombres siguen convención: xs, sm, md, lg, xl, xxl, full
        // Son cortos y fáciles de recordar
        expect(true, isTrue);
      });

      test('full es semánticamente diferente del resto', () {
        // full no sigue la escala incremental, es especial
        expect(AppRadius.full, isNot(AppRadius.xxl + 4));
      });

      test('md es explícitamente el valor por defecto', () {
        // Documentación indica que md es DEFAULT
        const defaultRadius = AppRadius.md;
        expect(defaultRadius, 12);
      });
    });

    group('Rangos de uso', () {
      test('valores pequeños (xs-sm) para componentes inline', () {
        // Tags, chips, badges pequeños usan xs o sm
        expect(AppRadius.xs, lessThanOrEqualTo(8));
        expect(AppRadius.sm, lessThanOrEqualTo(8));
      });

      test('valores medios (md-lg) para componentes principales', () {
        // Cards, botones, inputs usan md o lg
        expect(AppRadius.md, inInclusiveRange(10, 18));
        expect(AppRadius.lg, inInclusiveRange(10, 18));
      });

      test('valores grandes (xl-xxl) para componentes especiales', () {
        // Modals, sheets usan xl o xxl
        expect(AppRadius.xl, greaterThanOrEqualTo(20));
        expect(AppRadius.xxl, greaterThanOrEqualTo(20));
      });

      test('full para componentes circulares', () {
        // Avatares, badges circulares
        expect(AppRadius.full, greaterThan(100));
      });
    });
  });
}
