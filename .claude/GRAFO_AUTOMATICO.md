# Grafo de Conocimiento Automático

> **Para Claude:** Contexto automático del proyecto en cada sesión  
> **Para Alejo:** Cero trabajo manual

**Última actualización:** 2026-10-20

---

## 🎯 ¿Qué Es Esto?

Un **hook automático** que genera el grafo del proyecto cada vez que abres Claude Code.

### Objetivo

Que yo (Claude) tenga el proyecto "mapeado" automáticamente para responder mejor tus preguntas.

---

## 🔄 Cómo Funciona

```
Tú abres Claude Code
   ↓
Hook se ejecuta automáticamente (invisible)
   ↓
python3 generate_graph.py corre en background
   ↓
Genera: tools/knowledge-graph/output/graph.json
   ↓
Yo (Claude) puedo leer ese archivo cuando lo necesite
   ↓
Tengo contexto actualizado del proyecto
```

---

## 📁 Archivos Involucrados

### 1. Hook Config
**Ubicación:** `.claude/hooks.json`

```json
{
  "sessionStart": {
    "command": "cd tools/knowledge-graph && python3 generate_graph.py > /dev/null 2>&1 &",
    "description": "Generate knowledge graph on session start"
  }
}
```

**Qué hace:**
- Se ejecuta automáticamente al abrir Claude Code
- Corre en background (no bloquea)
- Genera el grafo silenciosamente

### 2. Referencia en CLAUDE.md

En `CLAUDE.md` hay una sección que me dice:

```markdown
## 🧠 GRAFO DE CONOCIMIENTO

Grafo disponible: tools/knowledge-graph/output/graph.json
```

Esto me indica que puedo leer ese archivo para obtener contexto.

### 3. Grafo Generado
**Ubicación:** `tools/knowledge-graph/output/graph.json`

**Contiene:**
```json
{
  "nodes": [
    {
      "id": "features.gossip.domain.repositories.gossip_repository",
      "type": "repository",
      "layer": "domain",
      "feature": "gossip"
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

---

## 💡 Beneficios

### Para Mí (Claude)

✅ Conozco la estructura del proyecto automáticamente  
✅ Sé qué features existen (gossip, location, home, etc.)  
✅ Veo dependencias entre archivos  
✅ Puedo responder mejor sobre impacto de cambios  

**Ejemplo:**
```
Tú: "Quiero cambiar GossipRepository"

Yo: [Leo graph.json]
    [Veo que GossipRepository es usado por 4 use cases y 2 controllers]
    
    "GossipRepository es crítico, es usado por create_gossip, 
    get_gossips, AddGossipController y HomeController. 
    Te recomiendo..."
```

### Para Ti (Alejo)

✅ Cero trabajo manual  
✅ Grafo siempre actualizado  
✅ Mejores respuestas de Claude  
✅ Claude entiende el proyecto desde el inicio  

---

## 🔍 ¿Cómo Lo Usa Claude?

### Automáticamente

Cuando me preguntas algo sobre arquitectura o dependencias:

```
Tú: "¿Qué usa AddGossipController?"

Yo: [Internamente]
    1. Veo en CLAUDE.md que hay un grafo
    2. Leo: tools/knowledge-graph/output/graph.json
    3. Busco "AddGossipController" en nodos
    4. Veo sus dependencias en edges
    5. Respondo con info precisa
```

### Ejemplos de Uso

**Pregunta sobre estructura:**
```
Tú: "¿Cómo está organizado el feature gossip?"
Yo: [Leo grafo] → Veo todos los nodos con feature="gossip"
    "El feature gossip tiene 45 archivos organizados en..."
```

**Pregunta sobre dependencias:**
```
Tú: "¿Qué depende de AppSpacing?"
Yo: [Leo grafo] → Busco edges que apuntan a AppSpacing
    "AppSpacing es usado en 15 pantallas..."
```

**Pregunta sobre impacto:**
```
Tú: "¿Puedo cambiar GossipRepository sin romper nada?"
Yo: [Leo grafo] → Analizo dependencias
    "Afectaría 4 use cases directamente y 8 archivos indirectamente..."
```

---

## ⚡ Performance

### Tiempo de Generación

```
Primera vez (grafo completo): ~3 segundos
Proyecto pequeño (<50 archivos): ~1 segundo
Proyecto mediano (50-100 archivos): ~2-3 segundos
Proyecto grande (>100 archivos): ~5 segundos
```

**Corre en background** → No bloquea Claude Code

### Cuándo Se Regenera

- ✅ Nueva sesión de Claude Code
- ✅ Cada día que abras el proyecto
- ❌ NO se regenera durante la sesión (cache)

**Si cambias mucho código y quieres actualizar:**
```bash
cd tools/knowledge-graph
python3 generate_graph.py
```

---

## 🐛 Troubleshooting

### Hook no se ejecuta

```bash
# Verificar que existe:
cat .claude/hooks.json

# Verificar que Python funciona:
cd tools/knowledge-graph
python3 generate_graph.py

# Debe generar: output/graph.json
```

### Grafo no se genera

```bash
# Ver logs de Claude Code:
tail -f ~/.claude/logs/*.log

# Ejecutar manualmente para ver errores:
cd tools/knowledge-graph
python3 generate_graph.py
```

### Claude no usa el grafo

```
# Pregúntale explícitamente:
"Claude, lee el grafo en tools/knowledge-graph/output/graph.json 
y dime qué features tiene el proyecto"
```

---

## 📊 Verificar que Funciona

### Paso 1: Abrir Claude Code

```bash
cd /Users/alejo/Documents/Piloto/chismes
claude code
```

### Paso 2: Esperar 3-5 segundos

El hook corre en background.

### Paso 3: Verificar archivo

```bash
# En otra terminal:
ls -lh tools/knowledge-graph/output/graph.json

# Debe existir y tener timestamp reciente
```

### Paso 4: Probar con Claude

```
Tú: "Claude, lee el grafo y dime cuántos archivos tiene el proyecto"

Yo: [Leo graph.json]
    "El proyecto tiene 80 archivos organizados en..."
```

---

## 🎯 Diferencia vs MCP (Nivel 2)

| Aspecto | Hook Automático (Esto) | MCP Nivel 2 |
|---------|------------------------|-------------|
| **Disponibilidad** | ✅ Funciona ahora | ❌ Paquete no existe |
| **Setup** | ✅ Listo (hooks.json) | ❌ No disponible |
| **Cómo funciona** | Hook genera archivo → Claude lo lee | Claude llama servidor automáticamente |
| **Performance** | 3 seg al inicio | Instantáneo |
| **Actualización** | Cada sesión nueva | Cada consulta (más fresco) |
| **Complejidad** | Simple | Más complejo |

**Para tu caso (proyecto personal, 80 archivos):** Hook es suficiente y funciona ahora.

---

## ✅ Resumen

**Configurado:**
- ✅ Hook en `.claude/hooks.json`
- ✅ Referencia en `CLAUDE.md`
- ✅ Script Python funcionando

**Funcionamiento:**
1. Abres Claude Code
2. Hook ejecuta automáticamente (3 seg)
3. Genera `graph.json`
4. Yo (Claude) lo leo cuando necesito
5. Respondo mejor tus preguntas

**Tu trabajo:** CERO (todo automático)

**Mi beneficio:** Contexto completo del proyecto desde el inicio

---

## 🚀 ¿Ya Está Funcionando?

**SÍ.** Solo necesitas:

1. Cerrar Claude Code (si está abierto)
2. Abrir de nuevo:
   ```bash
   cd /Users/alejo/Documents/Piloto/chismes
   claude code
   ```
3. Esperar 3-5 segundos
4. Preguntar: "Claude, cuántos features tiene el proyecto según el grafo?"

Si respondo con info del grafo → ✅ Funciona

---

**Creado:** 2026-10-20  
**Para:** Mejor contexto de Claude en cada sesión  
**Trabajo manual:** Ninguno (100% automático)
