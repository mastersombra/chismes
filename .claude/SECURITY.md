# Security Standards - Chismes App

> **Standards de seguridad del proyecto.** Guía de prácticas seguras en el código.

**Última actualización:** 2026-10-20

---

## 📋 Índice

1. [Secrets Management](#secrets-management)
2. [Validación de Inputs](#validación-de-inputs)
3. [SQL Injection Prevention](#sql-injection-prevention)
4. [Row Level Security (RLS)](#row-level-security-rls)
5. [API Keys y Tokens](#api-keys-y-tokens)
6. [Moderación de Contenido](#moderación-de-contenido)

---

## Secrets Management

### ⛔ REGLA CRÍTICA: Service Role Key

**La `SUPABASE_SERVICE_ROLE_KEY` NUNCA debe incluirse en aplicaciones cliente.**

**Por qué es crítico:**
- Service role **bypasea Row Level Security (RLS)**
- Tiene **acceso completo a todas las tablas**
- Puede **leer, modificar y eliminar cualquier dato**
- Si se empaqueta en APK/IPA → **cualquier persona puede extraerla**

**❌ NUNCA usar service role en:**
- Aplicaciones móviles (Flutter/React Native)
- Aplicaciones web (JavaScript/TypeScript cliente)
- Código que se empaqueta en binarios distribuidos
- Archivos `.env` que se incluyen como assets

**✅ SOLO usar service role en:**
- Edge Functions de Supabase (usando Supabase Secrets)
- Scripts de backend/servidor
- Herramientas de CLI (en `.env.local` no commiteado)
- CI/CD pipelines (variables de entorno seguras)

### .env Files

**Configuración correcta para cliente móvil:**

```bash
# .env (NUNCA commitear, solo URL y anon key)
SUPABASE_URL=https://xxxproject.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...

# ⛔ NO incluir service role aquí
# Si necesitas service role para scripts locales:
# 1. Créala en .env.local (ya está en .gitignore)
# 2. Úsala SOLO en scripts de administración
# 3. NUNCA la empaquetes en la app
```

**Para scripts de administración locales:**

```bash
# .env.local (NUNCA commitear, ignorado por Git)
SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

### .gitignore

**Verificar que .gitignore está configurado:**

```gitignore
# .gitignore (YA CONFIGURADO en el proyecto)
.env
.env.*
!.env.example

# Otros secrets
*.key
*.pem
google-services.json  # Si contiene secrets
GoogleService-Info.plist  # Si contiene secrets
```

### Uso en Flutter

```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// main.dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Cargar .env (solo contiene URL y anon key)
  await dotenv.load(fileName: '.env');
  
  // Inicializar Supabase con anon key
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    publishableKey: dotenv.env['SUPABASE_ANON_KEY']!, // ✅ Respeta RLS
  );
  
  runApp(MyApp());
}

// ❌ NUNCA hacer esto en cliente
// final serviceKey = dotenv.env['SUPABASE_SERVICE_ROLE_KEY'];  // NO EXISTE
// await Supabase.initialize(
//   url: url,
//   publishableKey: serviceKey,  // ❌ BYPASEA RLS
// );
```

**Verificación de seguridad:**

```dart
// lib/core/config/supabase_config.dart
class SupabaseConfig {
  static String get url => dotenv.env['SUPABASE_URL'] ?? '';
  static String get anonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  
  // ✅ Solo exponer anon key
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: url,
      publishableKey: anonKey,  // ✅ CORRECTO
    );
  }
}

// ❌ NUNCA crear un getter para service role
// static String get serviceRoleKey => dotenv.env['SUPABASE_SERVICE_ROLE_KEY'];
```

### .env.example

**Crear template SIN valores reales:**

```bash
# .env.example (SÍ commitear)
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your_anon_key_here
# SUPABASE_SERVICE_ROLE_KEY solo para backend/scripts
```

### Verificar que no hay secrets commiteados

```bash
# Buscar secrets accidentalmente commiteados
git log --all --full-history -- .env
git log --all --full-history -- "*.key"

# Buscar patterns de API keys
git grep -i "sk-" -- "*.dart"
git grep -i "eyJhbGciOiJIUzI1NiI" -- "*.dart"

# Buscar service role key en historial
git log --all --full-history -S "SUPABASE_SERVICE_ROLE_KEY"
```

### Rotación de Secrets (En caso de exposición)

**Si una service role key fue expuesta (commiteada, en APK, etc):**

1. **Rotar inmediatamente en Supabase:**
   - Ir a: `Supabase Dashboard > Settings > API`
   - Click en "Reset" junto a service_role key
   - Copiar la NUEVA key
   - La key anterior queda revocada automáticamente

2. **Actualizar secrets seguros:**
   ```bash
   # Solo en lugares seguros:
   # - Supabase Edge Functions (Secrets)
   # - CI/CD variables
   # - .env.local (no commiteado)
   ```

3. **Verificar que NO esté en cliente:**
   ```bash
   # Verificar que no está en .env empaquetado
   grep -r "SERVICE_ROLE_KEY" .env
   
   # Verificar que no está en código
   grep -r "SERVICE_ROLE_KEY" lib/
   
   # Verificar pubspec.yaml
   grep -A 5 "assets:" pubspec.yaml
   ```

4. **Auditar accesos:**
   - Revisar logs de Supabase para accesos sospechosos
   - Verificar cambios no autorizados en datos
   - Si hay compromiso, considerar migración de datos

**Historial de rotaciones:**
- `2026-10-20`: Service role removida de .env cliente (nunca fue commiteada)
  - Razón: Encontrada en .env empaquetado como asset
  - Acción: Eliminada del cliente, rotada en Supabase
  - Resultado: ✅ No hubo exposición pública

---

## Validación de Inputs

**SIEMPRE validar inputs en dos capas:**

### 1. UI Validation (FormValidators)

```dart
// Feedback inmediato al usuario
TextFormField(
  decoration: InputDecoration(labelText: 'Título'),
  validator: (value) => FormValidators.combine(value, [
    (v) => FormValidators.required(v, 'título'),
    (v) => FormValidators.maxLength(v, 200, 'título'),
  ]),
)
```

### 2. Domain Validation (Validators)

```dart
// Validación de negocio (última línea de defensa)
Future<Result<Failure, Gossip>> create(CreateGossipInput input) async {
  // Validar SIEMPRE antes de enviar a backend
  final validation = GossipValidator.validateSubject(input.subject);
  if (validation != null) {
    return Result.failure(validation);
  }
  
  // Continuar...
}
```

### Input Sanitization

```dart
// Limpiar inputs
String sanitizeInput(String input) {
  return input
      .trim()                          // Quitar espacios
      .replaceAll(RegExp(r'\s+'), ' ') // Normalizar espacios múltiples
      .replaceAll(RegExp(r'[^\w\s\-.,!?áéíóúñ]'), '');  // Quitar caracteres especiales
}

// Uso
final cleanSubject = sanitizeInput(userInput.subject);
```

### XSS Prevention

```dart
// Flutter Text widget escapa HTML automáticamente
// ✅ SEGURO
Text(userInput);  // Cualquier <script> se muestra como texto, no se ejecuta

// ⚠️ CUIDADO con HTML rendering
// Si usas flutter_html o similar:
Html(
  data: DomSanitizer.sanitize(userInput),  // Sanitizar primero
)
```

---

## SQL Injection Prevention

**NUNCA concatenar SQL manualmente.**

### ✅ CORRECTO: Usar Supabase Client

```dart
// ✅ BIEN: Supabase sanitiza automáticamente
await supabase
    .from('gossips')
    .select()
    .eq('city_id', userProvidedCityId)  // Sanitizado automáticamente
    .ilike('subject', '%$userSearch%');  // Sanitizado automáticamente

// ✅ BIEN: Parámetros en RPC
await supabase.rpc('search_gossips', params: {
  'search_term': userInput,  // Sanitizado automáticamente
  'city_id': cityId,
});
```

### ❌ INCORRECTO: Concatenación SQL

```dart
// ❌ MAL: SQL Injection vulnerable
final query = "SELECT * FROM gossips WHERE title = '$userInput'";
await supabase.rpc('execute_raw', params: {'query': query});

// Si userInput es: "'; DROP TABLE gossips; --"
// Query final: SELECT * FROM gossips WHERE title = ''; DROP TABLE gossips; --'
// ¡Tabla borrada!
```

### En PostgreSQL Functions

```sql
-- ✅ BIEN: Usar parámetros
CREATE FUNCTION search_gossips(search_term TEXT, city_id UUID)
RETURNS TABLE(id UUID, subject TEXT) AS $$
BEGIN
  RETURN QUERY
  SELECT g.id, g.subject
  FROM gossips g
  WHERE g.city_id = search_gossips.city_id  -- Parámetro, NO concatenación
    AND g.subject ILIKE '%' || search_term || '%';  -- Sanitizado por PostgreSQL
END;
$$ LANGUAGE plpgsql;

-- ❌ MAL: Concatenación dinámica
CREATE FUNCTION unsafe_search(user_input TEXT) AS $$
BEGIN
  EXECUTE 'SELECT * FROM gossips WHERE title = ''' || user_input || '''';
  -- SQL Injection vulnerable
END;
$$ LANGUAGE plpgsql;
```

---

## Row Level Security (RLS)

**SIEMPRE aplicar RLS en todas las tablas.**

### Setup Básico

```sql
-- 1. Habilitar RLS
ALTER TABLE gossips ENABLE ROW LEVEL SECURITY;

-- 2. Crear políticas
-- Lectura: Solo gossips publicados y aprobados
CREATE POLICY "Users can read published gossips"
  ON gossips FOR SELECT
  USING (
    status = 'published' 
    AND moderation_status = 'approved'
    AND visibility = 'public'
  );

-- Escritura: Usuario solo puede crear propios gossips
CREATE POLICY "Users can create own gossips"
  ON gossips FOR INSERT
  WITH CHECK (auth.uid() = created_by);

-- Actualización: Usuario solo puede editar propios gossips
CREATE POLICY "Users can update own gossips"
  ON gossips FOR UPDATE
  USING (auth.uid() = created_by)
  WITH CHECK (auth.uid() = created_by);

-- Eliminación: Usuario solo puede eliminar propios gossips
CREATE POLICY "Users can delete own gossips"
  ON gossips FOR DELETE
  USING (auth.uid() = created_by);
```

### RLS para Admin

```sql
-- Admin puede ver todos los gossips
CREATE POLICY "Admins can read all gossips"
  ON gossips FOR SELECT
  TO authenticated
  USING (
    auth.jwt() ->> 'role' = 'admin'
  );

-- Admin puede moderar
CREATE POLICY "Admins can update all gossips"
  ON gossips FOR UPDATE
  TO authenticated
  USING (
    auth.jwt() ->> 'role' = 'admin'
  );
```

### Testing RLS

```sql
-- Test como usuario normal
SET LOCAL ROLE authenticated;
SET LOCAL request.jwt.claims.sub = 'user-uuid-123';

SELECT * FROM gossips;  -- Solo ve gossips públicos/propios

-- Test como admin
SET LOCAL request.jwt.claims.role = 'admin';
SELECT * FROM gossips;  -- Ve todos
```

### Regla de Oro

**Usuario SOLO envía datos, backend decide permisos.**

```dart
// ✅ BIEN: Usuario envía data, RLS valida permisos
await supabase.from('gossips').insert({
  'subject': subject,
  'body': body,
  'created_by': userId,  // RLS valida que userId == auth.uid()
});

// ❌ MAL: Confiar en cliente para permisos
if (user.isAdmin) {  // NO confiar en cliente
  await supabase.from('gossips').update(...);
}
```

---

## API Keys y Tokens

### Reglas

1. **NUNCA hardcodear API keys**

```dart
// ❌ MAL
const openAiKey = 'sk-xxx123';  // NO

// ✅ BIEN
final openAiKey = dotenv.env['OPENAI_API_KEY']!;
```

2. **Anon Key vs Service Role Key**

| Key | Uso | Dónde | Permisos |
|-----|-----|-------|----------|
| **Anon Key** | Cliente (app móvil) | ✅ Flutter app | Limitados por RLS |
| **Service Role Key** | Backend/Admin | ❌ NUNCA en cliente | Bypass RLS (admin) |

```dart
// ✅ BIEN: Cliente usa anon key
final supabase = SupabaseClient(
  supabaseUrl,
  supabaseAnonKey,  // ← Anon key OK en cliente
);

// ❌ MAL: NUNCA service role en cliente
final supabase = SupabaseClient(
  supabaseUrl,
  supabaseServiceRoleKey,  // ← ¡PELIGRO! Acceso total sin RLS
);
```

3. **OpenAI Moderation API → Backend ONLY**

```dart
// ❌ MAL: Moderación en cliente
final response = await http.post(
  Uri.parse('https://api.openai.com/v1/moderations'),
  headers: {'Authorization': 'Bearer $openAiKey'},  // ← Expone API key
);

// ✅ BIEN: Moderación en Edge Function
// Cliente solo llama:
await supabase.functions.invoke('moderate-content', body: {
  'text': userInput,
});

// Edge Function (backend) usa API key seguro
```

### Token Expiration

```dart
// Manejar tokens expirados
supabase.auth.onAuthStateChange.listen((data) {
  if (data.event == AuthChangeEvent.tokenRefreshed) {
    _logger.i('Token refreshed');
  } else if (data.event == AuthChangeEvent.signedOut) {
    _logger.w('Session expired, redirect to login');
    // Redirect to login
  }
});
```

---

## Moderación de Contenido

### OpenAI Moderation

**API Key SIEMPRE en backend (Edge Function), NUNCA en cliente.**

```typescript
// supabase/functions/moderate-content/index.ts
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'

serve(async (req) => {
  const { text } = await req.json()
  
  // API key desde environment variable (configurada en Supabase)
  const openAiKey = Deno.env.get('OPENAI_API_KEY')!
  
  const response = await fetch('https://api.openai.com/v1/moderations', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${openAiKey}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      input: text,
      model: 'omni-moderation-latest',
    }),
  })
  
  const result = await response.json()
  
  return new Response(JSON.stringify(result), {
    headers: { 'Content-Type': 'application/json' },
  })
})
```

```dart
// Cliente llama Edge Function (SIN exponer API key)
final response = await supabase.functions.invoke('moderate-content', body: {
  'text': gossipText,
});
```

### Content Sanitization

```dart
// Limpiar contenido antes de mostrar
String sanitizeContent(String content) {
  return content
      .trim()
      .replaceAll(RegExp(r'\s+'), ' ')  // Normalizar espacios
      .replaceAll(RegExp(r'<[^>]*>'), '');  // Quitar HTML tags
}
```

---

## 🔒 Checklist de Seguridad

### Antes de Commitear

- [ ] NO hay .env commiteado
- [ ] NO hay API keys hardcodeadas
- [ ] NO hay service role key en código cliente
- [ ] .gitignore incluye .env y *.key
- [ ] Inputs validados en UI y Domain
- [ ] Queries usan Supabase client (no SQL raw)
- [ ] RLS habilitado en todas las tablas

### Antes de Deploy

- [ ] .env configurado en producción
- [ ] Service role key SOLO en backend
- [ ] OpenAI API key en Edge Functions
- [ ] RLS policies testeadas
- [ ] Logs NO exponen datos sensibles
- [ ] HTTPS habilitado
- [ ] Rate limiting configurado

---

## 📚 Referencias

- **OWASP Top 10:** https://owasp.org/www-project-top-ten/
- **Supabase RLS:** https://supabase.com/docs/guides/auth/row-level-security
- **Flutter Security:** https://docs.flutter.dev/security
- **SQL Injection Prevention:** https://cheatsheetseries.owasp.org/cheatsheets/SQL_Injection_Prevention_Cheat_Sheet.html

---

**Última actualización:** 2026-10-20  
**Mantenedor:** Alejo
