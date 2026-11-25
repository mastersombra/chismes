import 'package:chismes/core/widgets/user_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_network_image.dart';
import '../../helpers/widget_test_wrapper.dart';

void main() {
  testWidgets('sin foto muestra la inicial (sin @)', (tester) async {
    await tester.pumpWidget(testableWidget(
      child: const UserAvatar(avatarUrl: null, name: '@beto'),
    ));

    expect(find.text('B'), findsOneWidget);
    final avatar = tester.widget<CircleAvatar>(find.byType(CircleAvatar));
    expect(avatar.foregroundImage, isNull);
  });

  testWidgets('sin nombre muestra ?', (tester) async {
    await tester.pumpWidget(testableWidget(
      child: const UserAvatar(avatarUrl: '', name: ''),
    ));

    expect(find.text('?'), findsOneWidget);
  });

  testWidgets('con foto la carga encima de la inicial', (tester) async {
    useFakeNetworkImages(addTearDown);
    await tester.pumpWidget(testableWidget(
      child: const UserAvatar(avatarUrl: 'https://x/a.png', name: 'Ana', radius: 30),
    ));
    await tester.pumpAndSettle();

    final avatar = tester.widget<CircleAvatar>(find.byType(CircleAvatar));
    expect(avatar.foregroundImage, isA<NetworkImage>());
    expect(avatar.onForegroundImageError, isNotNull);
    expect(avatar.radius, 30);
  });
}
