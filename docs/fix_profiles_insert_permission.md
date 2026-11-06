# Fix: Permiso denegado en tabla profiles

**Fecha:** 2026-10-25  
**Problema:** Error "permission denied for table profiles" al crear cuenta  
**Estado:** ✅ Resuelto

---

## 🐛 Problema

Al intentar crear una cuenta nueva, el usuario recibía el error:

```
permission denied for table profiles
```

### Contexto

- **Tabla:** `profiles` (Supabase)
- **Operación:** INSERT al crear nuevo usuario
- **Origen:** Política RLS bloqueaba todos los INSERTs manuales

---

## 🔍 Causa raíz

### Política RLS restrictiva

**Migración original:** `005_create_profiles_table.sql`

```sql
CREATE POLICY "profiles_insert_system_only"
  ON profiles FOR INSERT
  WITH CHECK (FALSE);  -- ❌ Bloqueaba TODO
```

Esta política impedía que cualquier usuario insertara en `profiles`, incluyendo usuarios autenticados creando su propio perfil.

### Estrategia original (trigger)

La idea era que un trigger de PostgreSQL creara automáticamente el perfil:

```sql
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();
```

**Problema:**
- El trigger usa `SECURITY DEFINER` (permisos de superusuario)
- En algunos escenarios (OAuth, race conditions, etc.) el trigger podía fallar silenciosamente
- No había fallback si el trigger no se ejecutaba

---

## ✅ Solución implementada

### 1. Nueva política RLS (Migración 012)

**Archivo:** `supabase/migrations/012_fix_profiles_insert_policy.sql`

```sql
-- Eliminar política restrictiva
DROP POLICY IF EXISTS "profiles_insert_system_only" ON profiles;

-- Nueva política: Usuarios autenticados pueden insertar su propio perfil
CREATE POLICY "profiles_insert_own"
  ON profiles FOR INSERT
  WITH CHECK (
    auth.uid() = id  -- Solo puede insertar con su propio ID
  );
```

**Beneficios:**
- ✅ Usuarios autenticados pueden crear su propio perfil
- ✅ Seguridad mantenida: solo pueden insertar con su propio `auth.uid()`
- ✅ No pueden crear perfiles de otros usuarios
- ✅ El trigger sigue funcionando como backup

### 2. Fallback en código (DataSource)

**Archivo:** `lib/features/auth/data/datasources/supabase_auth_datasource_impl.dart`

#### SignUp con email

```dart
Future<UserModel> signUpWithEmail({
  required String email,
  required String password,
}) async {
  // ... signup con Supabase Auth

  // Obtener profile data
  var profileData = await _getProfileData(response.user!.id);

  // ✅ Si el trigger no creó el profile, crearlo manualmente
  if (profileData == null) {
    _logger.w('Profile not found after signup, creating manually');
    await _createProfile(response.user!.id);
    profileData = await _getProfileData(response.user!.id);
  }

  return UserModel.fromSupabase(...);
}
```

#### OAuth (Google/Apple)

```dart
Future<UserModel> signInWithGoogle() async {
  // ... OAuth flow

  // ✅ Asegurar que el profile existe
  await _ensureProfileExists(user.id);

  return user;
}
```

#### Helpers privados

```dart
/// Crea un profile manualmente si el trigger falló
Future<void> _createProfile(String userId) async {
  await _supabase.from('profiles').insert({
    'id': userId,
    'username': null,
    'display_name': null,
    'profile_completed': false,
  });
}

/// Asegura que el profile existe, creándolo si es necesario
Future<void> _ensureProfileExists(String userId) async {
  final profileData = await _getProfileData(userId);
  if (profileData == null) {
    await _createProfile(userId);
  }
}
```

---

## 🧪 Testing

### Casos cubiertos

1. **✅ SignUp email/password:**
   - Trigger crea el profile → OK
   - Trigger falla → Código lo crea manualmente → OK

2. **✅ OAuth (Google/Apple):**
   - Trigger crea el profile → OK
   - Trigger falla → Código lo crea manualmente → OK

3. **✅ Seguridad:**
   - Usuario A no puede crear profile de Usuario B → Bloqueado por RLS
   - Usuario autenticado puede crear su propio profile → Permitido

### Flujo de creación de perfil

```
Usuario se registra (auth.signUp)
         ↓
    Trigger intenta crear profile
         ↓
    ¿Trigger exitoso?
    ↙            ↘
  SÍ             NO
   ↓              ↓
Profile          Código crea
existe      profile manualmente
   ↓              ↓
   └──────┬───────┘
          ↓
    Profile existe
          ↓
    Usuario puede
       usar la app
```

---

## 📊 Impacto

### Antes del fix

```
❌ Usuario intenta registrarse
❌ Trigger falla (silenciosamente)
❌ App intenta obtener profile → No existe
❌ Error: "permission denied for table profiles"
❌ Usuario no puede usar la app
```

### Después del fix

```
✅ Usuario intenta registrarse
✅ Trigger falla (silenciosamente)
✅ App detecta que profile no existe
✅ App crea profile manualmente (RLS permite)
✅ Profile existe
✅ Usuario puede usar la app
```

---

## 🔒 Seguridad

### RLS mantiene seguridad

La nueva política sigue siendo segura:

```sql
WITH CHECK (auth.uid() = id)
```

**Esto significa:**
- ✅ Solo usuarios autenticados pueden insertar
- ✅ Solo pueden insertar con su propio ID (`auth.uid()`)
- ❌ No pueden crear perfiles de otros usuarios
- ❌ Usuarios no autenticados no pueden insertar

### Ejemplo de ataque bloqueado

```dart
// ❌ Usuario A (uid = "123") intenta crear profile de Usuario B
await supabase.from('profiles').insert({
  'id': '456',  // ← ID de otro usuario
  'username': 'hacker',
});

// Resultado: PostgrestException
// Error: new row violates row-level security policy
// Razón: auth.uid() = "123" pero id = "456"
```

---

## 📝 Archivos modificados

### Nuevos

1. **`supabase/migrations/012_fix_profiles_insert_policy.sql`**
   - Elimina política restrictiva
   - Crea política que permite INSERT propio

2. **`docs/fix_profiles_insert_permission.md`**
   - Esta documentación

### Modificados

1. **`lib/features/auth/data/datasources/supabase_auth_datasource_impl.dart`**
   - `signUpWithEmail()` - Fallback si trigger falla
   - `signInWithGoogle()` - Ensure profile exists
   - `signInWithApple()` - Ensure profile exists
   - `_createProfile()` - Helper para crear profile manualmente
   - `_ensureProfileExists()` - Helper para verificar/crear profile

---

## 🚀 Deployment

### Aplicar en producción

```bash
# Aplicar nueva migración
supabase db push --linked

# Verificar que se aplicó correctamente
supabase db diff --linked
```

### Rollback (si es necesario)

```sql
-- Revertir política
DROP POLICY IF EXISTS "profiles_insert_own" ON profiles;

-- Restaurar política restrictiva original
CREATE POLICY "profiles_insert_system_only"
  ON profiles FOR INSERT
  WITH CHECK (FALSE);
```

**⚠️ Nota:** El rollback requeriría también revertir los cambios en código.

---

## 🎓 Lecciones aprendidas

### ✅ DO

- Tener fallbacks cuando se depende de triggers
- Validar que operaciones críticas se ejecutaron correctamente
- Logs informativos para debugging (`_logger.w` cuando se crea manualmente)
- Políticas RLS granulares (permitir solo lo necesario)

### ❌ DON'T

- Depender 100% de triggers sin verificar que se ejecutaron
- Bloquear operaciones con `WITH CHECK (FALSE)` sin fallback
- Asumir que `SECURITY DEFINER` siempre funciona
- Ignorar errores silenciosos

---

## 📚 Referencias

- [Supabase RLS Docs](https://supabase.com/docs/guides/auth/row-level-security)
- [PostgreSQL Triggers](https://www.postgresql.org/docs/current/trigger-definition.html)
- [Supabase Auth Helpers](https://supabase.com/docs/guides/auth)

---

**FIN DEL DOCUMENTO**
