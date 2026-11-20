import 'package:chismes/features/home/domain/entities/feed_gossip.dart';
import 'package:chismes/features/home/presentation/widgets/feed_gossip_label.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/widget_test_wrapper.dart';

void main() {
  FeedGossip gossip({String? cityName, bool trending = false}) => FeedGossip(
        id: 'g1',
        subject: 's',
        content: 'c',
        cityId: 'MED',
        cityName: cityName,
        createdAt: DateTime(2024),
        likes: 0,
        comments: 0,
        shares: 0,
        publishedAs: 'profile',
        score: 1,
        isTrending: trending,
      );

  group('FeedGossipLabel', () {
    testWidgets('muestra la ciudad', (tester) async {
      await pumpWidgetWithI18n(
          tester, FeedGossipLabel(gossip: gossip(cityName: 'Medellín')));

      expect(find.text('📍 Medellín'), findsOneWidget);
    });

    testWidgets('muestra ciudad y tendencia (es)', (tester) async {
      await pumpWidgetWithI18n(tester,
          FeedGossipLabel(gossip: gossip(cityName: 'Madrid', trending: true)));

      expect(find.text('📍 Madrid  ·  🔥 Tendencia'), findsOneWidget);
    });

    testWidgets('traduce la tendencia (en)', (tester) async {
      await pumpWidgetWithI18n(
        tester,
        FeedGossipLabel(gossip: gossip(trending: true)),
        locale: const Locale('en'),
      );

      expect(find.text('🔥 Trending'), findsOneWidget);
    });

    testWidgets('sin ciudad ni tendencia no ocupa espacio', (tester) async {
      await pumpWidgetWithI18n(tester, FeedGossipLabel(gossip: gossip()));

      expect(find.byType(Text), findsNothing);
    });
  });
}
