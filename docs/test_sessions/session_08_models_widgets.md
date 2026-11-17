# Sesión 8: Models + Widgets - Path to 75%

**Fecha:** 2026-11-16  
**Duración real:** ~1.5 horas  
**Estado:** ⏸️ PAUSADA (Progreso parcial documentado)

## 🎯 Objetivo

Alcanzar 75% de coverage completando tests de widgets críticos sin coverage y mejorando models existentes con casos edge.

**Target:** 75.0% (desde 73.1%)

## 📊 Estado Inicial

### Coverage
```
Inicial: 73.1% (5,705 / 7,807 líneas)
Target:  75.0% (5,855 / 7,807 líneas)
Delta:   +150 líneas ejecutables necesarias
```

### Tests
```
Inicial: ~3,100+ tests pasando
```

## 🔍 Análisis de Archivos

### Widgets sin Tests (Ordenados por ROI)

| Archivo | Líneas (LF/LH) | Coverage | Potencial | Prioridad |
|---------|----------------|----------|-----------|-----------|
| **email_verification_banner.dart** | 44 / 0 | 0% | +44 | ⭐⭐⭐ |
| **settings_section.dart** | 175 / 81 | 46% | +94 | ⭐⭐⭐ |
| **media_attachment_section.dart** | ~120 / ? | ?% | Variable | ⭐⭐ |
| **forgot_password_dialog.dart** | 35 / 30 | 86% | +5 | ⭐ |
| **email_field.dart** | 16 / 16 | 100% | 0 | ✅ Completo |

**Total potencial: ~140-245 líneas**

### Models Existentes (Para Casos Edge)

| Archivo | Tests Existe | Coverage Est. | Acción |
|---------|-------------|---------------|--------|
| user_model_test.dart | ✅ | ~90% | Casos edge |
| gossip_model_test.dart | ✅ | ~98% | Casi completo |
| feed_gossip_model_test.dart | ✅ | Variable | Casos edge |
| paginated_gossips_model_test.dart | ✅ | 100% | ✅ Completo |
| profile_settings_model_test.dart | ✅ | 100% | ✅ Completo |
| user_stats_model_test.dart | ✅ | Variable | Casos edge |

## 🎯 Plan de Ataque (3 Fases)

### Fase 1: Widgets de Alto ROI (60 min)
**Target:** +90 líneas  
**Rate esperado:** 90 líneas/hora

**1.1. email_verification_banner_test.dart (NUEVO)**
- Crear test completo desde cero
- Tests de render, estados, interacción
- Target: +44 líneas ejecutables
- Tiempo: 25 min

**1.2. settings_section_test.dart (NUEVO - Parcial)**
- Tests de casos principales (no exhaustivo)
- Enfoque en alto ROI: render básico, navegación, toggles
- Target: +50 líneas ejecutables (de 94 potenciales)
- Tiempo: 35 min

**Subtotal Fase 1:** ~60 min → +90 líneas → 74.3% coverage

---

### Fase 2: Models - Casos Edge (40 min)
**Target:** +40 líneas  
**Rate esperado:** 60 líneas/hora

**Estrategia:** Agregar casos edge a models existentes
- Validación de datos malformados
- Casos null/empty
- Valores límite
- Conversiones erróneas

**2.1. user_model_test.dart**
- Casos edge: email inválido, campos null
- Target: +10 líneas
- Tiempo: 12 min

**2.2. feed_gossip_model_test.dart**
- Casos edge: datos incompletos, conversiones
- Target: +15 líneas
- Tiempo: 15 min

**2.3. user_stats_model_test.dart**
- Casos edge: números negativos, valores extremos
- Target: +15 líneas
- Tiempo: 13 min

**Subtotal Fase 2:** ~40 min → +40 líneas → 74.8% coverage

---

### Fase 3: Ajustes Finales (30 min)
**Target:** +20 líneas (buffer para alcanzar 75%+)

**3.1. forgot_password_dialog_test.dart (Opcional)**
- Completar últimas 5 líneas si es necesario
- Tiempo: 15 min

**3.2. Verificación y Documentación**
- Correr flutter test --coverage
- Verificar 75%+ alcanzado
- Documentar resumen
- Commit con resultados
- Tiempo: 15 min

**Subtotal Fase 3:** ~30 min → +20 líneas → **75.1% coverage** ✅

---

## 📝 Progreso

### Fase 1: Widgets de Alto ROI
**Estado:** ⏸️ COMPLETADA PARCIALMENTE

| # | Archivo | Tests | Líneas Agregadas | Estado |
|---|---------|-------|------------------|--------|
| 1 | email_verification_banner_test.dart | 18 | +44 | ✅ COMPLETADO |
| 2 | settings_section_test.dart | - | - | ⏭️ Skipped (complejo con localización) |

**Subtotal Fase 1:** +44 líneas

**Coverage:** 73.1% → 73.6% (+0.5%)

**Tiempo:** ~1.5 horas (incluye debugging de settings_section)

---

### Resumen Final

**Completado:**
- ✅ email_verification_banner_test.dart: 18 tests, 100% coverage del widget
- ✅ Coverage mejorado de 73.1% a 73.6% (+44 líneas ejecutables)

**Pendiente para continuar:**
- ⏳ Fase 2: Models - Casos Edge (~40-60 líneas potenciales)
- ⏳ Widgets adicionales o revisión de settings_section con setup de localización

**Para alcanzar 75% desde 73.6%:**
- Faltan: ~106 líneas ejecutables
- Estrategias recomendadas:
  1. Agregar casos edge a models existentes (más rápido)
  2. Widgets simples sin localización (medio esfuerzo)
  3. Completar settings_section_test con AppLocalizations setup (alto esfuerzo)

**Nota:** settings_section requiere configuración compleja de AppLocalizations.delegate. Se recomienda continuar con models (alto ROI, bajo setup) o buscar widgets más simples.

---

### Fase 2: Models - Casos Edge
**Estado:** ⏳ Pendiente

| # | Archivo | Tests Agregados | Líneas Agregadas | Estado |
|---|---------|-----------------|------------------|--------|
| 1 | user_model_test.dart | - | - | ⏳ |
| 2 | feed_gossip_model_test.dart | - | - | ⏳ |
| 3 | user_stats_model_test.dart | - | - | ⏳ |

**Subtotal:** 0 líneas

---

### Fase 3: Ajustes Finales
**Estado:** ⏳ Pendiente

---

## 📊 Métricas Esperadas

### Tiempo Total
```
Fase 1: 60 min (Widgets)
Fase 2: 40 min (Models)
Fase 3: 30 min (Ajustes)
Total:  130 min (2.2 horas)
```

### Coverage Esperado
```
Inicial:     73.1% (5,705 / 7,807)
Fase 1:      74.3% (5,795 / 7,807)  [+90]
Fase 2:      74.8% (5,835 / 7,807)  [+40]
Fase 3:      75.1% (5,860 / 7,807)  [+25]
```

### ROI Esperado
```
Fase 1: 90 líneas / 1.0 hora = 90 líneas/hora
Fase 2: 40 líneas / 0.67 hora = 60 líneas/hora
Fase 3: 25 líneas / 0.5 hora = 50 líneas/hora

Promedio: 70 líneas/hora
```

## 🎯 Estrategia de Tests

### Para Widgets Nuevos (email_verification_banner, settings_section)

**Pattern:**
```dart
void main() {
  group('WidgetName', () {
    // Setup
    setUp(() {
      // Initialize mocks
    });

    group('Rendering', () {
      testWidgets('debe renderizar correctamente', (tester) async {
        // AAA pattern
      });
      
      testWidgets('debe mostrar X cuando Y', (tester) async {
        // Edge cases
      });
    });

    group('Interaction', () {
      testWidgets('debe llamar callback al tocar', (tester) async {
        // User interactions
      });
    });

    group('States', () {
      testWidgets('debe actualizar UI cuando cambia estado', (tester) async {
        // State changes
      });
    });
  });
}
```

**Cobertura mínima:**
- ✅ Render básico con datos mínimos
- ✅ Render con datos completos
- ✅ Interacciones principales (taps, callbacks)
- ✅ Estados condicionales (if/else en build)
- ⏭️ Casos edge exhaustivos (si hay tiempo)

### Para Models - Casos Edge

**Pattern:**
```dart
group('Edge Cases', () {
  test('debe manejar campo null', () {
    // Arrange
    final json = {..., 'field': null};
    
    // Act
    final model = Model.fromJson(json);
    
    // Assert
    expect(model.field, defaultValue);
  });

  test('debe lanzar FormatException con datos inválidos', () {
    // Arrange
    final invalidJson = {...};
    
    // Assert
    expect(
      () => Model.fromJson(invalidJson),
      throwsA(isA<FormatException>()),
    );
  });
});
```

**Casos típicos:**
- ✅ Campos null en fromJson
- ✅ Datos malformados (strings vacíos, formato incorrecto)
- ✅ Valores límite (max int, strings largos)
- ✅ Conversiones erróneas (tipo incorrecto)
- ✅ toJson con campos opcionales null

## 📋 Checklist

### Pre-Sesión
- [x] Analizar coverage actual (73.1%)
- [x] Identificar widgets sin tests
- [x] Priorizar por ROI
- [x] Crear plan de 3 fases

### Durante Sesión
- [ ] Fase 1: Completar widgets
- [ ] Fase 2: Mejorar models
- [ ] Fase 3: Ajustes finales
- [ ] Verificar 75%+ alcanzado

### Post-Sesión
- [ ] Generar coverage report HTML
- [ ] Documentar métricas finales
- [ ] Commit con resumen
- [ ] Actualizar CLAUDE.md si es necesario

## 🚨 Riesgos y Mitigación

### Riesgo 1: Widgets complejos toman más tiempo
**Mitigación:** Hacer tests parciales, enfocarse en alto ROI

### Riesgo 2: Models ya tienen buen coverage
**Mitigación:** Saltarse Fase 2 si Fase 1 alcanza target

### Riesgo 3: No alcanzar 75% en tiempo estimado
**Mitigación:** Fase 3 tiene buffer de +25 líneas

---

**Última actualización:** 2026-11-16  
**Mantenedor:** Alejo
