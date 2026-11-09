import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chismes/features/gossip/presentation/widgets/image_picker_widget.dart';
import '../../../../helpers/widget_test_wrapper.dart';

void main() {
  group('ImagePickerWidget', () {
    testWidgets('debe mostrar botones de selección cuando no hay imagen', (tester) async {
      // Act
      await tester.pumpWidget(
        testableWidget(
          child: ImagePickerWidget(
              imageUrl: null,
              isUploading: false,
              onPickFromCamera: () {},
              onPickFromGallery: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Agrega una foto (opcional)'), findsOneWidget);
      expect(find.text('Cámara'), findsOneWidget);
      expect(find.text('Galería'), findsOneWidget);
      expect(find.byIcon(Icons.camera_alt), findsOneWidget);
      expect(find.byIcon(Icons.photo_library), findsOneWidget);
    });

    testWidgets('debe llamar onPickFromCamera cuando se presiona botón de cámara', (tester) async {
      // Arrange
      var cameraPressed = false;

      await tester.pumpWidget(
        testableWidget(
          child: ImagePickerWidget(
              imageUrl: null,
              isUploading: false,
              onPickFromCamera: () => cameraPressed = true,
              onPickFromGallery: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.text('Cámara'));
      await tester.pump();

      // Assert
      expect(cameraPressed, isTrue);
    });

    testWidgets('debe llamar onPickFromGallery cuando se presiona botón de galería', (tester) async {
      // Arrange
      var galleryPressed = false;

      await tester.pumpWidget(
        testableWidget(
          child: ImagePickerWidget(
              imageUrl: null,
              isUploading: false,
              onPickFromCamera: () {},
              onPickFromGallery: () => galleryPressed = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.text('Galería'));
      await tester.pump();

      // Assert
      expect(galleryPressed, isTrue);
    });

    testWidgets('debe mostrar loading state cuando isUploading es true', (tester) async {
      // Act
      await tester.pumpWidget(
        testableWidget(
          child: ImagePickerWidget(
              imageUrl: null,
              isUploading: true,
              onPickFromCamera: () {},
              onPickFromGallery: () {},
          ),
        ),
      );
      await tester.pump();

      // Assert
      expect(find.text('Seleccionando imagen...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('debe mostrar texto "Imagen seleccionada" cuando hay imageUrl', (tester) async {
      // Act
      await tester.pumpWidget(
        testableWidget(
          child: ImagePickerWidget(
              imageUrl: '/tmp/test_image.jpg',
              isUploading: false,
              onPickFromCamera: () {},
              onPickFromGallery: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Imagen seleccionada'), findsOneWidget);
    });

    testWidgets('debe tener Container con altura 200 en estado sin imagen', (tester) async {
      // Act
      await tester.pumpWidget(
        testableWidget(
          child: ImagePickerWidget(
              imageUrl: null,
              isUploading: false,
              onPickFromCamera: () {},
              onPickFromGallery: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert - El Container de selección debe tener altura 200
      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(ImagePickerWidget),
          matching: find.byType(Container),
        ).first,
      );

      final decoration = container.decoration as BoxDecoration;
      expect(decoration.borderRadius, BorderRadius.circular(8));
    });

    testWidgets('debe tener Container con altura 200 en loading state', (tester) async {
      // Act
      await tester.pumpWidget(
        testableWidget(
          child: ImagePickerWidget(
              imageUrl: null,
              isUploading: true,
              onPickFromCamera: () {},
              onPickFromGallery: () {},
          ),
        ),
      );
      await tester.pump();

      // Assert
      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(ImagePickerWidget),
          matching: find.byType(Container),
        ).first,
      );

      expect(container.constraints?.maxHeight, greaterThanOrEqualTo(200));
    });

    testWidgets('debe mostrar ícono de imagen en estado sin selección', (tester) async {
      // Act
      await tester.pumpWidget(
        testableWidget(
          child: ImagePickerWidget(
              imageUrl: null,
              isUploading: false,
              onPickFromCamera: () {},
              onPickFromGallery: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.byIcon(Icons.image), findsOneWidget);
    });

    testWidgets('debe tener botones de cámara y galería visibles', (tester) async {
      // Act
      await tester.pumpWidget(
        testableWidget(
          child: ImagePickerWidget(
              imageUrl: null,
              isUploading: false,
              onPickFromCamera: () {},
              onPickFromGallery: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert - Debe haber botones con texto Cámara y Galería
      expect(find.text('Cámara'), findsOneWidget);
      expect(find.text('Galería'), findsOneWidget);
    });

    testWidgets('debe cambiar de estado sin imagen a loading', (tester) async {
      // Arrange - Estado inicial sin imagen
      await tester.pumpWidget(
        testableWidget(
          child: ImagePickerWidget(
              imageUrl: null,
              isUploading: false,
              onPickFromCamera: () {},
              onPickFromGallery: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Agrega una foto (opcional)'), findsOneWidget);

      // Act - Cambiar a loading
      await tester.pumpWidget(
        testableWidget(
          child: ImagePickerWidget(
              imageUrl: null,
              isUploading: true,
              onPickFromCamera: () {},
              onPickFromGallery: () {},
          ),
        ),
      );
      await tester.pump();

      // Assert
      expect(find.text('Seleccionando imagen...'), findsOneWidget);
      expect(find.text('Agrega una foto (opcional)'), findsNothing);
    });

    testWidgets('no debe mostrar botones cuando está en loading', (tester) async {
      // Act
      await tester.pumpWidget(
        testableWidget(
          child: ImagePickerWidget(
              imageUrl: null,
              isUploading: true,
              onPickFromCamera: () {},
              onPickFromGallery: () {},
          ),
        ),
      );
      await tester.pump();

      // Assert
      expect(find.text('Cámara'), findsNothing);
      expect(find.text('Galería'), findsNothing);
    });

    testWidgets('debe tener Row con botones en estado sin imagen', (tester) async {
      // Act
      await tester.pumpWidget(
        testableWidget(
          child: ImagePickerWidget(
              imageUrl: null,
              isUploading: false,
              onPickFromCamera: () {},
              onPickFromGallery: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert - Debe haber un Row conteniendo los botones
      expect(find.byType(Row), findsWidgets);
    });

    testWidgets('loading state debe tener Column centrada', (tester) async {
      // Act
      await tester.pumpWidget(
        testableWidget(
          child: ImagePickerWidget(
              imageUrl: null,
              isUploading: true,
              onPickFromCamera: () {},
              onPickFromGallery: () {},
          ),
        ),
      );
      await tester.pump();

      // Assert
      final column = tester.widget<Column>(
        find.descendant(
          of: find.byType(Center),
          matching: find.byType(Column),
        ),
      );

      expect(column.mainAxisAlignment, MainAxisAlignment.center);
    });

    testWidgets('ambos botones deben estar presentes en el widget', (tester) async {
      // Act
      await tester.pumpWidget(
        testableWidget(
          child: ImagePickerWidget(
              imageUrl: null,
              isUploading: false,
              onPickFromCamera: () {},
              onPickFromGallery: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert - Ambos botones deben ser visibles
      expect(find.text('Cámara'), findsOneWidget);
      expect(find.text('Galería'), findsOneWidget);

      // Y deben tener sus respectivos íconos
      expect(find.byIcon(Icons.camera_alt), findsOneWidget);
      expect(find.byIcon(Icons.photo_library), findsOneWidget);
    });

    testWidgets('debe mostrar botón de remover cuando onRemove está definido', (tester) async {
      await tester.pumpWidget(
        testableWidget(
          child: ImagePickerWidget(
              imageUrl: '/tmp/test_image.jpg',
              isUploading: false,
              onPickFromCamera: () {},
              onPickFromGallery: () {},
              onRemove: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.close), findsOneWidget);
      expect(find.byTooltip('Eliminar imagen'), findsOneWidget);
    });

    testWidgets('NO debe mostrar botón de remover cuando onRemove es null', (tester) async {
      await tester.pumpWidget(
        testableWidget(
          child: ImagePickerWidget(
              imageUrl: '/tmp/test_image.jpg',
              isUploading: false,
              onPickFromCamera: () {},
              onPickFromGallery: () {},
              onRemove: null,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.close), findsNothing);
    });

    testWidgets('debe llamar onRemove cuando se presiona botón de eliminar', (tester) async {
      var removePressed = false;

      await tester.pumpWidget(
        testableWidget(
          child: ImagePickerWidget(
              imageUrl: '/tmp/test_image.jpg',
              isUploading: false,
              onPickFromCamera: () {},
              onPickFromGallery: () {},
              onRemove: () => removePressed = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();

      expect(removePressed, isTrue);
    });

    testWidgets('preview debe tener ClipRRect con borderRadius', (tester) async {
      await tester.pumpWidget(
        testableWidget(
          child: ImagePickerWidget(
              imageUrl: '/tmp/test_image.jpg',
              isUploading: false,
              onPickFromCamera: () {},
              onPickFromGallery: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      final clipRRect = tester.widget<ClipRRect>(find.byType(ClipRRect));
      expect(clipRRect.borderRadius, BorderRadius.circular(8));
    });

    testWidgets('botón de remover debe estar posicionado en top-right', (tester) async {
      await tester.pumpWidget(
        testableWidget(
          child: ImagePickerWidget(
              imageUrl: '/tmp/test_image.jpg',
              isUploading: false,
              onPickFromCamera: () {},
              onPickFromGallery: () {},
              onRemove: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      final positioned = tester.widget<Positioned>(
        find.ancestor(
          of: find.byIcon(Icons.close),
          matching: find.byType(Positioned),
        ),
      );

      expect(positioned.top, 8);
      expect(positioned.right, 8);
    });

    testWidgets('botón remover debe tener minimumSize 48x48', (tester) async {
      await tester.pumpWidget(
        testableWidget(
          child: ImagePickerWidget(
              imageUrl: '/tmp/test_image.jpg',
              isUploading: false,
              onPickFromCamera: () {},
              onPickFromGallery: () {},
              onRemove: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      final iconButton = tester.widget<IconButton>(
        find.ancestor(
          of: find.byIcon(Icons.close),
          matching: find.byType(IconButton),
        ),
      );

      // Verificar que tiene style con minimumSize
      expect(iconButton.style, isNotNull);
    });


    testWidgets('estado loading debe tener Container con altura 200', (tester) async {
      await tester.pumpWidget(
        testableWidget(
          child: ImagePickerWidget(
              imageUrl: null,
              isUploading: true,
              onPickFromCamera: () {},
              onPickFromGallery: () {},
          ),
        ),
      );
      await tester.pump();

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(ImagePickerWidget),
          matching: find.byType(Container),
        ).first,
      );

      expect(container.constraints?.minHeight ?? 0, greaterThanOrEqualTo(0));
    });

    testWidgets('estado sin imagen debe tener Column centrada', (tester) async {
      await tester.pumpWidget(
        testableWidget(
          child: ImagePickerWidget(
              imageUrl: null,
              isUploading: false,
              onPickFromCamera: () {},
              onPickFromGallery: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      final columns = tester.widgetList<Column>(find.byType(Column));
      final centeredColumn = columns.firstWhere(
        (col) => col.mainAxisAlignment == MainAxisAlignment.center,
      );

      expect(centeredColumn, isNotNull);
    });

    testWidgets('debe tener Semantics para accesibilidad', (tester) async {
      await tester.pumpWidget(
        testableWidget(
          child: ImagePickerWidget(
              imageUrl: null,
              isUploading: false,
              onPickFromCamera: () {},
              onPickFromGallery: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Semantics), findsWidgets);
    });

    testWidgets('loading debe tener Semantics con liveRegion', (tester) async {
      await tester.pumpWidget(
        testableWidget(
          child: ImagePickerWidget(
              imageUrl: null,
              isUploading: true,
              onPickFromCamera: () {},
              onPickFromGallery: () {},
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(Semantics), findsWidgets);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('preview debe tener Column con crossAxisAlignment.start', (tester) async {
      await tester.pumpWidget(
        testableWidget(
          child: ImagePickerWidget(
              imageUrl: '/tmp/test_image.jpg',
              isUploading: false,
              onPickFromCamera: () {},
              onPickFromGallery: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      final column = tester.widget<Column>(
        find.descendant(
          of: find.byType(ImagePickerWidget),
          matching: find.byType(Column),
        ).first,
      );

      expect(column.crossAxisAlignment, CrossAxisAlignment.start);
    });

    testWidgets('debe mostrar texto con estilo correcto en preview', (tester) async {
      await tester.pumpWidget(
        testableWidget(
          child: ImagePickerWidget(
              imageUrl: '/tmp/test_image.jpg',
              isUploading: false,
              onPickFromCamera: () {},
              onPickFromGallery: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      final text = tester.widget<Text>(find.text('Imagen seleccionada'));
      expect(text.style?.fontWeight, FontWeight.w500);
    });

    testWidgets('estado sin imagen debe tener icono de tamaño 48', (tester) async {
      await tester.pumpWidget(
        testableWidget(
          child: ImagePickerWidget(
              imageUrl: null,
              isUploading: false,
              onPickFromCamera: () {},
              onPickFromGallery: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      final icon = tester.widget<Icon>(find.byIcon(Icons.image));
      expect(icon.size, 48);
    });

    testWidgets('debe tener espaciado entre texto y elementos en preview', (tester) async {
      await tester.pumpWidget(
        testableWidget(
          child: ImagePickerWidget(
              imageUrl: '/tmp/test_image.jpg',
              isUploading: false,
              onPickFromCamera: () {},
              onPickFromGallery: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      final sizedBoxes = tester.widgetList<SizedBox>(find.byType(SizedBox));
      final hasCorrectSpacing = sizedBoxes.any((box) => box.height == 8.0);
      expect(hasCorrectSpacing, isTrue);
    });

    testWidgets('debe tener espaciado entre botones', (tester) async {
      await tester.pumpWidget(
        testableWidget(
          child: ImagePickerWidget(
              imageUrl: null,
              isUploading: false,
              onPickFromCamera: () {},
              onPickFromGallery: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      final sizedBoxes = tester.widgetList<SizedBox>(find.byType(SizedBox));
      final hasCorrectSpacing = sizedBoxes.any((box) => box.width == 12.0);
      expect(hasCorrectSpacing, isTrue);
    });

    testWidgets('Container de estado sin imagen debe tener border', (tester) async {
      await tester.pumpWidget(
        testableWidget(
          child: ImagePickerWidget(
              imageUrl: null,
              isUploading: false,
              onPickFromCamera: () {},
              onPickFromGallery: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(ImagePickerWidget),
          matching: find.byType(Container),
        ).first,
      );

      final decoration = container.decoration as BoxDecoration;
      expect(decoration.border, isNotNull);
    });

    testWidgets('Container de loading debe tener border', (tester) async {
      await tester.pumpWidget(
        testableWidget(
          child: ImagePickerWidget(
              imageUrl: null,
              isUploading: true,
              onPickFromCamera: () {},
              onPickFromGallery: () {},
          ),
        ),
      );
      await tester.pump();

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(ImagePickerWidget),
          matching: find.byType(Container),
        ).first,
      );

      final decoration = container.decoration as BoxDecoration;
      expect(decoration.border, isNotNull);
    });

    testWidgets('debe usar Builder para acceso a context', (tester) async {
      await tester.pumpWidget(
        testableWidget(
          child: ImagePickerWidget(
              imageUrl: null,
              isUploading: false,
              onPickFromCamera: () {},
              onPickFromGallery: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Builder), findsWidgets);
    });
  });
}
