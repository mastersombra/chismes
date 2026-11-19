# Estado de Migración I18n: easy_localization → gen-l10n

**Fecha inicio:** 2026-11-09  
**Status:** 🚧 80% COMPLETADO - PAUSADO  
**Próxima sesión:** Completar Opción A

---

## ✅ Progreso Completado

### 1. Infraestructura Base (100%)
- ✅ `lib/l10n/app_es.arb` + `app_en.arb` generados (371 keys + 9 password strength)
- ✅ `l10n.yaml` configurado correctamente
- ✅ `pubspec.yaml` actualizado (flutter_localizations + intl)
- ✅ `flutter gen-l10n` ejecutándose correctamente
- ✅ Código generado en `lib/l10n/app_localizations*.dart`
- ✅ Extension `L10nContext` creada (`lib/core/l10n/l10n.dart`)

### 2. Scripts de Migración (100%)
- ✅ `scripts/json_to_arb.py` - Conversor JSON → ARB
- ✅ `scripts/migrate_tr_to_l10n.py` - Migrador automático
- ✅ `scripts/fix_imports.py` - Fixer de imports
- ✅ `scripts/fix_error_messages_calls.py` - Fixer ErrorMessages

### 3. Código Migrado (70%)
- ✅ 17 archivos principales migrados automáticamente
- ✅ 179 usos de `.tr()` → `context.l10n.xxx`
- ✅ 1 uso de `.tr(namedArgs:)` migrado
- ✅ Strings hardcoded arreglados (password_strength, submit_button)
- ✅ `main.dart` actualizado (sin EasyLocalization)
- ✅ `ErrorMessages` adaptado (con versión sin context para logs)
- ✅ 31 archivos con imports actualizados

### 4. Dependencias
- ✅ `easy_localization` removido de pubspec.yaml
- ✅ `flutter_localizations` agregado
- ✅ `intl` agregado
- ✅ `flutter: generate: true` habilitado

---

## ❌ Problemas Pendientes

### P1: Cambio de Idioma Manual (CRÍTICO)

**Archivos afectados:**
- `lib/core/widgets/language_selector.dart:15,24`
- `lib/features/profile/presentation/screens/profile_screen.dart:46,50`
- `lib/features/profile/presentation/widgets/settings_section.dart:385`

**Problema:**
```dart
// ❌ NO EXISTE en gen-l10n
context.locale
context.setLocale(Locale('es'))
```

**Solución requerida:**
Implementar cambio de idioma con Provider/Riverpod:

```dart
// 1. Crear LocaleProvider
class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('es');
  Locale get locale => _locale;

  void setLocale(Locale locale) {
    _locale = locale;
    notifyListeners();
    // Guardar en SharedPreferences
  }
}

// 2. Actualizar main.dart
class ChismesApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LocaleProvider(),
      child: Consumer<LocaleProvider>(
        builder: (context, localeProvider, _) {
          return MaterialApp(
            locale: localeProvider.locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            // ...
          );
        },
      ),
    );
  }
}

// 3. Usar en widgets
context.read<LocaleProvider>().setLocale(Locale('es'));
```

**Archivos a modificar:**
1. Crear `lib/core/providers/locale_provider.dart`
2. Actualizar `lib/main.dart`
3. Actualizar `lib/core/widgets/language_selector.dart`
4. Actualizar `lib/features/profile/presentation/widgets/settings_section.dart`
5. Actualizar `lib/features/profile/presentation/screens/profile_screen.dart`

---

### P2: Uso de `context` fuera de `build()`

**Archivo 1: `lib/features/gossip/presentation/widgets/gossip_text_fields.dart`**

**Problema:**
```dart
class GossipTextFields extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      TextFormField(
        labelText: context.l10n.gossipTextFieldsSubjectLabel,  // ❌ context en body
      ),
    ]);
  }
}
```

**Solución:**
Widget necesita recibir BuildContext o convertir a StatefulWidget. Más simple: pasar textos como parámetros.

---

**Archivo 2: `lib/features/profile/presentation/widgets/settings_section.dart`**

**Problema:** Método `_getPrivacyText()` usa `context` pero es llamado desde constructor de objeto.

**Solución:** Pasar BuildContext como parámetro o refactorizar.

---

### P3: Keys faltantes en ARB

Algunos widgets usan keys que no existen en ARB generado:

```dart
// ❌ Member not found:
context.l10n.gossipCardReportError
context.l10n.gossipCardSemanticLabel(subject, content)
context.l10n.locationChangeDialogTitle
context.l10n.cancel
context.l10n.confirm
// ... ~20 más
```

**Solución:** Verificar que `scripts/migrate_tr_to_l10n.py` convirtió correctamente las keys:
- `gossip.card.report_error` → `gossipCardReportError`
- Verificar en `lib/l10n/app_es.arb` que existan todas las keys

---

### P4: Validators sin BuildContext

**Archivo: `lib/core/validation/form_validators.dart`**
**Archivo: `lib/features/auth/domain/validators/auth_validator.dart`**

**Problema:**
```dart
static String? required(String? value, String fieldName) {
  if (value == null || value.isEmpty) {
    return AppLocalizations.select(fieldName);  // ❌ No context disponible
  }
}
```

**Solución:**
Estos validators son usados en UI donde SÍ hay context. Opciones:
1. Pasar BuildContext como parámetro
2. Retornar keys y traducir en el caller
3. Mantener versión en inglés para validators (más simple)

---

## 📋 Checklist de Próxima Sesión

### Fase 1: Cambio de Idioma (1 hora)
- [ ] Crear `LocaleProvider` con SharedPreferences
- [ ] Actualizar `main.dart` con Provider
- [ ] Actualizar `language_selector.dart`
- [ ] Actualizar `settings_section.dart`
- [ ] Actualizar `profile_screen.dart`
- [ ] Probar cambio de idioma manual

### Fase 2: Widgets con Context (30 min)
- [ ] Refactorizar `gossip_text_fields.dart`
- [ ] Refactorizar `settings_section.dart`

### Fase 3: Keys Faltantes (30 min)
- [ ] Verificar ARB vs código
- [ ] Agregar keys faltantes a ARB
- [ ] Regenerar: `flutter gen-l10n`

### Fase 4: Validators (30 min)
- [ ] Decidir estrategia (context vs keys vs inglés)
- [ ] Implementar en `form_validators.dart`
- [ ] Implementar en `auth_validator.dart`

### Fase 5: Testing (30 min)
- [ ] `flutter analyze` sin errores
- [ ] `flutter test` pasa
- [ ] Actualizar `test/helpers/test_translations_loader.dart`
- [ ] Probar app end-to-end

---

## 🔧 Comandos Útiles

```bash
# Regenerar localizaciones
flutter gen-l10n

# Verificar errores
flutter analyze | grep -E "(error|warning)"

# Buscar usos de old API
grep -r "\.tr()" lib/ --include="*.dart" | grep -v ".g.dart"
grep -r "setLocale\|context.locale" lib/ --include="*.dart"

# Tests
flutter test

# Ver archivo ARB
cat lib/l10n/app_es.arb | jq 'keys' | less
```

---

## 📁 Archivos Clave

### Configuración
- `l10n.yaml` - Configuración gen-l10n
- `pubspec.yaml` - Dependencias
- `lib/core/l10n/l10n.dart` - Extension L10nContext

### ARB Files
- `lib/l10n/app_es.arb` - Español (380 keys)
- `lib/l10n/app_en.arb` - Inglés (380 keys)

### Scripts
- `scripts/json_to_arb.py`
- `scripts/migrate_tr_to_l10n.py`
- `scripts/fix_imports.py`

### Problemáticos
- `lib/core/widgets/language_selector.dart`
- `lib/features/gossip/presentation/widgets/gossip_text_fields.dart`
- `lib/features/profile/presentation/widgets/settings_section.dart`
- `lib/core/validation/form_validators.dart`
- `lib/features/auth/domain/validators/auth_validator.dart`

---

## 📚 Referencias

- [Flutter gen-l10n](https://docs.flutter.dev/ui/accessibility-and-internationalization/internationalization)
- [Provider Package](https://pub.dev/packages/provider)
- [SharedPreferences](https://pub.dev/packages/shared_preferences)

---

## 🎯 Estimación Tiempo Restante

- **Mínimo:** 2 horas (solo lo crítico)
- **Completo:** 3 horas (con testing y refinamiento)
- **Con documentación:** 3.5 horas

---

## ⚠️ Notas Importantes

1. **No borrar `assets/translations/*.json`** hasta que todo funcione
2. **Mantener backup** de código actual antes de continuar
3. **Provider/Riverpod:** Proyecto ya usa GetIt, considerar si agregar Provider vale la pena
4. **Alternativa simple:** Hacer cambio de idioma solo al reiniciar app (sin Provider)

---

**Última actualización:** 2026-11-09 (Sesión con Claude Sonnet 4.5)
