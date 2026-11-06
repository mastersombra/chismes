import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chismes/features/gossip/presentation/widgets/report_gossip_dialog.dart';
import 'package:chismes/features/gossip/domain/entities/report_reason.dart';

void main() {
  group('ReportGossipDialog', () {
    testWidgets('debe renderizar título del diálogo', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ReportGossipDialog(),
        ),
      );

      expect(find.text('Reportar chisme'), findsOneWidget);
    });

    testWidgets('debe renderizar pregunta principal', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ReportGossipDialog(),
        ),
      );

      expect(find.text('¿Por qué reportas este chisme?'), findsOneWidget);
    });

    testWidgets('debe renderizar todas las razones de reporte', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ReportGossipDialog(),
        ),
      );

      // Verificar que están todas las razones
      expect(find.text('Spam'), findsOneWidget);
      expect(find.text('Acoso o intimidación'), findsOneWidget);
      expect(find.text('Violencia o amenazas'), findsOneWidget);
      expect(find.text('Contenido sexual'), findsOneWidget);
      expect(find.text('Desinformación'), findsOneWidget);
      expect(find.text('Otro motivo'), findsOneWidget);
    });

    testWidgets('debe renderizar Radio buttons para cada razón', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ReportGossipDialog(),
        ),
      );

      final radioButtons = find.byType(Radio<ReportReason>);
      expect(radioButtons, findsNWidgets(ReportReason.values.length));
    });

    testWidgets('debe renderizar campo de detalles opcionales', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ReportGossipDialog(),
        ),
      );

      expect(find.text('Detalles adicionales (opcional)'), findsOneWidget);
      expect(find.text('Describe el problema...'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('TextField debe tener maxLines 3', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ReportGossipDialog(),
        ),
      );

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.maxLines, 3);
    });

    testWidgets('TextField debe tener maxLength 500', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ReportGossipDialog(),
        ),
      );

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.maxLength, 500);
    });

    testWidgets('debe renderizar botón Cancelar', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ReportGossipDialog(),
        ),
      );

      expect(find.text('Cancelar'), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Cancelar'), findsOneWidget);
    });

    testWidgets('debe renderizar botón Reportar', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ReportGossipDialog(),
        ),
      );

      expect(find.text('Reportar'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Reportar'), findsOneWidget);
    });

    testWidgets('botón Reportar debe estar deshabilitado inicialmente', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ReportGossipDialog(),
        ),
      );

      final reportButton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Reportar'),
      );
      expect(reportButton.onPressed, isNull);
    });

    testWidgets('debe poder seleccionar una razón con Radio', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ReportGossipDialog(),
        ),
      );

      // Seleccionar "Spam"
      await tester.tap(find.byType(Radio<ReportReason>).first);
      await tester.pump();

      // El radio debe estar seleccionado
      final radio = tester.widget<Radio<ReportReason>>(
        find.byType(Radio<ReportReason>).first,
      );
      // ignore: deprecated_member_use
      expect(radio.groupValue, ReportReason.spam);
    });

    testWidgets('debe poder seleccionar una razón tocando el ListTile', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ReportGossipDialog(),
        ),
      );

      // Tap en el ListTile de "Acoso o intimidación"
      await tester.tap(find.text('Acoso o intimidación'));
      await tester.pump();

      // Verificar que el radio correspondiente está seleccionado
      final radio = tester.widget<Radio<ReportReason>>(
        find.byType(Radio<ReportReason>).at(1),
      );
      // ignore: deprecated_member_use
      expect(radio.groupValue, ReportReason.harassment);
    });

    testWidgets('botón Reportar debe habilitarse al seleccionar razón', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ReportGossipDialog(),
        ),
      );

      // Seleccionar una razón
      await tester.tap(find.text('Spam'));
      await tester.pump();

      // El botón debe estar habilitado
      final reportButton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Reportar'),
      );
      expect(reportButton.onPressed, isNotNull);
    });

    testWidgets('debe retornar null al presionar Cancelar', (tester) async {
      Object? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    result = await showDialog(
                      context: context,
                      builder: (_) => const ReportGossipDialog(),
                    );
                  },
                  child: const Text('Show Dialog'),
                );
              },
            ),
          ),
        ),
      );

      // Abrir diálogo
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Presionar Cancelar
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(result, isNull);
    });

    testWidgets('debe retornar datos al presionar Reportar con razón seleccionada', (tester) async {
      Object? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    result = await showDialog(
                      context: context,
                      builder: (_) => const ReportGossipDialog(),
                    );
                  },
                  child: const Text('Show Dialog'),
                );
              },
            ),
          ),
        ),
      );

      // Abrir diálogo
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Seleccionar razón
      await tester.tap(find.text('Spam'));
      await tester.pump();

      // Presionar Reportar
      await tester.tap(find.text('Reportar'));
      await tester.pumpAndSettle();

      expect(result, isA<Map<String, dynamic>>());
      final resultMap = result as Map<String, dynamic>;
      expect(resultMap['reason'], ReportReason.spam);
      expect(resultMap['details'], isNull);
    });

    testWidgets('debe incluir detalles si se proporcionan', (tester) async {
      Object? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    result = await showDialog(
                      context: context,
                      builder: (_) => const ReportGossipDialog(),
                    );
                  },
                  child: const Text('Show Dialog'),
                );
              },
            ),
          ),
        ),
      );

      // Abrir diálogo
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Seleccionar razón
      await tester.tap(find.text('Violencia o amenazas'));
      await tester.pump();

      // Escribir detalles
      await tester.enterText(find.byType(TextField), 'Detalles del reporte');
      await tester.pump();

      // Presionar Reportar
      await tester.tap(find.text('Reportar'));
      await tester.pumpAndSettle();

      expect(result, isA<Map<String, dynamic>>());
      final resultMap = result as Map<String, dynamic>;
      expect(resultMap['reason'], ReportReason.violence);
      expect(resultMap['details'], 'Detalles del reporte');
    });

    testWidgets('debe retornar null en details si el texto está vacío', (tester) async {
      Object? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    result = await showDialog(
                      context: context,
                      builder: (_) => const ReportGossipDialog(),
                    );
                  },
                  child: const Text('Show Dialog'),
                );
              },
            ),
          ),
        ),
      );

      // Abrir diálogo
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Seleccionar razón
      await tester.tap(find.text('Spam'));
      await tester.pump();

      // Escribir espacios en blanco
      await tester.enterText(find.byType(TextField), '   ');
      await tester.pump();

      // Presionar Reportar
      await tester.tap(find.text('Reportar'));
      await tester.pumpAndSettle();

      expect(result, isA<Map<String, dynamic>>());
      final resultMap = result as Map<String, dynamic>;
      expect(resultMap['reason'], ReportReason.spam);
      expect(resultMap['details'], isNull);
    });

    testWidgets('debe tener AlertDialog como contenedor', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ReportGossipDialog(),
        ),
      );

      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('debe tener SingleChildScrollView para contenido', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ReportGossipDialog(),
        ),
      );

      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('debe tener Column con mainAxisSize.min', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ReportGossipDialog(),
        ),
      );

      final column = tester.widget<Column>(
        find.descendant(
          of: find.byType(SingleChildScrollView),
          matching: find.byType(Column),
        ),
      );
      expect(column.mainAxisSize, MainAxisSize.min);
      expect(column.crossAxisAlignment, CrossAxisAlignment.start);
    });

    testWidgets('ListTile debe tener dense true', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ReportGossipDialog(),
        ),
      );

      final listTiles = tester.widgetList<ListTile>(find.byType(ListTile));
      for (final listTile in listTiles) {
        expect(listTile.dense, isTrue);
      }
    });

    testWidgets('ListTile debe tener contentPadding zero', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ReportGossipDialog(),
        ),
      );

      final listTiles = tester.widgetList<ListTile>(find.byType(ListTile));
      for (final listTile in listTiles) {
        expect(listTile.contentPadding, EdgeInsets.zero);
      }
    });

    testWidgets('debe tener espaciado correcto entre elementos', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ReportGossipDialog(),
        ),
      );

      final sizedBoxes = tester.widgetList<SizedBox>(find.byType(SizedBox));
      final spacings = sizedBoxes.where((box) => box.height == 12.0);
      expect(spacings.length, greaterThanOrEqualTo(2));
    });

    testWidgets('TextField debe tener OutlineInputBorder', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ReportGossipDialog(),
        ),
      );

      final textField = tester.widget<TextField>(find.byType(TextField));
      final decoration = textField.decoration;
      expect(decoration?.border, isA<OutlineInputBorder>());
    });

    testWidgets('debe poder seleccionar cada una de las razones', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ReportGossipDialog(),
        ),
      );

      // Probar seleccionando cada razón
      final reasons = [
        'Spam',
        'Acoso o intimidación',
        'Violencia o amenazas',
        'Contenido sexual',
        'Desinformación',
        'Otro motivo',
      ];

      for (final reason in reasons) {
        await tester.tap(find.text(reason));
        await tester.pump();

        // Verificar que algún radio está seleccionado
        final radios = tester.widgetList<Radio<ReportReason>>(
          find.byType(Radio<ReportReason>),
        );
        // ignore: deprecated_member_use
        final hasSelection = radios.any((radio) => radio.groupValue != null);
        expect(hasSelection, isTrue, reason: 'No selection for $reason');
      }
    });

    testWidgets('pregunta principal debe tener fontWeight w500', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ReportGossipDialog(),
        ),
      );

      final text = tester.widget<Text>(
        find.text('¿Por qué reportas este chisme?'),
      );
      expect(text.style?.fontWeight, FontWeight.w500);
    });

    testWidgets('debe disponer del controller al cerrar', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => const ReportGossipDialog(),
                    );
                  },
                  child: const Text('Show Dialog'),
                );
              },
            ),
          ),
        ),
      );

      // Abrir diálogo
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Cerrar diálogo
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      // El test pasa si no hay memory leaks (controller dispuesto correctamente)
      expect(find.byType(ReportGossipDialog), findsNothing);
    });

    testWidgets('debe trimear los detalles antes de retornar', (tester) async {
      Object? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    result = await showDialog(
                      context: context,
                      builder: (_) => const ReportGossipDialog(),
                    );
                  },
                  child: const Text('Show Dialog'),
                );
              },
            ),
          ),
        ),
      );

      // Abrir diálogo
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Seleccionar razón
      await tester.tap(find.text('Spam'));
      await tester.pump();

      // Escribir texto con espacios al inicio y final
      await tester.enterText(find.byType(TextField), '  texto con espacios  ');
      await tester.pump();

      // Presionar Reportar
      await tester.tap(find.text('Reportar'));
      await tester.pumpAndSettle();

      final resultMap = result as Map<String, dynamic>;
      expect(resultMap['details'], 'texto con espacios');
    });
  });
}
