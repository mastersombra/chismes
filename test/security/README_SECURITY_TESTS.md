# 🧪 Security Tests - P0-03 Fix Verification

**Propósito:** Verificar que el fix P0-03 (eliminación de spike-user) funciona correctamente.

**Fecha:** 2026-10-21

---

## 📋 **TESTS DISPONIBLES**

### **1. Edge Function Auth Tests** (Dart)

**Archivo:** `test/security/edge_function_auth_test.dart`

**Qué verifica:**
- ✅ Sin JWT → 401 Unauthorized
- ✅ JWT inválido → 401 Unauthorized
- ✅ JWT válido → Success (200)
- ✅ No acepta `spike-user` como `created_by`
- ✅ Rate limiting funciona con UUID

### **2. RLS Policies Tests** (SQL)

**Archivo:** `test/security/rls_policies_test.sql`

**Qué verifica:**
- ✅ Usuario A no puede ver drafts de Usuario B
- ✅ Usuario A puede ver sus propios drafts
- ✅ Gossips públicos visibles para todos
- ✅ No existen referencias a `spike-user`
- ✅ Todos los `created_by` son UUID válidos
- ✅ INSERT directo desde cliente falla
- ✅ Usuario no puede falsificar `created_by`

---

## 🚀 **EJECUTAR TESTS**

### **Opción 1: Tests Automatizados (Dart)**

#### **Requisitos:**
- Edge Function desplegada
- Usuario de prueba creado en Supabase

#### **Pasos:**

1. **Crear usuario de prueba:**
   ```bash
   # Opción A: Desde Flutter app
   flutter run
   # Registra un usuario: test@example.com / Test123!@#
   
   # Opción B: Desde Supabase Dashboard
   # Authentication → Users → Add user
   # Email: test@example.com
   # Password: Test123!@#
   ```

2. **Obtener JWT del usuario:**
   ```dart
   // En Flutter (después de login)
   final jwt = supabase.auth.currentSession?.accessToken;
   print('JWT: $jwt');
   // Copia el token
   ```

3. **Ejecutar tests:**
   ```bash
   # Sin JWT (solo tests de 401)
   flutter test test/security/edge_function_auth_test.dart
   
   # Con JWT (todos los tests)
   flutter test test/security/edge_function_auth_test.dart \
     --dart-define=TEST_JWT=tu-jwt-aqui
   ```

#### **Resultado esperado:**
```
✓ P0-03 Fix: Sin JWT → 401 Unauthorized
✓ P0-03 Fix: JWT inválido → 401 Unauthorized
✓ P0-03 Fix: JWT válido → Success (200)
✓ P0-03 Fix: No acepta spike-user como created_by
⚠ Rate limiting funciona con UUID (manual)

00:05 +5: All tests passed!
```

---

### **Opción 2: Tests SQL (Manual)**

#### **Requisitos:**
- Acceso a Supabase Dashboard
- Permisos de admin (service_role)

#### **Pasos:**

1. **Abrir SQL Editor:**
   ```
   https://supabase.com/dashboard/project/njqamqcsldpmtbiqwbwo/sql
   ```

2. **Copiar archivo:**
   ```bash
   cat test/security/rls_policies_test.sql
   ```

3. **Pegar en SQL Editor**

4. **Ejecutar** (click "Run")

#### **Resultado esperado:**
```sql
🧪 Iniciando tests de políticas RLS...

📝 TEST 1: Aislamiento de drafts entre usuarios
   ✅ PASS: Usuario A no puede ver drafts de B

📝 TEST 2: Usuario puede ver sus propios drafts
   ✅ PASS: Usuario A puede ver sus propios drafts

📝 TEST 3: Gossips públicos visibles sin autenticación
   ✅ PASS: Gossips públicos son visibles para todos

📝 TEST 4: No existen referencias a spike-user
   ✅ PASS: No hay referencias a spike-user

📝 TEST 5: Todos los created_by son UUID válidos
   ✅ PASS: Todos los created_by son UUID válidos

📝 TEST 6: INSERT directo desde cliente falla
   ✅ PASS: INSERT directo bloqueado correctamente

📝 TEST 7: Usuario no puede falsificar created_by
   ✅ PASS: created_by protegido por trigger

================================================
📊 RESUMEN DE TESTS
================================================
Total:   7 tests
Pasados: 7 tests ✅
Fallidos: 0 tests ❌

🎉 TODOS LOS TESTS PASARON
✅ El fix P0-03 está funcionando correctamente
================================================
```

---

### **Opción 3: Tests Manuales (Curl)**

#### **Test 1: Sin JWT → 401**

```bash
curl -X POST https://njqamqcsldpmtbiqwbwo.supabase.co/functions/v1/moderate-gossip \
  -H "Content-Type: application/json" \
  -d '{
    "subject": "Test",
    "content": "Test content",
    "country_id": "CO",
    "region_id": "34",
    "city_id": "3688689",
    "published_as": "anonymous",
    "idempotency_key": "test-123"
  }'

# Esperado: {"error":"Missing Authorization header"}
```

#### **Test 2: JWT inválido → 401**

```bash
curl -X POST https://njqamqcsldpmtbiqwbwo.supabase.co/functions/v1/moderate-gossip \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer invalid-jwt-token" \
  -d '{
    "subject": "Test",
    "content": "Test content",
    "country_id": "CO",
    "region_id": "34",
    "city_id": "3688689",
    "published_as": "anonymous",
    "idempotency_key": "test-456"
  }'

# Esperado: {"error":"Authentication required","message":"You must be logged in to create gossips"}
```

#### **Test 3: JWT válido → Success**

```bash
# Obtén un JWT válido primero (desde Flutter app después de login)
JWT="tu-jwt-aqui"

curl -X POST https://njqamqcsldpmtbiqwbwo.supabase.co/functions/v1/moderate-gossip \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $JWT" \
  -d '{
    "subject": "Test seguro",
    "content": "Test con autenticación",
    "country_id": "CO",
    "region_id": "34",
    "city_id": "3688689",
    "published_as": "anonymous",
    "idempotency_key": "test-789"
  }'

# Esperado: {"gossip":{...,"created_by":"uuid-valido",...}}
```

---

## 🔍 **VERIFICAR RESULTADOS**

### **En Supabase Dashboard:**

1. **Ver gossips creados:**
   ```
   Table Editor → gossips
   ```

2. **Verificar created_by:**
   - Todos deben ser UUID válidos (36 caracteres)
   - Ninguno debe ser `'spike-user'`

3. **Ver rate_limits:**
   ```
   Table Editor → rate_limits
   ```
   - `user_id` debe ser UUID (no TEXT)
   - Debe tener registros de `create_gossip`

---

## 📊 **CHECKLIST DE VERIFICACIÓN**

Después de ejecutar los tests, verifica:

### **Base de Datos:**
- [ ] No existen gossips con `created_by = 'spike-user'`
- [ ] Todos los `created_by` son UUID válidos
- [ ] Foreign Key a `auth.users(id)` está activa
- [ ] Rate limits funciona con UUID

### **Edge Function:**
- [ ] Rechaza requests sin JWT (401)
- [ ] Rechaza requests con JWT inválido (401)
- [ ] Acepta requests con JWT válido (200)
- [ ] Fuerza `created_by` desde `user.id`
- [ ] Logs muestran: "✅ User authenticated: <uuid>"

### **Políticas RLS:**
- [ ] Usuario A no ve drafts de Usuario B
- [ ] Usuario A ve sus propios drafts
- [ ] Gossips públicos son visibles para todos
- [ ] INSERT directo falla sin política

### **Código:**
- [ ] No existen referencias a `'spike-user'` en código
- [ ] Triggers validan `auth.uid()` obligatorio
- [ ] Comparación UUID directa (sin casting)

---

## 🐛 **TROUBLESHOOTING**

### **Error: "Missing Authorization header"**
- ✅ **Esperado** - El fix está funcionando
- Edge Function rechaza correctamente requests sin JWT

### **Error: "Authentication required"**
- ✅ **Esperado** - El fix está funcionando
- Edge Function valida JWT antes de procesar

### **Test falla: "Usuario A puede ver drafts de B"**
- ❌ **Problema de RLS**
- Verificar política: `auth.uid() = created_by` (sin `OR spike-user`)

### **Test falla: "No hay referencias a spike-user"**
- ❌ **Datos no limpiados**
- Ejecutar: `DELETE FROM gossips WHERE created_by::text = 'spike-user';`

### **Test falla: "Rate limiting funciona"**
- ❌ **Problema de tipos**
- Verificar: `rate_limits.user_id` es UUID NOT NULL
- Verificar: Edge Function usa `user.id` (UUID)

---

## 📝 **NOTAS ADICIONALES**

### **Ejecutar en CI/CD:**

```yaml
# .github/workflows/security_tests.yml
name: Security Tests
on: [push]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - run: flutter test test/security/
        env:
          TEST_JWT: ${{ secrets.TEST_JWT }}
          SUPABASE_URL: ${{ secrets.SUPABASE_URL }}
```

### **Frecuencia de Tests:**

- ✅ **Antes de cada deploy** a producción
- ✅ **Después de cambios** en políticas RLS
- ✅ **Después de cambios** en Edge Functions
- ✅ **Semanalmente** (automated)

### **Tests Futuros:**

- [ ] Tests de penetración (pentest)
- [ ] Tests de carga (rate limiting)
- [ ] Tests de concurrencia
- [ ] Tests de escalabilidad

---

## 🎉 **CONCLUSIÓN**

Si **todos los tests pasan** ✅:
- El fix P0-03 está funcionando correctamente
- No hay referencias a `spike-user`
- Autenticación es obligatoria
- Políticas RLS están activas
- Rate limiting funciona con UUID

**Estado:** 🟢 **LISTO PARA PRODUCCIÓN**

---

**Última actualización:** 2026-10-21  
**Autor:** Alejo + Claude Code
