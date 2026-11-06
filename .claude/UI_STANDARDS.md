# UI/UX Standards - Chismes App

> **Standards de UI/UX del proyecto.** Convenciones de diseño, espaciado, validación y widgets.

**Última actualización:** 2026-10-20

---

## 📋 Índice

1. [Portrait-Only App](#portrait-only-app-)
2. [Sistema de Espaciado (AppSpacing)](#sistema-de-espaciado-appspacing-)
3. [Validación de Formularios](#validación-de-formularios-)
4. [Sistema de Colores (AppColors)](#sistema-de-colores-appcolors)
5. [Sistema de Radios (AppRadius)](#sistema-de-radios-appradius)
6. [Widget Patterns](#widget-patterns)

---

## Portrait-Only App 📱

**La app está BLOQUEADA en modo portrait (vertical).**

### Por Qué

- App tipo feed social (Instagram/TikTok)
- Landscape desperdicia espacio en móviles
- Teclado cubre >50% de pantalla en landscape
- UX predecible y consistente
- Simplifica desarrollo

### Configuración

**Android:**
```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<activity
    android:name=".MainActivity"
    android:screenOrientation="portrait"
    android:configChanges="orientation|keyboardHidden|keyboard|screenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
    android:hardwareAccelerated="true"
    android:windowSoftInputMode="adjustResize">
</activity>
```

**iOS:**
```xml
<!-- ios/Runner/Info.plist -->
<key>UISupportedInterfaceOrientations</key>
<array>
    <string>UIInterfaceOrientationPortrait</string>
</array>

<key>UISupportedInterfaceOrientations~ipad</key>
<array>
    <string>UIInterfaceOrientationPortrait</string>
</array>
```

### Cuándo Cambiar

Solo habilitar landscape cuando:
- ✅ Se soporten tablets con diseño responsive dedicado
- ✅ Haya requerimiento de negocio específico
- ✅ Se diseñe UI específica para landscape

---

## Sistema de Espaciado (AppSpacing) ⭐

**NUNCA uses números mágicos para espaciado.** Siempre usa `AppSpacing`.

### Valores

**Archivo:** `lib/core/theme/app_spacing.dart`

```dart
class AppSpacing {
  // Escala base (múltiplos de 4)
  static const double xs = 4;    // 4px  - Muy pequeño
  static const double sm = 8;    // 8px  - Pequeño
  static const double md = 12;   // 12px - Mediano
  static const double lg = 16;   // 16px - Grande (base)
  static const double xl = 24;   // 24px - Extra grande
  static const double xxl = 32;  // 32px - Muy grande
  static const double xxxl = 48; // 48px - Enorme

  // Nombres semánticos (aliases)
  static const double horizontalContent = lg;   // 16px - Padding horizontal de contenido
  static const double verticalElements = md;    // 12px - Espacio entre elementos verticales
  static const double sectionGap = xl;          // 24px - Espacio entre secciones
}
```

### Uso Correcto

```dart
// ✅ CORRECTO
import '../../../../core/theme/app_spacing.dart';

// Padding
padding: const EdgeInsets.all(AppSpacing.lg)
padding: const EdgeInsets.symmetric(
  horizontal: AppSpacing.horizontalContent,
  vertical: AppSpacing.md,
)

// Spacing entre widgets
const SizedBox(height: AppSpacing.md)
const SizedBox(width: AppSpacing.sm)

// Gap en Flex widgets
Row(
  children: [
    Text('Texto 1'),
    const SizedBox(width: AppSpacing.sm),
    Text('Texto 2'),
  ],
)

// Margin
margin: const EdgeInsets.only(bottom: AppSpacing.xl)

// GridView
GridView.count(
  crossAxisCount: 2,
  crossAxisSpacing: AppSpacing.md,
  mainAxisSpacing: AppSpacing.md,
)
```

### Uso Incorrecto

```dart
// ❌ INCORRECTO - Números mágicos
padding: const EdgeInsets.all(16)          // NO
const SizedBox(height: 12)                  // NO
margin: const EdgeInsets.only(bottom: 24)   // NO

// ❌ INCORRECTO - Valores arbitrarios
padding: const EdgeInsets.all(15)           // NO (no es múltiplo de 4)
const SizedBox(height: 18)                  // NO (no está en la escala)
```

### Guía de Uso por Contexto

| Contexto | Valor | Uso |
|----------|-------|-----|
| **Icon + Text** | `xs` (4px) | Gap pequeño entre icono y texto |
| **Elementos relacionados** | `sm` (8px) | Chips, tags, badges |
| **Padding de inputs/cards** | `md` (12px) | Padding interno de elementos |
| **Padding de contenido** | `lg` (16px) | Base, padding horizontal de pantallas |
| **Entre secciones** | `xl` (24px) | Separación de secciones visuales |
| **Títulos grandes** | `xxl` (32px) | Espacio para títulos prominentes |
| **Headers/Heros** | `xxxl` (48px) | Headers grandes, spacing hero |

### Verificar Cumplimiento

```bash
# Debe dar 0 resultados:
grep -r "EdgeInsets.all(16)" lib/
grep -r "SizedBox(height: 16)" lib/
grep -r "padding: 12" lib/

# Encontrar violaciones comunes
grep -rE "EdgeInsets\.(all|symmetric|only)\([0-9]+" lib/ | grep -v AppSpacing
```

---

## Validación de Formularios ⭐

**Distinción CRÍTICA:** UI Validation vs Domain Validation

### Dos Tipos de Validación

| Tipo | Ubicación | Retorna | Propósito | Se ejecuta |
|------|-----------|---------|-----------|------------|
| **FormValidators** | `core/validation/form_validators.dart` | `String?` | Feedback UI inmediato | En `TextFormField.validator` |
| **Domain Validators** | `features/*/domain/validators/` | `Failure?` | Validación de negocio | En Controllers/UseCases |

### FormValidators (UI Validation)

**Archivo:** `lib/core/validation/form_validators.dart`

```dart
class FormValidators {
  // Required field
  static String? required(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return 'Por favor ingresa $fieldName';
    }
    return null;
  }
  
  // Max length
  static String? maxLength(String? value, int max, String fieldName) {
    if (value != null && value.length > max) {
      return 'El $fieldName no puede tener más de $max caracteres';
    }
    return null;
  }
  
  // Min length
  static String? minLength(String? value, int min, String fieldName) {
    if (value != null && value.length < min) {
      return 'El $fieldName debe tener al menos $min caracteres';
    }
    return null;
  }
  
  // Email
  static String? email(String? value) {
    if (value == null || value.isEmpty) return null;
    
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Por favor ingresa un email válido';
    }
    return null;
  }
  
  // Combine validators
  static String? combine(String? value, List<String? Function(String?)> validators) {
    for (final validator in validators) {
      final error = validator(value);
      if (error != null) return error;
    }
    return null;
  }
}
```

**Uso en TextFormField:**

```dart
// ✅ CORRECTO: Usar FormValidators
TextFormField(
  decoration: InputDecoration(labelText: 'País'),
  validator: (value) => FormValidators.required(value, 'un país'),
)

TextFormField(
  decoration: InputDecoration(labelText: 'Título'),
  validator: (value) => FormValidators.maxLength(value, 200, 'título'),
)

// Combinar validadores
TextFormField(
  decoration: InputDecoration(labelText: 'Descripción'),
  validator: (value) => FormValidators.combine(value, [
    (v) => FormValidators.required(v, 'una descripción'),
    (v) => FormValidators.maxLength(v, 500, 'descripción'),
    (v) => FormValidators.minLength(v, 10, 'descripción'),
  ]),
)

// Email
TextFormField(
  decoration: InputDecoration(labelText: 'Email'),
  validator: FormValidators.email,
)
```

**❌ INCORRECTO:**

```dart
// ❌ NO: Validación inline duplicada
TextFormField(
  validator: (value) {
    if (value == null || value.isEmpty) {  // Duplica lógica de FormValidators
      return 'Campo requerido';
    }
    if (value.length > 200) {
      return 'Muy largo';
    }
  },
)

// ❌ NO: Sin mensajes descriptivos
TextFormField(
  validator: (value) => value?.isEmpty ?? true ? 'Error' : null,
)
```

### Domain Validators (Business Logic)

**Ubicación:** `features/gossip/domain/validators/gossip_validator.dart`

```dart
class GossipValidator {
  static const int maxSubjectLength = 200;
  static const int maxBodyLength = 2000;
  
  static ValidationFailure? validateSubject(String? subject) {
    if (subject == null || subject.trim().isEmpty) {
      return ValidationFailure(
        message: 'El título es requerido',
        field: 'subject',
      );
    }
    
    if (subject.length > maxSubjectLength) {
      return ValidationFailure(
        message: 'El título no puede tener más de $maxSubjectLength caracteres',
        field: 'subject',
      );
    }
    
    return null;
  }
  
  static ValidationFailure? validateBody(String? body) {
    if (body != null && body.length > maxBodyLength) {
      return ValidationFailure(
        message: 'El contenido no puede tener más de $maxBodyLength caracteres',
        field: 'body',
      );
    }
    
    return null;
  }
  
  static ValidationFailure? validateCityId(String? cityId) {
    if (cityId == null || cityId.isEmpty) {
      return ValidationFailure(
        message: 'La ciudad es requerida',
        field: 'cityId',
      );
    }
    
    return null;
  }
}
```

**Uso en Controllers/UseCases:**

```dart
// En controller o use case
Future<Result<Failure, Gossip>> createGossip(CreateGossipInput input) async {
  // Validar con Domain Validator
  final subjectValidation = GossipValidator.validateSubject(input.subject);
  if (subjectValidation != null) {
    return Result.failure(subjectValidation);
  }
  
  final bodyValidation = GossipValidator.validateBody(input.body);
  if (bodyValidation != null) {
    return Result.failure(bodyValidation);
  }
  
  final cityValidation = GossipValidator.validateCityId(input.cityId);
  if (cityValidation != null) {
    return Result.failure(cityValidation);
  }
  
  // Continuar con creación...
}
```

### ¿Por Qué Dos Tipos?

| Aspecto | FormValidators (UI) | Domain Validators (Business) |
|---------|---------------------|------------------------------|
| **Cuándo** | Inmediato (mientras escribe) | Antes de submit/guardado |
| **Propósito** | UX (feedback rápido) | Seguridad (validación definitiva) |
| **Dónde** | Widget layer | Controller/UseCase layer |
| **Retorna** | `String?` (mensaje error) | `Failure?` (domain error) |
| **Ejemplo** | "Campo requerido" | ValidationFailure con contexto |

**Ambos son necesarios:**
- FormValidators → UX inmediata
- Domain Validators → Última línea de defensa

---

## Sistema de Colores (AppColors)

**Archivo:** `lib/core/theme/app_colors.dart`

```dart
class AppColors {
  // Primary
  static const Color primary = Color(0xFF6200EE);
  static const Color primaryVariant = Color(0xFF3700B3);
  
  // Secondary
  static const Color secondary = Color(0xFF03DAC6);
  static const Color secondaryVariant = Color(0xFF018786);
  
  // Background
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFFFFFFF);
  
  // Error
  static const Color error = Color(0xFFB00020);
  
  // Text
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onSecondary = Color(0xFF000000);
  static const Color onBackground = Color(0xFF000000);
  static const Color onSurface = Color(0xFF000000);
  static const Color onError = Color(0xFFFFFFFF);
}
```

---

## Sistema de Radios (AppRadius)

**Archivo:** `lib/core/theme/app_radius.dart`

```dart
class AppRadius {
  static const double xs = 4;    // 4px  - Muy pequeño
  static const double sm = 8;    // 8px  - Pequeño
  static const double md = 12;   // 12px - Mediano
  static const double lg = 16;   // 16px - Grande
  static const double xl = 20;   // 20px - Extra grande
  static const double xxl = 24;  // 24px - Muy grande
  static const double full = 9999; // Circular
}
```

**Uso:**

```dart
// Border radius
BorderRadius.circular(AppRadius.md)

// Card
Card(
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(AppRadius.lg),
  ),
)

// Container
Container(
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(AppRadius.md),
  ),
)

// Botón circular
BorderRadius.circular(AppRadius.full)
```

---

## Widget Patterns

### Screen Structure

```dart
class MyScreen extends StatefulWidget {
  @override
  State<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends State<MyScreen> {
  late final MyController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = getIt<MyController>();
    _controller.addListener(_onStateChanged);
  }
  
  void _onStateChanged() {
    // Handle state changes
  }
  
  @override
  void dispose() {
    _controller.removeListener(_onStateChanged);
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Title')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: ListenableBuilder(
          listenable: _controller,
          builder: (context, _) {
            return _buildContent();
          },
        ),
      ),
    );
  }
  
  Widget _buildContent() {
    // Content based on state
  }
}
```

### Form Pattern

```dart
class MyForm extends StatefulWidget {
  @override
  State<MyForm> createState() => _MyFormState();
}

class _MyFormState extends State<MyForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  
  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _titleController,
            decoration: InputDecoration(labelText: 'Título'),
            validator: (v) => FormValidators.combine(v, [
              (v) => FormValidators.required(v, 'título'),
              (v) => FormValidators.maxLength(v, 200, 'título'),
            ]),
          ),
          const SizedBox(height: AppSpacing.md),
          
          ElevatedButton(
            onPressed: _submit,
            child: Text('Guardar'),
          ),
        ],
      ),
    );
  }
  
  void _submit() {
    if (_formKey.currentState!.validate()) {
      // Handle submit
    }
  }
}
```

### Loading State

```dart
if (state.isLoading) {
  return Center(
    child: CircularProgressIndicator(),
  );
}
```

### Error State

```dart
if (state.failure != null) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.error_outline, size: 48, color: AppColors.error),
        const SizedBox(height: AppSpacing.md),
        Text(
          state.failure!.message,
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.error),
        ),
        const SizedBox(height: AppSpacing.lg),
        ElevatedButton(
          onPressed: _retry,
          child: Text('Reintentar'),
        ),
      ],
    ),
  );
}
```

---

## 📚 Referencias

- **Material Design Spacing:** https://material.io/design/layout/spacing-methods.html
- **Flutter Form Validation:** https://docs.flutter.dev/cookbook/forms/validation
- **Material Colors:** https://material.io/design/color

---

**Última actualización:** 2026-10-20  
**Mantenedor:** Alejo
