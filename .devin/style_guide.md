# Style Guide - Chismes App

## � Orientación de Pantalla

### Regla de Oro
**La app está bloqueada en modo portrait (vertical) para optimizar la UX en dispositivos móviles.**

### Por qué portrait solo

1. **Tipo de app** - Es una app de feed social (tipo Instagram/TikTok)
2. **UX óptima** - Portrait es mejor para scroll y contenido vertical
3. **Teclado** - En landscape, el teclado cubre más del 50% de la pantalla
4. **Espacio** - Landscape desperdicia mucho espacio a los lados en móviles
5. **Consistencia** - UX predecible sin necesidad de diseñar 2 layouts

### Configuración

**Android:**
```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<activity
    android:name=".MainActivity"
    android:screenOrientation="portrait">  <!-- Solo portrait -->
```

**iOS:**
```xml
<!-- ios/Runner/Info.plist -->
<key>UISupportedInterfaceOrientations</key>
<array>
    <string>UIInterfaceOrientationPortrait</string>
</array>
```

### Cuándo habilitar landscape

**Habilitar landscape cuando:**
- La app soporte tablets
- Se agregue responsive design en roadmap
- Se implemente un layout específico para landscape

**Para tablets:**
Cuando se soporte tablets, modificar iOS Info.plist:
```xml
<key>UISupportedInterfaceOrientations~ipad</key>
<array>
    <string>UIInterfaceOrientationPortrait</string>
    <string>UIInterfaceOrientationLandscapeLeft</string>
    <string>UIInterfaceOrientationLandscapeRight</string>
</array>
```

## 🔍 Validación de Formularios

### Regla de Oro
**Usar `FormValidators` para validaciones de UI en lugar de validaciones inline.**

### Por qué centralizar validaciones

1. **Evita duplicación** - La misma lógica no se repite en múltiples lugares
2. **Consistencia** - Todos los campos usan el mismo estilo de validación
3. **Mantenibilidad** - Cambiar la lógica de validación en un solo lugar
4. **Legibilidad** - `FormValidators.required(value, 'un país')` más claro que un if inline

### Archivo de helpers

**`lib/core/validation/form_validators.dart`** contiene:
- `required` - Campo requerido con mensaje generado
- `requiredWithMessage` - Campo requerido con mensaje personalizado
- `minLength` - Validación de longitud mínima
- `maxLength` - Validación de longitud máxima
- `email` - Validación de formato de email

### Uso correcto

```dart
// ✅ CORRECTO: Usar FormValidators
TextFormField(
  validator: (value) => FormValidators.required(value, 'un país'),
)

// ✅ CORRECTO: Con mensaje personalizado
TextFormField(
  validator: (value) => FormValidators.requiredWithMessage(
    value,
    'Escribe sobre quién o dónde es el chisme',
  ),
)
```

### Uso incorrecto

```dart
// ❌ INCORRECTO: Validación inline duplicada
TextFormField(
  validator: (value) {
    if (value == null || value.isEmpty) {
      return 'Selecciona un país';
    }
    return null;
  },
)
```

### Distinción entre UI validators y Domain validators

**UI Validators (FormValidators):**
- Propósito: Feedback inmediato al usuario en el formulario
- Retorna: `String?` (mensaje de error o null)
- Ubicación: `lib/core/validation/form_validators.dart`
- Uso: En widgets de formulario (TextFormField, DropdownButtonFormField)

**Domain Validators (GossipValidator):**
- Propósito: Validación de negocio antes de enviar al backend
- Retorna: `Failure?` (error de negocio o null)
- Ubicación: `lib/features/gossip/domain/validators/gossip_validator.dart`
- Uso: En controllers y use cases

**Ambos son necesarios:**
- UI validators → Feedback inmediato (UX)
- Domain validators → Validación de negocio (Security)

## 📐 Sistema de Espaciado

### Regla de Oro
**NUNCA uses números mágicos para espaciado.** Siempre usa `AppSpacing` del archivo `lib/core/theme/app_spacing.dart`.

### Por qué existe este estándar

1. **Consistencia visual** - Todo el diseño usa la misma escala de espaciado
2. **Mantenibilidad** - Cambiar el espaciado global es cambiar una constante
3. **Legibilidad** - `AppSpacing.lg` es más claro que `16`
4. **Type-safe** - No errores de typo en números
5. **Material Design** - Basado en el estándar de 4px (0.5rem)

### Sistema de Espaciado

El sistema usa una escala de 4px como base (Material Design):

```dart
class AppSpacing {
  static const double xs = 4;    // 4px  - Muy pequeño
  static const double sm = 8;    // 8px  - Pequeño
  static const double md = 12;   // 12px - Mediano
  static const double lg = 16;   // 16px - Grande (base)
  static const double xl = 24;   // 24px - Extra grande
  static const double xxl = 32;  // 32px - Muy grande
  static const double xxxl = 48; // 48px - Enorme

  // Constantes de propósito específico
  static const double horizontalContent = lg;
  static const double verticalElements = md;
  static const double sectionGap = xl;
}
```

### Uso Correcto

✅ **CORRECTO:**
```dart
import '../../../../core/theme/app_spacing.dart';

// Padding
padding: const EdgeInsets.all(AppSpacing.lg)
padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.lg)

// SizedBox
const SizedBox(height: AppSpacing.md)
const SizedBox(width: AppSpacing.sm)

// Grid spacing
crossAxisSpacing: AppSpacing.md
mainAxisSpacing: AppSpacing.md
```

❌ **INCORRECTO:**
```dart
// ❌ Números mágicos
padding: const EdgeInsets.all(16)
const SizedBox(height: 12)

// ❌ Inconsistente
padding: const EdgeInsets.all(15)  // ¿Por qué 15?
const SizedBox(height: 17)          // ¿Por qué 17?
```

### Cuándo usar cada valor

| Valor | Tamaño | Uso recomendado |
|-------|--------|-----------------|
| `xs` (4px) | Muy pequeño | Espaciado entre icono y texto |
| `sm` (8px) | Pequeño | Separación de elementos relacionados |
| `md` (12px) | Mediano | Padding de cards, padding de inputs |
| `lg` (16px) | Grande (base) | Padding de contenido principal, SizedBox entre secciones |
| `xl` (24px) | Extra grande | Separación entre secciones importantes |
| `xxl` (32px) | Muy grande | Separación de secciones principales |
| `xxxl` (48px) | Enorme | Separación de secciones grandes |

### Constantes de Propósito Específico

Para casos comunes, usa las constantes semánticas:

```dart
// Espaciado horizontal estándar para contenido
padding: const EdgeInsets.symmetric(horizontal: AppSpacing.horizontalContent)

// Espaciado vertical estándar entre elementos
const SizedBox(height: AppSpacing.verticalElements)

// Espaciado para secciones principales
const SizedBox(height: AppSpacing.sectionGap)
```

### Ejemplos Prácticos

#### Padding de un Card
```dart
Card(
  child: Padding(
    padding: const EdgeInsets.all(AppSpacing.lg),
    child: Text('Contenido'),
  ),
)
```

#### Separación entre elementos de formulario
```dart
Column(
  children: [
    TextField(...),
    const SizedBox(height: AppSpacing.md),
    TextField(...),
  ],
)
```

#### Grid spacing
```dart
GridView.builder(
  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 2,
    crossAxisSpacing: AppSpacing.md,
    mainAxisSpacing: AppSpacing.md,
  ),
  // ...
)
```

### Implementación

1. **Importar siempre:**
```dart
import '../../../../core/theme/app_spacing.dart';
```

2. **Usar constantes con `const`:**
```dart
const SizedBox(height: AppSpacing.lg)  // ✅ const para rendimiento
SizedBox(height: AppSpacing.lg)        // ❌ sin const, reconstruye en cada build
```

3. **No inventar nuevos valores:**
Si necesitas un espaciado que no existe, agrega una constante al archivo `AppSpacing` con un nombre descriptivo, no uses números mágicos.

### Ejemplo de agregar una nueva constante

Si necesitas un espaciado específico para botones:

```dart
// En lib/core/theme/app_spacing.dart
class AppSpacing {
  // ... constantes existentes ...
  
  /// Espaciado para botones
  static const double buttonPadding = lg;
}
```

Luego usa:
```dart
ElevatedButton(
  style: ElevatedButton.styleFrom(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.buttonPadding),
  ),
  // ...
)
```

### Verificación

**Para verificar que el código sigue este estándar:**

```bash
# Buscar números mágicos de espaciado (debería dar 0 resultados)
grep -r "EdgeInsets.all(16)" lib/
grep -r "SizedBox(height: 16)" lib/
grep -r "EdgeInsets.all(12)" lib/
```

Si encuentras resultados, reemplázalos con `AppSpacing`.

### Referencias

- [Material Design Spacing System](https://m3.material.io/styles/spacing/overview)
- [Flutter Best Practices](https://flutter.dev/docs/development/data-and-backend/state-mgmt/simple)
