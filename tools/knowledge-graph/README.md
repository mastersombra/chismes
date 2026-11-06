# Knowledge Graph para Proyecto Chismes

Herramienta para generar y analizar el grafo de conocimiento del proyecto.

## 🎯 ¿Qué hace?

- **Analiza** el código Dart del proyecto
- **Genera** un grafo de dependencias
- **Detecta** violaciones de arquitectura
- **Visualiza** la estructura del proyecto
- **Permite** búsquedas y análisis de impacto

## ⚡ Uso Automático (Recomendado)

**Ya está configurado con un hook automático.**

Cada vez que abres Claude Code:
1. Hook se ejecuta automáticamente (3 segundos, background)
2. Genera: `output/graph.json`
3. Claude lo lee cuando necesita contexto
4. **Tú no haces nada** ✅

**Ubicación del hook:** `chismes/.claude/hooks.json`

## 📦 Instalación

Ya está instalado si ejecutaste:

```bash
cd /Users/alejo/Documents/Piloto/chismes/tools/knowledge-graph
./install.sh
```

**Dependencias:**
- Python 3
- networkx
- matplotlib

## 🔧 Uso Manual (Opcional)

Si quieres ejecutarlo manualmente:

### Generar Grafo Completo

```bash
cd /Users/alejo/Documents/Piloto/chismes/tools/knowledge-graph
python3 generate_graph.py
```

**Output:**
- `output/graph.json` - Grafo en formato JSON
- `output/graph.png` - Visualización del grafo
- Estadísticas en consola

### Buscar en el Grafo

```bash
python3 generate_graph.py search "GossipRepository"
```

**Output ejemplo:**
```
🔍 Búsqueda: GossipRepository

  📄 features.gossip.data.repositories.gossip_repository_impl
     Tipo: repository | Layer: data | Feature: gossip
     Depende de: datasources.supabase_gossip_remote_data_source
     Usado por: usecases.create_gossip, usecases.get_gossips
```

### Análisis de Impacto

```bash
python3 generate_graph.py impact "features.gossip.domain.repositories.gossip_repository"
```

**Output ejemplo:**
```
💥 Análisis de Impacto: features.gossip.domain.repositories.gossip_repository

  Nivel de riesgo: HIGH
  Componentes afectados: 15

  Dependientes directos (4):
    - features.gossip.domain.usecases.create_gossip
    - features.gossip.domain.usecases.get_gossips
    - features.gossip.domain.usecases.update_gossip
    - features.gossip.domain.usecases.delete_gossip

  Dependientes indirectos (11):
    - features.gossip.presentation.controllers.add_gossip_controller
    - features.gossip.presentation.controllers.home_controller
    ...
```

## 📊 Estructura del Grafo

### Nodos

Cada archivo Dart es un nodo con:
- **id:** Path del archivo (relativo)
- **type:** entity, repository, usecase, controller, screen, etc.
- **layer:** domain, data, presentation, core
- **feature:** gossip, location, home, auth, core

### Relaciones (Edges)

- **imports:** Cuando un archivo importa otro

### Formato JSON

```json
{
  "nodes": [
    {
      "id": "features.gossip.domain.repositories.gossip_repository",
      "type": "repository",
      "layer": "domain",
      "feature": "gossip",
      "file": "features/gossip/domain/repositories/gossip_repository.dart"
    }
  ],
  "edges": [
    {
      "from": "features.gossip.data.repositories.gossip_repository_impl",
      "to": "features.gossip.domain.repositories.gossip_repository",
      "relation": "imports"
    }
  ],
  "stats": {
    "total_nodes": 80,
    "total_edges": 200
  }
}
```

## 🔍 Análisis Disponibles

### 1. Estadísticas por Feature

```
gossip: 45 nodos, 120 relaciones
location: 18 nodos, 35 relaciones
home: 12 nodos, 25 relaciones
```

### 2. Detección de Violaciones

Detecta violaciones de Clean Architecture:

- ❌ **Presentation → Data** (directo)
- ❌ **Data → Presentation**
- ❌ **Features interdependientes** (sin pasar por Core)

### 3. Análisis de Impacto

Calcula:
- Dependencias directas
- Dependientes directos
- Dependientes indirectos (transitivos)
- Nivel de riesgo: LOW, MEDIUM, HIGH, CRITICAL

**Niveles de riesgo:**
- **LOW:** 0 componentes afectados
- **MEDIUM:** 1-4 componentes afectados
- **HIGH:** 5-14 componentes afectados
- **CRITICAL:** 15+ componentes afectados

## 📈 Visualización

El grafo se visualiza con colores por layer:

- 🟢 **Verde:** Domain
- 🔵 **Azul:** Data
- 🟠 **Naranja:** Presentation
- 🟣 **Púrpura:** Core
- ⚫ **Gris:** Shared

**Ver:** `output/graph.png`

## 🎯 Casos de Uso

### Entender una Feature

```bash
python3 generate_graph.py search "gossip"
# Ver todos los componentes y sus relaciones
```

### Antes de Refactorizar

```bash
# ¿Qué se rompe si cambio GossipRepository?
python3 generate_graph.py impact "features.gossip.domain.repositories.gossip_repository"

# Ver impacto → decidir si es seguro
```

### Detectar Problemas

```bash
# Generar grafo completo
python3 generate_graph.py

# Revisar sección "VIOLACIONES DE ARQUITECTURA"
# Fix violaciones encontradas
```

### Para Claude

El grafo se genera automáticamente al abrir Claude Code.

Claude lo lee de: `output/graph.json`

Esto permite a Claude:
- Conocer la estructura del proyecto
- Ver dependencias entre archivos
- Analizar impacto de cambios
- Responder mejor tus preguntas

## 🐛 Troubleshooting

### Error: ModuleNotFoundError

```bash
# Instalar dependencias
pip3 install networkx matplotlib
```

### Error: No such file or directory

```bash
# Asegurarse de estar en el directorio correcto
cd /Users/alejo/Documents/Piloto/chismes/tools/knowledge-graph
```

### Visualización no se genera

```bash
# Instalar backend de matplotlib
pip3 install matplotlib pillow
```

### Grafo vacío

```bash
# Verificar que lib/ existe y tiene archivos .dart
ls -la ../../lib/
```

### Hook no se ejecuta

```bash
# Verificar que existe:
cat ../../.claude/hooks.json

# Ejecutar manualmente para ver errores:
python3 generate_graph.py
```

## 📚 Referencias

- **NetworkX:** https://networkx.org/
- **Clean Architecture:** https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html
- **Claude Code Hooks:** Ver `.claude/GRAFO_AUTOMATICO.md`

---

**Autor:** Alejo  
**Última actualización:** 2026-10-20  
**Uso:** Automático vía hook + Manual opcional
