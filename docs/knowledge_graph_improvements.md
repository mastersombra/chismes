# Knowledge Graph: Mejoras y Fixes

**Fecha:** 2026-10-22  
**Status:** ✅ IMPLEMENTADO  
**Versión:** 2.0

---

## 📋 Problema Original

### Análisis de IA:

**Chismes:** 231 nodos  
**Gestia:** 149 nodos (proyecto 20x más grande)

**Problema identificado:**
- Script de Chismes creaba "nodos fantasmas" para imports no resueltos
- Imports a paquetes externos o paths incorrectos creaban nodos sin archivo
- Inflación artificial: 231 nodos vs ~119 archivos reales
- Gestia usa grafo semántico (conceptos), Chismes usaba grafo sintáctico (archivos)

---

## ✅ Solución Implementada

### Fix 1: Eliminar Nodos Fantasmas

**Problema:**
```python
# ANTES (bug)
def _extract_dependencies(self, node_id, content):
    dep_node_id = self._resolve_import(node_id, import_path)
    if dep_node_id:
        self.graph.add_edge(node_id, dep_node_id)  # ❌ Crea nodo si no existe
```

**Solución:**
```python
# AHORA (fixed)
def __init__(self):
    self.pending_edges = []  # Guardar edges temporalmente

def _extract_dependencies(self, node_id, content):
    dep_node_id = self._resolve_import(node_id, import_path)
    if dep_node_id:
        self.pending_edges.append((node_id, dep_node_id))  # ✅ Guardar

def analyze_project(self):
    # Paso 1: Analizar archivos (crear nodos)
    for dart_file in self.lib_path.rglob("*.dart"):
        self._analyze_file(dart_file)

    # Paso 2: Crear edges solo entre nodos existentes
    for source, target in self.pending_edges:
        if target in self.graph:  # ✅ Verificar que existe
            self.graph.add_edge(source, target)
```

**Resultado:**
- ✅ **119 nodos** (antes: 231)
- ✅ **0 nodos fantasmas** (antes: ~112)
- ⚠️ **244 imports no resueltos** detectados (antes: ocultos)

---

### Fix 2: Agregar Evidence Semántica

**Problema:**
- Nodos solo tenían: `id`, `file`, `type`, `layer`, `feature`
- Sin información sobre QUÉ contiene el archivo
- Difícil entender qué hace cada nodo sin leer el archivo

**Solución:**
```python
def _extract_evidence(self, content, node_type):
    """Extrae metadata semántica del código"""
    evidence = []
    detail = ""

    # Extraer clase principal
    class_match = re.search(r'class\s+(\w+)', content)
    if class_match:
        class_name = class_match.group(1)
        evidence.append(f"class {class_name}")
        detail = class_name

    # Extraer extends/implements
    extends_match = re.search(r'extends\s+(\w+)', content)
    if extends_match:
        evidence.append(f"extends {extends_match.group(1)}")

    # Extraer métodos públicos principales
    methods = re.findall(r'(?:Future<\w+>|void|String|\w+)\s+(\w+)\s*\([^)]*\)', content)
    public_methods = [m for m in methods if not m.startswith('_')]
    evidence.extend([f"method:{m}" for m in public_methods[:3]])

    # Tipo específico
    if node_type == "entity":
        # Buscar propiedades
        properties = re.findall(r'final\s+(\w+)\s+(\w+);', content)
        evidence.extend([f"field:{prop[1]}" for prop in properties[:3]])

    return evidence[:8], detail
```

**Resultado:**
Nodos ahora tienen:
```json
{
    "id": "features.gossip.domain.entities.gossip",
    "file": "features/gossip/domain/entities/gossip.dart",
    "type": "entity",
    "layer": "domain",
    "feature": "gossip",
    "evidence": [
        "class Gossip",
        "field:id",
        "field:subject",
        "field:content"
    ],
    "detail": "Gossip"
}
```

---

## 📊 Comparación: Antes vs Ahora

### Métricas:

| Métrica | Antes | Ahora | Mejora |
|---------|-------|-------|--------|
| **Nodos totales** | 231 | **119** | ✅ -48% |
| **Nodos reales** | ~119 | 119 | ✅ 100% |
| **Nodos fantasmas** | ~112 | **0** | ✅ Eliminados |
| **Metadata semántica** | ❌ | ✅ Evidence | ✅ Agregada |
| **Detail field** | ❌ | ✅ Clase principal | ✅ Agregado |

### Proporción vs Gestia:

- **Chismes:** 119 nodos (file-based)
- **Gestia:** 149 nodos (concept-based, 20x más grande)
- **Proporción:** ~0.8x (razonable para proyecto más pequeño)

---

## 🎯 Beneficios para Claude

Como Claude que usa el grafo, ahora puedo:

### ✅ Antes (solo sintáctico):
```json
{
    "id": "gossip.domain.entities.gossip",
    "file": "gossip/domain/entities/gossip.dart",
    "type": "entity"
}
```

**Pregunta:** "¿Qué hace este nodo?"  
**Respuesta:** "No sé, necesito leer el archivo"

### ✅ Ahora (sintáctico + semántico):
```json
{
    "id": "gossip.domain.entities.gossip",
    "file": "gossip/domain/entities/gossip.dart",
    "type": "entity",
    "layer": "domain",
    "feature": "gossip",
    "evidence": [
        "class Gossip",
        "field:id",
        "field:subject",
        "field:content"
    ],
    "detail": "Gossip"
}
```

**Pregunta:** "¿Qué hace este nodo?"  
**Respuesta:** "Es la entity Gossip, tiene campos id, subject, content"

**Sin necesidad de leer el archivo.**

---

## 🚀 Enfoque Híbrido: File-based + Semántico

### Ventajas del Enfoque Actual:

| Aspecto | Gestia (semántico) | Chismes (híbrido) |
|---------|-------------------|-------------------|
| **Mantenimiento** | Manual | ✅ Automático |
| **Actualización** | Puede quedar stale | ✅ Siempre actualizado |
| **Granularidad** | Conceptos | ✅ Archivos + metadata |
| **Evidence** | Sí | ✅ Sí (agregado) |
| **Dependencias** | Lógicas | ✅ Reales (código) |
| **Impacto de cambios** | Aproximado | ✅ Exacto (file-level) |

### Lo Mejor de Ambos Mundos:

✅ **File-based:** Automático, siempre actualizado, dependencias reales  
✅ **Semántico:** Metadata rica (evidence, detail, type)

---

## 📁 Estructura del Grafo Mejorado

### Nodos (119 archivos reales):

```json
{
    "id": "features.gossip.presentation.controllers.add_gossip_controller",
    "file": "features/gossip/presentation/controllers/add_gossip_controller.dart",
    "type": "controller",
    "layer": "presentation",
    "feature": "gossip",
    "evidence": [
        "class AddGossipController",
        "extends ChangeNotifier",
        "method:submitGossip",
        "method:selectLocation",
        "method:uploadImage"
    ],
    "detail": "AddGossipController"
}
```

### Edges (188 dependencias reales):

```json
{
    "from": "features.gossip.presentation.controllers.add_gossip_controller",
    "to": "features.gossip.domain.usecases.create_gossip",
    "relation": "imports"
}
```

### Stats:

```json
{
    "stats": {
        "total_nodes": 119,
        "total_edges": 188,
        "files_analyzed": 119,
        "phantom_nodes_avoided": 244
    }
}
```

---

## 🔍 Casos de Uso

### Para Claude:

**1. Entender arquitectura rápidamente:**
```
Q: "¿Qué features hay?"
A: auth (32 nodos), gossip (35), location (13), home (3), search (1)
```

**2. Encontrar nodos por tipo:**
```
Q: "¿Cuántas entities hay?"
A: [filtrar por type: "entity"]
- gossip.domain.entities.gossip
- gossip.domain.entities.create_gossip_input
- ...
```

**3. Ver dependencias:**
```
Q: "Si cambio GossipModel, ¿qué afecto?"
A: [impact_analysis]
- 5 dependientes directos
- 12 dependientes indirectos
- Risk level: HIGH
```

**4. Detectar violaciones arquitectónicas:**
```
Q: "¿Hay violaciones de Clean Architecture?"
A: [detect_violations]
- ✅ No se detectaron violaciones
```

---

## 📊 Estadísticas por Feature

```
auth: 32 nodos
  - domain: 8
  - data: 10
  - presentation: 14

gossip: 35 nodos
  - domain: 12
  - data: 10
  - presentation: 13

location: 13 nodos
  - domain: 4
  - data: 4
  - presentation: 5

core: 33 nodos
  - services: 8
  - theme: 5
  - config: 4
  - di: 3
  - logging: 4
  - error: 5
  - validation: 4
```

---

## 🎓 Lecciones Aprendidas

### 1. Nodos Fantasmas son Ruido

**Problema:**
- Imports externos (package:) crean nodos sin archivo
- Imports a paths incorrectos crean nodos sin archivo
- Inflación artificial de conteo

**Solución:**
- Two-pass: Primero crear nodos (archivos reales), luego edges
- Verificar existencia antes de crear edge
- Reportar imports no resueltos (útil para debugging)

### 2. Metadata Semántica es Crítica

**Problema:**
- Solo tener `id` y `file` no es suficiente
- Necesito saber QUÉ hace el archivo sin leerlo

**Solución:**
- Extraer evidence: clase, extends, métodos, campos
- Agregar detail: nombre de clase principal
- Permite búsqueda y filtrado rápido

### 3. File-based vs Concept-based

**No son opuestos, son complementarios:**
- File-based: Automático, preciso, dependencias reales
- Concept-based: Alto nivel, semántico, fácil de entender

**Solución híbrida:**
- Nodos = Archivos (automático)
- Metadata = Semántica (evidence, detail)
- Agrupación = Features/Layers (contexto)

---

## 🚀 Mejoras Futuras (Opcional)

### 1. Clustering por Similitud

Agrupar nodos similares:
- Entities con fields similares
- Controllers con mismas dependencias
- Screens con misma estructura

### 2. Métricas de Complejidad

Agregar por nodo:
- Líneas de código
- Complejidad ciclomática
- Número de dependencias

### 3. Análisis de Cohesión

Detectar:
- Features altamente acoplados
- Nodos aislados (baja cohesión)
- God classes (muchas dependencias)

### 4. Visualización Interactiva

- Web viewer (D3.js)
- Filtros por feature/layer/type
- Zoom a subgrafos
- Click en nodo → Ver código

---

## ✅ Resumen Final

### Implementación Completada:

1. ✅ **Fix nodos fantasmas**
   - Two-pass analysis
   - Verificación de existencia
   - Reporte de imports no resueltos

2. ✅ **Evidence semántica**
   - Extracción de clase, extends, métodos
   - Campos para entities
   - Detail field (nombre de clase)

3. ✅ **Grafo mejorado**
   - 119 nodos (100% reales)
   - 188 edges (dependencias reales)
   - Metadata rica para búsqueda

### Resultado:

**Grafo híbrido (file-based + semántico):**
- ✅ Automático (no requiere mantenimiento)
- ✅ Actualizado (siempre refleja código actual)
- ✅ Semántico (metadata rica)
- ✅ Útil para Claude (búsqueda, impacto, arquitectura)
- ✅ Comparable con Gestia (119 vs 149 nodos, proporción razonable)

---

**FIN DEL DOCUMENTO**
