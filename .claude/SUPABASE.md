# Arquitectura Supabase para Chismes

**Fecha:** Octubre 2026  
**Versión:** 1.0  
**Audiencia:** Arquitectos de software, desarrolladores backend

---

## Resumen Ejecutivo

Este documento describe la arquitectura completa para implementar **Chismes** (red social de chismes con 4-5M usuarios proyectados) usando **Supabase** como backend principal.

**Decisión clave:** Supabase en lugar de Firebase o backend custom (Spring Boot) por:
- ✅ Time-to-market: 3-4 meses vs 10-12 meses (Spring Boot)
- ✅ Costo: $30-50k MVP vs $100-150k (Spring Boot)
- ✅ Escalabilidad: PostgreSQL escala a millones con plan Enterprise
- ✅ Costos operativos: $2-4k/mes con 4-5M usuarios vs $35-45k/mes (Firebase optimizado)
- ✅ Control: Edge Functions + RLS = backend propio sobre PostgreSQL
- ✅ Búsqueda: Full-text search nativo (vs Algolia +$500/mes en Firebase)

---

## Tabla de Contenidos

1. [Stack Tecnológico Completo](#1-stack-tecnológico-completo)
2. [Arquitectura General](#2-arquitectura-general)
3. [Base de Datos PostgreSQL](#3-base-de-datos-postgresql)
4. [Autenticación y Seguridad](#4-autenticación-y-seguridad)
5. [Row Level Security (RLS) - Protección del Anonimato](#5-row-level-security-rls---protección-del-anonimato)
6. [Edge Functions - Backend Lógico](#6-edge-functions---backend-lógico)
7. [Supabase Storage + CDN](#7-supabase-storage--cdn)
8. [Búsqueda Full-Text](#8-búsqueda-full-text)
9. [Geolocalización con PostGIS](#9-geolocalización-con-postgis)
10. [Sistema de Moderación](#10-sistema-de-moderación)
11. [Notificaciones Push](#11-notificaciones-push)
12. [Real-time Subscriptions](#12-real-time-subscriptions)
13. [Panel Web de Moderación](#13-panel-web-de-moderación)
14. [Optimización y Caché](#14-optimización-y-caché)
15. [Monitoreo y Observabilidad](#15-monitoreo-y-observabilidad)
16. [Plan de Implementación](#16-plan-de-implementación)
17. [Costos Proyectados](#17-costos-proyectados)
18. [Migración Futura](#18-migración-futura)

---

## 1. Stack Tecnológico Completo

### Core Backend
```yaml
Backend Principal: Supabase (PostgreSQL + Auth + Storage + Edge Functions)
Base de Datos: PostgreSQL 15+ (managed by Supabase)
Extensiones DB: PostGIS (geolocalización), pg_trgm (búsqueda), pgvector (futuro IA)
Real-time: Supabase Realtime (PostgreSQL replication)
Storage: Supabase Storage (S3-compatible) + Cloudflare CDN
```

### Servicios Externos Obligatorios
```yaml
Moderación IA: OpenAI Moderation API (omni-moderation-latest)
Push Notifications: Firebase Cloud Messaging (FCM) + Apple Push Notification (APN)
CDN: Cloudflare (incluido en Supabase Storage)
Monitoring: Supabase Dashboard + Sentry (errores) + PostHog (analytics)
```

### Servicios Opcionales (Fase 2+)
```yaml
Email Transaccional: Resend o SendGrid (notificaciones email)
SMS Verificación: Twilio (verificación teléfono si se requiere)
Video Processing: Cloudflare Stream o Mux (cuando se agreguen videos)
Search Avanzado: Typesense (si PostgreSQL full-text no es suficiente - solo si necesario)
```

### Cliente
```yaml
Mobile: Flutter (Android/iOS)
Panel Admin: React + Vite + TypeScript
Design System: shadcn/ui o Material UI
Estado: TanStack Query + Zustand

```
OpenAI Moderation API:
  - Moderación de contenido con IA
  - Costo: GRATIS hasta 1M requests/mes
  - Uso: Validar chismes antes de publicar

Firebase Cloud Messaging (FCM):
  - Solo para notificaciones push
  - Costo: GRATIS
  - Uso: Enviar notificaciones móviles
  - ⚠️ Supabase NO tiene push notifications nativo

Sentry (opcional):
  - Tracking de errores
  - Costo: Plan free suficiente

PostHog (opcional):
  - Analytics
  - Costo: ~$0/mes inicial (1M eventos gratis)

---

## 2. Arquitectura General

```
┌─────────────────────────────────────────────────────────────────┐
│                         CLIENTES                                │
├─────────────────────────────────────────────────────────────────┤
│  Flutter Mobile          │         React Admin Panel            │
│  (Android/iOS)           │         (Moderadores)                │
└──────────┬───────────────┴────────────────────┬─────────────────┘
           │                                    │
           ├────────────────────────────────────┤
           │        HTTPS / REST / GraphQL       │
           ▼                                    ▼
┌─────────────────────────────────────────────────────────────────┐
│                      SUPABASE CLOUD                             │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌────────────────┐  ┌────────────────┐  ┌──────────────────┐ │
│  │  Supabase Auth │  │  Edge Functions│  │ Supabase Storage │ │
│  │                │  │   (Deno/TS)    │  │  + CDN           │ │
│  │ - Google OAuth │  │                │  │                  │ │
│  │ - Facebook     │  │ - Moderación   │  │ - Audio          │ │
│  │ - Apple        │  │ - Denuncias    │  │ - Imágenes       │ │
│  │ - JWT tokens   │  │ - Notif logic  │  │ - Videos         │ │
│  └────────┬───────┘  └───────┬────────┘  └────────┬─────────┘ │
│           │                  │                     │           │
│           └──────────────────┼─────────────────────┘           │
│                              │                                 │
│  ┌──────────────────────────▼──────────────────────────────┐  │
│  │           PostgreSQL 15+ (Primary Database)             │  │
│  ├─────────────────────────────────────────────────────────┤  │
│  │  Tables:                                                │  │
│  │  - users (perfiles)                                     │  │
│  │  - gossips (chismes)                                    │  │
│  │  - comments (comentarios)                               │  │
│  │  - likes (likes)                                        │  │
│  │  - reports (denuncias)                                  │  │
│  │  - followers (seguidores)                               │  │
│  │  - audit_log (auditoría)                                │  │
│  │  - moderation_queue (cola moderación)                   │  │
│  │                                                         │  │
│  │  Extensions:                                            │  │
│  │  - PostGIS (geolocalización)                            │  │
│  │  - pg_trgm (búsqueda trigrams)                          │  │
│  │  - pgvector (embeddings futuro)                         │  │
│  │                                                         │  │
│  │  Row Level Security (RLS): ACTIVO                       │  │
│  └─────────────────────────────────────────────────────────┘  │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │              Supabase Realtime                           │  │
│  │  - Notificaciones de likes                               │  │
│  │  - Comentarios en tiempo real                            │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
           │                              │
           ▼                              ▼
┌──────────────────────┐      ┌───────────────────────────┐
│  OpenAI Moderation   │      │  Firebase Cloud Messaging │
│  API (Moderación IA) │      │  (Push Notifications)     │
└──────────────────────┘      └───────────────────────────┘
```

---

## 3. Base de Datos PostgreSQL

### 3.1 Schema Principal

```sql
-- =============================================================================
-- EXTENSIONES
-- =============================================================================

-- Geolocalización (búsquedas por ciudad, región, coordenadas)
CREATE EXTENSION IF NOT EXISTS postgis;

-- Búsqueda full-text (búsqueda de chismes por texto)
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- UUIDs
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =============================================================================
-- TABLAS CORE
-- =============================================================================

-- -----------------------------------------------------------------------------
-- USERS (Perfiles de usuario)
-- -----------------------------------------------------------------------------
CREATE TABLE users (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  
  -- Información básica
  username TEXT UNIQUE NOT NULL,
  display_name TEXT NOT NULL,
  avatar_url TEXT,
  bio TEXT,
  
  -- Ubicación
  country_id TEXT NOT NULL, -- 'co', 'ec', 'pe', etc.
  region_id TEXT NOT NULL,  -- 'antioquia', 'cundinamarca', etc.
  city_id TEXT NOT NULL,    -- 'medellin', 'bogota', etc.
  location GEOGRAPHY(POINT), -- PostGIS: lat/lng para búsquedas cercanas
  
  -- Configuración
  language TEXT DEFAULT 'es' CHECK (language IN ('es', 'en', 'pt')),
  theme TEXT DEFAULT 'system' CHECK (theme IN ('light', 'dark', 'system')),
  
  -- Moderación
  role TEXT DEFAULT 'user' CHECK (role IN ('user', 'moderator', 'admin')),
  is_verified BOOLEAN DEFAULT FALSE,
  is_suspended BOOLEAN DEFAULT FALSE,
  suspended_until TIMESTAMPTZ,
  
  -- Estadísticas
  gossips_count INTEGER DEFAULT 0,
  followers_count INTEGER DEFAULT 0,
  following_count INTEGER DEFAULT 0,
  
  -- Auditoría
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  last_active_at TIMESTAMPTZ DEFAULT NOW()
);

-- Índices para users
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_location ON users USING GIST(location);
CREATE INDEX idx_users_city ON users(country_id, region_id, city_id);

-- -----------------------------------------------------------------------------
-- GOSSIPS (Chismes)
-- -----------------------------------------------------------------------------
CREATE TABLE gossips (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  
  -- Ubicación del chisme
  country_id TEXT NOT NULL,
  region_id TEXT NOT NULL,
  city_id TEXT NOT NULL,
  location GEOGRAPHY(POINT), -- Ubicación exacta (opcional)
  
  -- Contenido
  subject TEXT NOT NULL CHECK (char_length(subject) <= 200),
  content TEXT NOT NULL CHECK (char_length(content) <= 1000),
  
  -- Media
  audio_url TEXT,
  image_url TEXT,
  video_url TEXT, -- Futuro
  
  -- Publicación
  published_as TEXT NOT NULL CHECK (published_as IN ('anonymous', 'profile')),
  visibility TEXT DEFAULT 'public' CHECK (visibility IN ('public', 'private', 'followers')),
  
  -- Estados (máquina de estados del dominio)
  status TEXT NOT NULL DEFAULT 'published' CHECK (
    status IN ('draft', 'published', 'under_review', 'hidden', 'deleted')
  ),
  moderation_status TEXT NOT NULL DEFAULT 'pending' CHECK (
    moderation_status IN ('pending', 'approved', 'rejected', 'flagged')
  ),
  
  -- Contadores (actualizados por triggers)
  view_count INTEGER DEFAULT 0,
  like_count INTEGER DEFAULT 0,
  comment_count INTEGER DEFAULT 0,
  report_count INTEGER DEFAULT 0,
  
  -- Auditoría (SIEMPRE se guarda identidad real)
  created_by UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  modified_by UUID REFERENCES users(id),
  modified_at TIMESTAMPTZ,
  deleted_by UUID REFERENCES users(id),
  deleted_at TIMESTAMPTZ,
  
  -- Full-text search
  search_vector tsvector GENERATED ALWAYS AS (
    setweight(to_tsvector('spanish', coalesce(subject, '')), 'A') ||
    setweight(to_tsvector('spanish', coalesce(content, '')), 'B')
  ) STORED
);

-- Índices para gossips
CREATE INDEX idx_gossips_location ON gossips USING GIST(location);
CREATE INDEX idx_gossips_city ON gossips(country_id, region_id, city_id);
CREATE INDEX idx_gossips_status ON gossips(status, moderation_status) WHERE deleted_at IS NULL;
CREATE INDEX idx_gossips_created_by ON gossips(created_by);
CREATE INDEX idx_gossips_created_at ON gossips(created_at DESC);
CREATE INDEX idx_gossips_view_count ON gossips(view_count DESC);
CREATE INDEX idx_gossips_search ON gossips USING GIN(search_vector);

-- -----------------------------------------------------------------------------
-- COMMENTS (Comentarios)
-- -----------------------------------------------------------------------------
CREATE TABLE comments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  
  gossip_id UUID NOT NULL REFERENCES gossips(id) ON DELETE CASCADE,
  parent_comment_id UUID REFERENCES comments(id) ON DELETE CASCADE, -- Para respuestas
  
  content TEXT NOT NULL CHECK (char_length(content) <= 500),
  
  -- Auditoría
  created_by UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  modified_at TIMESTAMPTZ,
  deleted_at TIMESTAMPTZ,
  
  -- Moderación
  is_flagged BOOLEAN DEFAULT FALSE
);

CREATE INDEX idx_comments_gossip ON comments(gossip_id, created_at DESC);
CREATE INDEX idx_comments_user ON comments(created_by);

-- -----------------------------------------------------------------------------
-- LIKES (Likes)
-- -----------------------------------------------------------------------------
CREATE TABLE likes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  
  gossip_id UUID NOT NULL REFERENCES gossips(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  
  created_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- Un usuario solo puede dar 1 like por chisme
  UNIQUE(gossip_id, user_id)
);

CREATE INDEX idx_likes_gossip ON likes(gossip_id);
CREATE INDEX idx_likes_user ON likes(user_id);

-- -----------------------------------------------------------------------------
-- REPORTS (Denuncias)
-- -----------------------------------------------------------------------------
CREATE TABLE reports (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  
  gossip_id UUID NOT NULL REFERENCES gossips(id) ON DELETE CASCADE,
  reporter_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  
  reason TEXT NOT NULL CHECK (reason IN (
    'spam', 'harassment', 'sexual_content', 'violence', 
    'hate_speech', 'false_information', 'privacy_violation', 'other'
  )),
  description TEXT,
  
  -- Resolución
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'reviewing', 'resolved', 'dismissed')),
  resolved_by UUID REFERENCES users(id),
  resolved_at TIMESTAMPTZ,
  resolution_note TEXT,
  
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_reports_gossip ON reports(gossip_id);
CREATE INDEX idx_reports_status ON reports(status, created_at DESC);

-- -----------------------------------------------------------------------------
-- FOLLOWERS (Sistema de seguimiento)
-- -----------------------------------------------------------------------------
CREATE TABLE followers (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  
  follower_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  following_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  
  created_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- Un usuario no puede seguir dos veces a otro
  UNIQUE(follower_id, following_id),
  
  -- Un usuario no puede seguirse a sí mismo
  CHECK (follower_id != following_id)
);

CREATE INDEX idx_followers_follower ON followers(follower_id);
CREATE INDEX idx_followers_following ON followers(following_id);

-- -----------------------------------------------------------------------------
-- AUDIT_LOG (Auditoría completa)
-- -----------------------------------------------------------------------------
CREATE TABLE audit_log (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  
  -- Qué acción
  action TEXT NOT NULL, -- 'gossip_created', 'gossip_deleted', 'user_suspended', etc.
  entity_type TEXT NOT NULL, -- 'gossip', 'user', 'comment', etc.
  entity_id UUID NOT NULL,
  
  -- Quién
  actor_id UUID REFERENCES users(id),
  actor_role TEXT, -- 'user', 'moderator', 'admin', 'system'
  
  -- Metadata
  metadata JSONB,
  ip_address INET,
  user_agent TEXT,
  
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_audit_log_entity ON audit_log(entity_type, entity_id);
CREATE INDEX idx_audit_log_actor ON audit_log(actor_id);
CREATE INDEX idx_audit_log_created ON audit_log(created_at DESC);

-- -----------------------------------------------------------------------------
-- MODERATION_QUEUE (Cola de moderación)
-- -----------------------------------------------------------------------------
CREATE TABLE moderation_queue (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  
  gossip_id UUID NOT NULL REFERENCES gossips(id) ON DELETE CASCADE,
  
  -- Resultado de moderación IA
  ai_decision TEXT CHECK (ai_decision IN ('approve', 'review', 'reject')),
  ai_confidence DECIMAL(3, 2), -- 0.00 - 1.00
  ai_flags JSONB, -- {"categories": ["harassment"], "scores": {...}}
  ai_provider TEXT, -- 'openai', 'google', etc.
  
  -- Prioridad (calculada por backend)
  priority INTEGER DEFAULT 5, -- 1 (baja) - 10 (crítica)
  
  -- Asignación
  assigned_to UUID REFERENCES users(id),
  assigned_at TIMESTAMPTZ,
  
  -- Resolución
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'in_review', 'resolved')),
  reviewed_by UUID REFERENCES users(id),
  reviewed_at TIMESTAMPTZ,
  moderator_decision TEXT CHECK (moderator_decision IN ('approve', 'reject', 'escalate')),
  moderator_notes TEXT,
  
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_moderation_queue_status ON moderation_queue(status, priority DESC, created_at);
CREATE INDEX idx_moderation_queue_assigned ON moderation_queue(assigned_to);
```

### 3.2 Triggers para Contadores

```sql
-- Actualizar contador de likes en gossips
CREATE OR REPLACE FUNCTION update_gossip_like_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE gossips SET like_count = like_count + 1 WHERE id = NEW.gossip_id;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE gossips SET like_count = GREATEST(like_count - 1, 0) WHERE id = OLD.gossip_id;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_gossip_like_count
AFTER INSERT OR DELETE ON likes
FOR EACH ROW
EXECUTE FUNCTION update_gossip_like_count();

-- Actualizar contador de comentarios en gossips
CREATE OR REPLACE FUNCTION update_gossip_comment_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE gossips SET comment_count = comment_count + 1 WHERE id = NEW.gossip_id;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE gossips SET comment_count = GREATEST(comment_count - 1, 0) WHERE id = OLD.gossip_id;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_gossip_comment_count
AFTER INSERT OR DELETE ON comments
FOR EACH ROW
EXECUTE FUNCTION update_gossip_comment_count();

-- Actualizar contador de denuncias en gossips
CREATE OR REPLACE FUNCTION update_gossip_report_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE gossips SET report_count = report_count + 1 WHERE id = NEW.gossip_id;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_gossip_report_count
AFTER INSERT ON reports
FOR EACH ROW
EXECUTE FUNCTION update_gossip_report_count();

-- Auto-ocultar chisme si recibe muchas denuncias
CREATE OR REPLACE FUNCTION auto_hide_reported_gossip()
RETURNS TRIGGER AS $$
BEGIN
  -- Si un chisme recibe 10+ denuncias, ocultarlo automáticamente
  IF (SELECT report_count FROM gossips WHERE id = NEW.gossip_id) >= 10 THEN
    UPDATE gossips 
    SET status = 'hidden', moderation_status = 'flagged'
    WHERE id = NEW.gossip_id AND status = 'published';
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_auto_hide_reported_gossip
AFTER INSERT ON reports
FOR EACH ROW
EXECUTE FUNCTION auto_hide_reported_gossip();

-- Actualizar updated_at automáticamente
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_users_updated_at
BEFORE UPDATE ON users
FOR EACH ROW
EXECUTE FUNCTION update_updated_at();
```

---

## 4. Autenticación y Seguridad

### 4.1 Configuración de Supabase Auth

**Proveedores OAuth a activar:**

```yaml
Google OAuth:
  Client ID: [Tu Client ID de Google Cloud Console]
  Client Secret: [Tu Secret]
  Scopes: email, profile
  
Facebook Login:
  App ID: [Tu App ID de Facebook Developers]
  App Secret: [Tu Secret]
  
Apple Sign In:
  Services ID: [Tu Services ID]
  Team ID: [Tu Team ID]
  Key ID: [Tu Key ID]
  Private Key: [Tu .p8 file]
```

**Configuración en Supabase Dashboard:**

1. Ir a `Authentication` > `Providers`
2. Activar Google, Facebook, Apple
3. Configurar redirect URLs:
   - Mobile: `your-app://callback` (Deep link configurado en Flutter)
   - Web Admin: `https://admin.chismes.app/auth/callback`

### 4.2 JWT Tokens

Supabase genera JWT automáticamente con esta estructura:

```json
{
  "sub": "user-uuid",
  "email": "user@example.com",
  "role": "authenticated",
  "user_metadata": {
    "username": "juanperez",
    "role": "user"
  },
  "aud": "authenticated",
  "exp": 1698765432
}
```

### 4.3 Crear Usuario al Registrarse

**Edge Function:** `create-user-profile`

```typescript
// supabase/functions/create-user-profile/index.ts
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

serve(async (req) => {
  try {
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    const authHeader = req.headers.get('Authorization')!
    const { data: { user } } = await supabase.auth.getUser(authHeader.replace('Bearer ', ''))

    if (!user) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), { status: 401 })
    }

    const { username, country_id, region_id, city_id } = await req.json()

    // Crear perfil de usuario
    const { data, error } = await supabase
      .from('users')
      .insert({
        id: user.id,
        username,
        display_name: user.user_metadata.full_name || username,
        avatar_url: user.user_metadata.avatar_url,
        country_id,
        region_id,
        city_id
      })
      .select()
      .single()

    if (error) throw error

    return new Response(JSON.stringify(data), {
      headers: { 'Content-Type': 'application/json' }
    })
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 400,
      headers: { 'Content-Type': 'application/json' }
    })
  }
})
```

---

## 5. Row Level Security (RLS) - Protección del Anonimato

**CRÍTICO:** RLS es la clave para proteger la identidad de usuarios que publican anónimamente.

### 5.1 Políticas RLS para Gossips

```sql
-- =============================================================================
-- RLS POLICIES PARA GOSSIPS
-- =============================================================================

-- Activar RLS
ALTER TABLE gossips ENABLE ROW LEVEL SECURITY;

-- -----------------------------------------------------------------------------
-- SELECT: Leer chismes
-- -----------------------------------------------------------------------------

-- 1. Usuarios normales solo ven chismes publicados y aprobados
CREATE POLICY "Users can view published gossips"
ON gossips FOR SELECT
TO authenticated
USING (
  status = 'published' 
  AND moderation_status = 'approved'
  AND visibility = 'public'
  AND deleted_at IS NULL
);

-- 2. Usuarios ven sus propios chismes (cualquier estado)
CREATE POLICY "Users can view their own gossips"
ON gossips FOR SELECT
TO authenticated
USING (created_by = auth.uid());

-- 3. Moderadores ven TODO
CREATE POLICY "Moderators can view all gossips"
ON gossips FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM users 
    WHERE id = auth.uid() 
    AND role IN ('moderator', 'admin')
  )
);

-- -----------------------------------------------------------------------------
-- PROTECCIÓN DEL ANONIMATO - COLUMNA created_by
-- -----------------------------------------------------------------------------

-- ⚠️ IMPORTANTE: El SELECT de arriba devuelve created_by.
-- Para proteger el anonimato, usamos una VIEW que oculta created_by si es anónimo.

CREATE OR REPLACE VIEW public_gossips AS
SELECT 
  id,
  country_id,
  region_id,
  city_id,
  subject,
  content,
  audio_url,
  image_url,
  video_url,
  published_as,
  visibility,
  status,
  moderation_status,
  view_count,
  like_count,
  comment_count,
  report_count,
  
  -- ⚠️ PROTECCIÓN: Solo mostrar created_by si NO es anónimo
  CASE 
    WHEN published_as = 'anonymous' THEN NULL
    ELSE created_by
  END AS created_by,
  
  created_at,
  modified_at
  
FROM gossips
WHERE status = 'published' 
  AND moderation_status = 'approved'
  AND visibility = 'public'
  AND deleted_at IS NULL;

-- RLS en la view
ALTER VIEW public_gossips OWNER TO authenticated;

-- Flutter debe usar esta view en lugar de la tabla directa
```

### 5.2 Políticas RLS para Otras Tablas

```sql
-- -----------------------------------------------------------------------------
-- USERS
-- -----------------------------------------------------------------------------
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- Todos ven perfiles públicos
CREATE POLICY "Anyone can view user profiles"
ON users FOR SELECT
TO authenticated
USING (true);

-- Solo el propio usuario puede actualizar su perfil
CREATE POLICY "Users can update their own profile"
ON users FOR UPDATE
TO authenticated
USING (id = auth.uid())
WITH CHECK (id = auth.uid());

-- -----------------------------------------------------------------------------
-- COMMENTS
-- -----------------------------------------------------------------------------
ALTER TABLE comments ENABLE ROW LEVEL SECURITY;

-- Ver comentarios de chismes publicados
CREATE POLICY "Users can view comments"
ON comments FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM gossips 
    WHERE id = comments.gossip_id 
    AND status = 'published'
  )
);

-- Crear comentarios
CREATE POLICY "Users can create comments"
ON comments FOR INSERT
TO authenticated
WITH CHECK (created_by = auth.uid());

-- Eliminar propios comentarios
CREATE POLICY "Users can delete their own comments"
ON comments FOR DELETE
TO authenticated
USING (created_by = auth.uid());

-- -----------------------------------------------------------------------------
-- LIKES
-- -----------------------------------------------------------------------------
ALTER TABLE likes ENABLE ROW LEVEL SECURITY;

-- Ver likes
CREATE POLICY "Users can view likes"
ON likes FOR SELECT
TO authenticated
USING (true);

-- Crear like
CREATE POLICY "Users can create likes"
ON likes FOR INSERT
TO authenticated
WITH CHECK (user_id = auth.uid());

-- Eliminar propio like
CREATE POLICY "Users can delete their own likes"
ON likes FOR DELETE
TO authenticated
USING (user_id = auth.uid());

-- -----------------------------------------------------------------------------
-- REPORTS
-- -----------------------------------------------------------------------------
ALTER TABLE reports ENABLE ROW LEVEL SECURITY;

-- Solo moderadores ven denuncias
CREATE POLICY "Moderators can view reports"
ON reports FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM users 
    WHERE id = auth.uid() 
    AND role IN ('moderator', 'admin')
  )
);

-- Usuarios pueden crear denuncias
CREATE POLICY "Users can create reports"
ON reports FOR INSERT
TO authenticated
WITH CHECK (reporter_id = auth.uid());

-- -----------------------------------------------------------------------------
-- AUDIT_LOG
-- -----------------------------------------------------------------------------
ALTER TABLE audit_log ENABLE ROW LEVEL SECURITY;

-- Solo admins ven audit logs
CREATE POLICY "Admins can view audit logs"
ON audit_log FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM users 
    WHERE id = auth.uid() 
    AND role = 'admin'
  )
);
```

---

## 6. Edge Functions - Backend Lógico

**Edge Functions** son el backend real de la aplicación. Aquí va la lógica de negocio.

### 6.1 Estructura de Edge Functions

```
supabase/
└── functions/
    ├── create-gossip/
    │   ├── index.ts
    │   └── moderation.ts
    ├── moderate-gossip/
    │   └── index.ts
    ├── handle-report/
    │   └── index.ts
    ├── send-notification/
    │   └── index.ts
    └── _shared/
        ├── supabase.ts
        ├── openai.ts
        └── fcm.ts
```

### 6.2 Edge Function: Crear Chisme con Moderación

**Archivo:** `supabase/functions/create-gossip/index.ts`

```typescript
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { moderateContent } from './moderation.ts'

serve(async (req) => {
  try {
    // 1. Autenticación
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), { status: 401 })
    }

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    const { data: { user }, error: authError } = await supabase.auth.getUser(
      authHeader.replace('Bearer ', '')
    )

    if (authError || !user) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), { status: 401 })
    }

    // 2. Validar input
    const { 
      country_id, 
      region_id, 
      city_id, 
      subject, 
      content, 
      audio_url,
      image_url, 
      published_as, 
      visibility 
    } = await req.json()

    // Validaciones básicas
    if (!subject || subject.length > 200) {
      return new Response(
        JSON.stringify({ error: 'Subject must be 1-200 characters' }), 
        { status: 400 }
      )
    }

    if (!content || content.length > 1000) {
      return new Response(
        JSON.stringify({ error: 'Content must be 1-1000 characters' }), 
        { status: 400 }
      )
    }

    // 3. Moderación automática con IA
    const moderationResult = await moderateContent(subject, content)

    let status: string
    let moderation_status: string
    let should_add_to_queue = false

    if (moderationResult.decision === 'reject') {
      // Contenido rechazado (amenazas, contenido ilegal)
      status = 'hidden'
      moderation_status = 'rejected'
    } else if (moderationResult.decision === 'review') {
      // Contenido dudoso - enviar a revisión humana
      status = 'under_review'
      moderation_status = 'pending'
      should_add_to_queue = true
    } else {
      // Contenido aprobado
      status = 'published'
      moderation_status = 'approved'
    }

    // 4. Insertar chisme (servidor tiene autoridad)
    const { data: gossip, error: insertError } = await supabase
      .from('gossips')
      .insert({
        country_id,
        region_id,
        city_id,
        subject,
        content,
        audio_url,
        image_url,
        published_as,
        visibility,
        status, // ← SERVIDOR decide
        moderation_status, // ← SERVIDOR decide
        created_by: user.id, // ← SERVIDOR asigna identidad real
      })
      .select()
      .single()

    if (insertError) throw insertError

    // 5. Si requiere revisión, agregar a cola de moderación
    if (should_add_to_queue) {
      await supabase
        .from('moderation_queue')
        .insert({
          gossip_id: gossip.id,
          ai_decision: moderationResult.decision,
          ai_confidence: moderationResult.confidence,
          ai_flags: moderationResult.flags,
          ai_provider: 'openai',
          priority: moderationResult.priority,
        })
    }

    // 6. Auditoría
    await supabase
      .from('audit_log')
      .insert({
        action: 'gossip_created',
        entity_type: 'gossip',
        entity_id: gossip.id,
        actor_id: user.id,
        actor_role: 'user',
        metadata: {
          moderation_result: moderationResult,
          ip_address: req.headers.get('x-forwarded-for'),
        },
      })

    // 7. Respuesta
    return new Response(
      JSON.stringify({
        gossip,
        moderation: {
          status: moderation_status,
          message: moderationResult.decision === 'review' 
            ? 'Your gossip is under review and will be published after approval'
            : 'Your gossip has been published'
        }
      }),
      {
        headers: { 'Content-Type': 'application/json' },
        status: 201,
      }
    )

  } catch (error) {
    console.error('Error creating gossip:', error)
    return new Response(
      JSON.stringify({ error: error.message }), 
      { status: 500 }
    )
  }
})
```

**Archivo:** `supabase/functions/create-gossip/moderation.ts`

```typescript
interface ModerationResult {
  decision: 'approve' | 'review' | 'reject'
  confidence: number
  flags: any
  priority: number
}

export async function moderateContent(
  subject: string, 
  content: string
): Promise<ModerationResult> {
  
  const combinedText = `${subject}\n\n${content}`

  try {
    // Llamar a OpenAI Moderation API
    const response = await fetch('https://api.openai.com/v1/moderations', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${Deno.env.get('OPENAI_API_KEY')}`,
      },
      body: JSON.stringify({
        input: combinedText,
        model: 'omni-moderation-latest',
      }),
    })

    const data = await response.json()
    const result = data.results[0]

    // Categorías que requieren rechazo inmediato
    const severeCategories = [
      'sexual/minors',
      'violence/graphic',
    ]

    // Categorías que requieren revisión humana
    const reviewCategories = [
      'harassment',
      'harassment/threatening',
      'hate',
      'hate/threatening',
      'sexual',
      'violence',
      'self-harm',
    ]

    // Determinar decisión
    let decision: 'approve' | 'review' | 'reject' = 'approve'
    let priority = 5

    // Rechazar si hay categorías severas
    for (const category of severeCategories) {
      if (result.categories[category]) {
        decision = 'reject'
        priority = 10
        break
      }
    }

    // Enviar a revisión si hay flags
    if (decision === 'approve' && result.flagged) {
      for (const category of reviewCategories) {
        if (result.categories[category]) {
          decision = 'review'
          priority = result.category_scores[category] > 0.8 ? 9 : 7
          break
        }
      }
    }

    // Reglas locales adicionales
    const localRules = checkLocalRules(combinedText)
    if (localRules.shouldReview && decision === 'approve') {
      decision = 'review'
      priority = 6
    }

    return {
      decision,
      confidence: Math.max(...Object.values(result.category_scores)),
      flags: result,
      priority,
    }

  } catch (error) {
    console.error('Moderation API error:', error)
    
    // FAIL CLOSED: Si la API falla, enviar a revisión
    return {
      decision: 'review',
      confidence: 0,
      flags: { error: error.message },
      priority: 8,
    }
  }
}

function checkLocalRules(text: string): { shouldReview: boolean } {
  // Reglas locales adicionales (spam, datos personales, etc.)
  const lowerText = text.toLowerCase()
  
  // Detectar posibles números de teléfono
  const phonePattern = /\b\d{10,}\b/
  if (phonePattern.test(text)) {
    return { shouldReview: true }
  }
  
  // Detectar emails
  const emailPattern = /\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b/
  if (emailPattern.test(text)) {
    return { shouldReview: true }
  }
  
  // Detectar URLs
  const urlPattern = /https?:\/\//
  if (urlPattern.test(text)) {
    return { shouldReview: true }
  }
  
  return { shouldReview: false }
}
```

### 6.3 Otras Edge Functions Importantes

**Lista de Edge Functions a implementar:**

```typescript
// 1. create-gossip - Ya implementada arriba
// 2. report-gossip - Procesar denuncias
// 3. moderate-gossip - Acción de moderador (aprobar/rechazar)
// 4. increment-view-count - Incrementar vistas
// 5. send-notification - Enviar notificación push
// 6. follow-user - Seguir usuario
// 7. unfollow-user - Dejar de seguir
```

---

## 7. Supabase Storage + CDN

### 7.1 Configuración de Storage

**Buckets a crear:**

```sql
-- Bucket para audios
INSERT INTO storage.buckets (id, name, public)
VALUES ('gossip-audios', 'gossip-audios', true);

-- Bucket para imágenes
INSERT INTO storage.buckets (id, name, public)
VALUES ('gossip-images', 'gossip-images', true);

-- Bucket para videos (futuro)
INSERT INTO storage.buckets (id, name, public)
VALUES ('gossip-videos', 'gossip-videos', true);

-- Bucket para avatares
INSERT INTO storage.buckets (id, name, public)
VALUES ('user-avatars', 'user-avatars', true);
```

### 7.2 Políticas de Storage

```sql
-- Políticas para gossip-audios
CREATE POLICY "Anyone can view audios"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'gossip-audios');

CREATE POLICY "Authenticated users can upload audios"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'gossip-audios' 
  AND auth.uid()::text = (storage.foldername(name))[1]
);

-- Políticas para gossip-images
CREATE POLICY "Anyone can view images"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'gossip-images');

CREATE POLICY "Authenticated users can upload images"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'gossip-images'
  AND auth.uid()::text = (storage.foldername(name))[1]
);
```

### 7.3 CDN (Cloudflare)

**Supabase Storage usa Cloudflare CDN automáticamente.** No requiere configuración adicional.

**Ventajas:**
- Caché global en 200+ ubicaciones
- Compresión automática de imágenes
- HTTPS automático
- DDoS protection

**URLs generadas:**

```
https://[project-id].supabase.co/storage/v1/object/public/gossip-audios/[user-id]/[file-name].mp3
```

**Optimización de imágenes (transformación on-the-fly):**

```
https://[project-id].supabase.co/storage/v1/render/image/public/gossip-images/[file]?width=400&height=400&quality=80
```

### 7.4 Upload desde Flutter

```dart
// lib/features/gossip/data/datasources/storage_remote_datasource.dart

class StorageRemoteDataSource {
  final SupabaseClient supabase;

  Future<String> uploadAudio(File audioFile, String userId) async {
    final fileName = '${uuid.v4()}.mp3';
    final filePath = '$userId/$fileName';

    await supabase.storage
        .from('gossip-audios')
        .upload(filePath, audioFile);

    final url = supabase.storage
        .from('gossip-audios')
        .getPublicUrl(filePath);

    return url;
  }

  Future<String> uploadImage(File imageFile, String userId) async {
    final fileName = '${uuid.v4()}.jpg';
    final filePath = '$userId/$fileName';

    await supabase.storage
        .from('gossip-images')
        .upload(filePath, imageFile);

    // Usar transformación para optimizar
    final url = supabase.storage
        .from('gossip-images')
        .getPublicUrl(filePath, transform: TransformOptions(
          width: 800,
          height: 800,
          quality: 80,
        ));

    return url;
  }
}
```

---

## 8. Búsqueda Full-Text

### 8.1 Configuración de PostgreSQL Full-Text Search

Ya configurado en el schema (ver sección 3.1):

```sql
-- Columna generada automáticamente
search_vector tsvector GENERATED ALWAYS AS (
  setweight(to_tsvector('spanish', coalesce(subject, '')), 'A') ||
  setweight(to_tsvector('spanish', coalesce(content, '')), 'B')
) STORED

-- Índice GIN para búsqueda rápida
CREATE INDEX idx_gossips_search ON gossips USING GIN(search_vector);
```

### 8.2 Query de Búsqueda desde Flutter

```dart
// Búsqueda simple
final results = await supabase
    .from('public_gossips')
    .select()
    .textSearch('search_vector', query, config: 'spanish')
    .limit(20);

// Búsqueda con ranking
final results = await supabase
    .rpc('search_gossips', params: {
      'query_text': query,
      'limit_count': 20,
    });
```

### 8.3 Función RPC para Búsqueda con Ranking

```sql
CREATE OR REPLACE FUNCTION search_gossips(
  query_text TEXT,
  limit_count INT DEFAULT 20
)
RETURNS TABLE (
  id UUID,
  subject TEXT,
  content TEXT,
  created_at TIMESTAMPTZ,
  like_count INT,
  comment_count INT,
  rank REAL
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    g.id,
    g.subject,
    g.content,
    g.created_at,
    g.like_count,
    g.comment_count,
    ts_rank(g.search_vector, websearch_to_tsquery('spanish', query_text)) AS rank
  FROM gossips g
  WHERE 
    g.search_vector @@ websearch_to_tsquery('spanish', query_text)
    AND g.status = 'published'
    AND g.moderation_status = 'approved'
    AND g.deleted_at IS NULL
  ORDER BY rank DESC, g.created_at DESC
  LIMIT limit_count;
END;
$$ LANGUAGE plpgsql STABLE;
```

### 8.4 Búsqueda de Usuarios

```sql
-- Índice para búsqueda de usuarios
CREATE INDEX idx_users_search ON users USING GIN(
  to_tsvector('spanish', coalesce(username, '') || ' ' || coalesce(display_name, ''))
);

-- Función de búsqueda
CREATE OR REPLACE FUNCTION search_users(
  query_text TEXT,
  limit_count INT DEFAULT 20
)
RETURNS TABLE (
  id UUID,
  username TEXT,
  display_name TEXT,
  avatar_url TEXT,
  followers_count INT
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    u.id,
    u.username,
    u.display_name,
    u.avatar_url,
    u.followers_count
  FROM users u
  WHERE 
    to_tsvector('spanish', u.username || ' ' || u.display_name) 
    @@ websearch_to_tsquery('spanish', query_text)
  ORDER BY u.followers_count DESC
  LIMIT limit_count;
END;
$$ LANGUAGE plpgsql STABLE;
```

### 8.5 ¿Cuándo usar motor de búsqueda externo?

**Usar PostgreSQL full-text si:**
- < 1M chismes en la base de datos
- Búsquedas simples por texto
- No necesitas typo tolerance avanzado

**Considerar Typesense/MeiliSearch si:**
- > 5M chismes
- Necesitas búsquedas <50ms
- Quieres typo tolerance, facetas, sinónimos
- Búsqueda con autocompletado en tiempo real

**Costo de Typesense Cloud:**
- $30-100/mes para 4-5M documentos
- Setup: 2-3 días
- Sincronización: Trigger PostgreSQL → Typesense

---

## 9. Geolocalización con PostGIS

### 9.1 Extensión PostGIS

Ya activada en schema (sección 3.1):

```sql
CREATE EXTENSION IF NOT EXISTS postgis;
```

### 9.2 Queries de Geolocalización

**Chismes por ciudad:**

```sql
SELECT * FROM gossips
WHERE country_id = 'co'
  AND region_id = 'antioquia'
  AND city_id = 'medellin'
  AND status = 'published'
  AND moderation_status = 'approved'
ORDER BY created_at DESC
LIMIT 20;
```

**Chismes cercanos (radio de 10km):**

```sql
-- Primero insertar ubicación al crear chisme
INSERT INTO gossips (..., location)
VALUES (..., ST_SetSRID(ST_MakePoint(-75.5636, 6.2442), 4326));

-- Buscar chismes a 10km de una ubicación
SELECT 
  id,
  subject,
  content,
  ST_Distance(location, ST_SetSRID(ST_MakePoint(-75.5636, 6.2442), 4326)::geography) AS distance_meters
FROM gossips
WHERE 
  ST_DWithin(
    location,
    ST_SetSRID(ST_MakePoint(-75.5636, 6.2442), 4326)::geography,
    10000 -- 10km en metros
  )
  AND status = 'published'
  AND moderation_status = 'approved'
ORDER BY distance_meters
LIMIT 20;
```

### 9.3 Función RPC para Chismes Cercanos

```sql
CREATE OR REPLACE FUNCTION nearby_gossips(
  lat DOUBLE PRECISION,
  lng DOUBLE PRECISION,
  radius_meters INT DEFAULT 10000,
  limit_count INT DEFAULT 20
)
RETURNS TABLE (
  id UUID,
  subject TEXT,
  content TEXT,
  distance_meters DOUBLE PRECISION,
  created_at TIMESTAMPTZ
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    g.id,
    g.subject,
    g.content,
    ST_Distance(
      g.location,
      ST_SetSRID(ST_MakePoint(lng, lat), 4326)::geography
    ) AS distance_meters,
    g.created_at
  FROM gossips g
  WHERE 
    g.location IS NOT NULL
    AND ST_DWithin(
      g.location,
      ST_SetSRID(ST_MakePoint(lng, lat), 4326)::geography,
      radius_meters
    )
    AND g.status = 'published'
    AND g.moderation_status = 'approved'
    AND g.deleted_at IS NULL
  ORDER BY distance_meters
  LIMIT limit_count;
END;
$$ LANGUAGE plpgsql STABLE;
```

### 9.4 Desde Flutter

```dart
final nearbyGossips = await supabase
    .rpc('nearby_gossips', params: {
      'lat': 6.2442, // Medellín
      'lng': -75.5636,
      'radius_meters': 10000, // 10km
      'limit_count': 20,
    });
```

---

## 10. Sistema de Moderación

### 10.1 Flujo de Moderación

```
Usuario crea chisme
        ↓
Edge Function: create-gossip
        ↓
Moderación IA (OpenAI)
        ↓
   ┌────┴────┬─────────┐
   ▼         ▼         ▼
Approve   Review    Reject
   │         │         │
   ▼         ▼         ▼
Published  Queue  Hidden
          ↓
    Moderador humano
          ↓
    ┌─────┴─────┐
    ▼           ▼
  Approve    Reject
    │           │
    ▼           ▼
Published    Hidden
```

### 10.2 OpenAI Moderation API

**Setup:**

1. Obtener API Key de OpenAI
2. Agregar a Supabase Edge Functions secrets:

```bash
supabase secrets set OPENAI_API_KEY=sk-...
```

**Implementación:** Ver sección 6.2 (`moderation.ts`)

**Modelo:** `omni-moderation-latest` (soporta texto e imágenes)

**Categorías detectadas:**
- `sexual/minors` → Rechazo inmediato
- `harassment`, `hate`, `violence` → Revisión humana
- `self-harm` → Revisión humana + protocolo de seguridad

**Costos OpenAI Moderation:**
- GRATIS hasta 1M requests/mes
- Después: $0.002 por 1k requests

### 10.3 Panel de Moderación (React)

**Estructura:**

```
admin-panel/
├── src/
│   ├── pages/
│   │   ├── ModerationQueue.tsx
│   │   ├── Reports.tsx
│   │   └── AuditLog.tsx
│   ├── components/
│   │   ├── GossipCard.tsx
│   │   ├── ModerationActions.tsx
│   │   └── ReportDetails.tsx
│   └── api/
│       └── supabase.ts
```

**ModerationQueue.tsx:**

```typescript
import { useEffect, useState } from 'react'
import { supabase } from '../api/supabase'

export function ModerationQueue() {
  const [queue, setQueue] = useState([])

  useEffect(() => {
    loadQueue()
  }, [])

  async function loadQueue() {
    const { data } = await supabase
      .from('moderation_queue')
      .select(`
        *,
        gossip:gossips (
          id,
          subject,
          content,
          audio_url,
          image_url,
          created_by,
          created_at
        )
      `)
      .eq('status', 'pending')
      .order('priority', { ascending: false })
      .order('created_at', { ascending: true })
      .limit(50)

    setQueue(data)
  }

  async function approve(queueItem) {
    // Llamar a Edge Function
    await supabase.functions.invoke('moderate-gossip', {
      body: {
        gossip_id: queueItem.gossip_id,
        action: 'approve',
        notes: 'Approved by moderator'
      }
    })

    loadQueue()
  }

  async function reject(queueItem, reason) {
    await supabase.functions.invoke('moderate-gossip', {
      body: {
        gossip_id: queueItem.gossip_id,
        action: 'reject',
        notes: reason
      }
    })

    loadQueue()
  }

  return (
    <div>
      <h1>Moderation Queue ({queue.length})</h1>
      {queue.map(item => (
        <GossipCard 
          key={item.id}
          gossip={item.gossip}
          aiFlags={item.ai_flags}
          onApprove={() => approve(item)}
          onReject={(reason) => reject(item, reason)}
        />
      ))}
    </div>
  )
}
```

---

## 11. Notificaciones Push

### 11.1 Firebase Cloud Messaging (FCM)

**Por qué FCM y no otra solución:**
- Supabase no tiene push notifications nativas
- FCM es gratis, robusto y bien documentado
- Compatible con Android y iOS

**Setup:**

1. Crear proyecto en Firebase Console (solo para FCM, no usar Firestore)
2. Descargar `google-services.json` (Android) y `GoogleService-Info.plist` (iOS)
3. Configurar en Flutter:

```yaml
# pubspec.yaml
dependencies:
  firebase_core: ^2.24.0
  firebase_messaging: ^14.7.6
  flutter_local_notifications: ^16.3.0
```

```dart
// lib/core/notifications/fcm_service.dart

class FCMService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final SupabaseClient _supabase;

  Future<void> init() async {
    // Pedir permisos
    await _fcm.requestPermission();

    // Obtener token
    final token = await _fcm.getToken();
    
    // Guardar token en Supabase
    if (token != null) {
      await _supabase
          .from('user_fcm_tokens')
          .upsert({
            'user_id': _supabase.auth.currentUser!.id,
            'token': token,
            'platform': Platform.isIOS ? 'ios' : 'android',
            'updated_at': DateTime.now().toIso8601String(),
          });
    }

    // Escuchar mensajes
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);
  }

  void _handleForegroundMessage(RemoteMessage message) {
    // Mostrar notificación local
    FlutterLocalNotificationsPlugin().show(
      message.hashCode,
      message.notification?.title,
      message.notification?.body,
      NotificationDetails(/* ... */),
    );
  }
}
```

### 11.2 Tabla para FCM Tokens

```sql
CREATE TABLE user_fcm_tokens (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  token TEXT NOT NULL,
  platform TEXT NOT NULL CHECK (platform IN ('ios', 'android')),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  UNIQUE(user_id, token)
);

CREATE INDEX idx_fcm_tokens_user ON user_fcm_tokens(user_id);
```

### 11.3 Edge Function para Enviar Notificaciones

**Archivo:** `supabase/functions/send-notification/index.ts`

```typescript
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

serve(async (req) => {
  try {
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    const { user_id, title, body, data } = await req.json()

    // Obtener tokens del usuario
    const { data: tokens } = await supabase
      .from('user_fcm_tokens')
      .select('token, platform')
      .eq('user_id', user_id)

    if (!tokens || tokens.length === 0) {
      return new Response(JSON.stringify({ message: 'No tokens found' }), { status: 200 })
    }

    // Enviar a FCM
    const fcmServerKey = Deno.env.get('FCM_SERVER_KEY')
    
    for (const tokenData of tokens) {
      await fetch('https://fcm.googleapis.com/fcm/send', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `key=${fcmServerKey}`,
        },
        body: JSON.stringify({
          to: tokenData.token,
          notification: {
            title,
            body,
          },
          data,
          priority: 'high',
        }),
      })
    }

    return new Response(JSON.stringify({ success: true }), { status: 200 })

  } catch (error) {
    console.error('Error sending notification:', error)
    return new Response(JSON.stringify({ error: error.message }), { status: 500 })
  }
})
```

### 11.4 Triggers para Notificaciones Automáticas

```sql
-- Notificar cuando alguien comenta tu chisme
CREATE OR REPLACE FUNCTION notify_gossip_comment()
RETURNS TRIGGER AS $$
DECLARE
  gossip_author UUID;
BEGIN
  -- Obtener autor del chisme
  SELECT created_by INTO gossip_author
  FROM gossips
  WHERE id = NEW.gossip_id;

  -- No notificar si el comentario es del mismo autor
  IF gossip_author != NEW.created_by THEN
    -- Llamar a Edge Function (usando pg_net extension)
    PERFORM net.http_post(
      url := 'https://[project-id].supabase.co/functions/v1/send-notification',
      headers := '{"Content-Type": "application/json", "Authorization": "Bearer ' || current_setting('request.jwt.claim.sub') || '"}'::jsonb,
      body := jsonb_build_object(
        'user_id', gossip_author,
        'title', 'New comment',
        'body', 'Someone commented on your gossip',
        'data', jsonb_build_object('gossip_id', NEW.gossip_id)
      )
    );
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_notify_gossip_comment
AFTER INSERT ON comments
FOR EACH ROW
EXECUTE FUNCTION notify_gossip_comment();
```

**Nota:** Instalar extensión `pg_net` para HTTP requests desde PostgreSQL:

```sql
CREATE EXTENSION IF NOT EXISTS pg_net;
```

---

## 12. Real-time Subscriptions

### 12.1 Configuración de Realtime

**Activar Realtime en tablas:**

```sql
-- Habilitar realtime en likes
ALTER PUBLICATION supabase_realtime ADD TABLE likes;

-- Habilitar realtime en comments
ALTER PUBLICATION supabase_realtime ADD TABLE comments;
```

### 12.2 Suscribirse a Cambios desde Flutter

```dart
// lib/features/gossip/presentation/screens/gossip_detail_screen.dart

class GossipDetailScreen extends StatefulWidget {
  final String gossipId;

  @override
  _GossipDetailScreenState createState() => _GossipDetailScreenState();
}

class _GossipDetailScreenState extends State<GossipDetailScreen> {
  late RealtimeChannel _commentsChannel;
  List<Comment> _comments = [];

  @override
  void initState() {
    super.initState();
    _loadComments();
    _subscribeToComments();
  }

  void _subscribeToComments() {
    _commentsChannel = supabase
        .channel('comments:${widget.gossipId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'comments',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'gossip_id',
            value: widget.gossipId,
          ),
          callback: (payload) {
            setState(() {
              _comments.add(Comment.fromJson(payload.newRecord));
            });
          },
        )
        .subscribe();
  }

  @override
  void dispose() {
    _commentsChannel.unsubscribe();
    super.dispose();
  }

  // ...
}
```

### 12.3 Actualizar Contadores en Tiempo Real

```dart
// Suscribirse a cambios en likes
supabase
    .channel('gossip:${gossipId}')
    .onPostgresChanges(
      event: PostgresChangeEvent.update,
      schema: 'public',
      table: 'gossips',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'id',
        value: gossipId,
      ),
      callback: (payload) {
        setState(() {
          likeCount = payload.newRecord['like_count'];
          commentCount = payload.newRecord['comment_count'];
        });
      },
    )
    .subscribe();
```

---

## 13. Panel Web de Moderación

### 13.1 Tech Stack del Panel

```yaml
Framework: React 18 + Vite
Lenguaje: TypeScript
UI Library: shadcn/ui (Radix UI + Tailwind)
Estado: TanStack Query + Zustand
Autenticación: Supabase Auth (mismo proyecto)
Hosting: Vercel (gratis tier suficiente)
```

### 13.2 Estructura del Proyecto

```
admin-panel/
├── src/
│   ├── pages/
│   │   ├── Login.tsx
│   │   ├── Dashboard.tsx
│   │   ├── ModerationQueue.tsx
│   │   ├── Reports.tsx
│   │   ├── Users.tsx
│   │   └── AuditLog.tsx
│   ├── components/
│   │   ├── ui/ (shadcn components)
│   │   ├── GossipCard.tsx
│   │   ├── ReportCard.tsx
│   │   └── ModerationActions.tsx
│   ├── api/
│   │   └── supabase.ts
│   ├── hooks/
│   │   └── useModeration.ts
│   └── App.tsx
├── public/
├── package.json
├── vite.config.ts
└── tailwind.config.js
```

### 13.3 Autenticación de Moderadores

**Protección por rol:**

```typescript
// src/api/supabase.ts
import { createClient } from '@supabase/supabase-js'

export const supabase = createClient(
  import.meta.env.VITE_SUPABASE_URL,
  import.meta.env.VITE_SUPABASE_ANON_KEY
)

// Verificar si el usuario es moderador
export async function isModerator(): Promise<boolean> {
  const { data: { user } } = await supabase.auth.getUser()
  
  if (!user) return false

  const { data } = await supabase
    .from('users')
    .select('role')
    .eq('id', user.id)
    .single()

  return data?.role === 'moderator' || data?.role === 'admin'
}
```

```typescript
// src/App.tsx
import { useEffect, useState } from 'react'
import { supabase, isModerator } from './api/supabase'

function App() {
  const [authorized, setAuthorized] = useState(false)

  useEffect(() => {
    checkAuth()
  }, [])

  async function checkAuth() {
    const isAuth = await isModerator()
    setAuthorized(isAuth)
  }

  if (!authorized) {
    return <div>Unauthorized - Moderators only</div>
  }

  return <Dashboard />
}
```

### 13.4 Deploy en Vercel

```bash
# Desde admin-panel/
npm run build

# Deploy
vercel --prod
```

**Environment variables en Vercel:**
```
VITE_SUPABASE_URL=https://[project-id].supabase.co
VITE_SUPABASE_ANON_KEY=[anon-key]
```

---

## 14. Optimización y Caché

### 14.1 Materialized Views para Queries Pesados

**Top chismes (actualizado cada 5 minutos):**

```sql
-- Crear materialized view
CREATE MATERIALIZED VIEW top_gossips AS
SELECT 
  id,
  subject,
  content,
  image_url,
  view_count,
  like_count,
  comment_count,
  created_at
FROM gossips
WHERE 
  status = 'published'
  AND moderation_status = 'approved'
  AND deleted_at IS NULL
ORDER BY 
  (view_count * 0.4 + like_count * 0.4 + comment_count * 0.2) DESC,
  created_at DESC
LIMIT 100;

-- Índice
CREATE INDEX idx_top_gossips_id ON top_gossips(id);

-- Refresh automático con pg_cron
CREATE EXTENSION IF NOT EXISTS pg_cron;

SELECT cron.schedule(
  'refresh-top-gossips',
  '*/5 * * * *', -- Cada 5 minutos
  $$REFRESH MATERIALIZED VIEW CONCURRENTLY top_gossips$$
);
```

### 14.2 Caché en Flutter

```dart
// lib/core/cache/cache_service.dart

class CacheService {
  final _storage = FlutterSecureStorage();
  final _memoryCache = <String, CachedItem>{};

  Future<T?> get<T>(String key, T Function(Map<String, dynamic>) fromJson) async {
    // 1. Revisar memoria
    if (_memoryCache.containsKey(key)) {
      final cached = _memoryCache[key]!;
      if (!cached.isExpired) {
        return cached.value as T;
      }
    }

    // 2. Revisar storage
    final stored = await _storage.read(key: key);
    if (stored != null) {
      final json = jsonDecode(stored);
      final item = CachedItem.fromJson(json);
      
      if (!item.isExpired) {
        _memoryCache[key] = item;
        return fromJson(item.value);
      }
    }

    return null;
  }

  Future<void> set<T>(String key, T value, Duration ttl) async {
    final item = CachedItem(
      value: value,
      expiresAt: DateTime.now().add(ttl),
    );

    _memoryCache[key] = item;
    await _storage.write(key: key, value: jsonEncode(item.toJson()));
  }
}

class CachedItem {
  final dynamic value;
  final DateTime expiresAt;

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  CachedItem({required this.value, required this.expiresAt});

  Map<String, dynamic> toJson() => {
    'value': value,
    'expiresAt': expiresAt.toIso8601String(),
  };

  factory CachedItem.fromJson(Map<String, dynamic> json) => CachedItem(
    value: json['value'],
    expiresAt: DateTime.parse(json['expiresAt']),
  );
}
```

### 14.3 Estrategia de Caché

```dart
// lib/features/gossip/data/repositories/gossip_repository_impl.dart

class GossipRepositoryImpl implements GossipRepository {
  final GossipRemoteDataSource remoteDataSource;
  final CacheService cacheService;

  @override
  Future<Result<Failure, List<Gossip>>> getTopGossips() async {
    // 1. Intentar caché (5 minutos)
    final cached = await cacheService.get<List<Gossip>>(
      'top_gossips',
      (json) => (json['items'] as List).map((e) => Gossip.fromJson(e)).toList(),
    );

    if (cached != null) {
      return Success(cached);
    }

    // 2. Fetch desde Supabase
    try {
      final gossips = await remoteDataSource.getTopGossips();
      
      // 3. Cachear resultado
      await cacheService.set('top_gossips', gossips, Duration(minutes: 5));
      
      return Success(gossips);
    } catch (e) {
      return Failure(ServerFailure(e.toString()));
    }
  }
}
```

---

## 15. Monitoreo y Observabilidad

### 15.1 Supabase Dashboard

**Monitoreo nativo de Supabase:**

- **Database**: CPU, memoria, conexiones activas
- **Storage**: GB usados, requests/min
- **Edge Functions**: Invocaciones, errores, latencia
- **Auth**: Logins/día, usuarios activos

**Acceso:** `https://app.supabase.com/project/[project-id]`

### 15.2 Sentry para Errores

**Setup:**

```yaml
# pubspec.yaml
dependencies:
  sentry_flutter: ^7.14.0
```

```dart
// lib/main.dart
import 'package:sentry_flutter/sentry_flutter.dart';

Future<void> main() async {
  await SentryFlutter.init(
    (options) {
      options.dsn = 'https://[your-dsn]@sentry.io/[project-id]';
      options.tracesSampleRate = 0.1;
      options.environment = 'production';
    },
    appRunner: () => runApp(MyApp()),
  );
}
```

**Capturar errores:**

```dart
try {
  await supabase.from('gossips').select();
} catch (error, stackTrace) {
  Sentry.captureException(error, stackTrace: stackTrace);
  rethrow;
}
```

### 15.3 PostHog para Analytics

**Setup:**

```yaml
# pubspec.yaml
dependencies:
  posthog_flutter: ^3.1.0
```

```dart
// lib/core/analytics/analytics_service.dart
import 'package:posthog_flutter/posthog_flutter.dart';

class AnalyticsService {
  Future<void> init() async {
    await Posthog().setup(
      apiKey: 'phc_...',
      host: 'https://app.posthog.com',
    );
  }

  void trackEvent(String event, [Map<String, dynamic>? properties]) {
    Posthog().capture(eventName: event, properties: properties);
  }

  void identifyUser(String userId, Map<String, dynamic> traits) {
    Posthog().identify(userId: userId, userProperties: traits);
  }
}
```

**Eventos importantes a trackear:**

```dart
// Usuario crea chisme
analytics.trackEvent('gossip_created', {
  'published_as': 'anonymous',
  'has_audio': true,
  'city_id': 'medellin',
});

// Usuario busca
analytics.trackEvent('search_performed', {
  'query': query,
  'results_count': results.length,
});

// Usuario reporta
analytics.trackEvent('gossip_reported', {
  'reason': 'spam',
  'gossip_id': gossipId,
});
```

### 15.4 Logs Estructurados

**Edge Functions:**

```typescript
// Usar structured logging en Edge Functions
console.log(JSON.stringify({
  level: 'info',
  message: 'Gossip created',
  gossip_id: gossip.id,
  user_id: user.id,
  moderation_decision: moderationResult.decision,
  timestamp: new Date().toISOString(),
}));
```

**Acceso a logs:**

```bash
# CLI de Supabase
supabase functions logs create-gossip --tail

# O en Dashboard: Functions > Logs
```

---

## 16. Plan de Implementación

### 16.1 Fase 1: MVP Core (Semanas 1-6)

**Semana 1-2: Setup Base**
- [ ] Crear proyecto Supabase
- [ ] Configurar PostgreSQL schema (users, gossips, comments, likes)
- [ ] Activar PostGIS extension
- [ ] Configurar Row Level Security (RLS)
- [ ] Setup Flutter con supabase_flutter package

**Semana 3-4: Autenticación y Usuarios**
- [ ] Configurar Supabase Auth (Google, Facebook, Apple)
- [ ] Implementar login en Flutter
- [ ] Edge Function: create-user-profile
- [ ] Pantalla de registro con ubicación

**Semana 5-6: Chismes Core**
- [ ] Edge Function: create-gossip con moderación básica
- [ ] Setup OpenAI Moderation API
- [ ] Implementar CRUD de chismes en Flutter
- [ ] Feed de chismes (query por ciudad)
- [ ] Storage: Subir audios

### 16.2 Fase 2: Interacciones Sociales (Semanas 7-10)

**Semana 7-8: Comentarios y Likes**
- [ ] Implementar sistema de comentarios
- [ ] Implementar likes
- [ ] Real-time subscriptions (comentarios en vivo)
- [ ] Triggers para contadores

**Semana 9-10: Búsqueda y Descubrimiento**
- [ ] Implementar búsqueda full-text
- [ ] Búsqueda de usuarios
- [ ] Queries de geolocalización (chismes cercanos)
- [ ] Top chismes (materialized view)

### 16.3 Fase 3: Moderación y Administración (Semanas 11-14)

**Semana 11-12: Sistema de Denuncias**
- [ ] Tabla reports
- [ ] Edge Function: report-gossip
- [ ] Auto-hide con 10+ denuncias
- [ ] Moderation queue

**Semana 13-14: Panel de Moderación**
- [ ] Setup React admin panel
- [ ] Integrar con Supabase Auth
- [ ] Vista de moderation queue
- [ ] Edge Function: moderate-gossip (aprobar/rechazar)
- [ ] Deploy en Vercel

### 16.4 Fase 4: Notificaciones y Social (Semanas 15-16)

**Semana 15: Notificaciones Push**
- [ ] Setup Firebase Cloud Messaging
- [ ] Tabla user_fcm_tokens
- [ ] Edge Function: send-notification
- [ ] Triggers para notificaciones automáticas

**Semana 16: Sistema de Seguimiento**
- [ ] Tabla followers
- [ ] Follow/unfollow endpoints
- [ ] Feed de usuarios seguidos
- [ ] Notificaciones de nuevos chismes

### 16.5 Fase 5: Optimización y Launch (Semanas 17-18)

**Semana 17: Performance**
- [ ] Implementar caché en Flutter
- [ ] Optimizar queries (índices, explain analyze)
- [ ] Configurar CDN de Storage
- [ ] Materialized views para dashboards

**Semana 18: Testing y Deploy**
- [ ] Testing end-to-end
- [ ] Security audit (RLS, Edge Functions)
- [ ] Setup monitoring (Sentry, PostHog)
- [ ] Staging environment
- [ ] Launch en 1 ciudad (Medellín)

---

## 17. Costos Proyectados

### 17.1 Fase MVP (0-10k usuarios)

```yaml
Supabase:
  Plan: Pro ($25/mes)
  Incluye:
    - 8GB database
    - 100GB bandwidth
    - 50GB storage
    - 2M Edge Function invocations
  Costo: $25/mes

OpenAI Moderation:
  Requests: ~50k/mes
  Costo: GRATIS (bajo 1M/mes)

Firebase (solo FCM):
  Costo: GRATIS

Vercel (admin panel):
  Plan: Hobby
  Costo: GRATIS

Sentry:
  Plan: Developer (10k errors/mes)
  Costo: GRATIS

PostHog:
  Plan: Free (1M events/mes)
  Costo: GRATIS

TOTAL MVP: $25/mes
```

### 17.2 Fase Crecimiento (100k-500k usuarios)

```yaml
Supabase:
  Plan: Team ($599/mes)
  Incluye:
    - Compute dedicated
    - Read replicas
    - Daily backups
  Costo: $599/mes

OpenAI Moderation:
  Requests: ~500k/mes
  Costo: GRATIS (bajo 1M/mes)

Storage adicional:
  +500GB: $0.021/GB/mes = $10/mes

Bandwidth adicional:
  +1TB: $0.09/GB = $90/mes

Firebase FCM:
  Costo: GRATIS

Vercel:
  Plan: Pro ($20/mes)

Sentry:
  Plan: Team ($26/mes)

PostHog:
  Plan: Growth ($0.00031/evento) ~5M eventos = $1,550/mes

TOTAL: ~$2,300/mes
```

### 17.3 Fase Escala (1-5M usuarios)

```yaml
Supabase:
  Plan: Enterprise (custom pricing)
  Estimado: $2,000-3,000/mes
  Incluye:
    - Multi-region
    - 99.99% SLA
    - Dedicated support
    - Custom compute

OpenAI Moderation:
  Requests: ~2M/mes
  Costo: 1M gratis + 1M * $0.002 = $2/mes

Storage:
  2TB: $0.021/GB * 2000 = $42/mes

Bandwidth:
  10TB: $0.09/GB * 10000 = $900/mes

Firebase FCM:
  Costo: GRATIS

Vercel:
  Plan: Pro: $20/mes

Sentry:
  Plan: Business: $80/mes

PostHog:
  ~50M eventos/mes: $15,500/mes

TOTAL: ~$18,500/mes
```

**Alternativa:** Usar Supabase analytics en lugar de PostHog = Ahorro de $15k/mes

**Total ajustado:** ~$3,500-4,000/mes

---

## 18. Migración Futura

### 18.1 ¿Cuándo considerar migración?

**Quedarse con Supabase si:**
- ✅ Costos son aceptables (~$3-4k/mes con 4-5M usuarios)
- ✅ Performance es suficiente (<200ms queries)
- ✅ No hay necesidad de optimizaciones específicas

**Considerar migración a backend custom si:**
- ❌ Costos superan $5k/mes y puedes optimizar
- ❌ Necesitas latencias <50ms en operaciones específicas
- ❌ Requieres lógica de negocio muy compleja que Edge Functions no maneja bien
- ❌ Necesitas multi-región con data sovereignty estricta

### 18.2 Path de Migración

**Ventaja de Supabase:** PostgreSQL estándar = migración más fácil

**Opción 1: Self-hosted Supabase**
- Costo: $500-1000/mes infraestructura
- Complejidad: Media
- Beneficio: Control total, mismo stack

**Opción 2: Custom backend (Spring Boot / Node.js)**
- Costo: $100-150k desarrollo + $5-10k/mes operación
- Complejidad: Alta
- Beneficio: Optimización máxima

**Pasos para migrar:**

1. **Exportar datos de Supabase:**
```bash
pg_dump -h db.[project-id].supabase.co -U postgres -d postgres > dump.sql
```

2. **Migrar schema a nuevo PostgreSQL**
3. **Reimplementar Edge Functions como API endpoints**
4. **Dual-write temporalmente** (Supabase + nuevo backend)
5. **Migrar clientes gradualmente**
6. **Apagar Supabase**

---

## Conclusión

Este documento describe la arquitectura completa para implementar **Chismes** con Supabase.

**Ventajas clave:**
- ✅ MVP en 3-4 meses
- ✅ Costos predecibles: $25/mes → $3-4k/mes con 4-5M usuarios
- ✅ PostgreSQL = queries complejos, búsqueda full-text, geolocalización
- ✅ Edge Functions + RLS = backend real con control total
- ✅ Sin vendor lock-in crítico (PostgreSQL estándar)

**Próximos pasos:**
1. Crear proyecto en Supabase
2. Implementar schema de base de datos
3. Configurar autenticación social
4. Desarrollar Edge Functions core
5. Integrar en Flutter

**Contacto para dudas:**
- Documentación Supabase: https://supabase.com/docs
- PostgreSQL Full-Text Search: https://www.postgresql.org/docs/current/textsearch.html
- PostGIS: https://postgis.net/documentation/
- OpenAI Moderation: https://platform.openai.com/docs/guides/moderation

---

**Última actualización:** Octubre 2026  
**Versión:** 1.0
