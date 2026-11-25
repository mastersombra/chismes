-- =====================================================
-- Test: aceptación de políticas (016_policy_acceptances.sql)
-- =====================================================
-- P1: crear un usuario registra las versiones vigentes de las dos políticas
-- P2: con una versión nueva, los usuarios nuevos registran la nueva y los
--     anteriores conservan la que aceptaron
-- P3: el usuario lee solo sus aceptaciones; anon no lee ninguna
-- P4: los clientes no pueden escribir aceptaciones ni cambiar versiones
--     (sí leer las versiones vigentes)
-- P5: eliminar el usuario borra sus aceptaciones en cascada
-- P6: versión con formato inválido → rechazada
--
-- Correr en un Supabase LOCAL con migraciones + seed aplicados:
--   docker exec -i supabase_db_<project_id> psql -U postgres < supabase/tests/008_policy_acceptances_test.sql
-- Todo corre en una transacción con ROLLBACK (no deja datos).
-- =====================================================
\set ON_ERROR_STOP 1
BEGIN;

-- Con triggers (es lo que se prueba): U1 y U2 con las versiones iniciales
INSERT INTO auth.users (id, instance_id, aud, role, email) VALUES
 ('c1000000-0000-4000-8000-000000000001','00000000-0000-0000-0000-000000000000','authenticated','authenticated','p1@t.co'),
 ('c1000000-0000-4000-8000-000000000002','00000000-0000-0000-0000-000000000000','authenticated','authenticated','p2@t.co');

-- P1
DO $$
DECLARE
  v_count INT;
BEGIN
  SELECT count(*) INTO v_count FROM policy_acceptances
  WHERE user_id = 'c1000000-0000-4000-8000-000000000001';
  IF v_count <> 2 THEN
    RAISE EXCEPTION 'P1: esperaba 2 aceptaciones, hay %', v_count;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM policy_acceptances a
    JOIN legal_documents d USING (document)
    WHERE a.user_id = 'c1000000-0000-4000-8000-000000000001'
      AND a.version = d.current_version
      AND a.accepted_at > now() - interval '1 minute'
    GROUP BY a.user_id HAVING count(*) = 2
  ) THEN
    RAISE EXCEPTION 'P1: las aceptaciones no tienen la versión vigente o la fecha';
  END IF;
  RAISE NOTICE 'P1 ok';
END $$;

-- P2: nueva versión de la política de privacidad
UPDATE legal_documents SET current_version = '9.0' WHERE document = 'privacy_policy';
INSERT INTO auth.users (id, instance_id, aud, role, email) VALUES
 ('c1000000-0000-4000-8000-000000000003','00000000-0000-0000-0000-000000000000','authenticated','authenticated','p3@t.co');
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM policy_acceptances
    WHERE user_id = 'c1000000-0000-4000-8000-000000000003'
      AND document = 'privacy_policy' AND version = '9.0') THEN
    RAISE EXCEPTION 'P2: el usuario nuevo no registró la versión nueva';
  END IF;
  IF EXISTS (SELECT 1 FROM policy_acceptances
    WHERE user_id = 'c1000000-0000-4000-8000-000000000001'
      AND document = 'privacy_policy' AND version = '9.0') THEN
    RAISE EXCEPTION 'P2: el usuario anterior no debe tener la versión nueva';
  END IF;
  RAISE NOTICE 'P2 ok';
END $$;

-- P3 + P4: authenticated (U1)
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claims','{"sub":"c1000000-0000-4000-8000-000000000001","role":"authenticated"}',true);
DO $$
DECLARE
  v_own INT;
  v_other INT;
BEGIN
  SELECT count(*) INTO v_own FROM policy_acceptances
  WHERE user_id = 'c1000000-0000-4000-8000-000000000001';
  SELECT count(*) INTO v_other FROM policy_acceptances
  WHERE user_id <> 'c1000000-0000-4000-8000-000000000001';
  IF v_own <> 2 OR v_other <> 0 THEN
    RAISE EXCEPTION 'P3: propias=% (esperaba 2), ajenas=% (esperaba 0)', v_own, v_other;
  END IF;

  PERFORM 1 FROM legal_documents; -- leer versiones vigentes: permitido

  BEGIN
    INSERT INTO policy_acceptances (user_id, document, version)
    VALUES ('c1000000-0000-4000-8000-000000000001', 'terms_of_service', '0.1');
    RAISE EXCEPTION 'P4: authenticated pudo insertar una aceptación';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;

  BEGIN
    UPDATE policy_acceptances SET accepted_at = now() - interval '1 year'
    WHERE user_id = 'c1000000-0000-4000-8000-000000000001';
    RAISE EXCEPTION 'P4: authenticated pudo cambiar una aceptación';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;

  BEGIN
    DELETE FROM policy_acceptances
    WHERE user_id = 'c1000000-0000-4000-8000-000000000001';
    RAISE EXCEPTION 'P4: authenticated pudo borrar sus aceptaciones';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;

  BEGIN
    UPDATE legal_documents SET current_version = '0.1';
    RAISE EXCEPTION 'P4: authenticated pudo cambiar la versión vigente';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;

  BEGIN
    PERFORM record_policy_acceptances();
    RAISE EXCEPTION 'P4: authenticated pudo ejecutar la función del trigger';
  EXCEPTION WHEN insufficient_privilege OR feature_not_supported THEN NULL;
  END;
  RAISE NOTICE 'P3/P4 authenticated ok';
END $$;
RESET ROLE;

-- P3 + P4: anon
SET LOCAL ROLE anon;
SELECT set_config('request.jwt.claims','{"role":"anon"}',true);
DO $$
DECLARE
  v_count INT;
BEGIN
  PERFORM 1 FROM legal_documents; -- permitido

  BEGIN
    SELECT count(*) INTO v_count FROM policy_acceptances;
    RAISE EXCEPTION 'P3: anon pudo leer aceptaciones (% filas)', v_count;
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;

  BEGIN
    INSERT INTO legal_documents (document, current_version) VALUES ('privacy_policy', '0.1');
    RAISE EXCEPTION 'P4: anon pudo escribir legal_documents';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;
  RAISE NOTICE 'P3/P4 anon ok';
END $$;
RESET ROLE;

-- P5: eliminar U2 → sin aceptaciones; U1 intacto
DELETE FROM auth.users WHERE id = 'c1000000-0000-4000-8000-000000000002';
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM policy_acceptances
    WHERE user_id = 'c1000000-0000-4000-8000-000000000002') THEN
    RAISE EXCEPTION 'P5: quedaron aceptaciones del usuario eliminado';
  END IF;
  IF (SELECT count(*) FROM policy_acceptances
      WHERE user_id = 'c1000000-0000-4000-8000-000000000001') <> 2 THEN
    RAISE EXCEPTION 'P5: se borraron aceptaciones de otro usuario';
  END IF;
  RAISE NOTICE 'P5 ok';
END $$;

-- P6
DO $$
BEGIN
  BEGIN
    UPDATE legal_documents SET current_version = 'v2' WHERE document = 'terms_of_service';
    RAISE EXCEPTION 'P6: aceptó una versión con formato inválido';
  EXCEPTION WHEN check_violation THEN NULL;
  END;
  RAISE NOTICE 'P6 ok';
END $$;

ROLLBACK;
