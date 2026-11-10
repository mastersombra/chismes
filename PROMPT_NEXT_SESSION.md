# 🔥 PROMPT PARA PRÓXIMA SESIÓN

**Copia y pega EXACTAMENTE este texto cuando inicies la próxima sesión:**

---

Estoy continuando una migración de i18n que quedó al 80%. Lee primero:

```
docs/i18n_migration_STATUS.md
```

**Contexto rápido:**
- Migrando de `easy_localization` → `gen-l10n` (oficial Flutter)
- ✅ ARB files generados, gen-l10n configurado, 179 usos migrados
- ❌ Quedan 4 problemas bloqueantes que impiden compilar

**Tu tarea:**
1. Lee `docs/i18n_migration_STATUS.md` - sección "Problemas Pendientes"
2. Implementa las 5 fases del Checklist
3. Prioridad: P1 (cambio de idioma) y P3 (keys faltantes)

**Decisión arquitectónica para P1 (cambio de idioma):**
- Proyecto ya usa GetIt/Injectable para DI
- NO agregar Provider solo para esto
- **Solución:** Usa `ChangeNotifier` + GetIt + `ListenableBuilder`
- Guarda locale en SharedPreferences
- Ver ejemplo en STATUS.md pero adaptar a GetIt

**Comando inicial:**
```bash
flutter analyze 2>&1 | grep "error •" | wc -l
```

Deberías ver ~100 errores. Tu objetivo: llegar a 0.

**Archivos críticos a revisar primero:**
1. `lib/l10n/app_es.arb` - Verificar keys existen
2. `lib/core/widgets/language_selector.dart` - Implementar cambio de idioma
3. `lib/core/validation/form_validators.dart` - Arreglar validators sin context

**NO hagas:**
- ❌ Revertir cambios
- ❌ Agregar dependencias nuevas sin consultar (Provider, Riverpod, etc)
- ❌ Regenerar ARB desde cero (ya están bien)

**SÍ haz:**
- ✅ Usar GetIt para LocaleNotifier
- ✅ Agregar keys faltantes a ARB existentes
- ✅ Refactorizar widgets para pasar BuildContext correctamente
- ✅ Preguntar si hay trade-offs (no decidas solo)

Empecemos. ¿Cuántos errores de compilación hay actualmente?

---

**FIN DEL PROMPT**

---

## 📝 Notas para Alejo

### Qué esperar en la próxima sesión:

1. **Duración:** 2-3 horas
2. **Momento ideal:** Cuando tengas tiempo continuo sin interrupciones
3. **Backup:** Antes de empezar, haz `git stash` por si acaso

### Si el nuevo Claude se confunde:

**Redirigelo con:**
> "Lee docs/i18n_migration_STATUS.md sección 'Problemas Pendientes'. Empieza por P1 y P3."

### Si pregunta sobre arquitectura:

**Responde:**
> "Usa GetIt + ChangeNotifier para locale. NO agregues Provider. Ver código existente en `lib/core/di/`"

### Comando para verificar progreso:

```bash
# Ver errores restantes
flutter analyze 2>&1 | grep "error •" | wc -l

# Ver warnings restantes
flutter analyze 2>&1 | grep "warning •" | wc -l
```

### Cuándo declarar éxito:

```bash
flutter analyze  # 0 errores, 0-2 warnings OK
flutter test     # Todos pasan
flutter run      # App corre, cambio de idioma funciona
```

---

## 🎯 Resultado Esperado

Al final de la próxima sesión tendrás:

✅ App compila sin errores  
✅ Cambio de idioma funciona (español ↔ inglés)  
✅ Todas las traducciones muestran correctamente  
✅ Tests pasan  
✅ Type-safety completo (compile-time errors para keys inexistentes)  

**Bonus:** Sistema de i18n profesional, escalable a 10+ idiomas fácilmente.

---

**¿Dudas antes de la próxima sesión?** Guárdalas para cuando inicies con el nuevo Claude.
