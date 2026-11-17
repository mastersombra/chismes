# Comandos para Sesiones de Coverage

**Propósito:** Frases exactas para iniciar cada sesión de mejora de cobertura.

---

## 🎯 Formato General

```
Sesión [N] de coverage: [Nombre de la sesión]
```

---

## 📋 Sesiones Programadas

### Sesión 1: Home Controllers

**Comando:**
```
Sesión 1 de coverage: Home Controllers
```

**Qué haré:**
- Leer `docs/TEST_COVERAGE_IMPROVEMENT_PLAN.md` - Sesión 1
- Crear tests para `following_tab_controller.dart`
- Crear tests para `popular_tab_controller.dart`
- Tests de paginación, refresh, error handling
- Verificar coverage: 53.0% → 55.6%

---

### Sesión 2: Profile + Auth OTP

**Comando:**
```
Sesión 2 de coverage: Profile + Auth OTP
```

**Qué haré:**
- Tests para `profile_controller.dart`
- Tests para `otp_verification_screen.dart`
- Tests para `otp_verification_controller.dart`
- Tests para `profile_header.dart`
- Tests para `settings_section.dart`
- Verificar coverage: 55.6% → 60.1%

---

### Sesión 3: Auth + Data Layer

**Comando:**
```
Sesión 3 de coverage: Auth + Data Layer
```

**Qué haré:**
- Tests para `supabase_auth_datasource_impl.dart`
- Tests para `home_remote_datasource.dart`
- Tests para `feed_gossip_model.dart`
- Tests para `profile_settings_model.dart`
- Tests para `reset_password_screen.dart`
- Verificar coverage: 60.1% → 65.8%

---

### Sesión 4: Data Layer Completion

**Comando:**
```
Sesión 4 de coverage: Data Layer Completion
```

**Qué haré:**
- Tests para `supabase_location_remote_data_source.dart`
- Completar tests de models faltantes
- Tests de serialización/deserialización
- Verificar coverage: 65.8% → 68.4%

---

### Sesión 5: Tabs + States

**Comando:**
```
Sesión 5 de coverage: Tabs + States
```

**Qué haré:**
- Completar tests de `following_tab.dart`
- Completar tests de `following_tab_state.dart`
- Completar tests de `popular_tab_state.dart`
- Completar tests de `deep_link_service.dart`
- Verificar coverage: 68.4% → 74.7%

---

### Sesión 6: Core Services

**Comando:**
```
Sesión 6 de coverage: Core Services
```

**Qué haré:**
- Completar tests de `device_info_provider.dart`
- Completar tests de `auth_service.dart`
- Completar tests de `feed_gossip.dart`
- Completar tests de `supabase_storage_service.dart`
- Verificar coverage: 74.7% → 80.9%

---

### Sesión 7: Screens Partial

**Comando:**
```
Sesión 7 de coverage: Screens Partial
```

**Qué haré:**
- Completar tests de `search_screen.dart`
- Completar tests de `supabase_gossip_remote_data_source.dart`
- Completar tests de `profile_screen.dart`
- Completar tests de `location_change_dialog.dart`
- Verificar coverage: 80.9% → 86.5%

---

### Sesión 8: Models + Widgets

**Comando:**
```
Sesión 8 de coverage: Models + Widgets
```

**Qué haré:**
- Completar tests de `auth_repository_impl.dart`
- Completar tests de `gossip_card.dart`
- Completar tests de `popular_tab.dart`
- Completar tests de `login_screen.dart`
- Completar tests de `user_model.dart`
- Verificar coverage: 86.5% → 93.7%

---

## 🔄 Comandos Alternativos

### Ver Progreso Actual

**Comando:**
```
Muéstrame el progreso de coverage actual
```

**Qué haré:**
- Ejecutar `./tools/coverage_progress.sh`
- Mostrar cobertura actual
- Mostrar progreso vs plan

---

### Continuar Sesión Incompleta

**Comando:**
```
Continuar sesión [N] de coverage
```

**Qué haré:**
- Leer checklist de sesión N
- Verificar qué está completo
- Continuar con tareas pendientes

---

### Revisar Coverage de Feature

**Comando:**
```
Revisar coverage de [feature]
```

**Qué haré:**
- Analizar cobertura de la feature específica
- Identificar gaps
- Sugerir tests prioritarios

---

## 📊 Después de Cada Sesión

Al finalizar cada sesión, automáticamente:

1. ✅ Ejecutaré tests: `flutter test --coverage`
2. ✅ Verificaré coverage: `lcov --summary`
3. ✅ Actualizaré progreso
4. ✅ Mostraré resumen de resultados
5. ✅ Indicaré próxima sesión

---

## 💡 Tips

### Si Olvidaste en Qué Sesión Vas

**Comando:**
```
¿En qué sesión de coverage voy?
```

**Qué haré:**
- Verificar coverage actual
- Comparar con plan
- Indicar próxima sesión sugerida

---

### Si Quieres Cambiar el Orden

**Comando:**
```
En vez de sesión [N], hacer sesión [M] de coverage
```

**Qué haré:**
- Adaptar al orden solicitado
- Trabajar en la sesión indicada

---

### Si Quieres Focus Específico

**Comando:**
```
Tests para [archivo específico]
```

**Qué haré:**
- Leer archivo
- Crear tests específicos
- Seguir templates de TEST_TEMPLATES_EXAMPLES.md

---

## 📋 Checklist Rápida

Antes de iniciar cualquier sesión, verificar que tengas:

- [ ] ✅ Documentación leída (al menos COVERAGE_ANALYSIS_SUMMARY.md)
- [ ] ✅ Git status limpio (o branch específica)
- [ ] ✅ Tests actuales pasando: `flutter test`
- [ ] ✅ Coverage baseline: `flutter test --coverage`

---

## 🎯 Ejemplo de Flujo Completo

```bash
# Sesión 1
Usuario: "Sesión 1 de coverage: Home Controllers"
Claude: [Lee plan, crea tests, ejecuta, verifica]

# Después de Sesión 1
Usuario: "Muéstrame el progreso de coverage actual"
Claude: [Ejecuta script, muestra 55.6%]

# Sesión 2
Usuario: "Sesión 2 de coverage: Profile + Auth OTP"
Claude: [Lee plan, crea tests, ejecuta, verifica]

# Y así sucesivamente...
```

---

## 🚀 Comando Más Simple

Si solo quieres que continúe con el plan:

**Comando Ultra-Simple:**
```
Siguiente sesión de coverage
```

**Qué haré:**
- Verificar cobertura actual
- Determinar qué sesión corresponde
- Iniciar automáticamente

---

## 📞 Comandos de Ayuda

### Ver Plan Completo

```
Ver plan completo de coverage
```

### Ver Template para Tipo de Test

```
Template para [Controller/DataSource/Screen/State/Service]
```

### Ver Ejemplos de Feature

```
Ejemplos de tests de gossip feature
```

---

## ⚡ Quick Start (Para la Próxima Sesión)

**Lo más simple:**

```
Sesión 1 de coverage: Home Controllers
```

**Eso es todo.** Con esa frase iniciaré:
1. ✅ Leer plan de sesión 1
2. ✅ Crear todos los tests necesarios
3. ✅ Ejecutar y verificar
4. ✅ Reportar progreso

---

**Última actualización:** 2026-11-12  
**Autor:** Claude Code
