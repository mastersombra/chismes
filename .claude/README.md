# .claude/ Documentation Structure

> **Estructura de documentación del proyecto Chismes.**

Esta carpeta contiene documentación modular organizada por temas. El archivo principal **CLAUDE.md** (en el directorio raíz) se carga automáticamente y contiene quick references con el índice maestro.

## 📚 Archivos

| Archivo | Tamaño | Contenido | Cuándo Leer |
|---------|--------|-----------|-------------|
| **ARCHITECTURE.md** | 4.2k | Arquitectura detallada, estructura de features, capas | Al iniciar en proyecto o antes de modificar arquitectura |
| **PATTERNS.md** | 16k | Repository, Result, DI, Data Sources, Controllers | Antes de implementar nuevos features o refactorizar |
| **TESTING.md** | 15k | AAA pattern, Mocks, Coverage, Anti-patterns | Antes de escribir tests o revisar coverage |
| **UI_STANDARDS.md** | 15k | AppSpacing, FormValidators, Portrait-only, AppColors | Antes de trabajar en UI/widgets |
| **SECURITY.md** | 11k | Secrets, Validación, RLS, SQL injection | Antes de manejar datos sensibles o autenticación |
| **SUPABASE.md** | 70k | Backend, migraciones, RLS, nomenclatura | Antes de tocar base de datos o backend |
| **WORKFLOWS.md** | 19k | Agregar feature/migración, comandos, flows | Como referencia de comandos y tareas comunes |

## 🎯 Flujo de Uso

### Nueva Sesión de Claude
1. **CLAUDE.md** se carga automáticamente (15.7k chars, quick reference)
2. Contiene conceptos esenciales e índice maestro
3. Referencias a archivos específicos para detalles

### Trabajando en el Proyecto
```
¿Necesitas implementar feature? → Lee PATTERNS.md + WORKFLOWS.md
¿Necesitas escribir tests?      → Lee TESTING.md
¿Necesitas modificar UI?        → Lee UI_STANDARDS.md
¿Necesitas agregar migración?   → Lee SUPABASE.md + WORKFLOWS.md
¿Necesitas manejar secrets?     → Lee SECURITY.md
```

## 📊 Historial de Versiones

### v3.0 - 2026-10-20 (Reorganización)
- **Cambio:** Dividir CLAUDE.md monolítico (43k) en 8 archivos modulares
- **Razón:** CLAUDE.md excedía límite de 40k chars
- **Resultado:** CLAUDE.md compacto (15.7k) + 7 archivos especializados
- **Ventajas:** 
  - Carga instantánea
  - Mejor descubribilidad
  - Escalable
  - Mantenible

### v2.0 - 2026-10-19 (Consolidación)
- Fusión de múltiples docs en CLAUDE.md único

### v1.0 - Inicial
- CLAUDE.md original

## 🔄 Mantenimiento

### Agregar Nuevo Tema
1. Crear nuevo archivo: `.claude/NUEVO_TEMA.md`
2. Agregar entrada en esta tabla
3. Referenciar desde CLAUDE.md índice maestro
4. NO modificar contenido de CLAUDE.md (solo índice si es necesario)

### Actualizar Contenido
- Actualizar archivo específico (ej: `TESTING.md`)
- NO tocar CLAUDE.md a menos que sea quick reference esencial
- Mantener esta tabla actualizada

### Reglas
- ✅ CLAUDE.md debe permanecer < 25k chars (margen de seguridad)
- ✅ Archivos específicos pueden crecer libremente
- ✅ Usar links relativos entre archivos
- ❌ NO duplicar contenido entre archivos
- ❌ NO mover contenido detallado a CLAUDE.md

## 📖 Nomenclatura

```
SCREAMING_SNAKE_CASE.md    # Archivos principales
PascalCase.md              # No usado en este proyecto
snake_case.md              # No usado en este proyecto
```

Usamos `SCREAMING_SNAKE_CASE` para archivos de documentación principal porque:
- Fácil de distinguir de código
- Convención de archivos de configuración/docs (README, LICENSE, etc.)
- Consistente con CLAUDE.md

## 🎓 Para Nuevos Desarrolladores

1. Leer `CLAUDE.md` (raíz del proyecto) - 15 min
2. Leer `ARCHITECTURE.md` - 10 min
3. Leer `PATTERNS.md` - 20 min
4. Navegar otros archivos según necesidad

**Total tiempo inicial:** ~45 min para estar productivo

---

**Última actualización:** 2026-10-20  
**Mantenedor:** Alejo
