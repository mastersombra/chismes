# Sesión 6: Widget Sprint Final - Alcanzar 75%

**Fecha:** 2026-11-13  
**Duración estimada:** 1.5-2 horas  
**Estado:** 🚧 EN PROGRESO

## 🎯 Objetivo
Alcanzar 75% de coverage mediante tests de widgets pequeños, screens simples y value objects con validación (estrategia de alto ROI validada en Sesión 3).

**Target:** 75.0% (desde 71.5%)

## 📊 Estado Inicial

### Coverage
```
Inicial: 71.5% (5,433 / 7,598 líneas)
Target:  75.0% (5,698 / 7,598 líneas)
Delta:   +265 líneas ejecutables necesarias
```

### Tests
```
Inicial: ~3,448 tests pasando
```

## 🎯 Plan de Ataque (3 Fases)

### Fase 1: Widgets de Presentación (30 min)
**Target:** +120 líneas  
**Rate esperado:** 240 líneas/hora

### Fase 2: Screens Pequeños (40 min)
**Target:** +95 líneas  
**Rate esperado:** 140 líneas/hora

### Fase 3: Value Objects con Validación (30 min)
**Target:** +50 líneas  
**Rate esperado:** 100 líneas/hora

**Total estimado:** 1.5-2 horas → **+265 líneas** → **75.5% coverage** ✅

## ✅ Progreso - Fase 1 Completada

### Archivos Completados

| # | Archivo | Tests | Líneas Agregadas | Estado |
|---|---------|-------|------------------|--------|
| 1 | feed_gossip_adapter_test.dart | 24 | ~10 líneas | ✅ |
| 2 | new_gossips_banner_test.dart | 13 | ~13 líneas | ✅ |

### Coverage Actual
```
Inicial: 71.5% (5,433 / 7,598)
Actual:  71.8% (5,456 / 7,598)
Delta:   +23 líneas (+37 tests)
```

### Resumen Fase 1
- **Tiempo:** ~45 minutos
- **Tests:** 37 tests (100% passing)
- **ROI:** ~31 líneas/hora ejecutables
- **Nota:** ROI más bajo del esperado porque:
  - feed_gossip_adapter tiene poca lógica ejecutable (solo mapeos)
  - new_gossips_banner es principalmente presentación
  - Helper functions en tests no cuentan como coverage

---

**Última actualización:** 2026-11-13  
**Mantenedor:** Alejo
