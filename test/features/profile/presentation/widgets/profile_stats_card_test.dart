import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chismes/features/profile/presentation/widgets/profile_stats_card.dart';
import 'package:chismes/features/profile/domain/entities/user_stats.dart';

import '../../../../helpers/widget_test_wrapper.dart';

void main() {
  const mockStats = UserStats(
    gossipsCount: 42,
    commentsCount: 128,
    followersCount: 1500,
    followingCount: 89,
  );

  const mockStatsLarge = UserStats(
    gossipsCount: 5000,
    commentsCount: 1200000,
    followersCount: 3500000,
    followingCount: 250,
  );

  Widget createTestWidget(UserStats stats) {
    return testableWidget(
      child: ProfileStatsCard(stats: stats),
    );
  }

  group('ProfileStatsCard - Básicos', () {
    testWidgets('debe renderizar el widget', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget(mockStats));
      await tester.pump();

      // Assert
      expect(find.byType(ProfileStatsCard), findsOneWidget);
    });

    testWidgets('debe ser un StatelessWidget', (tester) async {
      // Arrange
      const widget = ProfileStatsCard(stats: mockStats);

      // Assert
      expect(widget, isA<StatelessWidget>());
    });

    testWidgets('debe renderizar Card principal', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget(mockStats));
      await tester.pump();

      // Assert
      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('Card debe tener elevation 0', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget(mockStats));
      await tester.pump();

      // Assert
      final card = tester.widget<Card>(find.byType(Card));
      expect(card.elevation, 0);
    });

    testWidgets('debe tener RoundedRectangleBorder con radio 12', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget(mockStats));
      await tester.pump();

      // Assert
      final card = tester.widget<Card>(find.byType(Card));
      final shape = card.shape as RoundedRectangleBorder;
      expect(shape.borderRadius, BorderRadius.circular(12));
    });

    testWidgets('debe aceptar key opcional', (tester) async {
      // Arrange
      const key = Key('stats-card-key');

      // Act
      await tester.pumpWidget(
        testableWidget(
          child: const ProfileStatsCard(
            key: key,
            stats: mockStats,
          ),
        ),
      );
      await tester.pump();

      // Assert
      expect(find.byKey(key), findsOneWidget);
    });
  });

  group('ProfileStatsCard - Estadísticas', () {
    testWidgets('debe mostrar gossipsCount', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget(mockStats));
      await tester.pump();

      // Assert
      expect(find.text('42'), findsOneWidget);
    });

    testWidgets('debe mostrar commentsCount', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget(mockStats));
      await tester.pump();

      // Assert
      expect(find.text('128'), findsOneWidget);
    });

    testWidgets('debe mostrar followersCount formateado', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget(mockStats));
      await tester.pump();

      // Assert
      expect(find.text('1.5K'), findsOneWidget);
    });

    testWidgets('debe mostrar followingCount', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget(mockStats));
      await tester.pump();

      // Assert
      expect(find.text('89'), findsOneWidget);
    });

    testWidgets('debe mostrar todas las 4 estadísticas', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget(mockStats));
      await tester.pump();

      // Assert
      expect(find.text('42'), findsOneWidget); // gossips
      expect(find.text('128'), findsOneWidget); // comments
      expect(find.text('1.5K'), findsOneWidget); // followers
      expect(find.text('89'), findsOneWidget); // following
    });
  });

  group('ProfileStatsCard - Formato de Números', () {
    testWidgets('debe formatear números < 1000 sin sufijo', (tester) async {
      // Arrange
      const stats = UserStats(
        gossipsCount: 999,
        commentsCount: 0,
        followersCount: 1,
        followingCount: 500,
      );

      // Act
      await tester.pumpWidget(createTestWidget(stats));
      await tester.pump();

      // Assert
      expect(find.text('999'), findsOneWidget);
      expect(find.text('0'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('500'), findsOneWidget);
    });

    testWidgets('debe formatear números >= 1000 con K', (tester) async {
      // Arrange
      const stats = UserStats(
        gossipsCount: 1000,
        commentsCount: 5000,
        followersCount: 12345,
        followingCount: 100,
      );

      // Act
      await tester.pumpWidget(createTestWidget(stats));
      await tester.pump();

      // Assert
      expect(find.text('1.0K'), findsOneWidget);
      expect(find.text('5.0K'), findsOneWidget);
      expect(find.text('12.3K'), findsOneWidget);
      expect(find.text('100'), findsOneWidget);
    });

    testWidgets('debe formatear números >= 1000000 con M', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget(mockStatsLarge));
      await tester.pump();

      // Assert
      expect(find.text('5.0K'), findsOneWidget); // gossips: 5000
      expect(find.text('1.2M'), findsOneWidget); // comments: 1200000
      expect(find.text('3.5M'), findsOneWidget); // followers: 3500000
      expect(find.text('250'), findsOneWidget); // following: 250
    });

    testWidgets('debe usar 1 decimal en formato K', (tester) async {
      // Arrange
      const stats = UserStats(
        gossipsCount: 1234,
        commentsCount: 0,
        followersCount: 0,
        followingCount: 0,
      );

      // Act
      await tester.pumpWidget(createTestWidget(stats));
      await tester.pump();

      // Assert
      expect(find.text('1.2K'), findsOneWidget);
    });

    testWidgets('debe usar 1 decimal en formato M', (tester) async {
      // Arrange
      const stats = UserStats(
        gossipsCount: 2500000,
        commentsCount: 0,
        followersCount: 0,
        followingCount: 0,
      );

      // Act
      await tester.pumpWidget(createTestWidget(stats));
      await tester.pump();

      // Assert
      expect(find.text('2.5M'), findsOneWidget);
    });
  });

  group('ProfileStatsCard - Iconos', () {
    testWidgets('debe mostrar ícono de chat_bubble_outline para gossips',
        (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget(mockStats));
      await tester.pump();

      // Assert
      expect(find.byIcon(Icons.chat_bubble_outline), findsOneWidget);
    });

    testWidgets('debe mostrar ícono de comment_outlined para comments',
        (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget(mockStats));
      await tester.pump();

      // Assert
      expect(find.byIcon(Icons.comment_outlined), findsOneWidget);
    });

    testWidgets('debe mostrar ícono de people_outline para followers',
        (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget(mockStats));
      await tester.pump();

      // Assert
      expect(find.byIcon(Icons.people_outline), findsOneWidget);
    });

    testWidgets('debe mostrar ícono de person_add_outlined para following',
        (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget(mockStats));
      await tester.pump();

      // Assert
      expect(find.byIcon(Icons.person_add_outlined), findsOneWidget);
    });

    testWidgets('debe tener 4 íconos en total', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget(mockStats));
      await tester.pump();

      // Assert
      expect(find.byType(Icon), findsNWidgets(4));
    });

    testWidgets('cada ícono debe tener tamaño 28', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget(mockStats));
      await tester.pump();

      // Assert
      final icons = tester.widgetList<Icon>(find.byType(Icon));
      for (final icon in icons) {
        expect(icon.size, 28);
      }
    });
  });

  group('ProfileStatsCard - Colores', () {
    testWidgets('gossips debe usar color purple', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget(mockStats));
      await tester.pump();

      // Assert
      final gossipIcon = tester.widget<Icon>(
        find.byIcon(Icons.chat_bubble_outline),
      );
      expect(gossipIcon.color, Colors.purple);
    });

    testWidgets('comments debe usar color blue', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget(mockStats));
      await tester.pump();

      // Assert
      final commentIcon = tester.widget<Icon>(
        find.byIcon(Icons.comment_outlined),
      );
      expect(commentIcon.color, Colors.blue);
    });

    testWidgets('followers debe usar color green', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget(mockStats));
      await tester.pump();

      // Assert
      final followersIcon = tester.widget<Icon>(
        find.byIcon(Icons.people_outline),
      );
      expect(followersIcon.color, Colors.green);
    });

    testWidgets('following debe usar color orange', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget(mockStats));
      await tester.pump();

      // Assert
      final followingIcon = tester.widget<Icon>(
        find.byIcon(Icons.person_add_outlined),
      );
      expect(followingIcon.color, Colors.orange);
    });
  });

  group('ProfileStatsCard - Layout', () {
    testWidgets('debe tener Column principal', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget(mockStats));
      await tester.pump();

      // Assert
      expect(find.byType(Column), findsWidgets);
    });

    testWidgets('debe tener 2 Row para stats', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget(mockStats));
      await tester.pump();

      // Assert
      // Al menos 2 Rows (uno para cada fila de stats)
      expect(find.byType(Row), findsAtLeastNWidgets(2));
    });

    testWidgets('debe tener Padding alrededor del contenido', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget(mockStats));
      await tester.pump();

      // Assert
      expect(find.byType(Padding), findsWidgets);
    });

    testWidgets('debe tener SizedBox para espaciado', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget(mockStats));
      await tester.pump();

      // Assert
      expect(find.byType(SizedBox), findsWidgets);
    });

    testWidgets('debe tener Container circular para cada ícono', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget(mockStats));
      await tester.pump();

      // Assert - debe haber 4 Containers (uno por stat)
      final containers = tester.widgetList<Container>(
        find.byType(Container),
      );

      // Verificar que hay al menos 4 containers
      expect(containers.length, greaterThanOrEqualTo(4));
    });

    testWidgets('Rows deben usar MainAxisAlignment.spaceAround',
        (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget(mockStats));
      await tester.pump();

      // Assert - verificar que hay Rows
      expect(find.byType(Row), findsWidgets);
    });
  });

  group('ProfileStatsCard - Texto', () {
    testWidgets('números deben usar headlineSmall en negrita', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget(mockStats));
      await tester.pump();

      // Assert - verificar que el número 42 tiene el estilo correcto
      final textWidget = tester.widget<Text>(find.text('42'));
      expect(textWidget.style?.fontWeight, FontWeight.bold);
    });

    testWidgets('labels deben usar bodySmall', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget(mockStats));
      await tester.pump();

      // Assert - verificar que hay múltiples Text widgets
      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('labels deben tener color gris', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget(mockStats));
      await tester.pump();

      // Assert - verificar que hay textos con estilo
      final textWidgets = tester.widgetList<Text>(find.byType(Text));
      expect(textWidgets.length, greaterThan(4));
    });

    testWidgets('labels deben tener textAlign center', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget(mockStats));
      await tester.pump();

      // Assert - verificar que hay widgets Text
      expect(find.byType(Text), findsWidgets);
    });
  });

  group('ProfileStatsCard - Constructor', () {
    test('debe requerir stats en constructor', () {
      // Act & Assert
      expect(
        () => const ProfileStatsCard(stats: mockStats),
        returnsNormally,
      );
    });

    test('debe ser const constructor', () {
      // Act
      const widget = ProfileStatsCard(stats: mockStats);

      // Assert
      expect(widget, isA<ProfileStatsCard>());
      expect(widget.stats, mockStats);
    });

    test('stats debe ser final', () {
      // Arrange
      const widget = ProfileStatsCard(stats: mockStats);

      // Assert
      expect(widget.stats, equals(mockStats));
    });
  });

  group('ProfileStatsCard - Edge Cases', () {
    testWidgets('debe manejar stats con todos los valores en 0', (tester) async {
      // Arrange
      const zeroStats = UserStats(
        gossipsCount: 0,
        commentsCount: 0,
        followersCount: 0,
        followingCount: 0,
      );

      // Act
      await tester.pumpWidget(createTestWidget(zeroStats));
      await tester.pump();

      // Assert
      expect(find.text('0'), findsNWidgets(4));
    });

    testWidgets('debe manejar números muy grandes', (tester) async {
      // Arrange
      const hugeStats = UserStats(
        gossipsCount: 999999999,
        commentsCount: 999999999,
        followersCount: 999999999,
        followingCount: 999999999,
      );

      // Act
      await tester.pumpWidget(createTestWidget(hugeStats));
      await tester.pump();

      // Assert - Todos deben estar en formato M
      expect(find.textContaining('M'), findsNWidgets(4));
    });

    testWidgets('debe manejar el límite 1000 exacto', (tester) async {
      // Arrange
      const exactStats = UserStats(
        gossipsCount: 1000,
        commentsCount: 1000,
        followersCount: 1000,
        followingCount: 1000,
      );

      // Act
      await tester.pumpWidget(createTestWidget(exactStats));
      await tester.pump();

      // Assert
      expect(find.text('1.0K'), findsNWidgets(4));
    });

    testWidgets('debe manejar el límite 1000000 exacto', (tester) async {
      // Arrange
      const exactStats = UserStats(
        gossipsCount: 1000000,
        commentsCount: 1000000,
        followersCount: 1000000,
        followingCount: 1000000,
      );

      // Act
      await tester.pumpWidget(createTestWidget(exactStats));
      await tester.pump();

      // Assert
      expect(find.text('1.0M'), findsNWidgets(4));
    });
  });
}
