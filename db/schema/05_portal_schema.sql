-- ============================================================
-- SECTION 6 — PORTAL SCHEMA
-- FHIR Resources: Consent, Appointment, Communication
-- Custom: PatientAccount, Notification, SecureMessage
-- ============================================================

SET search_path TO dev, public;

-- ── 6.1  Patient Portal Accounts ────────────────────────────
-- Separate from patient demographics — authentication concern

CREATE TABLE patient_accounts (
    id                          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),

    -- One-to-one with patient record
    patient_id                  UUID        NOT NULL UNIQUE
                                            REFERENCES patients(id) ON DELETE CASCADE,

    -- Credentials — email stored encrypted; UNIQUE enforced via hash
    email                       BYTEA       NOT NULL,               -- [PHI-ENCRYPTED]
    email_hash                  BYTEA       NOT NULL UNIQUE,        -- HMAC-SHA256 for unique constraint + lookup
    email_verified              BOOLEAN     NOT NULL DEFAULT false,
    email_verified_at           TIMESTAMPTZ,

    phone                       BYTEA,                              -- [PHI-ENCRYPTED]
    phone_hash                  BYTEA       UNIQUE,                 -- HMAC for lookup
    phone_verified              BOOLEAN     NOT NULL DEFAULT false,
    phone_verified_at           TIMESTAMPTZ,

    -- Username is optional — MRN or email can serve as login
    username                    VARCHAR(50) UNIQUE,

    -- Password — bcrypt hash (cost factor >= 12)
    password_hash               TEXT        NOT NULL,
    password_changed_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    must_change_password        BOOLEAN     NOT NULL DEFAULT false,

    -- MFA (TOTP)
    mfa_enabled                 BOOLEAN     NOT NULL DEFAULT false,
    mfa_secret                  BYTEA,                              -- [PHI-ENCRYPTED] TOTP secret
    mfa_backup_codes            BYTEA,                              -- [PHI-ENCRYPTED] hashed backup codes JSON

    -- Login tracking
    last_login_at               TIMESTAMPTZ,
    last_login_ip               INET,
    last_login_user_agent       TEXT,
    failed_login_attempts       SMALLINT    NOT NULL DEFAULT 0,
    locked_until                TIMESTAMPTZ,

    -- Account status
    is_active                   BOOLEAN     NOT NULL DEFAULT true,
    deactivated_at              TIMESTAMPTZ,
    deactivation_reason         TEXT,

    -- Compliance acceptances
    terms_version_accepted      TEXT,
    terms_accepted_at           TIMESTAMPTZ,
    privacy_policy_version      TEXT,
    privacy_policy_accepted_at  TIMESTAMPTZ,
    hipaa_notice_version        TEXT,
    hipaa_notice_acknowledged_at TIMESTAMPTZ,

    created_at                  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at                  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at                  TIMESTAMPTZ,

    CONSTRAINT patient_accounts_password_hash_nonempty CHECK (password_hash != ''),
    CONSTRAINT patient_accounts_login_attempts_non_negative CHECK (failed_login_attempts >= 0)
);

COMMENT ON TABLE  patient_accounts IS 'Patient portal authentication accounts — separate from clinical demographics';
COMMENT ON COLUMN patient_accounts.email IS '[PHI-ENCRYPTED] AES-256-GCM encrypted; use email_hash for equality lookups';
COMMENT ON COLUMN patient_accounts.password_hash IS 'bcrypt hash (cost >= 12) — never store plaintext password';
COMMENT ON COLUMN patient_accounts.mfa_secret IS '[PHI-ENCRYPTED] TOTP secret for authenticator app integration';

-- Indexes on frequently used lookup fields
CREATE INDEX idx_patient_accounts_email_hash    ON patient_accounts (email_hash);
CREATE INDEX idx_patient_accounts_phone_hash    ON patient_accounts (phone_hash);
CREATE INDEX idx_patient_accounts_username      ON patient_accounts (username) WHERE username IS NOT NULL;


-- ── 6.2  Consents ────────────────────────────────────────────
-- HIPAA Authorization, Treatment Consent, Research Authorization

CREATE TABLE consents (
    id                      UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    fhir_id                 UUID        UNIQUE NOT NULL DEFAULT gen_random_uuid(),

    patient_id              UUID        NOT NULL REFERENCES patients(id) ON DELETE CASCADE,

    status                  consent_status NOT NULL DEFAULT 'active',
    scope_code              consent_scope  NOT NULL DEFAULT 'patient_privacy',
    scope_display           TEXT        NOT NULL,

    category_codes          TEXT[]      NOT NULL DEFAULT '{}',      -- LOINC / HL7 consent category
    category_displays       TEXT[]      NOT NULL DEFAULT '{}',

    -- Policy reference
    policy_uri              TEXT,                                   -- URL to the full policy document
    policy_rule_code        TEXT,                                   -- e.g., 'hipaa-auth'
    policy_rule_display     TEXT,

    -- When signed / effective
    date_time               TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    period_start            TIMESTAMPTZ,
    period_end              TIMESTAMPTZ,

    -- Parties
    grantor_patient_id      UUID        REFERENCES patients(id) ON DELETE SET NULL,
    grantee_practitioner_id UUID        REFERENCES practitioners(id) ON DELETE SET NULL,
    grantee_org_id          UUID        REFERENCES organizations(id) ON DELETE SET NULL,

    -- Source (signed consent form)
    source_document_id      UUID        REFERENCES documents(id) ON DELETE SET NULL,
    source_attachment_url   TEXT,

    -- Verification
    is_verified             BOOLEAN     NOT NULL DEFAULT false,
    verified_with_code      TEXT,                                   -- patient, parent, guardian
    verified_with_display   TEXT,
    verified_at             TIMESTAMPTZ,

    note                    TEXT,

    fhir_version_id         TEXT        NOT NULL DEFAULT '1',
    fhir_last_updated       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT consents_period_check CHECK (
        period_end IS NULL OR period_start IS NULL OR period_end >= period_start
    )
);

COMMENT ON TABLE consents IS 'HIPAA consents, treatment authorizations, research releases (FHIR Consent)';


CREATE TABLE consent_provisions (
    id                  UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    consent_id          UUID        NOT NULL REFERENCES consents(id) ON DELETE CASCADE,
    parent_provision_id UUID        REFERENCES consent_provisions(id) ON DELETE CASCADE,

    provision_type      TEXT        NOT NULL DEFAULT 'permit',      -- deny | permit
    period_start        TIMESTAMPTZ,
    period_end          TIMESTAMPTZ,

    -- Who the provision applies to
    actor_role_code     TEXT,
    actor_role_display  TEXT,
    actor_reference_id  UUID,                                       -- practitioner or organization

    -- What actions are covered
    action_codes        TEXT[]      NOT NULL DEFAULT '{}',          -- FHIR ConsentActionCode
    action_displays     TEXT[]      NOT NULL DEFAULT '{}',

    -- Security classification
    security_label_codes TEXT[]     NOT NULL DEFAULT '{}',          -- e.g., 'PHI', 'PSY', 'HIV'

    -- Purpose of use
    purpose_codes       TEXT[]      NOT NULL DEFAULT '{}',          -- FHIR V3 Purpose Of Use
    purpose_displays    TEXT[]      NOT NULL DEFAULT '{}',

    -- Data scope
    class_codes         TEXT[]      NOT NULL DEFAULT '{}',          -- FHIR resource type codes
    data_meaning        TEXT,                                       -- instance, related, dependents, authoredby
    data_reference_id   UUID,

    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE consent_provisions IS 'Fine-grained rules within a consent (permit/deny specific actions, resources, purposes)';


-- ── 6.3  Appointments ────────────────────────────────────────

CREATE TABLE appointments (
    id                          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    fhir_id                     UUID        UNIQUE NOT NULL DEFAULT gen_random_uuid(),

    patient_id                  UUID        NOT NULL REFERENCES patients(id) ON DELETE RESTRICT,

    status                      appointment_status NOT NULL DEFAULT 'booked',
    cancellation_reason         TEXT,

    -- Service details
    service_type_code           TEXT,
    service_type_display        TEXT,
    specialty_code              TEXT,
    specialty_display           TEXT,
    appointment_type_code       TEXT        NOT NULL DEFAULT 'ROUTINE',
    -- ROUTINE, WALKIN, CHECKUP, FOLLOWUP, EMERGENCY, PREVENTIVE, WELLBABY

    -- Reason
    reason_codes                TEXT[]      NOT NULL DEFAULT '{}',
    reason_displays             TEXT[]      NOT NULL DEFAULT '{}',
    priority                    SMALLINT    NOT NULL DEFAULT 5,      -- 1=highest, 9=lowest (HL7)

    description                 TEXT,

    -- Timing
    start_time                  TIMESTAMPTZ NOT NULL,
    end_time                    TIMESTAMPTZ NOT NULL,
    duration_minutes            INTEGER GENERATED ALWAYS AS (
                                    EXTRACT(EPOCH FROM (end_time - start_time))::INTEGER / 60
                                ) STORED,
    created                     TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Telehealth
    telehealth_url              TEXT,
    telehealth_meeting_id       TEXT,
    telehealth_passcode         BYTEA,                              -- [PHI-ENCRYPTED] meeting passcode

    -- Instructions
    comment                     TEXT,
    patient_instruction         TEXT,

    -- Linked clinical resources
    based_on_service_request_id UUID        REFERENCES service_requests(id) ON DELETE SET NULL,
    encounter_id                UUID        REFERENCES encounters(id) ON DELETE SET NULL,

    -- Scheduling slot (optional — supports slot-based scheduling)
    slot_id                     UUID,

    -- Reminders sent
    reminder_24h_sent           BOOLEAN     NOT NULL DEFAULT false,
    reminder_2h_sent            BOOLEAN     NOT NULL DEFAULT false,
    reminder_24h_sent_at        TIMESTAMPTZ,
    reminder_2h_sent_at         TIMESTAMPTZ,

    version                     INTEGER     NOT NULL DEFAULT 1,
    fhir_version_id             TEXT        NOT NULL DEFAULT '1',
    fhir_last_updated           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at                  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at                  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at                  TIMESTAMPTZ,

    CONSTRAINT appointments_end_after_start CHECK (end_time > start_time),
    CONSTRAINT appointments_priority_range  CHECK (priority BETWEEN 1 AND 9)
);

COMMENT ON TABLE appointments IS 'Telehealth and in-person appointment bookings (FHIR Appointment)';

-- Back-fill FK on encounters
ALTER TABLE encounters ADD CONSTRAINT encounters_appointment_fk
    FOREIGN KEY (appointment_id) REFERENCES appointments(id) ON DELETE SET NULL;


CREATE TABLE appointment_participants (
    id                  UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    appointment_id      UUID        NOT NULL REFERENCES appointments(id) ON DELETE CASCADE,

    type_code           TEXT        NOT NULL,           -- HL7 ParticipationType: ATND, CON, REF, PART
    type_display        TEXT,

    -- Exactly one actor type per row
    actor_practitioner_id UUID      REFERENCES practitioners(id) ON DELETE CASCADE,
    actor_patient_id    UUID        REFERENCES patients(id) ON DELETE CASCADE,
    actor_org_id        UUID        REFERENCES organizations(id) ON DELETE CASCADE,

    required            participant_required  NOT NULL DEFAULT 'required',
    status              participant_status    NOT NULL DEFAULT 'needs_action',
    period_start        TIMESTAMPTZ,
    period_end          TIMESTAMPTZ,

    CONSTRAINT apt_participants_single_actor CHECK (
        (
            (actor_practitioner_id IS NOT NULL)::INT +
            (actor_patient_id      IS NOT NULL)::INT +
            (actor_org_id          IS NOT NULL)::INT
        ) = 1
    )
);

COMMENT ON TABLE appointment_participants IS 'All participants in an appointment (FHIR Appointment.participant)';


-- ── 6.4  Secure Messaging ────────────────────────────────────

CREATE TABLE message_threads (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),

    patient_id      UUID        NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    practitioner_id UUID        REFERENCES practitioners(id) ON DELETE SET NULL,

    subject         TEXT        NOT NULL,
    is_urgent       BOOLEAN     NOT NULL DEFAULT false,
    is_archived     BOOLEAN     NOT NULL DEFAULT false,
    last_message_at TIMESTAMPTZ,
    message_count   INTEGER     NOT NULL DEFAULT 0,
    unread_count    INTEGER     NOT NULL DEFAULT 0,

    encounter_id    UUID        REFERENCES encounters(id) ON DELETE SET NULL,

    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE message_threads IS 'Secure message threads between patient and care team';


CREATE TABLE messages (
    id                      UUID        PRIMARY KEY DEFAULT gen_random_uuid(),

    thread_id               UUID        NOT NULL REFERENCES message_threads(id) ON DELETE CASCADE,
    parent_message_id       UUID        REFERENCES messages(id) ON DELETE SET NULL,

    -- Sender (exactly one)
    sender_patient_id       UUID        REFERENCES patients(id) ON DELETE SET NULL,
    sender_practitioner_id  UUID        REFERENCES practitioners(id) ON DELETE SET NULL,

    -- Recipient (exactly one)
    recipient_patient_id    UUID        REFERENCES patients(id) ON DELETE SET NULL,
    recipient_practitioner_id UUID      REFERENCES practitioners(id) ON DELETE SET NULL,

    body                    BYTEA       NOT NULL,           -- [PHI-ENCRYPTED] message body
    body_hash               BYTEA       NOT NULL,           -- For deduplication
    status                  message_status NOT NULL DEFAULT 'sent',

    sent_at                 TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    delivered_at            TIMESTAMPTZ,
    read_at                 TIMESTAMPTZ,

    is_urgent               BOOLEAN     NOT NULL DEFAULT false,
    has_attachments         BOOLEAN     NOT NULL DEFAULT false,

    created_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at              TIMESTAMPTZ,

    CONSTRAINT messages_single_sender CHECK (
        (sender_patient_id IS NOT NULL)::INT +
        (sender_practitioner_id IS NOT NULL)::INT = 1
    ),
    CONSTRAINT messages_single_recipient CHECK (
        (recipient_patient_id IS NOT NULL)::INT +
        (recipient_practitioner_id IS NOT NULL)::INT = 1
    )
);

COMMENT ON TABLE  messages IS 'HIPAA-compliant encrypted secure messages between patient and clinicians';
COMMENT ON COLUMN messages.body IS '[PHI-ENCRYPTED] Message content — AES-256-GCM, key per-thread or per-org';


CREATE TABLE message_attachments (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    message_id      UUID        NOT NULL REFERENCES messages(id) ON DELETE CASCADE,
    document_id     UUID        REFERENCES documents(id) ON DELETE SET NULL,

    file_name       TEXT        NOT NULL,
    content_type    TEXT        NOT NULL,
    file_size_bytes BIGINT,
    content_url     TEXT        NOT NULL,               -- [PHI] Object storage path
    content_sha256  TEXT        NOT NULL,

    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE message_attachments IS 'File attachments on secure messages — stored in encrypted object storage';


-- ── 6.5  Notifications ───────────────────────────────────────

CREATE TABLE notification_preferences (
    id                          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id                  UUID        NOT NULL UNIQUE
                                            REFERENCES patients(id) ON DELETE CASCADE,

    -- What to notify
    appointment_reminders       BOOLEAN     NOT NULL DEFAULT true,
    appointment_reminder_hours  INTEGER[]   NOT NULL DEFAULT '{24, 2}', -- Hours before appt
    lab_results_available       BOOLEAN     NOT NULL DEFAULT true,
    prescription_status         BOOLEAN     NOT NULL DEFAULT true,
    message_received            BOOLEAN     NOT NULL DEFAULT true,
    care_plan_updates           BOOLEAN     NOT NULL DEFAULT true,
    billing_updates             BOOLEAN     NOT NULL DEFAULT true,

    -- How to notify
    channels                    notification_channel[] NOT NULL DEFAULT '{in_app}',

    -- Quiet hours
    quiet_hours_start           TIME,
    quiet_hours_end             TIME,
    timezone                    TEXT        NOT NULL DEFAULT 'America/New_York',

    created_at                  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at                  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE notification_preferences IS 'Patient notification delivery preferences per channel and event type';


CREATE TABLE notifications (
    id                      UUID        NOT NULL DEFAULT gen_random_uuid(),

    patient_id              UUID        NOT NULL REFERENCES patients(id) ON DELETE CASCADE,

    channel                 notification_channel  NOT NULL,
    status                  notification_status   NOT NULL DEFAULT 'pending',

    -- Type
    notification_type       TEXT        NOT NULL,       -- appointment_reminder, lab_result, rx_update, message, etc.
    title                   TEXT        NOT NULL,
    body                    TEXT        NOT NULL,
    data                    JSONB       NOT NULL DEFAULT '{}',  -- Type-specific payload

    -- Linked resource
    related_resource_type   TEXT,                       -- FHIR resource type
    related_resource_id     UUID,

    -- Scheduling
    scheduled_for           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    sent_at                 TIMESTAMPTZ,
    delivered_at            TIMESTAMPTZ,
    read_at                 TIMESTAMPTZ,

    -- Error handling
    error_message           TEXT,
    retry_count             SMALLINT    NOT NULL DEFAULT 0,
    max_retries             SMALLINT    NOT NULL DEFAULT 3,
    next_retry_at           TIMESTAMPTZ,

    expires_at              TIMESTAMPTZ,

    created_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Partition key must be part of PRIMARY KEY
    PRIMARY KEY (id, created_at)
) PARTITION BY RANGE (created_at);

COMMENT ON TABLE notifications IS 'Outbound notification records (email, SMS, push, in-app) — range-partitioned';

CREATE TABLE notifications_2025 PARTITION OF notifications
    FOR VALUES FROM ('2025-01-01') TO ('2026-01-01');
CREATE TABLE notifications_2026 PARTITION OF notifications
    FOR VALUES FROM ('2026-01-01') TO ('2027-01-01');
CREATE TABLE notifications_future PARTITION OF notifications
    FOR VALUES FROM ('2027-01-01') TO (MAXVALUE);
