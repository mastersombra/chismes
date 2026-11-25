import 'package:chismes/core/services/location_service.dart';
import 'package:chismes/features/profile/presentation/widgets/location_privacy_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../../../../helpers/widget_test_wrapper.dart';
import 'location_privacy_card_test.mocks.dart';

@GenerateNiceMocks([MockSpec<LocationService>()])
void main() {
  late MockLocationService service;

  final medellin = SavedLocation(
    countryId: 'CO',
    regionId: 'co-antioquia',
    cityId: 'medellin',
    countryName: 'Colombia',
    regionName: 'Antioquia',
    cityName: 'Medellín',
  );

  setUp(() {
    service = MockLocationService();
    when(service.getDefaultLocation()).thenAnswer((_) async => medellin);
    when(service.isAnonymousModeEnabled()).thenAnswer((_) async => false);
    when(service.clearDefaultLocation()).thenAnswer((_) async {});
    when(service.setAnonymousMode(any)).thenAnswer((_) async => true);
  });

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(testableWidget(
      child: SingleChildScrollView(
        child: LocationPrivacyCard(locationService: service),
      ),
    ));
    await tester.pumpAndSettle();
  }

  SwitchListTile dontSaveSwitch(WidgetTester tester) => tester.widget(
      find.byKey(const Key('locationPrivacyDontSaveSwitch')));

  testWidgets('muestra la ciudad guardada y el switch apagado', (tester) async {
    await pump(tester);

    expect(find.text('Ubicación'), findsOneWidget);
    expect(find.text('Medellín, Antioquia, Colombia'), findsOneWidget);
    expect(find.byKey(const Key('locationPrivacyForgetButton')), findsOneWidget);
    expect(dontSaveSwitch(tester).value, isFalse);
  });

  testWidgets('sin ciudad guardada: "No guardada" y sin botón de olvidar',
      (tester) async {
    when(service.getDefaultLocation()).thenAnswer((_) async => null);
    when(service.isAnonymousModeEnabled()).thenAnswer((_) async => true);

    await pump(tester);

    expect(find.text('No guardada'), findsOneWidget);
    expect(find.byKey(const Key('locationPrivacyForgetButton')), findsNothing);
    expect(dontSaveSwitch(tester).value, isTrue);
  });

  testWidgets('mientras carga, el switch está deshabilitado', (tester) async {
    await tester.pumpWidget(testableWidget(
      child: LocationPrivacyCard(locationService: service),
    ));

    expect(find.text('…'), findsOneWidget);
    expect(dontSaveSwitch(tester).onChanged, isNull);
    await tester.pumpAndSettle();
  });

  testWidgets('olvidar → confirmar borra la ciudad y avisa', (tester) async {
    await pump(tester);

    await tester.tap(find.byKey(const Key('locationPrivacyForgetButton')));
    await tester.pumpAndSettle();
    expect(find.text('¿Olvidar tu ubicación?'), findsOneWidget);

    await tester.tap(find.byKey(const Key('locationPrivacyForgetConfirm')));
    await tester.pumpAndSettle();

    verify(service.clearDefaultLocation()).called(1);
    expect(find.text('No guardada'), findsOneWidget);
    expect(find.text('Ubicación olvidada'), findsOneWidget);
  });

  testWidgets('olvidar → cancelar no borra nada', (tester) async {
    await pump(tester);

    await tester.tap(find.byKey(const Key('locationPrivacyForgetButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    verifyNever(service.clearDefaultLocation());
    expect(find.text('Medellín, Antioquia, Colombia'), findsOneWidget);
  });

  testWidgets('activar "No guardar ubicación" lo guarda y oculta la ciudad',
      (tester) async {
    await pump(tester);

    await tester.tap(find.byKey(const Key('locationPrivacyDontSaveSwitch')));
    await tester.pumpAndSettle();

    verify(service.setAnonymousMode(true)).called(1);
    expect(dontSaveSwitch(tester).value, isTrue);
    expect(find.text('No guardada'), findsOneWidget);
  });

  testWidgets('desactivarlo no toca la ciudad', (tester) async {
    when(service.isAnonymousModeEnabled()).thenAnswer((_) async => true);
    await pump(tester);

    await tester.tap(find.byKey(const Key('locationPrivacyDontSaveSwitch')));
    await tester.pumpAndSettle();

    verify(service.setAnonymousMode(false)).called(1);
    expect(dontSaveSwitch(tester).value, isFalse);
    expect(find.text('Medellín, Antioquia, Colombia'), findsOneWidget);
  });

  testWidgets('si no se puede guardar, el switch no cambia y avisa',
      (tester) async {
    when(service.setAnonymousMode(any)).thenAnswer((_) async => false);
    await pump(tester);

    await tester.tap(find.byKey(const Key('locationPrivacyDontSaveSwitch')));
    await tester.pumpAndSettle();

    expect(dontSaveSwitch(tester).value, isFalse);
    expect(find.text('No se pudo guardar el cambio. Intenta de nuevo.'),
        findsOneWidget);
  });
}
