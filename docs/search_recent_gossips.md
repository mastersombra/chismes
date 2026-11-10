# Feature: Chismes Recientes en Búsqueda

**Fecha:** 2026-11-08  
**Tipo:** Enhancement  
**Status:** ✅ Implementado

---

## 📋 Resumen

Implementación de la funcionalidad "Recientes" en la pantalla de búsqueda para mejorar la experiencia del usuario mostrando contenido relevante en el estado inicial (antes de realizar una búsqueda).

---

## 🎯 Problema Resuelto

**Antes:** La pantalla de búsqueda mostraba solo un mensaje estático en el estado inicial:
```
🔍 Buscar chismes...

Escribe para buscar chismes 🔎
```

**Después:** Ahora muestra los 10 chismes más recientes mientras el usuario decide qué buscar:
```
🔍 Buscar chismes...

🆕 Recientes
[Grid con 10 chismes más recientes]
```

---

## 🏗️ Arquitectura

### Reutilización de Código

No se creó un nuevo UseCase. Se reutilizó `GetGossips` existente con `GossipQuery.defaultPublic()`:

```dart
// GossipQuery.defaultPublic() retorna:
GossipQuery(
  status: GossipStatus.published,
  visibility: GossipVisibility.public,
  orderBy: 'createdAt',
  descending: true,  // ← Más recientes primero
  limit: 20,
)
```

### Cambios en SearchScreen

**Estados nuevos:**
- `isLoadingRecent`: Loading mientras carga recientes
- `recentGossips`: Lista de chismes recientes (top 10)
- `currentQuery`: Query actual de búsqueda

**Flujo:**
1. `initState()` → `_loadRecentGossips()` → Carga 10 recientes
2. Usuario escribe → `searchGossip()` → Busca y filtra
3. Usuario limpia TextField → Resetea a recientes

---

## 🎨 UI/UX

### Estados de la Pantalla

| Estado | Condición | UI |
|--------|-----------|-----|
| **Loading Inicial** | `isLoadingRecent = true` | CircularProgressIndicator |
| **Recientes** | `!hasSearched && recentGossips.isNotEmpty` | 🆕 Recientes + GridView |
| **Empty Inicial** | `!hasSearched && recentGossips.isEmpty` | Mensaje "Busca chismes por tema" |
| **Buscando** | `isLoading && hasSearched` | CircularProgressIndicator |
| **Resultados** | `hasSearched && results.isNotEmpty` | "X resultados" + GridView |
| **Sin Resultados** | `hasSearched && results.isEmpty` | "No se encontraron chismes" |
| **Error** | `errorMessage != null` | Banner rojo con mensaje |

### Mejoras Adicionales

- **Loading indicator en TextField:** Muestra `CircularProgressIndicator` en `suffixIcon` mientras busca
- **Contador de resultados:** Muestra "X resultado(s)" en búsquedas
- **Sugerencia en empty:** Agrega "Intenta con otras palabras" cuando no hay resultados
- **Banner de error:** Muestra errores de red de forma visible

---

## 🧪 Testing

**Tests actualizados:** 15 tests pasando

**Nuevos tests:**
- `debe cargar y mostrar chismes recientes al iniciar`
- `debe mostrar mensaje cuando no hay recientes`
- `debe resetear búsqueda al limpiar el TextField`
- `debe mostrar loading indicator mientras busca`

**Tests modificados:**
- Actualizados para esperar 2 llamadas a `GetGossips`: una en `initState()` (recientes) y otra en búsqueda

---

## 📊 Datos

**Cantidad de recientes mostrados:** 10 chismes  
**Query utilizada:** `GossipQuery.defaultPublic()` (filtra published + approved + public, ordena por fecha DESC)

**Ventajas de 10 vs 20:**
- ✅ Carga más rápida
- ✅ Suficiente para scroll inicial
- ✅ Reduce uso de data/batería

---

## 🔄 Diferencias con Home/Popular

| Aspecto | Search (Recientes) | Home (Populares) |
|---------|-------------------|------------------|
| **Algoritmo** | Simple: `ORDER BY created_at DESC` | Complejo: Ciudad (40%) + Interacciones (30%) + Velocity (20%) + Decay (10%) |
| **Objetivo** | Contenido fresco | Contenido relevante/viral |
| **Cantidad** | 10 chismes | 20 chismes (paginado) |
| **Duplicación** | ❌ No duplica (diferentes criterios) | - |

---

## 🚀 Próximos Pasos (Futuro)

### Opción A: Sugerencias de Búsqueda (Chips)
```
💡 Intenta buscar:
[Amor] [Trabajo] [Familia] [Escuela]

🆕 Recientes
[Grid de chismes]
```

**Esfuerzo:** ~2 horas  
**Valor:** Guía al usuario, reduce búsquedas vacías

### Opción B: Personalización por Ciudad
Si el usuario tiene location configurada, mostrar:
```
📍 Recientes en [Ciudad]
```

**Esfuerzo:** ~3 horas  
**Valor:** Mayor relevancia

### Opción C: Categorización con Tags
Agregar campo `category` o tabla `tags` para filtrado real por categoría.

**Esfuerzo:** ~8-10 horas  
**Valor:** Búsqueda estructurada, mejor descubrimiento

---

## ✅ Checklist de Implementación

- [x] Modificar `SearchScreen` para cargar recientes en `initState()`
- [x] Agregar estados: `isLoadingRecent`, `recentGossips`, `currentQuery`
- [x] Refactorizar UI en método `_buildContent()` para manejar estados
- [x] Agregar loading indicator en `suffixIcon` del TextField
- [x] Agregar banner de error visible
- [x] Agregar contador de resultados
- [x] Implementar reset a recientes al limpiar TextField
- [x] Actualizar tests (15 tests)
- [x] Verificar análisis estático (0 issues)
- [x] Documentar feature

---

## 📝 Notas Técnicas

### Por Qué No Crear GetRecentGossips UseCase

Se decidió **NO crear un nuevo UseCase** porque:
1. `GetGossips` ya soporta `GossipQuery` flexible
2. `GossipQuery.defaultPublic()` ya retorna recientes (`orderBy: 'createdAt', descending: true`)
3. Evita duplicación de código
4. Mantiene arquitectura simple

Si en el futuro "recientes" necesita lógica diferente (ej: excluir gossips vistos), entonces sí se podría crear `GetRecentGossips`.

### API Deprecated

Se usó `.withValues(alpha: 0.3)` en lugar de `.withOpacity(0.3)` para compatibilidad con Flutter 3.27+.

---

## 🎓 Aprendizajes

1. **Reutilizar antes de crear:** Verificar si existe funcionalidad antes de implementar nueva
2. **Testing primero:** Actualizar tests junto con código, no después
3. **Estados claros:** Definir estados explícitamente mejora mantenibilidad
4. **UX progresivo:** Mostrar contenido útil en cada estado, no pantallas vacías

---

**Documentado por:** Claude Sonnet 4.5  
**Revisado por:** Alejo
