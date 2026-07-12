-- ============================================================
-- SECTION 9 — ROW-LEVEL SECURITY (RLS)
-- Enforces minimum-necessary access at the database layer.
-- Application must SET LOCAL app.current_user_id / app.user_role
-- before executing queries in a transaction.
--
-- Roles used:
--   db_patient      : Patient portal user — sees only their own records
--   db_clinician    : Licensed clinician — sees patients in their care team
--   db_admin        : Platform administrator — broader access, always audited
--   db_system       : Internal service accounts — full access (not for humans)
--   db_auditor      : Compliance / audit officer — read-only audit schema
-- ============================================================

-- ── Create roles (must exist before policies reference them) ──
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'db_patient')   THEN CREATE ROLE db_patient   NOLOGIN; END IF;
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'db_clinician') THEN CREATE ROLE db_clinician NOLOGIN; END IF;
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'db_admin')     THEN CREATE ROLE db_admin     NOLOGIN; END IF;
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'db_system')    THEN CREATE ROLE db_system    NOLOGIN; END IF;
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'db_auditor')   THEN CREATE ROLE db_auditor   NOLOGIN; END IF;
END $$;

-- ── Helper: current session context ──────────────────────────
-- Application must call SET LOCAL at the start of each request:
--   SET LOCAL app.current_user_id  = '<uuid>';
--   SET LOCAL app.user_role        = 'patient|clinician|admin|system';
--   SET LOCAL app.patient_id       = '<uuid>';    -- for patient sessions
--   SET LOCAL app.organization_id  = '<uuid>';    -- for clinician sessions

SET search_path TO dev, public;

CREATE OR REPLACE FUNCTION current_user_id() RETURNS UUID
    LANGUAGE sql STABLE SECURITY DEFINER AS
$$SELECT NULLIF(current_setting('app.current_user_id', true), '')::UUID$$;

CREATE OR REPLACE FUNCTION current_user_role() RETURNS TEXT
    LANGUAGE sql STABLE SECURITY DEFINER AS
$$SELECT COALESCE(current_setting('app.user_role', true), 'anonymous')$$;

CREATE OR REPLACE FUNCTION current_patient_id() RETURNS UUID
    LANGUAGE sql STABLE SECURITY DEFINER AS
$$SELECT NULLIF(current_setting('app.patient_id', true), '')::UUID$$;

CREATE OR REPLACE FUNCTION current_org_id() RETURNS UUID
    LANGUAGE sql STABLE SECURITY DEFINER AS
$$SELECT NULLIF(current_setting('app.organization_id', true), '')::UUID$$;

-- Checks whether the current clinician is in this patient's care team
SET search_path TO dev, public;

CREATE OR REPLACE FUNCTION clinician_has_access_to_patient(p_patient_id UUID)
RETURNS BOOLEAN
LANGUAGE sql STABLE SECURITY DEFINER AS
$$
    SELECT EXISTS (
        SELECT 1
        FROM   care_team_participants ctp
        JOIN   care_teams ct ON ct.id = ctp.care_team_id
        WHERE  ct.patient_id       = p_patient_id
          AND  ctp.practitioner_id = current_user_id()
          AND  ctp.is_active       = true
    )
    OR EXISTS (
        SELECT 1
        FROM   encounters e
        WHERE  e.patient_id               = p_patient_id
          AND  e.primary_practitioner_id  = current_user_id()
          AND  e.deleted_at IS NULL
    );
$$;


-- ── Enable RLS on all tables containing PHI ──────────────────

SET search_path TO dev, public;

ALTER TABLE patients               ENABLE ROW LEVEL SECURITY;
ALTER TABLE patient_identifiers    ENABLE ROW LEVEL SECURITY;
ALTER TABLE patient_names          ENABLE ROW LEVEL SECURITY;
ALTER TABLE patient_addresses      ENABLE ROW LEVEL SECURITY;
ALTER TABLE patient_telecoms       ENABLE ROW LEVEL SECURITY;
ALTER TABLE patient_contacts       ENABLE ROW LEVEL SECURITY;
ALTER TABLE patient_languages      ENABLE ROW LEVEL SECURITY;
ALTER TABLE patient_race_ethnicities ENABLE ROW LEVEL SECURITY;
ALTER TABLE patient_flags          ENABLE ROW LEVEL SECURITY;

SET search_path TO dev, public;

ALTER TABLE coverage               ENABLE ROW LEVEL SECURITY;

SET search_path TO dev, public;

ALTER TABLE encounters            ENABLE ROW LEVEL SECURITY;
ALTER TABLE observations          ENABLE ROW LEVEL SECURITY;
ALTER TABLE conditions            ENABLE ROW LEVEL SECURITY;
ALTER TABLE allergy_intolerances  ENABLE ROW LEVEL SECURITY;
ALTER TABLE medication_requests   ENABLE ROW LEVEL SECURITY;
ALTER TABLE service_requests      ENABLE ROW LEVEL SECURITY;
ALTER TABLE diagnostic_reports    ENABLE ROW LEVEL SECURITY;
ALTER TABLE care_plans            ENABLE ROW LEVEL SECURITY;
ALTER TABLE documents             ENABLE ROW LEVEL SECURITY;

SET search_path TO dev, public;

ALTER TABLE patient_accounts        ENABLE ROW LEVEL SECURITY;
ALTER TABLE consents                ENABLE ROW LEVEL SECURITY;
ALTER TABLE appointments            ENABLE ROW LEVEL SECURITY;
ALTER TABLE message_threads         ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages                ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications           ENABLE ROW LEVEL SECURITY;


-- ── patients ─────────────────────────────────────────
SET search_path TO dev, public;

-- Patients see only their own record
CREATE POLICY patients_patient_select ON patients
    AS PERMISSIVE FOR SELECT TO db_patient
    USING (id = current_patient_id());

-- Clinicians see patients in their care or their organization
CREATE POLICY patients_clinician_select ON patients
    AS PERMISSIVE FOR SELECT TO db_clinician
    USING (
        clinician_has_access_to_patient(id)
        OR managing_organization_id = current_org_id()
    );

-- System and admin: unrestricted (but still audited at app layer)
CREATE POLICY patients_system_all ON patients
    AS PERMISSIVE FOR ALL TO db_system, db_admin
    USING (true)
    WITH CHECK (true);

-- Patients cannot INSERT their own demographic record
CREATE POLICY patients_patient_no_write ON patients
    AS RESTRICTIVE FOR INSERT TO db_patient
    WITH CHECK (false);


-- ── Macro: patient-scoped table policies (patient_id column) ─
-- Applied to: patient_names, addresses, telecoms, contacts,
--             languages, race_ethnicities, flags, identifiers

-- Pattern:
--   Patient: patient_id = current_patient_id()
--   Clinician: care-team or org check
--   Admin/System: unrestricted

DO $$ DECLARE
    t RECORD;
BEGIN
    FOR t IN SELECT unnest(ARRAY[
        'patient_identifiers',
        'patient_names',
        'patient_addresses',
        'patient_telecoms',
        'patient_contacts',
        'patient_languages',
        'patient_race_ethnicities',
        'patient_flags'
    ]) AS tbl
    LOOP
        EXECUTE format(
            'CREATE POLICY %I_patient_sel ON %s AS PERMISSIVE FOR SELECT TO db_patient
             USING (patient_id = current_patient_id())',
            replace(t.tbl, '.', '_'), t.tbl
        );
        EXECUTE format(
            'CREATE POLICY %I_clinician_sel ON %s AS PERMISSIVE FOR SELECT TO db_clinician
             USING (clinician_has_access_to_patient(patient_id))',
            replace(t.tbl, '.', '_'), t.tbl
        );
        EXECUTE format(
            'CREATE POLICY %I_system_all ON %s AS PERMISSIVE FOR ALL TO db_system, db_admin
             USING (true) WITH CHECK (true)',
            replace(t.tbl, '.', '_'), t.tbl
        );
    END LOOP;
END $$;


-- ── coverage ─────────────────────────────────────────
SET search_path TO dev, public;

CREATE POLICY coverage_patient_select ON coverage
    AS PERMISSIVE FOR SELECT TO db_patient
    USING (patient_id = current_patient_id());

CREATE POLICY coverage_clinician_select ON coverage
    AS PERMISSIVE FOR SELECT TO db_clinician
    USING (clinician_has_access_to_patient(patient_id));

CREATE POLICY coverage_system_all ON coverage
    AS PERMISSIVE FOR ALL TO db_system, db_admin
    USING (true) WITH CHECK (true);


-- ── encounters ──────────────────────────────────────
SET search_path TO dev, public;

CREATE POLICY encounters_patient_select ON encounters
    AS PERMISSIVE FOR SELECT TO db_patient
    USING (patient_id = current_patient_id());

CREATE POLICY encounters_clinician_select ON encounters
    AS PERMISSIVE FOR SELECT TO db_clinician
    USING (
        primary_practitioner_id = current_user_id()
        OR clinician_has_access_to_patient(patient_id)
    );

CREATE POLICY encounters_system_all ON encounters
    AS PERMISSIVE FOR ALL TO db_system, db_admin
    USING (true) WITH CHECK (true);

-- Clinicians can INSERT encounters for their patients
CREATE POLICY encounters_clinician_insert ON encounters
    AS PERMISSIVE FOR INSERT TO db_clinician
    WITH CHECK (primary_practitioner_id = current_user_id());


-- ── observations ────────────────────────────────────

CREATE POLICY obs_patient_select ON observations
    AS PERMISSIVE FOR SELECT TO db_patient
    USING (patient_id = current_patient_id());

CREATE POLICY obs_clinician_select ON observations
    AS PERMISSIVE FOR SELECT TO db_clinician
    USING (clinician_has_access_to_patient(patient_id));

CREATE POLICY obs_system_all ON observations
    AS PERMISSIVE FOR ALL TO db_system, db_admin
    USING (true) WITH CHECK (true);


-- ── conditions ──────────────────────────────────────

CREATE POLICY cond_patient_select ON conditions
    AS PERMISSIVE FOR SELECT TO db_patient
    USING (patient_id = current_patient_id() AND deleted_at IS NULL);

CREATE POLICY cond_clinician_all ON conditions
    AS PERMISSIVE FOR ALL TO db_clinician
    USING (clinician_has_access_to_patient(patient_id));

CREATE POLICY cond_system_all ON conditions
    AS PERMISSIVE FOR ALL TO db_system, db_admin
    USING (true) WITH CHECK (true);


-- ── medication_requests ─────────────────────────────

CREATE POLICY medrx_patient_select ON medication_requests
    AS PERMISSIVE FOR SELECT TO db_patient
    USING (patient_id = current_patient_id() AND deleted_at IS NULL);

CREATE POLICY medrx_clinician_all ON medication_requests
    AS PERMISSIVE FOR ALL TO db_clinician
    USING (clinician_has_access_to_patient(patient_id));

CREATE POLICY medrx_system_all ON medication_requests
    AS PERMISSIVE FOR ALL TO db_system, db_admin
    USING (true) WITH CHECK (true);


-- ── patient_accounts ──────────────────────────────────
SET search_path TO dev, public;

CREATE POLICY acct_patient_own ON patient_accounts
    AS PERMISSIVE FOR SELECT TO db_patient
    USING (patient_id = current_patient_id());

-- Patients can update certain fields of their own account
CREATE POLICY acct_patient_update ON patient_accounts
    AS PERMISSIVE FOR UPDATE TO db_patient
    USING (patient_id = current_patient_id());
-- Column-level restrictions (password_hash, mfa_secret) enforced via GRANT

CREATE POLICY acct_system_all ON patient_accounts
    AS PERMISSIVE FOR ALL TO db_system, db_admin
    USING (true) WITH CHECK (true);


-- ── appointments ──────────────────────────────────────

CREATE POLICY appt_patient_select ON appointments
    AS PERMISSIVE FOR SELECT TO db_patient
    USING (patient_id = current_patient_id() AND deleted_at IS NULL);

CREATE POLICY appt_patient_cancel ON appointments
    AS PERMISSIVE FOR UPDATE TO db_patient
    USING (patient_id = current_patient_id() AND status IN ('booked', 'pending'));

CREATE POLICY appt_clinician_select ON appointments
    AS PERMISSIVE FOR SELECT TO db_clinician
    USING (clinician_has_access_to_patient(patient_id));

CREATE POLICY appt_system_all ON appointments
    AS PERMISSIVE FOR ALL TO db_system, db_admin
    USING (true) WITH CHECK (true);


-- ── messages ──────────────────────────────────────────

CREATE POLICY msg_patient_own ON messages
    AS PERMISSIVE FOR SELECT TO db_patient
    USING (
        sender_patient_id = current_patient_id() OR
        recipient_patient_id = current_patient_id()
    );

CREATE POLICY msg_patient_send ON messages
    AS PERMISSIVE FOR INSERT TO db_patient
    WITH CHECK (sender_patient_id = current_patient_id());

CREATE POLICY msg_clinician_select ON messages
    AS PERMISSIVE FOR SELECT TO db_clinician
    USING (
        sender_practitioner_id = current_user_id() OR
        recipient_practitioner_id = current_user_id()
    );

CREATE POLICY msg_system_all ON messages
    AS PERMISSIVE FOR ALL TO db_system, db_admin
    USING (true) WITH CHECK (true);


-- ── consents ──────────────────────────────────────────

CREATE POLICY consent_patient_select ON consents
    AS PERMISSIVE FOR SELECT TO db_patient
    USING (patient_id = current_patient_id());

CREATE POLICY consent_clinician_select ON consents
    AS PERMISSIVE FOR SELECT TO db_clinician
    USING (clinician_has_access_to_patient(patient_id));

CREATE POLICY consent_system_all ON consents
    AS PERMISSIVE FOR ALL TO db_system, db_admin
    USING (true) WITH CHECK (true);


-- ── notifications ─────────────────────────────────────

CREATE POLICY notif_patient_own ON notifications
    AS PERMISSIVE FOR SELECT TO db_patient
    USING (patient_id = current_patient_id());

CREATE POLICY notif_system_all ON notifications
    AS PERMISSIVE FOR ALL TO db_system, db_admin
    USING (true) WITH CHECK (true);


-- ── audit schema — read-only for auditors ────────────────────

-- Auditors can only read audit tables; no RLS filter needed (they see all)
GRANT SELECT ON ALL TABLES IN SCHEMA dev TO db_auditor;

-- Prevent accidental deletion of audit records by anyone except db_system
SET search_path TO dev, public;

CREATE POLICY audit_events_immutable ON audit_events
    AS RESTRICTIVE FOR DELETE TO PUBLIC
    USING (false);  -- Nobody can DELETE via SQL; use partition drop for retention

CREATE POLICY phi_log_immutable ON phi_access_log
    AS RESTRICTIVE FOR DELETE TO PUBLIC
    USING (false);
