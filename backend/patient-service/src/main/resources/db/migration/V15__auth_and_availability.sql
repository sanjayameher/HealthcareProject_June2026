-- ============================================================
-- SECTION 15 — AUTH ACCOUNTS & PRACTITIONER AVAILABILITY
-- New tables:
--   practitioner_accounts        (doctor portal auth)
--   admin_accounts               (hospital admin auth)
--   practitioner_availability_slots (doctor calendar)
--   auth_failure_log             (HIPAA: failed-login audit)
-- Modification:
--   notifications                (support practitioner recipients)
-- ============================================================

SET search_path TO dev, public;

-- ── 15.1  Practitioner Portal Accounts ──────────────────────
-- Mirrors patient_accounts but for licensed practitioners.
-- email is PHI-encrypted (BYTEA); equality lookups use email_hash.

CREATE TABLE IF NOT EXISTS dev.practitioner_accounts (
    id                          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),

    -- One-to-one with the practitioners record
    practitioner_id             UUID        NOT NULL UNIQUE
                                            REFERENCES dev.practitioners(id) ON DELETE CASCADE,

    -- Credentials
    email                       BYTEA       NOT NULL,               -- [PHI-ENCRYPTED] AES-256-GCM
    email_hash                  BYTEA       NOT NULL UNIQUE,        -- HMAC-SHA256 for lookup; never decrypt to query
    email_verified              BOOLEAN     NOT NULL DEFAULT false,
    email_verified_at           TIMESTAMPTZ,

    -- Password — bcrypt, cost factor >= 12
    password_hash               TEXT        NOT NULL,
    password_changed_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    must_change_password        BOOLEAN     NOT NULL DEFAULT true,  -- always true on admin-created accounts

    -- Login tracking
    last_login_at               TIMESTAMPTZ,
    last_login_ip               INET,
    last_login_user_agent       TEXT,
    failed_login_attempts       SMALLINT    NOT NULL DEFAULT 0,
    locked_until                TIMESTAMPTZ,

    -- Account lifecycle
    is_active                   BOOLEAN     NOT NULL DEFAULT true,
    deactivated_at              TIMESTAMPTZ,
    deactivation_reason         TEXT,

    created_at                  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at                  TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT prac_accounts_password_nonempty
        CHECK (password_hash <> ''),
    CONSTRAINT prac_accounts_attempts_non_negative
        CHECK (failed_login_attempts >= 0)
);

COMMENT ON TABLE  dev.practitioner_accounts IS
    'Practitioner portal authentication — separate from clinical demographics';
COMMENT ON COLUMN dev.practitioner_accounts.email IS
    '[PHI-ENCRYPTED] AES-256-GCM encrypted; use email_hash for equality lookups';
COMMENT ON COLUMN dev.practitioner_accounts.password_hash IS
    'bcrypt hash cost >= 12 — never store or log plaintext';
COMMENT ON COLUMN dev.practitioner_accounts.must_change_password IS
    'Set to TRUE on admin-created accounts; cleared after first successful password change';

CREATE INDEX IF NOT EXISTS idx_practitioner_accounts_email_hash
    ON dev.practitioner_accounts (email_hash);

CREATE INDEX IF NOT EXISTS idx_practitioner_accounts_practitioner_id
    ON dev.practitioner_accounts (practitioner_id);

CREATE TRIGGER trg_set_updated_at_practitioner_accounts
    BEFORE UPDATE ON dev.practitioner_accounts
    FOR EACH ROW EXECUTE FUNCTION public.fn_set_updated_at();


-- ── 15.2  Admin Accounts ─────────────────────────────────────
-- Hospital administrator accounts.
-- email is plain TEXT (not PHI); stored in lower-case.

CREATE TABLE IF NOT EXISTS dev.admin_accounts (
    id                      UUID        PRIMARY KEY DEFAULT gen_random_uuid(),

    email                   TEXT        NOT NULL UNIQUE,            -- plain text, lower-case enforced
    password_hash           TEXT        NOT NULL,                   -- bcrypt, cost >= 12
    full_name               TEXT        NOT NULL,

    is_super_admin          BOOLEAN     NOT NULL DEFAULT false,
    is_active               BOOLEAN     NOT NULL DEFAULT true,
    must_change_password    BOOLEAN     NOT NULL DEFAULT false,     -- set to TRUE for non-root new admins

    -- Self-referencing FK: who created this admin account (NULL = root / seeded)
    created_by              UUID        REFERENCES dev.admin_accounts(id) ON DELETE SET NULL,

    -- Login tracking
    last_login_at           TIMESTAMPTZ,
    last_login_ip           INET,
    last_login_user_agent   TEXT,
    failed_login_attempts   SMALLINT    NOT NULL DEFAULT 0,
    locked_until            TIMESTAMPTZ,

    created_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT admin_accounts_password_nonempty
        CHECK (password_hash <> ''),
    CONSTRAINT admin_accounts_email_lowercase
        CHECK (email = lower(email)),
    CONSTRAINT admin_accounts_attempts_non_negative
        CHECK (failed_login_attempts >= 0)
);

COMMENT ON TABLE  dev.admin_accounts IS
    'Hospital administrator authentication accounts — email is plain text (not PHI)';
COMMENT ON COLUMN dev.admin_accounts.is_super_admin IS
    'Super admins can create other admin accounts and perform all administrative operations';
COMMENT ON COLUMN dev.admin_accounts.created_by IS
    'Self-referencing FK to the admin who created this account; NULL for the root/seeded admin';

CREATE INDEX IF NOT EXISTS idx_admin_accounts_email
    ON dev.admin_accounts (email);

CREATE TRIGGER trg_set_updated_at_admin_accounts
    BEFORE UPDATE ON dev.admin_accounts
    FOR EACH ROW EXECUTE FUNCTION public.fn_set_updated_at();


-- ── 15.3  Practitioner Availability Slots ───────────────────
-- Represents a doctor's calendar blocks.
-- appointments.slot_id already references this table's id.
-- is_available = false when blocked/leave OR when appointment booked.

CREATE TABLE IF NOT EXISTS dev.practitioner_availability_slots (
    id                  UUID        PRIMARY KEY DEFAULT gen_random_uuid(),

    practitioner_id     UUID        NOT NULL
                                    REFERENCES dev.practitioners(id) ON DELETE CASCADE,

    slot_date           DATE        NOT NULL,
    start_time          TIME        NOT NULL,
    end_time            TIME        NOT NULL,

    is_available        BOOLEAN     NOT NULL DEFAULT true,
    slot_type           TEXT        NOT NULL DEFAULT 'regular',     -- regular | leave | blocked
    recurrence_rule     TEXT,                                       -- iCal RRULE string (optional)
    max_appointments    SMALLINT    NOT NULL DEFAULT 1,
    notes               TEXT,

    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT pas_end_after_start
        CHECK (end_time > start_time),
    CONSTRAINT pas_slot_type_values
        CHECK (slot_type IN ('regular', 'leave', 'blocked')),
    CONSTRAINT pas_max_appointments_positive
        CHECK (max_appointments >= 1),

    -- A practitioner cannot have two slots starting at the same time on the same day
    UNIQUE (practitioner_id, slot_date, start_time)
);

COMMENT ON TABLE  dev.practitioner_availability_slots IS
    'Practitioner calendar availability blocks used by the appointment booking flow';
COMMENT ON COLUMN dev.practitioner_availability_slots.is_available IS
    'Set to FALSE when blocked, on leave, or when a booked appointment occupies this slot';
COMMENT ON COLUMN dev.practitioner_availability_slots.slot_type IS
    'regular = normal working slot; leave = approved leave; blocked = admin-blocked';
COMMENT ON COLUMN dev.practitioner_availability_slots.recurrence_rule IS
    'iCal RRULE string for repeating availability patterns (e.g. FREQ=WEEKLY;BYDAY=MO,WE,FR)';

CREATE INDEX IF NOT EXISTS idx_pas_practitioner_date
    ON dev.practitioner_availability_slots (practitioner_id, slot_date);

CREATE INDEX IF NOT EXISTS idx_pas_available_date
    ON dev.practitioner_availability_slots (slot_date, is_available)
    WHERE is_available = true;

CREATE TRIGGER trg_set_updated_at_practitioner_availability_slots
    BEFORE UPDATE ON dev.practitioner_availability_slots
    FOR EACH ROW EXECUTE FUNCTION public.fn_set_updated_at();


-- ── 15.4  Auth Failure Log ───────────────────────────────────
-- HIPAA-required log of every failed login attempt.
-- Successful logins are recorded in audit_events (06_audit_schema).

CREATE TABLE IF NOT EXISTS dev.auth_failure_log (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Which role/portal was targeted
    account_type    TEXT        NOT NULL,                           -- 'admin' | 'practitioner' | 'patient'

    -- The account that was targeted (NULL when account does not exist)
    account_id      UUID,

    -- Masked email attempted (plain for admin; '<masked>' for PHI-protected portals)
    email_attempted TEXT,

    ip_address      INET,
    user_agent      TEXT,

    failure_reason  TEXT        NOT NULL,                          -- bad_password | account_locked | not_found | account_inactive
    attempted_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT auth_failure_account_type
        CHECK (account_type IN ('admin', 'practitioner', 'patient'))
);

-- NOTE: auth_failure_log already existed in 06_audit_schema.sql with column
--       "occurred_at" (not "attempted_at"). Indexes use the actual column name.
COMMENT ON TABLE dev.auth_failure_log IS
    'HIPAA-required audit log of all failed authentication attempts across all three portals';

CREATE INDEX IF NOT EXISTS idx_auth_failure_account
    ON dev.auth_failure_log (account_id, occurred_at DESC);

CREATE INDEX IF NOT EXISTS idx_auth_failure_time
    ON dev.auth_failure_log (occurred_at DESC);

CREATE INDEX IF NOT EXISTS idx_auth_failure_ip
    ON dev.auth_failure_log (ip_address, occurred_at DESC);


-- ── 15.5  Extend notifications to support practitioner recipients ─
-- Original schema: patient_id NOT NULL.
-- Change: make patient_id nullable, add recipient_practitioner_id,
-- enforce "at least one recipient" constraint.

ALTER TABLE dev.notifications
    ALTER COLUMN patient_id DROP NOT NULL;

ALTER TABLE dev.notifications
    ADD COLUMN IF NOT EXISTS recipient_practitioner_id UUID
        REFERENCES dev.practitioners(id) ON DELETE CASCADE;

-- Ensure every notification has exactly one recipient
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints
        WHERE table_schema = 'dev'
          AND table_name   = 'notifications'
          AND constraint_name = 'notifications_has_recipient'
    ) THEN
        ALTER TABLE dev.notifications
            ADD CONSTRAINT notifications_has_recipient
            CHECK (
                patient_id IS NOT NULL
                OR recipient_practitioner_id IS NOT NULL
            );
    END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_notifications_practitioner
    ON dev.notifications (recipient_practitioner_id, created_at DESC)
    WHERE recipient_practitioner_id IS NOT NULL;

COMMENT ON COLUMN dev.notifications.patient_id IS
    'Set when the notification targets a patient; NULL when targeting a practitioner';
COMMENT ON COLUMN dev.notifications.recipient_practitioner_id IS
    'Set when the notification targets a practitioner (e.g. appointment_assigned, doctor_welcome)';


-- ── 15.6  Role-based grants ───────────────────────────────────

-- db_admin — full control over all new objects
GRANT ALL PRIVILEGES ON dev.practitioner_accounts           TO db_admin;
GRANT ALL PRIVILEGES ON dev.admin_accounts                  TO db_admin;
GRANT ALL PRIVILEGES ON dev.practitioner_availability_slots TO db_admin;
GRANT ALL PRIVILEGES ON dev.auth_failure_log                TO db_admin;

-- db_system — portal-service service account
GRANT SELECT, INSERT, UPDATE
    ON dev.practitioner_accounts           TO db_system;
GRANT SELECT, INSERT, UPDATE
    ON dev.admin_accounts                  TO db_system;
GRANT SELECT, INSERT, UPDATE, DELETE
    ON dev.practitioner_availability_slots TO db_system;
GRANT INSERT
    ON dev.auth_failure_log                TO db_system;

-- db_clinician — practitioners can read/update their own account and manage their own slots
GRANT SELECT, UPDATE
    ON dev.practitioner_accounts           TO db_clinician;
GRANT SELECT, INSERT, UPDATE, DELETE
    ON dev.practitioner_availability_slots TO db_clinician;

-- db_patient — no access to auth tables
REVOKE ALL ON dev.practitioner_accounts           FROM db_patient;
REVOKE ALL ON dev.admin_accounts                  FROM db_patient;
REVOKE ALL ON dev.practitioner_availability_slots FROM db_patient;
REVOKE ALL ON dev.auth_failure_log                FROM db_patient;

-- db_auditor — read-only on auth_failure_log for compliance reporting
GRANT SELECT ON dev.auth_failure_log TO db_auditor;


-- ── 15.7  Seed: root super-admin ─────────────────────────────
-- Password: Admin@1234  (bcrypt cost=12)
-- CHANGE THIS before deploying to any non-local environment.
-- In production: override via application-local.yml or a separate secrets migration.

INSERT INTO dev.admin_accounts (
    email,
    password_hash,
    full_name,
    is_super_admin,
    is_active,
    must_change_password,
    created_by
)
VALUES (
    'admin@healthcare.local',
    '$2a$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj/oGkHsOwPO',
    'System Super Admin',
    true,
    true,
    false,
    NULL
)
ON CONFLICT (email) DO NOTHING;

COMMENT ON TABLE dev.admin_accounts IS
    'Seed row: admin@healthcare.local / Admin@1234 (bcrypt $2a$12$...) — CHANGE IN PRODUCTION';