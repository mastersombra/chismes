import 'dart:io';

import 'package:flutter_image_compress/flutter_image_compress.dart';

/// Llamada registrada a `FlutterImageCompress.compressAndGetFile`.
class CompressCall {
  final String path;
  final String targetPath;
  final int minWidth;
  final int minHeight;
  final int quality;
  final CompressFormat format;

  CompressCall(this.path, this.targetPath, this.minWidth, this.minHeight,
      this.quality, this.format);
}

/// Reemplaza el plugin nativo de compresión.
///
/// Por defecto escribe `outputBytes(call)` bytes en `targetPath` y retorna ese
/// archivo. Si `outputBytes` retorna null, simula que el plugin falló (null).
///
/// ```dart
/// final fake = FakeImageCompress.install();
/// addTearDown(fake.uninstall);
/// ```
class FakeImageCompress extends UnsupportedFlutterImageCompress {
  final List<CompressCall> calls = [];
  int? Function(CompressCall call) outputBytes = (_) => 100 * 1024;

  late final FlutterImageCompressPlatform _previous;

  static FakeImageCompress install() {
    final fake = FakeImageCompress();
    fake._previous = FlutterImageCompressPlatform.instance;
    FlutterImageCompressPlatform.instance = fake;
    return fake;
  }

  void uninstall() => FlutterImageCompressPlatform.instance = _previous;

  @override
  Future<XFile?> compressAndGetFile(
    String path,
    String targetPath, {
    int minWidth = 1920,
    int minHeight = 1080,
    int inSampleSize = 1,
    int quality = 95,
    int rotate = 0,
    bool autoCorrectionAngle = true,
    CompressFormat format = CompressFormat.jpeg,
    bool keepExif = false,
    int numberOfRetries = 5,
  }) async {
    final call =
        CompressCall(path, targetPath, minWidth, minHeight, quality, format);
    calls.add(call);
    final bytes = outputBytes(call);
    if (bytes == null) return null;
    await File(targetPath).writeAsBytes(List.filled(bytes, 0));
    return XFile(targetPath);
  }
}
