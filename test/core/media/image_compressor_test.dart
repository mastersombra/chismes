import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chismes/core/media/image_compressor.dart';

import '../../helpers/fake_image_compress.dart';

void main() {
  group('ImageCompressor', () {
    group('getFileSizeInKB', () {
      test('debe calcular correctamente el tamaño en KB', () async {
        // Crear archivo temporal de prueba
        final tempDir = Directory.systemTemp.createTempSync('image_test_');
        final testFile = File('${tempDir.path}/test.txt');

        // Escribir 2048 bytes (2 KB)
        final content = 'x' * 2048;
        await testFile.writeAsString(content);

        final sizeKB = await ImageCompressor.getFileSizeInKB(testFile);

        expect(sizeKB, closeTo(2.0, 0.1)); // ~2 KB

        // Limpiar
        await tempDir.delete(recursive: true);
      });

      test('debe manejar archivos pequeños (menos de 1 KB)', () async {
        final tempDir = Directory.systemTemp.createTempSync('image_test_');
        final testFile = File('${tempDir.path}/small.txt');

        // Escribir 512 bytes (0.5 KB)
        final content = 'x' * 512;
        await testFile.writeAsString(content);

        final sizeKB = await ImageCompressor.getFileSizeInKB(testFile);

        expect(sizeKB, closeTo(0.5, 0.1));
        expect(sizeKB, lessThan(1.0));

        await tempDir.delete(recursive: true);
      });

      test('debe manejar archivos grandes (varios MB)', () async {
        final tempDir = Directory.systemTemp.createTempSync('image_test_');
        final testFile = File('${tempDir.path}/large.txt');

        // Escribir 1 MB (1024 * 1024 bytes)
        final content = 'x' * (1024 * 1024);
        await testFile.writeAsString(content);

        final sizeKB = await ImageCompressor.getFileSizeInKB(testFile);

        expect(sizeKB, greaterThan(1000)); // Más de 1000 KB (1 MB)
        expect(sizeKB, closeTo(1024.0, 10)); // ~1024 KB

        await tempDir.delete(recursive: true);
      });

      test('debe retornar 0 para archivo vacío', () async {
        final tempDir = Directory.systemTemp.createTempSync('image_test_');
        final testFile = File('${tempDir.path}/empty.txt');

        await testFile.writeAsString('');

        final sizeKB = await ImageCompressor.getFileSizeInKB(testFile);

        expect(sizeKB, 0.0);

        await tempDir.delete(recursive: true);
      });

      test('debe calcular tamaño con precisión decimal', () async {
        final tempDir = Directory.systemTemp.createTempSync('image_test_');
        final testFile = File('${tempDir.path}/test.txt');

        // Escribir exactamente 1536 bytes (1.5 KB)
        final content = 'x' * 1536;
        await testFile.writeAsString(content);

        final sizeKB = await ImageCompressor.getFileSizeInKB(testFile);

        expect(sizeKB, closeTo(1.5, 0.1));

        await tempDir.delete(recursive: true);
      });
    });
    group('con plugin de compresión falso', () {
      late FakeImageCompress compress;
      late Directory dir;
      late File original;

      setUp(() {
        compress = FakeImageCompress.install();
        addTearDown(compress.uninstall);
        dir = Directory.systemTemp.createTempSync('image_compressor_test');
        addTearDown(() => dir.deleteSync(recursive: true));
        original = File('${dir.path}/foto.png')
          ..writeAsBytesSync(List.filled(3 * 1024 * 1024, 1));
      });

      test('compressAvatar comprime a JPEG 400x400 @80 en memoria', () async {
        // Arrange
        compress.outputBytes = (_) => 50 * 1024;

        // Act
        final bytes = await ImageCompressor.compressAvatar(original);

        // Assert
        final call = compress.calls.single;
        expect(call.path, original.absolute.path);
        expect(call.minWidth, 400);
        expect(call.minHeight, 400);
        expect(call.quality, 80);
        expect(call.format, CompressFormat.jpeg);
        expect(bytes, hasLength(50 * 1024));
      });

      test('compressAvatar retorna null si el plugin falla', () async {
        // Arrange
        compress.outputBytes = (_) => null;

        // Act & Assert
        expect(await ImageCompressor.compressAvatar(original), isNull);
      });

      test('compressGossipImage comprime a JPEG 800x800 @75 en _compressed.jpg',
          () async {
        final result = await ImageCompressor.compressGossipImage(original);

        final call = compress.calls.single;
        expect(call.path, original.absolute.path);
        expect(call.targetPath, '${dir.path}/foto_compressed.jpg');
        expect(call.minWidth, 800);
        expect(call.minHeight, 800);
        expect(call.quality, 75);
        expect(call.format, CompressFormat.jpeg);
        expect(result!.path, '${dir.path}/foto_compressed.jpg');
        expect(await ImageCompressor.getFileSizeInKB(result), 100);
      });

      test('compressGossipImage solo cambia la última extensión', () async {
        final file = File('${dir.path}/mi.foto.2024.jpeg')
          ..writeAsBytesSync([1]);

        await ImageCompressor.compressGossipImage(file);

        expect(compress.calls.single.targetPath,
            '${dir.path}/mi.foto.2024_compressed.jpg');
      });

      // Regresión: con lastIndexOf('.') sin acotar al nombre, un archivo sin
      // extensión lanzaba RangeError y un punto en la carpeta cortaba la ruta.
      test('compressGossipImage agrega el sufijo si el archivo no tiene extensión',
          () async {
        final file = File('${dir.path}/image_picker_ABC')..writeAsBytesSync([1]);

        final result = await ImageCompressor.compressGossipImage(file);

        expect(compress.calls.single.targetPath,
            '${dir.path}/image_picker_ABC_compressed.jpg');
        expect(result!.path, '${dir.path}/image_picker_ABC_compressed.jpg');
      });

      test('no corta la ruta en un punto de la carpeta', () async {
        final sub = Directory('${dir.path}/cache.v2')..createSync();
        final file = File('${sub.path}/image')..writeAsBytesSync([1]);

        await ImageCompressor.compressGossipImage(file);
        await ImageCompressor.generateThumbnail(file);

        expect(compress.calls.map((c) => c.targetPath), [
          '${sub.path}/image_compressed.jpg',
          '${sub.path}/image_thumb.jpg',
        ]);
      });

      test('trata un archivo oculto (.foto) como sin extensión', () async {
        final file = File('${dir.path}/.foto')..writeAsBytesSync([1]);

        await ImageCompressor.generateThumbnail(file);

        expect(compress.calls.single.targetPath, '${dir.path}/.foto_thumb.jpg');
      });

      test('compressGossipImage retorna null si el plugin falla', () async {
        compress.outputBytes = (_) => null;

        expect(await ImageCompressor.compressGossipImage(original), isNull);
      });

      test('generateThumbnail genera JPEG 200x200 @70 en _thumb.jpg', () async {
        compress.outputBytes = (_) => 30 * 1024;

        final result = await ImageCompressor.generateThumbnail(original);

        final call = compress.calls.single;
        expect(call.path, original.absolute.path);
        expect(call.targetPath, '${dir.path}/foto_thumb.jpg');
        expect(call.minWidth, 200);
        expect(call.minHeight, 200);
        expect(call.quality, 70);
        expect(call.format, CompressFormat.jpeg);
        expect(result!.path, '${dir.path}/foto_thumb.jpg');
        expect(await ImageCompressor.getFileSizeInKB(result), 30);
      });

      test('generateThumbnail retorna null si el plugin falla', () async {
        compress.outputBytes = (_) => null;

        expect(await ImageCompressor.generateThumbnail(original), isNull);
      });
    });
  });
}
