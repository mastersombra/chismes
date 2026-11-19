# Tools - Chismes App

> **Herramientas de automatización y auditoría del proyecto.**

---

## 📋 Índice

1. [Dependency Audit](#dependency-audit)
2. [Knowledge Graph](#knowledge-graph)

---

## Dependency Audit

### `audit_dependencies.sh`

**Propósito:** Verifica que se cumple la **Dependency Rule** de Clean Architecture.

### Reglas Verificadas

| Regla | Permitido | Verificación |
|-------|-----------|--------------|
| Presentation → Domain | ✅ SÍ | OK |
| Data → Domain | ✅ SÍ | OK |
| Cualquiera → Core | ✅ SÍ | OK |
| Domain → Presentation | ❌ NO | **VIOLACIÓN** |
| Domain → Data | ❌ NO | **VIOLACIÓN** |
| Presentation → Data | ❌ NO | **VIOLACIÓN** |
| Feature A → Feature B | ❌ NO | **VIOLACIÓN** |

---

### Uso

```bash
# Ejecutar auditoría
./tools/audit_dependencies.sh

# Modo verbose (muestra todos los archivos checados)
./tools/audit_dependencies.sh --verbose

# Output JSON (para CI/CD)
./tools/audit_dependencies.sh --json

# Ayuda
./tools/audit_dependencies.sh --help
```

---

### Output

#### ✅ Sin Violaciones (PASS)

```
═══════════════════════════════════════════════════════════
   Dependency Rule Audit - Chismes App
═══════════════════════════════════════════════════════════

═══════════════════════════════════════════════════════════
   Summary
═══════════════════════════════════════════════════════════

Files checked:     169
Violations:        0
Warnings:          0

✅ PASS: No dependency violations found!

Clean Architecture Dependency Rule: 100% compliant
Score: 10/10

═══════════════════════════════════════════════════════════
```

**Exit Code:** `0` (success)

---

#### ❌ Con Violaciones (FAIL)

```
❌ VIOLATION: Domain → Presentation
   File:   lib/features/gossip/domain/usecases/example.dart
   Import: ../../../presentation/controllers/controller.dart

═══════════════════════════════════════════════════════════
   Summary
═══════════════════════════════════════════════════════════

Files checked:     169
Violations:        1
Warnings:          0

❌ FAIL: 1 dependency violations found

Fix these violations to maintain Clean Architecture
Score: 7-8/10 (violations reduce score)

═══════════════════════════════════════════════════════════
```

**Exit Code:** `1` (número de violaciones)

---

#### ⚠️ Warnings

```
⚠️  WARNING: Presentation → Data Model
   File:   lib/features/gossip/presentation/screens/screen.dart
   Import: ../../data/models/gossip_model.dart
   Note:   Presentation should use Domain Entities, not Data Models
```

**Warnings NO fallan el script** (exit code 0), pero indican code smells.

---

### Integración CI/CD

#### GitHub Actions

```yaml
# .github/workflows/ci.yml
name: CI

on: [push, pull_request]

jobs:
  architecture-audit:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Audit Dependencies
        run: ./tools/audit_dependencies.sh
        
      - name: Upload JSON Report
        if: always()
        run: |
          ./tools/audit_dependencies.sh --json > audit-report.json
        
      - uses: actions/upload-artifact@v3
        if: always()
        with:
          name: dependency-audit
          path: audit-report.json
```

---

#### Pre-commit Hook

```bash
# .git/hooks/pre-commit
#!/bin/bash

echo "Running dependency audit..."
./tools/audit_dependencies.sh

if [ $? -ne 0 ]; then
  echo ""
  echo "❌ Dependency violations found. Commit aborted."
  echo "Fix violations or use 'git commit --no-verify' to skip."
  exit 1
fi

echo "✅ Dependency audit passed"
```

```bash
# Hacer ejecutable
chmod +x .git/hooks/pre-commit
```

---

#### Pre-push Hook (Recomendado)

```bash
# .git/hooks/pre-push
#!/bin/bash

echo "Running dependency audit before push..."
./tools/audit_dependencies.sh

if [ $? -ne 0 ]; then
  echo ""
  echo "❌ Dependency violations found. Push aborted."
  echo "Fix violations or use 'git push --no-verify' to skip."
  exit 1
fi

echo "✅ Dependency audit passed"
```

```bash
# Hacer ejecutable
chmod +x .git/hooks/pre-push
```

---

### JSON Output

Para integración con herramientas externas:

```bash
./tools/audit_dependencies.sh --json
```

```json
{
  "timestamp": "2026-11-12T10:30:00Z",
  "violations": [
    {
      "type": "CRITICAL",
      "rule": "Domain → Data",
      "file": "lib/features/gossip/domain/example.dart",
      "import": "../../data/models/model.dart",
      "message": "Domain layer cannot depend on Data layer"
    }
  ],
  "summary": {
    "totalFiles": 169,
    "violations": 1,
    "warnings": 0,
    "status": "FAIL"
  }
}
```

---

### Troubleshooting

#### Script no encuentra archivos

```bash
# Verificar que estás en la raíz del proyecto
pwd  # Debe mostrar: .../chismes

# Verificar que lib/ existe
ls lib/
```

#### Falsos positivos

Si el script reporta una violación incorrecta:

1. Verificar que el import es realmente una violación
2. Si es válido, agregar excepción al script
3. Abrir issue en el proyecto

---

## Knowledge Graph

### `knowledge-graph/`

**Propósito:** Genera un grafo de dependencias del proyecto.

Ver: `knowledge-graph/README.md` para detalles.

---

## 📚 Referencias

- **Clean Architecture:** https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html
- **Dependency Rule:** `.claude/ARCHITECTURE.md#dependency-rule`

---

**Última actualización:** 2026-11-12  
**Mantenedor:** Alejo
