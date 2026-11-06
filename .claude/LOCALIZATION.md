# Guía de Internacionalización (i18n)

> Sistema de internacionalización con **easy_localization** para soporte multi-idioma en la app.

**Última actualización:** 2026-10-25  
**Idiomas soportados:** Español (es), Inglés (en)

---

## 🌍 ¿Cómo funciona?

### Detección automática del idioma

La app detecta automáticamente el idioma del dispositivo del usuario:

```dart
// En main.dart
startLocale: null, // null = detecta automáticamente
fallbackLocale: const Locale('es'), // Si no se detecta, usa español
saveLocale: true, // Guarda el idioma seleccionado por el usuario
```

**Opciones de detección:**

| Método | Descripción | Configuración |
|--------|-------------|---------------|
| **Automático** | Detecta del dispositivo | `startLocale: null` |
| **Manual forzado** | Siempre inicia en un idioma | `startLocale: Locale('es')` |
| **Guardado** | Recuerda la selección del usuario | `saveLocale: true` |

---

## 📁 Estructura de archivos

```
assets/
└── translations/
    ├── es.json   # Español
    └── en.json   # Inglés
```

### Formato de archivos de traducción (JSON)

```json
{
  "auth": {
    "login": {
      "title": "Iniciar Sesión",
      "email_hint": "Email"
    },
    "validation": {
      "email_required": "El email es requerido"
    }
  },
  "common": {
    "select": "Selecciona {field}",
    "min_length": "Debe tener al menos {count} caracteres"
  }
}
```

**Características:**
- ✅ Anidación jerárquica (categorías)
- ✅ Parámetros con `{variable}`
- ✅ Plurales automáticos
- ✅ Hot reload en desarrollo

---

## 💻 Uso en código

### 1. Textos simples

```dart
import 'package:chismes/core/localization/app_localizations.dart';

Text(AppLocalizations.loginTitle)
// ES: "Iniciar Sesión"
// EN: "Sign In"
```

### 2. Textos con parámetros

```dart
Text(AppLocalizations.select('un país'))
// ES: "Selecciona un país"
// EN: "Select a country"

Text(AppLocalizations.minLength(8))
// ES: "Debe tener al menos 8 caracteres"
// EN: "Must be at least 8 characters"
```

### 3. Acceso directo con `.tr()`

```dart
import 'package:easy_localization/easy_localization.dart';

Text('auth.login.title'.tr())
Text('common.select'.tr(namedArgs: {'field': 'país'}))
```

**Recomendación:** Usar `AppLocalizations` para type-safety.

---

## 🎨 Ejemplos de uso

### En pantallas

```dart
class LoginScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.loginTitle),
      ),
      body: Column(
        children: [
          Text(AppLocalizations.appTagline),
          EmailField(
            labelText: AppLocalizations.emailHint,
          ),
          ElevatedButton(
            onPressed: _signIn,
            child: Text(AppLocalizations.signInButton),
          ),
        ],
      ),
    );
  }
}
```

### En validadores

```dart
// Domain validator (auth_validator.dart)
static ValidationFailure? validateEmail(String? email) {
  if (email == null || email.isEmpty) {
    return ValidationFailure(
      code: ErrorCode.missingRequiredField,
      technicalMessage: AppLocalizations.emailRequired,
    );
  }
  // ...
}

// Form validator (form_validators.dart)
static String? required(String? value, String fieldName) {
  if (value == null || value.isEmpty) {
    return AppLocalizations.select(fieldName);
  }
  return null;
}
```

---

## 🔄 Cambiar idioma manualmente

### Opción 1: En la UI

```dart
ElevatedButton(
  onPressed: () {
    context.setLocale(const Locale('en'));
  },
  child: Text('English'),
),

ElevatedButton(
  onPressed: () {
    context.setLocale(const Locale('es'));
  },
  child: Text('Español'),
),
```

### Opción 2: Selector de idioma

```dart
DropdownButton<Locale>(
  value: context.locale,
  items: [
    DropdownMenuItem(
      value: const Locale('es'),
      child: Text('🇪🇸 Español'),
    ),
    DropdownMenuItem(
      value: const Locale('en'),
      child: Text('🇺🇸 English'),
    ),
  ],
  onChanged: (locale) {
    if (locale != null) {
      context.setLocale(locale);
    }
  },
)
```

### Opción 3: Leer idioma actual

```dart
final currentLocale = context.locale;
print(currentLocale.languageCode); // "es" o "en"

// Verificar si es español
if (context.locale.languageCode == 'es') {
  // Lógica específica para español
}
```

---

## ➕ Agregar nuevas traducciones

### 1. Agregar al JSON

**es.json:**
```json
{
  "profile": {
    "edit_title": "Editar Perfil",
    "save_button": "Guardar cambios"
  }
}
```

**en.json:**
```json
{
  "profile": {
    "edit_title": "Edit Profile",
    "save_button": "Save changes"
  }
}
```

### 2. Agregar a AppLocalizations

```dart
// lib/core/localization/app_localizations.dart

class AppLocalizations {
  // ...

  // =====================================================
  // PROFILE
  // =====================================================

  static String get profileEditTitle => 'profile.edit_title'.tr();
  static String get profileSaveButton => 'profile.save_button'.tr();
}
```

### 3. Usar en la app

```dart
Text(AppLocalizations.profileEditTitle)
ElevatedButton(
  onPressed: _save,
  child: Text(AppLocalizations.profileSaveButton),
)
```

---

## 🌐 Agregar nuevo idioma

### 1. Crear archivo JSON

```bash
touch assets/translations/pt.json  # Portugués
```

**pt.json:**
```json
{
  "app": {
    "name": "Chismes",
    "tagline": "Compartilhe histórias, descubra segredos"
  },
  "auth": {
    "login": {
      "title": "Entrar"
    }
  }
}
```

### 2. Agregar locale en main.dart

```dart
EasyLocalization(
  supportedLocales: const [
    Locale('es'), // Español
    Locale('en'), // Inglés
    Locale('pt'), // Portugués ← NUEVO
  ],
  fallbackLocale: const Locale('es'),
  // ...
)
```

### 3. Listo

La app detectará automáticamente si el dispositivo está en portugués.

---

## 📊 Estado actual

### Traducidos ✅

- Auth (login, signup, profile setup)
- Validaciones (email, password, username, display name, bio)
- Errores de autenticación
- Mensajes comunes (loading, error, success, etc.)

### Pendientes de traducir 📝

- Gossip (crear, editar, eliminar)
- Comments
- Reactions
- Search
- Notificaciones
- Perfil completo
- Settings

---

## 🔧 Mejores prácticas

### ✅ DO

```dart
// ✅ Usar AppLocalizations (type-safe)
Text(AppLocalizations.loginTitle)

// ✅ Parámetros con namedArgs
Text(AppLocalizations.select('país'))

// ✅ Organizar por categorías en JSON
"auth.login.title"
"auth.validation.email_required"
```

### ❌ DON'T

```dart
// ❌ Hardcodear strings
Text('Iniciar Sesión')

// ❌ Duplicar traducciones
"login_title": "Iniciar Sesión"
"signin_title": "Iniciar Sesión"  // Mismo texto

// ❌ Mezclar idiomas en el código
Text('Hola ' + user.name)  // Solo español
```

---

## 🐛 Troubleshooting

### Problema: Las traducciones no se cargan

**Solución:**
1. Verificar que los archivos JSON están en `assets/translations/`
2. Verificar `pubspec.yaml`:
   ```yaml
   flutter:
     assets:
       - assets/translations/
   ```
3. Ejecutar `flutter clean && flutter pub get`
4. Hot restart (no hot reload)

### Problema: Error "Key not found"

**Solución:**
```dart
// Verificar la ruta completa en JSON
'auth.login.title'.tr()  // Debe existir en el JSON

// Usar fallback
'auth.login.title'.tr(fallbackKey: 'Fallback Text')
```

### Problema: Parámetros no se reemplazan

**Solución:**
```dart
// ✅ CORRECTO
'common.select'.tr(namedArgs: {'field': 'país'})

// ❌ INCORRECTO
'common.select'.tr(args: ['país'])  // No funciona con {field}
```

---

## 📚 Recursos

- [easy_localization docs](https://pub.dev/packages/easy_localization)
- [Flutter i18n guide](https://docs.flutter.dev/ui/accessibility-and-internationalization/internationalization)
- Archivos de traducción: `assets/translations/`
- Helper class: `lib/core/localization/app_localizations.dart`

---

**FIN DEL DOCUMENTO**
