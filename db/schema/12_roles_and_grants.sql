-- ============================================================
-- SECTION 13 — ROLES & PRIVILEGE GRANTS
-- Principle of least privilege applied at every layer.
-- Database roles map 1:1 to application identity classes.
-- Never share roles between services.
-- ============================================================

-- ── Create roles (idempotent-safe) ───────────────────────────

DO $$
BEGIN
    -- Patient portal authenticated users
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'db_patient') THEN
        CREATE ROLE db_patient NOLOGIN;
    END IF;

    -- Licensed clinicians / care team
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'db_clinician') THEN
        CREATE ROLE db_clinician NOLOGIN;
    END IF;

    -- Administrative and billing staff
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'db_admin') THEN
        CREATE ROLE db_admin NOLOGIN;
    END IF;

    -- Internal microservices (notification, scheduling, billing engine)
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'db_system') THEN
        CREATE ROLE db_system NOLOGIN;
    END IF;

    -- Compliance / audit officer (read-only audit schema)
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'db_auditor') THEN
        CREATE ROLE db_auditor NOLOGIN;
    END IF;

    -- Application service accounts (login roles that inherit group roles)
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'svc_portal') THEN
        CREATE ROLE svc_portal LOGIN PASSWORD 'CHANGE_ME_PORTAL';
        GRANT db_patient, db_system TO svc_portal;
    END IF;

    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'svc_clinical') THEN
        CREATE ROLE svc_clinical LOGIN PASSWORD 'CHANGE_ME_CLINICAL';
        GRANT db_clinician, db_system TO svc_clinical;
    END IF;

    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'svc_billing') THEN
        CREATE ROLE svc_billing LOGIN PASSWORD 'CHANGE_ME_BILLING';
        GRANT db_admin TO svc_billing;
    END IF;

    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'svc_audit_reader') THEN
        CREATE ROLE svc_audit_reader LOGIN PASSWORD 'CHANGE_ME_AUDIT';
        GRANT db_auditor TO svc_audit_reader;
    END IF;
END $$;


-- ── Schema USAGE ─────────────────────────────────────────────

GRANT USAGE ON SCHEMA dev   TO db_patient, db_clinician, db_admin, db_system;
GRANT USAGE ON SCHEMA dev  TO db_patient, db_clinician, db_admin, db_system;
GRANT USAGE ON SCHEMA dev   TO db_patient, db_clinician, db_admin, db_system;
GRANT USAGE ON SCHEMA dev    TO db_patient, db_clinician, db_admin, db_system;
GRANT USAGE ON SCHEMA dev     TO db_system, db_admin, db_auditor;


-- ── patient schema grants ─────────────────────────────────────

-- Organizations and practitioners are reference data — all roles can read
GRANT SELECT ON organizations       TO db_patient, db_clinician, db_admin, db_system;
GRANT INSERT, UPDATE ON organizations TO db_admin, db_system;

GRANT SELECT ON practitioners       TO db_patient, db_clinician, db_admin, db_system;
GRANT INSERT, UPDATE ON practitioners TO db_admin, db_system;
GRANT SELECT ON practitioner_roles  TO db_patient, db_clinician, db_admin, db_system;
GRANT INSERT, UPDATE, DELETE ON practitioner_roles TO db_admin, db_system;

-- Patients: RLS governs row access; grants define column access
GRANT SELECT ON patients            TO db_patient, db_clinician, db_admin, db_system;
GRANT INSERT ON patients            TO db_admin, db_system;
GRANT UPDATE ON patients            TO db_clinician, db_admin, db_system;

-- Sensitive columns restricted to system/admin only
REVOKE SELECT (birth_date) ON patients FROM db_patient;
-- Patients see their own DOB via the view layer, not raw table

GRANT SELECT, INSERT, UPDATE, DELETE ON patient_identifiers   TO db_admin, db_system;
GRANT SELECT ON patient_identifiers                           TO db_clinician;

GRANT SELECT ON patient_names       TO db_patient, db_clinician, db_admin, db_system;
GRANT INSERT, UPDATE, DELETE ON patient_names TO db_admin, db_system;

GRANT SELECT ON patient_addresses   TO db_patient, db_clinician, db_admin, db_system;
GRANT INSERT, UPDATE, DELETE ON patient_addresses TO db_admin, db_system;

GRANT SELECT ON patient_telecoms    TO db_patient, db_clinician, db_admin, db_system;
GRANT INSERT, UPDATE, DELETE ON patient_telecoms TO db_admin, db_system;

GRANT SELECT ON patient_contacts    TO db_patient, db_clinician, db_admin, db_system;
GRANT INSERT, UPDATE, DELETE ON patient_contacts TO db_system, db_admin;

GRANT SELECT ON patient_languages, patient_race_ethnicities
    TO db_patient, db_clinician, db_admin, db_system;
GRANT INSERT, UPDATE, DELETE ON patient_languages, patient_race_ethnicities
    TO db_admin, db_system;

GRANT SELECT ON patient_flags       TO db_patient, db_clinician, db_admin, db_system;
GRANT INSERT, UPDATE ON patient_flags TO db_clinician, db_admin, db_system;

GRANT SELECT ON patient_links       TO db_clinician, db_admin, db_system;
GRANT INSERT ON patient_links       TO db_admin, db_system;


-- ── billing schema grants ─────────────────────────────────────

GRANT SELECT ON payers              TO db_patient, db_clinician, db_admin, db_system;
GRANT INSERT, UPDATE ON payers      TO db_admin, db_system;

GRANT SELECT ON coverage            TO db_patient, db_clinician, db_admin, db_system;
GRANT INSERT, UPDATE ON coverage    TO db_admin, db_system;

-- subscriber_id column is PHI — patient can see their own via RLS; raw column restricted
REVOKE SELECT (subscriber_id, subscriber_id_hash) ON coverage FROM db_patient;

GRANT SELECT ON eligibility_checks  TO db_clinician, db_admin, db_system;
GRANT INSERT ON eligibility_checks  TO db_admin, db_system;


-- ── clinical schema grants ────────────────────────────────────

GRANT SELECT ON encounters         TO db_patient, db_clinician, db_admin, db_system;
GRANT INSERT, UPDATE ON encounters TO db_clinician, db_admin, db_system;

GRANT SELECT ON encounter_participants TO db_clinician, db_admin, db_system;
GRANT INSERT, DELETE ON encounter_participants TO db_clinician, db_admin, db_system;

GRANT SELECT ON observations       TO db_patient, db_clinician, db_admin, db_system;
GRANT INSERT ON observations       TO db_clinician, db_admin, db_system;
GRANT UPDATE ON observations       TO db_clinician, db_admin, db_system;

GRANT SELECT ON conditions         TO db_patient, db_clinician, db_admin, db_system;
GRANT INSERT, UPDATE ON conditions TO db_clinician, db_admin, db_system;

GRANT SELECT ON allergy_intolerances TO db_patient, db_clinician, db_admin, db_system;
GRANT INSERT, UPDATE ON allergy_intolerances TO db_clinician, db_admin, db_system;
GRANT SELECT, INSERT ON allergy_reactions TO db_clinician, db_admin, db_system;

GRANT SELECT ON immunizations      TO db_patient, db_clinician, db_admin, db_system;
GRANT INSERT, UPDATE ON immunizations TO db_clinician, db_admin, db_system;

GRANT SELECT ON specimens          TO db_clinician, db_admin, db_system;
GRANT INSERT, UPDATE ON specimens  TO db_clinician, db_admin, db_system;

GRANT SELECT ON medication_requests TO db_patient, db_clinician, db_admin, db_system;
GRANT INSERT, UPDATE ON medication_requests TO db_clinician, db_admin, db_system;

GRANT SELECT ON medication_dispenses TO db_patient, db_clinician, db_admin, db_system;
GRANT INSERT ON medication_dispenses TO db_admin, db_system;

GRANT SELECT ON service_requests   TO db_patient, db_clinician, db_admin, db_system;
GRANT INSERT, UPDATE ON service_requests TO db_clinician, db_admin, db_system;

GRANT SELECT ON diagnostic_reports TO db_patient, db_clinician, db_admin, db_system;
GRANT INSERT, UPDATE ON diagnostic_reports TO db_clinician, db_admin, db_system;

GRANT SELECT ON care_plans         TO db_patient, db_clinician, db_admin, db_system;
GRANT INSERT, UPDATE ON care_plans TO db_clinician, db_admin, db_system;

GRANT SELECT ON care_teams         TO db_patient, db_clinician, db_admin, db_system;
GRANT INSERT, UPDATE ON care_teams TO db_clinician, db_admin, db_system;
GRANT SELECT, INSERT, UPDATE, DELETE ON care_team_participants TO db_clinician, db_admin, db_system;

GRANT SELECT ON documents          TO db_patient, db_clinician, db_admin, db_system;
GRANT INSERT, UPDATE ON documents  TO db_clinician, db_admin, db_system;


-- ── portal schema grants ──────────────────────────────────────

-- Patient accounts — only the system service and admin can write
GRANT SELECT ON patient_accounts     TO db_patient, db_admin, db_system;
GRANT INSERT ON patient_accounts     TO db_system;
-- Allow patients to update non-sensitive fields; sensitive fields restricted below
GRANT UPDATE (
    phone, phone_hash, phone_verified, phone_verified_at,
    terms_version_accepted, terms_accepted_at,
    privacy_policy_version, privacy_policy_accepted_at,
    hipaa_notice_version, hipaa_notice_acknowledged_at
) ON patient_accounts TO db_patient;
-- password_hash, mfa_secret, mfa_backup_codes — only db_system can write
GRANT UPDATE (
    password_hash, password_changed_at, mfa_enabled, mfa_secret,
    mfa_backup_codes, failed_login_attempts, locked_until,
    last_login_at, last_login_ip, last_login_user_agent,
    is_active, deactivated_at, deactivation_reason
) ON patient_accounts TO db_system, db_admin;

GRANT SELECT ON consents             TO db_patient, db_clinician, db_admin, db_system;
GRANT INSERT, UPDATE ON consents     TO db_admin, db_system;
GRANT SELECT, INSERT ON consent_provisions TO db_admin, db_system;

GRANT SELECT ON appointments         TO db_patient, db_clinician, db_admin, db_system;
GRANT INSERT ON appointments         TO db_clinician, db_admin, db_system;
GRANT UPDATE ON appointments         TO db_clinician, db_admin, db_system;

GRANT SELECT, INSERT, DELETE ON appointment_participants TO db_clinician, db_admin, db_system;

GRANT SELECT ON message_threads      TO db_patient, db_clinician, db_admin, db_system;
GRANT INSERT ON message_threads      TO db_patient, db_clinician, db_system;
GRANT UPDATE ON message_threads      TO db_system;

GRANT SELECT ON messages             TO db_patient, db_clinician, db_admin, db_system;
GRANT INSERT ON messages             TO db_patient, db_clinician, db_system;
GRANT UPDATE (status, delivered_at, read_at, deleted_at) ON messages TO db_patient, db_system;

GRANT SELECT, INSERT ON message_attachments TO db_patient, db_clinician, db_system;

GRANT SELECT ON notification_preferences TO db_patient, db_admin, db_system;
GRANT INSERT, UPDATE ON notification_preferences TO db_patient, db_system;

GRANT SELECT ON notifications        TO db_patient, db_admin, db_system;
GRANT INSERT, UPDATE ON notifications TO db_system;
GRANT UPDATE (read_at) ON notifications TO db_patient;


-- ── audit schema grants ───────────────────────────────────────

-- Only db_system can INSERT audit records
GRANT INSERT ON audit_events          TO db_system;
GRANT INSERT ON phi_access_log        TO db_system;
GRANT INSERT ON data_change_history   TO db_system;
GRANT INSERT ON auth_failure_log      TO db_system;

-- db_admin and db_auditor can read all audit tables
GRANT SELECT ON ALL TABLES IN SCHEMA dev  TO db_admin, db_auditor;

-- No one can UPDATE or DELETE audit records (immutability enforced by RLS + revoke)
REVOKE UPDATE, DELETE ON audit_events          FROM PUBLIC;
REVOKE UPDATE, DELETE ON phi_access_log        FROM PUBLIC;
REVOKE UPDATE, DELETE ON data_change_history   FROM PUBLIC;
REVOKE UPDATE, DELETE ON auth_failure_log      FROM PUBLIC;


-- ── Function grants ───────────────────────────────────────────

GRANT EXECUTE ON FUNCTION generate_mrn                  TO db_system, db_admin;
GRANT EXECUTE ON FUNCTION search_patients               TO db_clinician, db_admin, db_system;
GRANT EXECUTE ON FUNCTION calculate_age_years           TO db_patient, db_clinician, db_admin, db_system;
GRANT EXECUTE ON FUNCTION calculate_age_display         TO db_patient, db_clinician, db_admin, db_system;
GRANT EXECUTE ON FUNCTION check_allergy_conflict       TO db_clinician, db_system;
GRANT EXECUTE ON FUNCTION close_encounter              TO db_clinician, db_system;
GRANT EXECUTE ON FUNCTION log_phi_access                  TO db_system;
GRANT EXECUTE ON FUNCTION is_slot_available              TO db_clinician, db_system;
GRANT EXECUTE ON FUNCTION deactivate_patient_account     TO db_admin, db_system;


-- ── View grants ───────────────────────────────────────────────

GRANT SELECT ON v_patient_summary           TO db_patient, db_clinician, db_admin, db_system;
GRANT SELECT ON v_problem_list             TO db_patient, db_clinician, db_admin, db_system;
GRANT SELECT ON v_current_medications      TO db_patient, db_clinician, db_admin, db_system;
GRANT SELECT ON v_latest_vitals            TO db_patient, db_clinician, db_admin, db_system;
GRANT SELECT ON v_allergy_summary          TO db_patient, db_clinician, db_admin, db_system;
GRANT SELECT ON v_upcoming_appointments      TO db_patient, db_clinician, db_admin, db_system;
GRANT SELECT ON v_active_coverage           TO db_patient, db_clinician, db_admin, db_system;
GRANT SELECT ON mv_patient_care_gaps       TO db_clinician, db_admin, db_system;

-- Allow db_system to refresh the materialized view
GRANT UPDATE ON mv_patient_care_gaps       TO db_system;


-- ── Sequences ────────────────────────────────────────────────

GRANT USAGE ON SEQUENCE dev.mrn_seq TO db_system, db_admin;
