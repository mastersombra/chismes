#!/usr/bin/env dart
// ignore_for_file: avoid_print
/// Script para generar test_translations_loader.dart desde los archivos JSON
///
/// Uso: dart tool/generate_test_translations.dart
library;

import 'dart:convert';
import 'dart:io';

Future<void> main() async {
  print('📦 Generando test_translations_loader.dart...\n');

  // Leer archivos JSON
  final esFile = File('assets/translations/es.json');
  final enFile = File('assets/translations/en.json');

  if (!await esFile.exists() || !await enFile.exists()) {
    print('❌ Error: No se encontraron los archivos de traducción');
    print('   Verifica que existan:');
    print('   - assets/translations/es.json');
    print('   - assets/translations/en.json');
    exit(1);
  }

  final esContent = await esFile.readAsString();
  final enContent = await enFile.readAsString();

  final esJson = json.decode(esContent);
  final enJson = json.decode(enContent);

  // Generar el archivo Dart
  final output = StringBuffer();
  output.writeln("// ignore_for_file: lines_longer_than_80_chars");
  output.writeln("// GENERADO AUTOMÁTICAMENTE - NO EDITAR MANUALMENTE");
  output.writeln("// Ejecuta: dart tool/generate_test_translations.dart");
  output.writeln('');
  output.writeln("import 'package:easy_localization/easy_localization.dart';");
  output.writeln("import 'dart:ui';");
  output.writeln('');
  output.writeln('/// AssetLoader personalizado para tests con todas las traducciones');
  output.writeln('///');
  output.writeln('/// NOTA: Este archivo se genera automáticamente desde los archivos JSON.');
  output.writeln('/// Para regenerarlo ejecuta: dart tool/generate_test_translations.dart');
  output.writeln('class TestTranslationsLoader extends AssetLoader {');
  output.writeln('  const TestTranslationsLoader();');
  output.writeln('');

  // Generar mapa español
  output.writeln('  static const Map<String, dynamic> _esTranslations = ');
  output.writeln(_formatMap(esJson, 2));
  output.writeln(';');
  output.writeln('');

  // Generar mapa inglés
  output.writeln('  static const Map<String, dynamic> _enTranslations = ');
  output.writeln(_formatMap(enJson, 2));
  output.writeln(';');
  output.writeln('');

  // Generar método load
  output.writeln('  @override');
  output.writeln('  Future<Map<String, dynamic>> load(String path, Locale locale) async {');
  output.writeln('    switch (locale.languageCode) {');
  output.writeln("      case 'en':");
  output.writeln('        return _enTranslations;');
  output.writeln("      case 'es':");
  output.writeln('      default:');
  output.writeln('        return _esTranslations;');
  output.writeln('    }');
  output.writeln('  }');
  output.writeln('}');

  // Escribir el archivo
  final outputFile = File('test/helpers/test_translations_loader.dart');
  await outputFile.writeAsString(output.toString());

  print('✅ Archivo generado exitosamente:');
  print('   test/helpers/test_translations_loader.dart');
  print('');
  print('📊 Estadísticas:');
  print('   - Claves ES: ${_countKeys(esJson)}');
  print('   - Claves EN: ${_countKeys(enJson)}');
}

String _formatMap(dynamic data, int indent) {
  final spaces = ' ' * indent;
  final spacesNext = ' ' * (indent + 2);

  if (data is Map) {
    final buffer = StringBuffer('{\n');
    final entries = data.entries.toList();

    for (var i = 0; i < entries.length; i++) {
      final entry = entries[i];
      buffer.write("$spacesNext'${entry.key}': ");
      buffer.write(_formatMap(entry.value, indent + 2));
      if (i < entries.length - 1) {
        buffer.write(',');
      }
      buffer.write('\n');
    }

    buffer.write('$spaces}');
    return buffer.toString();
  } else if (data is String) {
    // Escapar strings apropiadamente
    final escaped = data
        .replaceAll('\\', '\\\\')
        .replaceAll("'", "\\'")
        .replaceAll('\n', '\\n');
    return "'$escaped'";
  } else {
    return data.toString();
  }
}

int _countKeys(dynamic data, [int count = 0]) {
  if (data is Map) {
    for (var value in data.values) {
      count = _countKeys(value, count);
    }
    return count + data.length;
  }
  return count;
}
