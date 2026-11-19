# Migración I18n: easy_localization → gen-l10n

**Fecha:** 2026-11-09  
**Status:** ✅ COMPLETADO

---

## 📋 Resumen

Migración completa del sistema de internacionalización de `easy_localization` (third-party) a `gen-l10n` (oficial de Flutter).

### Antes (easy_localization)
```dart
Text('gossip.add_screen.title'.tr())
```

### Después (gen-l10n)
```dart
Text(context.l10n.gossipAddScreenTitle)
```

---

## ✅ Cambios Realizados

### 1. Estructura de Archivos

**Creados:**
- `lib/l10n/app_es.arb` - Traducciones español (371 keys)
- `lib/l10n/app_en.arb` - Traducciones inglés (371 keys)
- `lib/core/l10n/l10n.dart` - Extension para acceso limpio
- `l10n.yaml` - Configuración gen-l10n
- `scripts/json_to_arb.py` - Conversor JSON → ARB
- `scripts/migrate_tr_to_l10n.py` - Migrador automático de código

**Eliminados:**
- `assets/translations/*.json` - Ya no necesarios
- `lib/core/localization/app_localizations.dart` - Wrapper manual
- Dependencia `easy_localization` de pubspec.yaml

### 2. Código Migrado

**Stats:**
- ✅ 17 archivos modificados
- ✅ 179 usos de `.tr()` migrados
- ✅ 1 uso de `.tr(namedArgs:)` migrado
- ✅ 2 strings hardcoded arreglados:
  - `password_strength_indicator.dart`
  - `submit_button.dart`

**Archivos principales:**
- `lib/main.dart` - Configuración de MaterialApp
- `lib/core/error/error_messages.dart` - Manejo especial para logs vs UI
- Todos los screens/widgets con traducciones

### 3. Configuración

**pubspec.yaml:**
```yaml
dependencies:
  flutter_localizations:
    sdk: flutter
  intl: any

flutter:
  generate: true  # ✅ Habilita gen-l10n
```

**l10n.yaml:**
```yaml
arb-dir: lib/l10n
template-arb-file: app_es.arb
output-localization-file: app_localizations.dart
output-class: AppLocalizations
```

---

## 🎯 Ventajas de gen-l10n

### Type-Safety Real
```dart
// ✅ Error en compile-time si la key no existe
context.l10n.emailRequired

// ❌ Error en runtime con easy_localization
'email.required'.tr()  // typo en key
```

### Parámetros Tipados
```dart
// gen-l10n genera:
String homePopularInCity(String city)

// Uso:
context.l10n.homePopularInCity(cityName)

// vs easy_localization:
'home.popular.in_city'.tr(namedArgs: {'city': cityName})
```

### Plurales ICU (futuro)
```arb
{
  "gossipCount": "{count, plural, =0{No hay chismes} =1{1 chisme} other{{count} chismes}}",
  "@gossipCount": {
    "placeholders": {
      "count": {"type": "int"}
    }
  }
}
```

### Sin Dependencias Third-Party
- `flutter_localizations` es oficial de Flutter
- No depende de paquetes externos que puedan deprecarse
- Mejor performance (sin overhead de easy_localization)

---

## 📚 Uso

### Extension L10nContext

```dart
import 'package:chismes/core/l10n/l10n.dart';

// En cualquier Widget con BuildContext:
Text(context.l10n.emailRequired)
Text(context.l10n.homePopularInCity(cityName))
```

### ErrorMessages

**Para UI (con traducción):**
```dart
ErrorMessages.getMessage(context, error.code)
ErrorMessages.getTitle(context, error.code)
```

**Para logs/debugging (sin traducción):**
```dart
ErrorMessages.getMessageEnglish(error.code)
_logger.e('Error: ${ErrorMessages.getMessageEnglish(failure.code)}');
```

---

## 🔄 Workflow de Traducciones

### Agregar Nueva Traducción

**1. Editar ARB files:**
```bash
# lib/l10n/app_es.arb
{
  "myNewKey": "Mi texto en español"
}

# lib/l10n/app_en.arb
{
  "myNewKey": "My text in English"
}
```

**2. Regenerar código:**
```bash
flutter gen-l10n
```

**3. Usar en código:**
```dart
Text(context.l10n.myNewKey)
```

### Con Placeholders

**ARB:**
```json
{
  "welcomeUser": "Bienvenido, {userName}",
  "@welcomeUser": {
    "description": "Welcome message with user name",
    "placeholders": {
      "userName": {
        "type": "String",
        "example": "Juan"
      }
    }
  }
}
```

**Uso:**
```dart
Text(context.l10n.welcomeUser('Carlos'))
```

---

## ⚠️ Pendientes

### 1. Tests

Algunos tests aún referencian `EasyLocalization`:
```
warning • override_on_non_overriding_method • test/helpers/test_translations_loader.dart:976
```

**Acción:** Actualizar helpers de tests para usar gen-l10n

### 2. Cambio de Idioma en Runtime

Actualmente usa el idioma del sistema. Para soportar cambio manual:

**Opción A: Provider con ValueNotifier**
```dart
class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('es');
  Locale get locale => _locale;

  void setLocale(Locale locale) {
    _locale = locale;
    notifyListeners();
  }
}

// En MaterialApp:
MaterialApp(
  locale: localeProvider.locale,
  // ...
)
```

**Opción B: SharedPreferences manual**
```dart
// Guardar
await prefs.setString('locale', 'es');

// Cargar en main
final savedLocale = prefs.getString('locale');
```

### 3. Lint Rules

Agregar regla personalizada para prevenir strings hardcoded:

**analysis_options.yaml:**
```yaml
linter:
  rules:
    prefer_const_literals_to_create_immutables: true
    # TODO: Custom lint para detectar Text('hardcoded')
```

### 4. CI/CD Validation

**GitHub Actions workflow:**
```yaml
- name: Validate translations
  run: |
    # Verificar que todos los ARB tienen las mismas keys
    python3 scripts/validate_arb_keys.py
    
    # Generar localizations
    flutter gen-l10n
    
    # Verificar que no hay referencias a easy_localization
    ! grep -r "easy_localization" lib/
```

---

## 📊 Métricas

### Antes
- Dependencia: `easy_localization 3.0.7`
- Archivos: `assets/translations/*.json`
- Type-safety: ❌ Runtime only
- Keys: 371
- Strings hardcoded: 2

### Después
- Dependencia: `flutter_localizations` (oficial)
- Archivos: `lib/l10n/*.arb`
- Type-safety: ✅ Compile-time
- Keys: 371 (+9 para password strength)
- Strings hardcoded: 0

---

## 🔗 Referencias

- [Flutter Internacionalization](https://docs.flutter.dev/ui/accessibility-and-internationalization/internationalization)
- [ARB Format Specification](https://github.com/google/app-resource-bundle/wiki/ApplicationResourceBundleSpecification)
- [ICU Message Format](https://unicode-org.github.io/icu/userguide/format_parse/messages/)

---

## ✅ Checklist de Verificación

- [x] Convertir JSON → ARB
- [x] Configurar l10n.yaml y pubspec.yaml
- [x] Generar código con flutter gen-l10n
- [x] Crear extension L10nContext
- [x] Migrar todos los .tr() → context.l10n
- [x] Arreglar strings hardcoded
- [x] Actualizar main.dart
- [x] Eliminar easy_localization
- [x] Eliminar wrapper manual AppLocalizations
- [x] flutter analyze sin errores
- [ ] Actualizar tests
- [ ] Documentar cambio de idioma en runtime
- [ ] CI/CD validation

---

**Migración completada por:** Claude Sonnet 4.5  
**Revisado por:** [Pendiente]
