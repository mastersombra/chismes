# Design Skills - Guía de Uso con Flutter

**Objetivo:** UI nivel Instagram/Facebook para Chismes app

**Skills instalados:** `frontend-design`, `emil-design-eng`

---

## 🎯 Cuándo Usar Cada Skill

### frontend-design → Diseño Visual

**Invocar cuando:**
- Diseñas una nueva screen completa
- Defines paleta de colores del proyecto
- Eliges tipografía y type scale
- Planeas layouts complejos (feeds, grids, dashboards)
- Necesitas decisiones de jerarquía visual

**NO invocar para:**
- Animaciones (usa `emil-design-eng`)
- Bugs de UI
- Ajustes menores de spacing

### emil-design-eng → Animaciones y Polish

**Invocar cuando:**
- Implementas cualquier animación
- Agregas gesture handlers (swipe, long-press, drag)
- Defines estados de componentes (pressed, disabled, loading)
- Trabajas en transiciones entre screens
- Necesitas timing/curves para animaciones

**NO invocar para:**
- Elección de colores (usa `frontend-design`)
- Layout structure
- Typography decisions

---

## 📝 Ejemplos Prácticos

### Ejemplo 1: Diseñar Screen de Perfil

**Prompt:**
```
/frontend-design Diseñar screen de perfil de usuario para Chismes, 
una app móvil de gossip/chismes estilo Instagram. Target: 18-35 años. 
Debe sentirse profesional, moderna, y con personalidad propia 
(no genérica). El perfil muestra: avatar, bio, stats (followers, posts), 
y feed de gossips del usuario.
```

**El skill te dará:**
- Paleta de colores específica (hex codes)
- Decisiones tipográficas (families, weights, sizes)
- Layout wireframe en ASCII
- Jerarquía visual de componentes

**Tu trabajo:**
```dart
// 1. Mapear colores sugeridos a AppColors
// Skill sugiere: Primary #4F46E5, Secondary #EC4899
class AppColors {
  static const primary = Color(0xFF4F46E5);
  static const secondary = Color(0xFFEC4899);
  // ...
}

// 2. Implementar layout según wireframe
// 3. Usar AppSpacing para consistency
```

### Ejemplo 2: Animación de Like Button

**Prompt:**
```
/emil-design-eng Implementar animación para botón de "like" en un 
gossip card. Al presionar debe sentirse responsivo y satisfactorio, 
como Instagram o Twitter. ¿Qué timing, curves y transforms usar?
```

**El skill te dará:**
- Timing específico (ej: 200ms)
- Curve recomendada (ej: `easeOut`)
- Transforms (ej: `scale(0.97)` on press, `scale(1.2)` on confirm)
- Secuencia de animación

**Tu implementación:**
```dart
class LikeButton extends StatefulWidget {
  @override
  _LikeButtonState createState() => _LikeButtonState();
}

class _LikeButtonState extends State<LikeButton> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    // Timing del skill: 200ms
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    // Curve del skill: easeOut
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  void _onTap() {
    // Animación en 2 fases como sugiere el skill
    _controller.forward().then((_) {
      _controller.reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        _onTap();
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            // Press state: 0.97, animación: 1.2
            scale: _pressed ? 0.97 : _scaleAnimation.value,
            child: Icon(
              isLiked ? Icons.favorite : Icons.favorite_border,
              color: isLiked ? AppColors.primary : Colors.grey,
            ),
          );
        },
      ),
    );
  }
}
```

### Ejemplo 3: Transition entre Screens

**Prompt:**
```
/emil-design-eng Transición de lista de gossips a detalle de gossip. 
Debe sentirse fluida y profesional como Instagram Stories o Reddit. 
¿Hero animation, slide, o scale? ¿Qué timing?
```

**Tu implementación:**
```dart
// El skill recomienda Hero + slide-up

// GossipCard.dart
Hero(
  tag: 'gossip-${gossip.id}',
  child: GossipCard(gossip: gossip),
)

// Navigation
Navigator.push(
  context,
  PageRouteBuilder(
    // Timing del skill: 400ms para transiciones entre screens
    transitionDuration: const Duration(milliseconds: 400),
    pageBuilder: (context, animation, secondaryAnimation) {
      return GossipDetailScreen(gossip: gossip);
    },
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      // Curve del skill: easeOut para apertura
      final curvedAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOut,
      );
      
      // Slide-up + fade (sugerido por skill)
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.1),
          end: Offset.zero,
        ).animate(curvedAnimation),
        child: FadeTransition(
          opacity: curvedAnimation,
          child: child,
        ),
      );
    },
  ),
);
```

---

## 🔄 Traducción Rápida: Web → Flutter

### Animaciones

| Web (Skill dice) | Flutter (Tu implementas) |
|------------------|--------------------------|
| `transition: transform 200ms ease-out` | `AnimationController(duration: Duration(milliseconds: 200))` + `Curves.easeOut` |
| `transition: opacity 150ms linear` | `AnimationController(duration: 150)` + `Curves.linear` + `FadeTransition` |
| `@keyframes slide-up { from { transform: translateY(20px) } }` | `Tween<Offset>(begin: Offset(0, 0.1), end: Offset.zero)` + `SlideTransition` |

### Transforms

| Web | Flutter |
|-----|---------|
| `transform: scale(0.97)` | `Transform.scale(scale: 0.97, child: ...)` |
| `transform: translateY(-10px)` | `Transform.translate(offset: Offset(0, -10), child: ...)` |
| `transform: rotate(45deg)` | `Transform.rotate(angle: pi/4, child: ...)` |
| `transform-origin: top left` | `alignment: Alignment.topLeft` en Transform |

### Curves (Easing)

| Web | Flutter Curve |
|-----|---------------|
| `ease-out` | `Curves.easeOut` |
| `ease-in` | `Curves.easeIn` |
| `ease-in-out` | `Curves.easeInOut` |
| `cubic-bezier(0.4, 0, 0.2, 1)` | `Cubic(0.4, 0, 0.2, 1)` |
| Spring animation | `Curves.elasticOut` o `SpringSimulation` |

### Colores

| Web | Flutter |
|-----|---------|
| `#4F46E5` | `Color(0xFF4F46E5)` |
| `rgba(79, 70, 229, 0.5)` | `Color(0xFF4F46E5).withOpacity(0.5)` |
| `hsl(245, 80%, 60%)` | Convertir a hex primero, luego `Color` |

---

## 🎨 Principios de Emil Kowalski (Memorizar)

### 1. Timing Guidelines

```dart
// Microinteracciones (hover, press)
Duration(milliseconds: 150-200)

// Animaciones de componentes (tooltips, popovers)
Duration(milliseconds: 200-300)

// Transiciones entre screens
Duration(milliseconds: 400-600)

// Animaciones complejas (onboarding, celebration)
Duration(milliseconds: 800-1200)
```

### 2. Curves por Contexto

```dart
// Apertura/Entrada: easeOut (feedback inmediato)
Curves.easeOut

// Cierre/Salida: easeIn (desaparición gradual)
Curves.easeIn

// Bi-direccional: easeInOut
Curves.easeInOut

// Elementos físicos (bounce, spring): elasticOut
Curves.elasticOut

// Sin aceleración (progress bars): linear
Curves.linear
```

### 3. Transform Origins

```dart
// Popovers: Desde el trigger
alignment: Alignment.topLeft // o donde esté el trigger

// Modals: Centro
alignment: Alignment.center

// Tooltips: Desde el arrow
alignment: calculado según posición
```

### 4. Press States

```dart
// Botones deben reaccionar SIEMPRE
onTapDown: scale to 0.97
onTapUp: scale back to 1.0

// NO usar solo onTap - no hay feedback visual
```

### 5. Nothing from Nothing

```dart
// ❌ MALO: Aparece de la nada
scale: 0.0 → 1.0

// ✅ BUENO: Aparece gradualmente
scale: 0.95 + opacity: 0 → scale: 1.0 + opacity: 1.0
```

---

## ⚠️ Anti-Patterns (Evitar)

### Diseño (frontend-design)

```dart
// ❌ Genérico de IA
- Paleta cream (#F4F1EA) + terracota (#D97757)
- Todo con el mismo BorderRadius.circular(12)
- Labels en mayúsculas: Text('FOLLOWERS', style: ...)
- Usar middle dots: "Profile · Settings · Logout"

// ✅ Profesional
- Paleta específica para tu app (identidad propia)
- BorderRadius según jerarquía:
  * Cards: BorderRadius.circular(16)
  * Buttons: BorderRadius.circular(12)
  * Chips/Tags: BorderRadius.circular(20)
- Sentence case: Text('Followers', style: ...)
- Separadores visuales apropiados
```

### Animaciones (emil-design-eng)

```dart
// ❌ MALO
// 1. Transición de "all"
AnimatedContainer(
  duration: Duration(milliseconds: 300),
  // Anima TODAS las propiedades (laggy)
)

// 2. ease-in para aperturas (se siente lento)
Curves.easeIn

// 3. Sin press state
IconButton(
  onPressed: () {},
  // No feedback visual
)

// ✅ BUENO
// 1. Transiciones específicas
AnimatedOpacity(...) // Solo opacity
AnimatedScale(...) // Solo scale

// 2. ease-out para aperturas (inmediato)
Curves.easeOut

// 3. Con press state
GestureDetector(
  onTapDown: (_) => setState(() => _pressed = true),
  onTapUp: (_) => setState(() => _pressed = false),
  child: Transform.scale(
    scale: _pressed ? 0.97 : 1.0,
    child: ...
  ),
)
```

---

## 🚀 Workflow Recomendado

### Para Nueva Screen

```bash
# 1. Diseño visual primero
/frontend-design Diseñar screen de [nombre]. Target: [audiencia]. 
Debe tener: [componentes]. Inspiración: [referencias].

# 2. Implementar layout base
# - Crear StatelessWidget
# - Usar AppSpacing, AppColors sugeridos
# - Implementar estructura sin animaciones

# 3. Agregar animaciones
/emil-design-eng Agregar animaciones para [interacción específica].

# 4. Implementar animaciones
# - AnimationController según timing sugerido
# - Curves según contexto
# - Verificar en dispositivo real
```

### Para Mejorar UI Existente

```bash
# 1. Identificar problema
"Esta screen se ve genérica" → /frontend-design
"Esta animación se siente lenta" → /emil-design-eng

# 2. Prompt específico con contexto
/frontend-design La screen de [nombre] se ve genérica. 
Mejorar jerarquía visual de: [elemento específico].

# 3. Aplicar sugerencias gradualmente
# - No cambiar todo de golpe
# - Testear cada cambio
# - Validar con usuario si es posible
```

---

## 📚 Recursos Complementarios

### Flutter Specifics

- **Curves:** https://api.flutter.dev/flutter/animation/Curves-class.html
- **Animations Tutorial:** https://docs.flutter.dev/ui/animations
- **Hero Animations:** https://docs.flutter.dev/ui/animations/hero-animations
- **Implicit Animations:** https://docs.flutter.dev/ui/animations/implicit-animations

### Inspiración

- **Instagram:** Transitions, pull-to-refresh, stories
- **Twitter:** Like animation, scroll physics
- **Reddit:** Card expansion, voting feedback
- **Dribbble:** https://dribbble.com/tags/mobile_animation

---

**Última actualización:** 2026-11-17  
**Mantenedor:** Alejo

**FIN DEL DOCUMENTO**
