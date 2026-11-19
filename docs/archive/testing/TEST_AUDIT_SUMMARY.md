# Test Audit - Resumen Ejecutivo

**Fecha:** 2026-11-17  
**Coverage:** 78.9% (objetivo: 90%)  
**Tests:** 1,897 totales | 1,846 pasando | 51 fallando

---

## 🎯 QUICK WINS

### 🔴 Hacer HOY (3-4 horas)

1. **Arreglar tests fallando** (51 tests - 2.7%)
   ```bash
   flutter test --reporter expanded | grep "FAIL"
   ```

2. **Home domain usecases** (4 archivos con 0% coverage)
   - `get_popular_feed_test.dart`
   - `get_following_feed_test.dart`
   - `get_recommended_feed_test.dart`
   - `check_new_gossips_test.dart`

3. **add_gossip_controller** (0% coverage, test existe pero no ejecuta)
   - Investigar por qué test no ejecuta código real

**Impacto:** Coverage +4% (78.9% → 82.9%)

---

## 📊 GAPS POR FEATURE

| Feature | Coverage | Gaps Críticos | Prioridad |
|---------|----------|---------------|-----------|
| **home** | ~15% domain | 8 archivos sin tests | 🔴 P0 |
| **gossip** | ~72% | add_gossip_controller (0%) | 🔴 P0 |
| **profile** | ~45% | 5 usecases + controller | 🟡 P1 |
| **auth** | ~85% | 2 archivos menores | 🟡 P1 |
| **location** | ~85% | Completo ✅ | - |
| **search** | 100% | Completo ✅ | - |

---

## 📋 PLAN DE SESIONES

### Sprint 1 - Features Core (1 semana)

**Sesión 1 (2-3h):** Arreglar 51 tests fallando → 100% pasando  
**Sesión 2 (3-4h):** Home domain tests → +3% coverage  
**Sesión 3 (4-5h):** Controllers (gossip, home, profile) → +4% coverage

**Total:** 9-12 horas | Coverage: 78.9% → 86%

### Sprint 2 - Completar Features (1 semana)

**Sesión 4 (2-3h):** Profile usecases → +1.5% coverage  
**Sesión 5 (2-3h):** Gossip gaps → +1% coverage  
**Sesión 6 (1-2h):** Auth remaining → +0.5% coverage

**Total:** 5-7 horas | Coverage: 86% → 89%

### Sprint 3 - Calidad (1 semana)

**Sesión 7 (2-3h):** Core modules  
**Sesión 8 (2-3h):** Investigar inconsistencias  
**Sesión 9 (3-4h):** Separar unit/integration  
**Sesión 10 (2-3h):** Limpieza y docs

**Total:** 9-13 horas | Coverage: 89% → 90%

---

## 🚨 PROBLEMAS CRÍTICOS

### 1. Tests Fallando (51)
**Impacto:** Alto  
**Acción:** Arreglar ANTES de agregar nuevos tests

### 2. Home Domain Sin Tests
**Impacto:** Alto - Feature principal  
**Archivos:** 8 (4 usecases, 3 entities, 1 repository)

### 3. Controllers con 0% Coverage
- `add_gossip_controller.dart` (124 líneas)
- `following_tab_controller.dart` (99 líneas)
- `profile_controller.dart` (83 líneas)

**Total:** 306 líneas de lógica sin tests

### 4. Inconsistencias de Coverage
Archivos reportando >1000% coverage pero con 0% real:
- `get_current_user.dart` (4000%)
- `profile_service.dart` (2000%)
- `check_new_gossips.dart` (1500%)

**Causa:** Tests ejecutan mocks, no implementación real

---

## ✅ CRITERIOS DE ÉXITO

### Objetivo Final
- ✅ Coverage: >90% (actualmente 78.9%)
- ✅ Tests pasando: 100% (actualmente 97.3%)
- ✅ Archivos críticos: 100% coverage
- ✅ Separación clara: unit vs integration tests

### Por Sprint
- **Sprint 1:** 86% coverage, 0 tests fallando
- **Sprint 2:** 89% coverage, features completos
- **Sprint 3:** 90% coverage, suite optimizada

---

## 📂 ARCHIVOS

**Reporte Completo:** `docs/TEST_AUDIT_REPORT.md` (50+ páginas)  
**Este Resumen:** `docs/TEST_AUDIT_SUMMARY.md`

---

## 🔧 COMANDOS ÚTILES

```bash
# Ver tests fallando
flutter test --reporter expanded | grep "FAIL"

# Coverage general
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html

# Coverage de un feature
flutter test test/features/home --coverage

# Tests específicos
flutter test test/features/home/domain/usecases/

# Ver archivos con bajo coverage
grep -E "^SF:|^LH:|^LF:" coverage/lcov.info | \
awk 'BEGIN {file=""} 
     /^SF:/ {file=$0; sub(/^SF:/,"",file)} 
     /^LH:/ {lh=$0; sub(/^LH:/,"",lh)} 
     /^LF:/ {lf=$0; sub(/^LF:/,"",lf); 
             if(lf>0) {
               cov=int((lh/lf)*100); 
               if(cov<50) print cov "% " file " (" lh "/" lf ")"
             }
            }' | sort -n
```

---

## 📊 TRACKING

### Sprint 1 (Crítico)
- [x] Sesión 1: Tests Fallando ✅ COMPLETADA
- [ ] Sesión 2: Home Domain
- [ ] Sesión 3: Controllers

### Sprint 2 (Alta Prioridad)
- [x] Sesión 4: Profile Usecases ✅ COMPLETADA
- [ ] Sesión 5: Gossip Gaps
- [ ] Sesión 6: Auth Remaining

### Sprint 3 (Calidad)
- [ ] Sesión 7: Core Modules
- [ ] Sesión 8: Investigación
- [ ] Sesión 9: Unit/Integration
- [ ] Sesión 10: Limpieza

---

**Ver detalles completos:** → `docs/TEST_AUDIT_REPORT.md`

**Última actualización:** 2026-11-17
