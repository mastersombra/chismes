-- =====================================================
-- 016: Registro de aceptación de las políticas legales
-- =====================================================
-- Prueba de QUÉ versión de la Política de Privacidad y de los Términos de Uso
-- aceptó cada usuario y CUÁNDO (GDPR art. 7.1: poder demostrarlo).
--
-- La app muestra "Al continuar aceptas los Términos y la Política de
-- Privacidad" antes de CUALQUIER forma de crear la cuenta (email, Google,
-- Apple). Crear la cuenta = aceptar las versiones vigentes en ese momento, así
-- que el registro lo hace el servidor con un trigger en auth.users: el cliente
-- no envía nada y no puede falsear la versión ni la fecha.
--
-- legal_documents guarda la versión vigente. Al cambiar una política:
--   1. Editar assets/legal/<doc>.es.md y .en.md (subir "Versión" del encabezado)
--   2. Nueva migración: UPDATE legal_documents SET current_version = 'X.Y'
--   3. (Pendiente 🟡) pedir re-aceptación a quien tenga una versión anterior:
--      se compara policy_acceptances con legal_documents; no cambia esta tabla.
--
-- Usuarios creados antes de esta migración: no se rellenan (no vieron el
-- aviso). Solo aplica a chismes-dev, que se resetea.
--
-- Eliminación de cuenta: las aceptaciones se borran en cascada con el usuario.
--
-- Acceso: el usuario lee solo las suyas (derecho de acceso); nadie las escribe
-- desde la API. legal_documents es pública (solo lectura).
-- =====================================================

-- =====================================================
-- 1. VERSIONES VIGENTES
-- =====================================================

CREATE TABLE legal_documents (
  document TEXT PRIMARY KEY CHECK (document IN ('privacy_policy', 'terms_of_service')),
  current_version TEXT NOT NULL CHECK (current_version ~ '^[0-9]+\.[0-9]+$'),
  updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

COMMENT ON TABLE legal_documents IS
  'Versión vigente de cada política legal. Debe coincidir con el encabezado de assets/legal/*.md';

INSERT INTO legal_documents (document, current_version) VALUES
  ('privacy_policy', '1.2'),
  ('terms_of_service', '1.1');

CREATE TRIGGER on_legal_document_updated
  BEFORE UPDATE ON legal_documents
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_updated_at();

ALTER TABLE legal_documents ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE legal_documents FROM anon, authenticated;
GRANT SELECT ON TABLE legal_documents TO anon, authenticated;
GRANT ALL ON TABLE legal_documents TO service_role;

CREATE POLICY "legal_documents_select_all"
  ON legal_documents FOR SELECT
  TO anon, authenticated
  USING (TRUE);

-- =====================================================
-- 2. ACEPTACIONES
-- =====================================================

CREATE TABLE policy_acceptances (
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  document TEXT NOT NULL REFERENCES legal_documents(document),
  version TEXT NOT NULL,
  accepted_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  PRIMARY KEY (user_id, document, version)
);

COMMENT ON TABLE policy_acceptances IS
  'Qué versión de cada política aceptó cada usuario y cuándo. Solo la escribe el servidor';

ALTER TABLE policy_acceptances ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE policy_acceptances FROM anon, authenticated;
GRANT SELECT ON TABLE policy_acceptances TO authenticated;
GRANT ALL ON TABLE policy_acceptances TO service_role;

CREATE POLICY "policy_acceptances_select_own"
  ON policy_acceptances FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

-- =====================================================
-- 3. REGISTRO AL CREAR LA CUENTA
-- =====================================================
-- Trigger aparte de handle_new_user (005): si este fallara, el registro
-- falla entero (mejor que una cuenta sin prueba de aceptación).

CREATE OR REPLACE FUNCTION public.record_policy_acceptances()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.policy_acceptances (user_id, document, version)
  SELECT NEW.id, document, current_version
  FROM public.legal_documents;
  RETURN NEW;
END;
$$;

REVOKE ALL ON FUNCTION public.record_policy_acceptances() FROM PUBLIC, anon, authenticated;

CREATE TRIGGER on_auth_user_created_record_policies
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.record_policy_acceptances();
