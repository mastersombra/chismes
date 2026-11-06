# Sistema de Internacionalización (i18n) - Chismes App

**Fecha:** 2026-11-03  
**Versión:** 1.0  
**Librería:** EasyLocalization 3.0.7

---

## 📚 **Tabla de Contenidos**

1. [Arquitectura](#arquitectura)
2. [Idiomas Soportados](#idiomas-soportados)
3. [Dónde Elige el Usuario](#dónde-elige-el-usuario)
4. [Dónde se Guarda la Preferencia](#dónde-se-guarda-la-preferencia)
5. [Persistencia entre Sesiones](#persistencia-entre-sesiones)
6. [Cómo Agregar Traducciones](#cómo-agregar-traducciones)
7. [Cómo Agregar un Nuevo Idioma](#cómo-agregar-un-nuevo-idioma)
8. [Testing](#testing)

---

## 🏗️ **Arquitectura**

### **EasyLocalization + SharedPreferences**

```
┌─────────────────────────────────────────┐
│           main.dart                     │
│  EasyLocalization(                      │
│    saveLocale: true ← Guarda automático│
│  )                                      │
└────────────┬────────────────────────────┘
             │
             ├─ Lee/Guarda en SharedPreferences
             │  Key: "locale"
             │  Value: "es" o "en"
             │
             ├─ Carga traducciones desde:
             │  assets/translations/es.json
             │  assets/translations/en.json
             │
             └─ Provee a toda la app:
                context.locale → Locale actual
                context.setLocale(locale) → Cambiar idioma
                'key'.tr() → Traducir texto
```

---

## 🌍 **Idiomas Soportados**

| Idioma | Código | Bandera | Archivo |
|--------|--------|---------|---------|
| Español | `es` | 🇪🇸 | `assets/translations/es.json` |
| English | `en` | 🇺🇸 | `assets/translations/en.json` |

**Idioma por defecto:** Español (`es`)

---

## 🎯 **Dónde Elige el Usuario**

### **LanguageSelector Widget**

Ubicado en el **AppBar** de 3 pantallas:

1. **LoginScreen** (pantalla de inicio de sesión)
2. **SignupScreen** (pantalla de registro)
3. **ResetPasswordScreen** (pantalla de reset de contraseña)

**Visualmente:**

```
┌─────────────────────────────┐
│  Chismes            🇪🇸  ▼  │ ← LanguageSelector
│                              │
│  ┌──────────────────────┐   │
│  │ 🇪🇸 Español      ✓   │   │
│  │ 🇺🇸 English          │   │
│  └──────────────────────┘   │
│                              │
│  Email: _______________     │
│  Password: ___________      │
└─────────────────────────────┘
```

### **Código:**

```dart
// En LoginScreen, SignupScreen, ResetPasswordScreen
appBar: AppBar(
  actions: const [
    LanguageSelector(), // ← Widget de selección
  ],
),
```

---

## 💾 **Dónde se Guarda la Preferencia**

### **SharedPreferences (Storage Local)**

EasyLocalization guarda automáticamente cuando el usuario cambia el idioma.

**Ubicación en el dispositivo:**

| Plataforma | Ubicación |
|------------|-----------|
| **iOS** | `~/Library/Preferences/[bundle_id].plist` |
| **Android** | `/data/data/[package_name]/shared_prefs/[package_name]_preferences.xml` |
| **Web** | `localStorage` |

**Key-Value:**

```
Key:   "locale"
Value: "es" (español) o "en" (inglés)
```

### **Configuración en `main.dart`:**

```dart
EasyLocalization(
  supportedLocales: const [
    Locale('es'), // Español
    Locale('en'), // Inglés
  ],
  path: 'assets/translations',
  fallbackLocale: const Locale('es'), // Si no hay guardado, usa español
  saveLocale: true, // ← Guarda automáticamente en SharedPreferences
  useOnlyLangCode: true, // Usa 'es' en lugar de 'es_ES'
  child: const ChismesApp(),
)
```

**`saveLocale: true`** hace que:
- Al cambiar idioma con `context.setLocale()`, se guarde automáticamente
- Al abrir la app, se restaure el idioma guardado
- Persista entre sesiones (cerrar/abrir app, reiniciar celular)

---

## 🔄 **Persistencia entre Sesiones**

### **Flujo Completo:**

#### **Primera Vez (Sin Preferencia Guardada)**

```
Usuario abre app por primera vez
  ↓
EasyLocalization.ensureInitialized()
  ↓
Verifica SharedPreferences["locale"]
  ↓
No encuentra valor guardado
  ↓
Usa fallbackLocale: Locale('es') ← Español por defecto
  ↓
App inicia en ESPAÑOL ✅
```

---

#### **Usuario Cambia a Inglés**

```
Usuario toca 🇪🇸 en LanguageSelector
  ↓
Aparece menú: 🇪🇸 Español, 🇺🇸 English
  ↓
Usuario selecciona 🇺🇸 English
  ↓
onSelected: (locale) => context.setLocale(Locale('en'))
  ↓
EasyLocalization:
  ├─ Cambia idioma de toda la app a inglés
  └─ Guarda "en" en SharedPreferences["locale"] ✅
  ↓
App se actualiza en INGLÉS (sin reiniciar) ✅
```

---

#### **Usuario Cierra y Reabre App**

```
Usuario cierra app (kill app o reinicia celular)
  ↓
[Preferencia persiste en SharedPreferences]
  ↓
Usuario abre app nuevamente
  ↓
EasyLocalization.ensureInitialized()
  ↓
Verifica SharedPreferences["locale"]
  ↓
Encuentra "en" guardado ✅
  ↓
Usa Locale('en') ← Inglés
  ↓
App inicia en INGLÉS (respeta preferencia del usuario) ✅
```

---

### **¿Cuándo se Pierde la Preferencia?**

Solo en estos casos:
- Usuario desinstala y reinstala la app
- Usuario limpia datos de la app manualmente (Settings > Apps > Chismes > Clear Data)
- Usuario limpia cache del navegador (Web)

**En todos los demás casos, la preferencia persiste.**

---

## 📝 **Cómo Agregar Traducciones**

### **1. Agregar nueva clave en los archivos JSON**

**`assets/translations/es.json`:**

```json
{
  "home": {
    "welcome": "¡Bienvenido a Chismes!",
    "new_gossip": "Nuevo chisme"
  }
}
```

**`assets/translations/en.json`:**

```json
{
  "home": {
    "welcome": "Welcome to Chismes!",
    "new_gossip": "New gossip"
  }
}
```

### **2. Usar en el código**

```dart
import 'package:easy_localization/easy_localization.dart';

// Opción 1: .tr()
Text('home.welcome'.tr())

// Opción 2: tr() function
Text(tr('home.welcome'))

// Con parámetros:
// JSON: "greeting": "Hola, {name}"
Text('greeting'.tr(namedArgs: {'name': 'Juan'}))

// Plural:
// JSON: "items": {
//   "zero": "Sin elementos",
//   "one": "1 elemento",
//   "other": "{count} elementos"
// }
Text('items'.plural(count))
```

### **3. Hot Reload**

```bash
# Después de modificar los JSON, hacer hot reload:
flutter run
# Presionar 'r' para hot reload
```

**No necesitas regenerar código.**

---

## 🌍 **Cómo Agregar un Nuevo Idioma**

### **Ejemplo: Agregar Portugués**

#### **1. Crear archivo de traducción**

**`assets/translations/pt.json`:**

```json
{
  "app": {
    "name": "Chismes",
    "tagline": "Compartilhe histórias, descubra segredos"
  },
  "auth": {
    "login": {
      "title": "Entrar",
      "email_hint": "E-mail",
      "password_hint": "Senha",
      "sign_in_button": "Entrar"
    }
  }
}
```

#### **2. Actualizar `main.dart`**

```dart
EasyLocalization(
  supportedLocales: const [
    Locale('es'), // Español
    Locale('en'), // Inglés
    Locale('pt'), // Portugués ← Agregar
  ],
  path: 'assets/translations',
  fallbackLocale: const Locale('es'),
  saveLocale: true,
  useOnlyLangCode: true,
  child: const ChismesApp(),
)
```

#### **3. Actualizar `LanguageSelector`**

```dart
// lib/core/widgets/language_selector.dart
itemBuilder: (context) => [
  _buildMenuItem(
    locale: const Locale('es'),
    isSelected: currentLocale.languageCode == 'es',
  ),
  _buildMenuItem(
    locale: const Locale('en'),
    isSelected: currentLocale.languageCode == 'en',
  ),
  _buildMenuItem(
    locale: const Locale('pt'), // ← Agregar
    isSelected: currentLocale.languageCode == 'pt',
  ),
],
```

#### **4. Actualizar `LocaleDetector`**

```dart
// lib/core/localization/locale_detector.dart

static String _getDisplayName(String languageCode) {
  switch (languageCode) {
    case 'es': return 'Spanish';
    case 'en': return 'English';
    case 'pt': return 'Portuguese'; // ← Agregar
    default: return 'Unknown';
  }
}

static String _getNativeName(String languageCode) {
  switch (languageCode) {
    case 'es': return 'Español';
    case 'en': return 'English';
    case 'pt': return 'Português'; // ← Agregar
    default: return 'Unknown';
  }
}

static String _getEmoji(String languageCode) {
  switch (languageCode) {
    case 'es': return '🇪🇸';
    case 'en': return '🇺🇸';
    case 'pt': return '🇧🇷'; // ← Agregar
    default: return '🌐';
  }
}
```

#### **5. Registrar en `pubspec.yaml`**

```yaml
flutter:
  assets:
    - assets/translations/es.json
    - assets/translations/en.json
    - assets/translations/pt.json  # ← Agregar
```

#### **6. Hot Reload**

```bash
flutter run
# Presionar 'R' para hot restart
```

---

## 🧪 **Testing**

### **1. Probar Cambio de Idioma**

```bash
flutter run
```

1. Abre la app
2. Ve a LoginScreen
3. Toca el selector de idioma (🇪🇸)
4. Selecciona 🇺🇸 English
5. Verifica que toda la UI cambie a inglés
6. Cierra la app completamente (kill app)
7. Abre la app nuevamente
8. Verifica que siga en inglés ✅

---

### **2. Probar Idioma por Defecto**

```bash
# Desinstalar app (para limpiar SharedPreferences)
flutter clean
flutter run
```

1. App debería iniciar en español (fallbackLocale)
2. Sin necesidad de seleccionar idioma

---

### **3. Probar Traducciones**

```dart
// En cualquier widget:
print(context.locale); // Locale actual
print('auth.login.title'.tr()); // Ver traducción

// Cambiar idioma programáticamente (solo para testing):
context.setLocale(Locale('en'));
```

---

### **4. Verificar Claves Faltantes**

Si una clave no existe en el JSON:

```dart
// Si "missing_key" no existe:
'missing_key'.tr() 
// Devuelve: "missing_key" (la clave misma, sin error)
```

**Revisa que todas las claves existan en ambos archivos.**

---

## 📊 **Resumen del Flujo**

```
Usuario abre app
  ↓
EasyLocalization lee SharedPreferences["locale"]
  ↓
Si existe → Usa ese idioma
Si no existe → Usa fallbackLocale (español)
  ↓
Usuario cambia idioma con LanguageSelector
  ↓
context.setLocale(new_locale)
  ↓
EasyLocalization:
  ├─ Actualiza toda la UI
  └─ Guarda en SharedPreferences["locale"]
  ↓
Usuario cierra app
  ↓
[Preferencia persiste en storage]
  ↓
Usuario abre app nuevamente
  ↓
EasyLocalization restaura idioma guardado ✅
```

---

## ✅ **Checklist de Implementación**

- [x] EasyLocalization configurado en `main.dart`
- [x] `saveLocale: true` habilitado
- [x] Traducciones en `assets/translations/es.json` y `en.json`
- [x] LanguageSelector en LoginScreen, SignupScreen, ResetPasswordScreen
- [x] LocaleDetector con información de idiomas
- [x] BottomNavigationBar con traducciones
- [x] Persistencia entre sesiones funciona
- [x] Hot reload funciona sin reiniciar app

---

## 🔗 **Referencias**

- [EasyLocalization Docs](https://pub.dev/packages/easy_localization)
- [Flutter i18n Guide](https://docs.flutter.dev/ui/accessibility-and-internationalization/internationalization)
- [SharedPreferences](https://pub.dev/packages/shared_preferences)

---

**FIN DEL DOCUMENTO**
