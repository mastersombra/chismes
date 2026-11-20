import 'package:flutter/widgets.dart';
import 'package:injectable/injectable.dart';

/// País según la configuración regional del teléfono (`es_CO` → `CO`).
///
/// Respaldo del feed cuando el usuario no tiene ciudad (nunca publicó ni
/// activó el GPS): con el país se muestran los chismes de su país y las
/// tendencias. No requiere permisos ni red.
///
/// Usa el locale del SISTEMA, no el idioma elegido en la app: alguien en
/// Colombia con la app en inglés sigue siendo `CO`.
@lazySingleton
class DeviceRegion {
  /// Código ISO 3166-1 alfa-2 en mayúsculas, o `null` si el sistema no lo
  /// informa (p. ej. locale `es` sin país).
  String? get countryCode {
    for (final locale in WidgetsBinding.instance.platformDispatcher.locales) {
      final code = locale.countryCode;
      if (code != null && code.length == 2) return code.toUpperCase();
    }
    return null;
  }
}
