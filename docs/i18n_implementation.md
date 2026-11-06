# Implementación de Internacionalización (i18n)

**Fecha:** 2026-10-25  
**Sistema:** easy_localization v3.0.7  
**Idiomas:** Español (es), Inglés (en)

---

## 📋 Resumen de Cambios

### ✅ Implementado

1. **Dependencia agregada:** `easy_localization: ^3.0.7`
2. **Archivos de traducción:**
   - `assets/translations/es.json` (Español)
   - `assets/translations/en.json` (Inglés)
3. **Helper class:** `lib/core/localization/app_localizations.dart`
4. **Detector de idioma:** `lib/core/localization/locale_detector.dart`
5. **Inicialización:** `main.dart` configurado con EasyLocalization
6. **Validadores traducidos:**
   - `auth_validator.dart` (Domain)
   - `form_validators.dart` (UI)
7. **UI traducida:** `login_screen.dart` como ejemplo
8. **Documentación:** `.claude/LOCALIZATION.md`

---

## 🌍 Detección de Idioma

### Automática (Recomendado)

El sistema detecta automáticamente el idioma del dispositivo:

```dart
// main.dart
EasyLocalization(
  supportedLocales: const [Locale('es'), Locale('en')],
  fallbackLocale: const Locale('es'),
  startLocale: null, // ← null = detección automática
  saveLocale: true,  // ← Guarda la preferencia del usuario
  // ...
)
```

**Flujo:**

1. **Primera ejecución:**
   - Lee idioma del dispositivo (Android Settings o iOS Settings)
   - Si el idioma es soportado (es/en) → usa ese idioma
   - Si no es soportado → usa `fallbackLocale` (español)

2. **Ejecuciones posteriores:**
   - Si el usuario cambió el idioma manualmente → usa el guardado
   - Si no → sigue usando el del dispositivo

### Manual

El usuario puede cambiar el idioma en cualquier momento:

```dart
// Cambiar a inglés
context.setLocale(const Locale('en'));

// Cambiar a español
context.setLocale(const Locale('es'));
```

El idioma seleccionado se guarda automáticamente (`saveLocale: true`).

### Obtener idioma actual

```dart
import 'package:easy_localization/easy_localization.dart';

// En cualquier widget con BuildContext
final currentLocale = context.locale;
print(currentLocale.languageCode); // "es" o "en"

// Verificar idioma
if (context.locale.languageCode == 'es') {
  // Español
} else {
  // Inglés
}
```

---

## 🔧 Cómo funciona el sistema

### 1. Archivos JSON

Las traducciones se almacenan en archivos JSON jerárquicos:

**Estructura:**
```
auth.validation.email_required
  │     │            │
  │     │            └─ Clave específica
  │     └─ Subcategoría
  └─ Categoría principal
```

**Ejemplo:**
```json
{
  "auth": {
    "validation": {
      "email_required": "El email es requerido",
      "password_needs_uppercase": "La contraseña debe contener al menos una letra mayúscula"
    }
  }
}
```

### 2. Helper Class (Type-Safe)

En lugar de usar strings directamente, usamos `AppLocalizations`:

```dart
// ❌ MAL: Propenso a errores tipográficos
Text('auth.validation.email_required'.tr())

// ✅ BIEN: Type-safe, autocompletado IDE
Text(AppLocalizations.emailRequired)
```

**Ventajas:**
- ✅ Autocompletado en IDE
- ✅ Errores en compile-time (no runtime)
- ✅ Fácil refactorización
- ✅ Code navigation

### 3. Validadores

Los validadores ahora retornan mensajes traducidos:

**Antes (hardcoded):**
```dart
return const ValidationFailure(
  code: ErrorCode.weakPassword,
  technicalMessage: 'Password must contain at least one uppercase letter',
);
```

**Ahora (traducido):**
```dart
return ValidationFailure(
  code: ErrorCode.weakPassword,
  technicalMessage: AppLocalizations.passwordNeedsUppercase,
  // ↑ Se traduce automáticamente según el idioma activo
);
```

---

## 🎯 Mensajes específicos corregidos

### Problema original

```dart
// auth_validator.dart - línea 101
technicalMessage: 'Password must contain at least one uppercase letter'
```

Este mensaje aparecía en inglés cuando el usuario registraba una cuenta.

### Solución

```dart
// Ahora usa traducciones
technicalMessage: AppLocalizations.passwordNeedsUppercase
```

**Español:**
> "La contraseña debe contener al menos una letra mayúscula"

**Inglés:**
> "Password must contain at least one uppercase letter"

---

## 📦 Traducciones incluidas

### Auth - Login
- ✅ Título de pantalla
- ✅ Placeholder de email
- ✅ Placeholder de password
- ✅ Botón de login
- ✅ Texto "O continúa con"
- ✅ "¿No tienes cuenta? Regístrate"

### Auth - Validaciones
- ✅ Email requerido / inválido / muy largo
- ✅ Password requerido / muy corto / muy largo
- ✅ Password necesita minúscula / **mayúscula** / número / especial
- ✅ Username requerido / muy corto / muy largo / caracteres inválidos
- ✅ Display name requerido / vacío / muy largo
- ✅ Bio muy larga

### Common
- ✅ "Selecciona {campo}"
- ✅ "Debe tener al menos {n} caracteres"
- ✅ "No puede exceder {n} caracteres"
- ✅ Loading, Error, Success, Cancel, Confirm, etc.

---

## 🚀 Próximos pasos

### Pendientes de traducir

Las siguientes áreas necesitan traducción:

1. **Gossip feature**
   - Crear gossip (título, contenido, botones)
   - Editar gossip
   - Eliminar gossip
   - Estados (draft, published, hidden)

2. **Home**
   - Feed
   - Filtros
   - Ordenamiento

3. **Search**
   - Placeholder
   - Resultados
   - Sin resultados

4. **Profile**
   - Información del usuario
   - Editar perfil
   - Configuraciones

5. **Comments & Reactions**
   - Agregar comentario
   - Reacciones
   - Mensajes de error

6. **Notifications**
   - Tipos de notificaciones
   - Mensajes

### Cómo agregar nuevas traducciones

1. **Agregar al JSON:**
   ```json
   // es.json
   "gossip": {
     "create": {
       "title": "Crear Chisme",
       "subject_hint": "Título del chisme"
     }
   }

   // en.json
   "gossip": {
     "create": {
       "title": "Create Gossip",
       "subject_hint": "Gossip title"
     }
   }
   ```

2. **Agregar a AppLocalizations:**
   ```dart
   class AppLocalizations {
     static String get gossipCreateTitle => 'gossip.create.title'.tr();
     static String get gossipSubjectHint => 'gossip.create.subject_hint'.tr();
   }
   ```

3. **Usar en UI:**
   ```dart
   Text(AppLocalizations.gossipCreateTitle)
   TextField(hintText: AppLocalizations.gossipSubjectHint)
   ```

---

## 🔍 Testing

### Probar manualmente

1. **Cambiar idioma del dispositivo:**
   - iOS: Settings → General → Language & Region
   - Android: Settings → System → Languages & input

2. **Reiniciar la app** (no hot reload, necesita restart completo)

3. **Verificar traducciones:**
   - Login screen debe mostrar textos en el idioma seleccionado
   - Validaciones deben estar traducidas

### Probar cambio manual

```dart
// Agregar botón temporal en LoginScreen
IconButton(
  icon: Icon(Icons.language),
  onPressed: () {
    // Cambiar entre español e inglés
    final currentLang = context.locale.languageCode;
    context.setLocale(
      currentLang == 'es' ? const Locale('en') : const Locale('es'),
    );
  },
)
```

---

## 📊 Estadísticas

### Archivos modificados: 9

**Nuevos:**
- `assets/translations/es.json`
- `assets/translations/en.json`
- `lib/core/localization/app_localizations.dart`
- `lib/core/localization/locale_detector.dart`
- `.claude/LOCALIZATION.md`
- `docs/i18n_implementation.md`

**Modificados:**
- `pubspec.yaml` (dependencia + assets)
- `lib/main.dart` (inicialización)
- `lib/features/auth/domain/validators/auth_validator.dart`
- `lib/core/validation/form_validators.dart`
- `lib/features/auth/presentation/screens/login_screen.dart`

### Líneas de código: ~600

- Traducciones: ~200 líneas (JSON)
- Helper classes: ~150 líneas
- Documentación: ~250 líneas

### Traducciones totales: ~60 strings

- Auth: ~30 strings
- Common: ~15 strings
- Pendientes: ~200+ strings (estimado)

---

## 🎓 Recursos adicionales

- **Documentación:** `.claude/LOCALIZATION.md`
- **easy_localization:** https://pub.dev/packages/easy_localization
- **Flutter i18n:** https://docs.flutter.dev/ui/accessibility-and-internationalization/internationalization

---

**FIN DEL DOCUMENTO**
