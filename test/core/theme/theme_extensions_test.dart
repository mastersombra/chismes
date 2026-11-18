import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chismes/core/theme/theme_extensions.dart';
import 'package:chismes/core/theme/app_theme.dart';

void main() {
  group('ThemeExtensions', () {
    setUp(() {
      // Inicializar contextos será en cada test con pumWidget
    });

    Future<BuildContext> _createContext(WidgetTester tester, ThemeData theme) async {
      late BuildContext capturedContext;

      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Builder(
            builder: (context) {
              capturedContext = context;
              return const SizedBox();
            },
          ),
        ),
      );

      return capturedContext;
    }

    group('ColorScheme access', () {
      testWidgets('colors debe retornar ColorScheme', (tester) async {
        // Arrange
        final context = await _createContext(tester, ThemeData.light());

        // Act
        final colors = context.colors;

        // Assert
        expect(colors, isA<ColorScheme>());
      });

      testWidgets('textTheme debe retornar TextTheme', (tester) async {
        // Arrange
        final context = await _createContext(tester, ThemeData.light());

        // Act
        final textTheme = context.textTheme;

        // Assert
        expect(textTheme, isA<TextTheme>());
      });
    });

    group('Semantic colors - Light mode', () {
      testWidgets('errorColor debe retornar color de error del theme', (tester) async {
        // Arrange
        final theme = ThemeData.light();
        final context = await _createContext(tester, theme);

        // Act
        final errorColor = context.errorColor;

        // Assert
        expect(errorColor, equals(theme.colorScheme.error));
      });

      testWidgets('successColor debe retornar AppTheme.successLight', (tester) async {
        // Arrange
        final context = await _createContext(tester, ThemeData.light());

        // Act
        final successColor = context.successColor;

        // Assert
        expect(successColor, equals(AppTheme.successLight));
      });

      testWidgets('warningColor debe retornar AppTheme.warningLight', (tester) async {
        // Arrange
        final context = await _createContext(tester, ThemeData.light());

        // Act
        final warningColor = context.warningColor;

        // Assert
        expect(warningColor, equals(AppTheme.warningLight));
      });

      testWidgets('surfaceColor debe retornar surface del theme', (tester) async {
        // Arrange
        final theme = ThemeData.light();
        final context = await _createContext(tester, theme);

        // Act
        final surfaceColor = context.surfaceColor;

        // Assert
        expect(surfaceColor, equals(theme.colorScheme.surface));
      });

      testWidgets('borderColor debe retornar outline del theme', (tester) async {
        // Arrange
        final theme = ThemeData.light();
        final context = await _createContext(tester, theme);

        // Act
        final borderColor = context.borderColor;

        // Assert
        expect(borderColor, equals(theme.colorScheme.outline));
      });
    });

    group('Semantic colors - Dark mode', () {
      testWidgets('successColor debe retornar AppTheme.successDark', (tester) async {
        // Arrange
        final context = await _createContext(tester, ThemeData.dark());

        // Act
        final successColor = context.successColor;

        // Assert
        expect(successColor, equals(AppTheme.successDark));
      });

      testWidgets('warningColor debe retornar AppTheme.warningDark', (tester) async {
        // Arrange
        final context = await _createContext(tester, ThemeData.dark());

        // Act
        final warningColor = context.warningColor;

        // Assert
        expect(warningColor, equals(AppTheme.warningDark));
      });
    });

    group('Background colors con opacidad', () {
      testWidgets('errorBackground debe tener opacidad 0.1', (tester) async {
        // Arrange
        final theme = ThemeData.light();
        final context = await _createContext(tester, theme);

        // Act
        final errorBackground = context.errorBackground;
        final expectedColor = theme.colorScheme.error.withValues(alpha: 0.1);

        // Assert
        expect(errorBackground.toARGB32(), equals(expectedColor.toARGB32()));
      });

      testWidgets('successBackground debe tener opacidad 0.1', (tester) async {
        // Arrange
        final context = await _createContext(tester, ThemeData.light());

        // Act
        final successBackground = context.successBackground;
        final expectedColor = AppTheme.successLight.withValues(alpha: 0.1);

        // Assert
        expect(successBackground.toARGB32(), equals(expectedColor.toARGB32()));
      });

      testWidgets('warningBackground debe tener opacidad 0.1', (tester) async {
        // Arrange
        final context = await _createContext(tester, ThemeData.light());

        // Act
        final warningBackground = context.warningBackground;
        final expectedColor = AppTheme.warningLight.withValues(alpha: 0.1);

        // Assert
        expect(warningBackground.toARGB32(), equals(expectedColor.toARGB32()));
      });
    });

    group('Border colors con opacidad', () {
      testWidgets('errorBorder debe tener opacidad 0.3', (tester) async {
        // Arrange
        final theme = ThemeData.light();
        final context = await _createContext(tester, theme);

        // Act
        final errorBorder = context.errorBorder;
        final expectedColor = theme.colorScheme.error.withValues(alpha: 0.3);

        // Assert
        expect(errorBorder.toARGB32(), equals(expectedColor.toARGB32()));
      });

      testWidgets('successBorder debe tener opacidad 0.3', (tester) async {
        // Arrange
        final context = await _createContext(tester, ThemeData.light());

        // Act
        final successBorder = context.successBorder;
        final expectedColor = AppTheme.successLight.withValues(alpha: 0.3);

        // Assert
        expect(successBorder.toARGB32(), equals(expectedColor.toARGB32()));
      });

      testWidgets('warningBorder debe tener opacidad 0.3', (tester) async {
        // Arrange
        final context = await _createContext(tester, ThemeData.light());

        // Act
        final warningBorder = context.warningBorder;
        final expectedColor = AppTheme.warningLight.withValues(alpha: 0.3);

        // Assert
        expect(warningBorder.toARGB32(), equals(expectedColor.toARGB32()));
      });
    });

    group('Light/Dark mode detection', () {
      testWidgets('debe detectar light mode correctamente', (tester) async {
        // Arrange
        final context = await _createContext(tester, ThemeData.light());

        // Act
        final successColor = context.successColor;

        // Assert
        expect(successColor, equals(AppTheme.successLight));
      });

      testWidgets('debe detectar dark mode correctamente', (tester) async {
        // Arrange
        final context = await _createContext(tester, ThemeData.dark());

        // Act
        final successColor = context.successColor;

        // Assert
        expect(successColor, equals(AppTheme.successDark));
      });
    });
  });
}
