import 'dart:async';

import 'package:chismes/core/result/result.dart';
import 'package:chismes/features/auth/domain/entities/user.dart';
import 'package:chismes/features/notifications/domain/usecases/get_unread_notifications_count.dart';
import 'package:chismes/features/notifications/presentation/controllers/notifications_badge_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../../notifications_fixtures.dart';
import '../../notifications_test_mocks.mocks.dart';

void main() {
  late MockNotificationsRepository repository;
  late MockAppLogger logger;
  late StreamController<User?> auth;
  late NotificationsBadgeController badge;
  late DateTime now;

  setUpAll(provideNotificationsDummies);

  setUp(() {
    repository = MockNotificationsRepository();
    logger = MockAppLogger();
    auth = StreamController<User?>.broadcast();
    final authService = MockAuthService();
    when(authService.userStream).thenAnswer((_) => auth.stream);
    badge = NotificationsBadgeController(
      GetUnreadNotificationsCount(repository),
      authService,
      logger,
    );
    now = DateTime(2026, 11, 24, 12);
    badge.now = () => now;
  });

  tearDown(() async {
    badge.dispose();
    await auth.close();
  });

  void stubCount(int count) =>
      when(repository.getUnreadCount()).thenAnswer((_) async => Result.success(count));

  test('empieza en 0', () {
    expect(badge.value, 0);
  });

  test('refresh pide el contador y notifica', () async {
    stubCount(5);
    var notified = 0;
    badge.addListener(() => notified++);

    await badge.refresh();

    expect(badge.value, 5);
    expect(notified, 1);
  });

  test('throttle: ignora otra llamada antes de 10 s; después vuelve a pedir', () async {
    stubCount(3);
    await badge.refresh();

    now = now.add(const Duration(seconds: 9));
    await badge.refresh();
    verify(repository.getUnreadCount()).called(1);

    now = now.add(const Duration(seconds: 1));
    stubCount(4);
    await badge.refresh();
    verify(repository.getUnreadCount()).called(1);
    expect(badge.value, 4);
  });

  test('force ignora el throttle', () async {
    stubCount(1);
    await badge.refresh();

    await badge.refresh(force: true);

    verify(repository.getUnreadCount()).called(2);
  });

  test('llamadas simultáneas comparten la misma petición', () async {
    final completer = Completer<void>();
    when(repository.getUnreadCount()).thenAnswer((_) async {
      await completer.future;
      return Result.success(2);
    });

    final first = badge.refresh();
    final second = badge.refresh(force: true);
    completer.complete();
    await Future.wait([first, second]);

    verify(repository.getUnreadCount()).called(1);
    expect(badge.value, 2);
  });

  test('un error conserva el último valor, avisa con warning y no activa el throttle', () async {
    stubCount(7);
    await badge.refresh();
    now = now.add(const Duration(minutes: 1));
    when(repository.getUnreadCount()).thenAnswer((_) async => Result.failure(tServerFailure));

    await badge.refresh();

    expect(badge.value, 7);
    verify(logger.w('Failed to refresh unread notifications', context: anyNamed('context'))).called(1);

    // Tras un error el siguiente intento sí va al servidor (sin esperar 10 s)
    stubCount(8);
    await badge.refresh();
    expect(badge.value, 8);
  });

  test('negativo (no debería) → 0', () async {
    stubCount(-1);

    await badge.refresh();

    expect(badge.value, 0);
  });

  test('clear vuelve a 0 y el siguiente refresh no espera el throttle', () async {
    stubCount(5);
    await badge.refresh();

    badge.clear();
    expect(badge.value, 0);

    await badge.refresh();
    verify(repository.getUnreadCount()).called(2);
  });

  test('clear durante una petición descarta su respuesta', () async {
    final completer = Completer<void>();
    when(repository.getUnreadCount()).thenAnswer((_) async {
      await completer.future;
      return Result.success(9);
    });

    final pending = badge.refresh();
    badge.clear();
    completer.complete();
    await pending;

    expect(badge.value, 0);
  });

  test('al cerrar sesión (usuario null) vuelve a 0', () async {
    stubCount(5);
    await badge.refresh();

    auth.add(User(
      id: 'u',
      email: 'a@b.c',
      emailVerified: true,
      profileCompleted: true,
      createdAt: DateTime(2026),
    ));
    await Future<void>.delayed(Duration.zero);
    expect(badge.value, 5);

    auth.add(null);
    await Future<void>.delayed(Duration.zero);
    expect(badge.value, 0);
  });

  test('error del stream de auth: solo warning', () async {
    auth.addError(Exception('boom'));
    await Future<void>.delayed(Duration.zero);

    verify(logger.w('Auth stream error in notifications badge', context: anyNamed('context')))
        .called(1);
  });

  test('label: vacío en 0, número hasta 99, 99+ desde 100', () {
    expect(NotificationsBadgeController.label(0), '');
    expect(NotificationsBadgeController.label(-3), '');
    expect(NotificationsBadgeController.label(5), '5');
    expect(NotificationsBadgeController.label(99), '99');
    expect(NotificationsBadgeController.label(100), '99+');
  });
}
