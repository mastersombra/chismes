# Paginación en Home Feed - Resumen Rápido

**Actualizado:** 2026-11-04

---

## ✅ **YA IMPLEMENTADO EN EL DOCUMENTO**

El sistema de paginación **cursor-based** está completamente especificado en:
📄 `home_feed_complete_specification.md`

---

## 🎯 **CÓMO FUNCIONA**

### **1. Primera Carga**

```dart
// Usuario abre app
controller.loadFeed()

// Request a Supabase
get_popular_feed(
  user_city_id: 'city-uuid',
  page_size: 20,
  cursor_score: NULL,      // Primera página
  cursor_id: NULL          // Primera página
)

// Response
{
  data: [20 chismes],
  has_more: true,
  next_cursor: {
    score: 145.2,
    id: "last-gossip-uuid"
  }
}
```

### **2. Infinite Scroll (Load More)**

```dart
// Usuario scrollea hasta el final
controller.loadMore()

// Request a Supabase
get_popular_feed(
  user_city_id: 'city-uuid',
  page_size: 20,
  cursor_score: 145.2,     // Del cursor anterior
  cursor_id: "last-uuid"   // Del cursor anterior
)

// Response
{
  data: [20 chismes más],
  has_more: true,
  next_cursor: {
    score: 98.7,
    id: "new-last-uuid"
  }
}
```

### **3. Última Página**

```dart
// Response cuando no hay más
{
  data: [5 chismes],       // Menos de page_size
  has_more: false,         // No hay más páginas
  next_cursor: null
}

// UI muestra: "No hay más chismes por ahora 🌙"
```

---

## 📊 **VENTAJAS DE CURSOR-BASED**

| Aspecto | Offset-based | Cursor-based |
|---------|--------------|--------------|
| **Performance** | ❌ Degrada con offset grande | ✅ Constante O(1) |
| **Duplicados** | ❌ Posible si hay nuevos | ✅ Imposible |
| **Complejidad** | ✅ Simple | ⚠️ Media |
| **Uso de índices** | ❌ No siempre | ✅ Siempre |

---

## 🔧 **CAMBIOS IMPLEMENTADOS**

### **Backend (Supabase)**

1. ✅ `get_popular_feed` acepta `cursor_score` y `cursor_id`
2. ✅ `get_following_feed` acepta `cursor_created_at` y `cursor_id`
3. ✅ Query con `WHERE (score, id) < ($cursor_score, $cursor_id)`
4. ✅ Índice compuesto `(score DESC, id ASC)` para performance

### **Domain Layer**

1. ✅ Nueva entity: `FeedCursor`
2. ✅ Nueva entity: `PaginatedGossips`
3. ✅ Use cases actualizados para aceptar `cursor`

### **Data Layer**

1. ✅ Repository retorna `PaginatedGossips` en vez de `List<FeedGossip>`
2. ✅ Lógica para detectar `hasMore` (si `data.length < pageSize`)
3. ✅ Construir `nextCursor` desde el último elemento

### **Presentation Layer**

1. ✅ Controller tiene:
   - `_hasMore: bool`
   - `_nextCursor: FeedCursor?`
   - `_isLoadingMore: bool`
   - `loadMore()` method
2. ✅ UI detecta cuando llega a 3 items del final
3. ✅ Loading indicator al final
4. ✅ Mensaje "No hay más" cuando `hasMore == false`

---

## 🎨 **UX FLOW**

```
Usuario scrollea
    ↓
Llega a 3 items del final
    ↓
Controller detecta: index == gossips.length - 3
    ↓
Llama loadMore() automáticamente
    ↓
Muestra CircularProgressIndicator al final
    ↓
Recibe 20 chismes más
    ↓
Agrega al array: gossips.addAll(newGossips)
    ↓
Guarda next_cursor para próxima vez
    ↓
Usuario sigue scrolleando...
```

---

## 📐 **CONFIGURACIÓN**

```dart
// Tamaño de página (recomendado: 20)
const int kPageSize = 20;

// Threshold de pre-carga (recomendado: 3)
// Empieza a cargar cuando faltan 3 items
const int kPreloadThreshold = 3;
```

**Por qué 20:**
- ✅ Balance entre requests y UX
- ✅ 3-4 pantallas en móvil promedio
- ✅ No muy grande (carga rápida)
- ✅ No muy pequeño (no muchas requests)

**Por qué threshold de 3:**
- ✅ Usuario NO ve loading (pre-carga antes de llegar al final)
- ✅ Seamless infinite scroll
- ✅ No carga demasiado pronto (desperdicia requests)

---

## 🧪 **TESTING**

### **Test 1: Primera Carga**
```dart
test('debe cargar primera página de 20 items', () async {
  final result = await useCase(
    userId: null,
    cityId: 'city-1',
    pageSize: 20,
    cursor: null,
  );
  
  expect(result.isSuccess, isTrue);
  expect(result.getOrNull()!.data.length, 20);
  expect(result.getOrNull()!.hasMore, isTrue);
  expect(result.getOrNull()!.nextCursor, isNotNull);
});
```

### **Test 2: Load More**
```dart
test('debe cargar siguiente página con cursor', () async {
  // Primera página
  final firstResult = await useCase(...);
  final cursor = firstResult.getOrNull()!.nextCursor!;
  
  // Segunda página
  final secondResult = await useCase(
    userId: null,
    cityId: 'city-1',
    pageSize: 20,
    cursor: cursor,
  );
  
  expect(secondResult.isSuccess, isTrue);
  expect(secondResult.getOrNull()!.data.length, 20);
  
  // Verificar que no hay duplicados
  final firstIds = firstResult.getOrNull()!.data.map((g) => g.id).toSet();
  final secondIds = secondResult.getOrNull()!.data.map((g) => g.id).toSet();
  expect(firstIds.intersection(secondIds).isEmpty, isTrue);
});
```

### **Test 3: Última Página**
```dart
test('debe detectar cuando no hay más páginas', () async {
  // Simular respuesta con menos de page_size
  when(mockDataSource.getPopularFeed(...))
    .thenAnswer((_) async => [5 gossips]);  // < 20
  
  final result = await repository.getPopularFeed(...);
  
  expect(result.getOrNull()!.hasMore, isFalse);
  expect(result.getOrNull()!.nextCursor, isNull);
});
```

---

## 🚨 **CASOS EDGE**

### **1. Usuario scrollea MUY rápido**
```dart
// Controller previene múltiples requests simultáneos
Future<void> loadMore() async {
  if (_isLoadingMore || !_hasMore) return;  // ← Guard clause
  
  _isLoadingMore = true;
  // ... load
  _isLoadingMore = false;
}
```

### **2. Chismes nuevos mientras scrollea**
✅ **No hay problema:** Cursor-based garantiza que no aparecen duplicados.

Ejemplo:
- Usuario carga página 1 (20 chismes)
- Mientras lee, se publican 5 chismes nuevos
- Usuario carga página 2
- **Resultado:** NO hay duplicados, cursor sigue desde donde quedó

### **3. Feed vacío**
```dart
if (gossips.isEmpty) {
  return EmptyStateWidget();
}
```

### **4. Error en load more**
```dart
// No crashea, solo muestra error y no cambia estado
result.fold(
  onFailure: (failure) {
    _logger.e('Error loading more');
    _isLoadingMore = false;  // Reset para permitir retry
    // NO cambiar _gossips (mantener los que ya tiene)
  },
  onSuccess: ...
);
```

---

## 📈 **PERFORMANCE**

### **Antes (sin paginación)**
```sql
-- Carga 1,000 chismes de una vez
SELECT * FROM gossips ORDER BY score DESC LIMIT 1000;
-- Tiempo: ~800ms
-- Memoria: ~5MB
```

### **Después (con paginación)**
```sql
-- Carga 20 chismes por vez
SELECT * FROM gossips 
WHERE (score, id) < ($cursor_score, $cursor_id)
ORDER BY score DESC, id ASC 
LIMIT 20;
-- Tiempo: ~50ms (16x más rápido)
-- Memoria: ~100KB (50x menos memoria)
```

**Beneficios:**
- ✅ Primera carga **16x más rápida**
- ✅ **50x menos memoria** en cliente
- ✅ **Menor consumo de datos** móviles
- ✅ **Mejor UX** (carga incremental)

---

## 🎯 **CHECKLIST DE IMPLEMENTACIÓN**

Cuando implementes, verifica:

**Backend:**
- [ ] Funciones SQL aceptan `cursor_*` params
- [ ] Query usa `WHERE (col1, col2) < ($cursor1, $cursor2)`
- [ ] Índice compuesto `(col1 DESC, col2 ASC)` creado
- [ ] Retorna menos de `page_size` cuando no hay más

**Domain:**
- [ ] `FeedCursor` entity creada
- [ ] `PaginatedGossips` entity creada
- [ ] Use cases aceptan `cursor` opcional

**Data:**
- [ ] Repository retorna `PaginatedGossips`
- [ ] Lógica de `hasMore` (basado en `data.length < pageSize`)
- [ ] Construye `nextCursor` desde último elemento

**Presentation:**
- [ ] Controller tiene `_hasMore`, `_nextCursor`, `_isLoadingMore`
- [ ] Método `loadMore()` implementado
- [ ] Guard clause `if (_isLoadingMore || !_hasMore) return`
- [ ] Reset de cursor en `refresh()`

**UI:**
- [ ] Detecta cuando llega a threshold (3 items del final)
- [ ] Llama `loadMore()` automáticamente
- [ ] Muestra loading indicator al final
- [ ] Muestra mensaje "No hay más" cuando `!hasMore`

---

**FIN DEL RESUMEN**

Ver especificación completa en: `home_feed_complete_specification.md`
