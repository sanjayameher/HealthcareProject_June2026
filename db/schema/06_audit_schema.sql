-- ============================================================
-- SECTION 7 — AUDIT SCHEMA
-- HIPAA requires audit trails for all PHI access (§ 164.312(b))
-- FHIR Resource: AuditEvent
-- Retention: minimum 6 years per HIPAA; longer per state law
-- ============================================================

SET search_path TO dev, public;

-- ── 7.1  FHIR-Aligned Audit Events ──────────────────────────
-- Full audit event log; partitioned by recorded for retention management

CREATE TABLE audit_events (
    id                      UUID        NOT NULL DEFAULT gen_random_uuid(),

    -- FHIR AuditEvent type
    type_code               TEXT        NOT NULL,       -- FHIR AuditEventType code
    type_display            TEXT,
    type_system             TEXT        DEFAULT 'http://terminology.hl7.org/CodeSystem/audit-event-type',
    subtype_codes           TEXT[]      NOT NULL DEFAULT '{}',
    subtype_displays        TEXT[]      NOT NULL DEFAULT '{}',

    action                  event_action  NOT NULL,
    recorded                TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    outcome                 event_outcome NOT NULL DEFAULT 'success',
    outcome_description     TEXT,
    purpose_of_event_codes  TEXT[]      NOT NULL DEFAULT '{}',  -- FHIR PurposeOfUse: TPO, TREAT, PAYOR, etc.

    -- Agent (who performed the action)
    agent_type              accessor_type NOT NULL,
    agent_user_id           UUID,                               -- patient_accounts.id or practitioners.id
    agent_user_name         TEXT,
    agent_user_role         TEXT,
    agent_network_address   INET,
    agent_network_type      TEXT    DEFAULT 'IP',
    agent_is_requestor      BOOLEAN NOT NULL DEFAULT true,

    -- Source (system that recorded the event)
    source_site             TEXT,
    source_observer         TEXT    NOT NULL DEFAULT 'HealthcarePlatform',
    source_type             TEXT    DEFAULT 'application-server',

    -- Entity (what was acted upon)
    entity_type             TEXT,                               -- FHIR resource type: Patient, Observation, etc.
    entity_id               UUID,
    entity_name             TEXT,
    entity_description      TEXT,

    -- Patient context (always required when PHI is involved)
    patient_id              UUID,                               -- FK not enforced for audit (patient may be deleted)

    -- Search query (for R action on search)
    query_string            TEXT,

    -- Additional details (JSONB for extensibility)
    detail                  JSONB   NOT NULL DEFAULT '{}',

    -- HTTP context
    http_method             TEXT,
    http_path               TEXT,
    http_status_code        SMALLINT,
    request_id              TEXT,
    session_id              TEXT,
    correlation_id          TEXT,

    -- Partition key
    PRIMARY KEY (id, recorded),

    CONSTRAINT audit_events_action_valid CHECK (action IS NOT NULL)
) PARTITION BY RANGE (recorded);

COMMENT ON TABLE audit_events IS 'HIPAA-mandated complete audit trail of all PHI access and system events (FHIR AuditEvent) — range-partitioned by recorded date, retain 6+ years';

-- Annual partitions aligned with calendar year (HIPAA 6-year minimum retention)
CREATE TABLE audit_events_2024 PARTITION OF audit_events
    FOR VALUES FROM ('2024-01-01') TO ('2025-01-01');
CREATE TABLE audit_events_2025 PARTITION OF audit_events
    FOR VALUES FROM ('2025-01-01') TO ('2026-01-01');
CREATE TABLE audit_events_2026 PARTITION OF audit_events
    FOR VALUES FROM ('2026-01-01') TO ('2027-01-01');
CREATE TABLE audit_events_2027 PARTITION OF audit_events
    FOR VALUES FROM ('2027-01-01') TO ('2028-01-01');
CREATE TABLE audit_events_2028 PARTITION OF audit_events
    FOR VALUES FROM ('2028-01-01') TO ('2029-01-01');
CREATE TABLE audit_events_2029 PARTITION OF audit_events
    FOR VALUES FROM ('2029-01-01') TO ('2030-01-01');
CREATE TABLE audit_events_future PARTITION OF audit_events
    FOR VALUES FROM ('2030-01-01') TO (MAXVALUE);


-- ── 7.2  PHI Access Log ──────────────────────────────────────
-- Simplified fast-write log for real-time PHI monitoring
-- More queryable than full FHIR audit events

CREATE TABLE phi_access_log (
    id                  UUID        NOT NULL DEFAULT gen_random_uuid(),

    accessed_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Who
    accessor_type       accessor_type NOT NULL,
    accessor_id         UUID        NOT NULL,
    accessor_name       TEXT,
    accessor_role       TEXT,
    accessor_org_id     UUID,

    -- Which patient
    patient_id          UUID        NOT NULL,           -- Not FK — audit survives patient deletion

    -- What
    resource_type       TEXT        NOT NULL,           -- FHIR resource type
    resource_id         UUID,
    action              TEXT        NOT NULL,           -- view, export, print, share, create, update, delete
    fields_accessed     TEXT[],                         -- Specific PHI fields accessed (for minimum necessary)

    -- Why
    purpose             TEXT        NOT NULL DEFAULT 'TPO',  -- TPO, RESEARCH, LEGAL, EMERGENCY, AUDIT
    purpose_detail      TEXT,

    -- Context
    ip_address          INET,
    user_agent          TEXT,
    session_id          TEXT,
    request_id          TEXT,

    -- Outcome
    was_authorized      BOOLEAN     NOT NULL DEFAULT true,
    breach_indicator    BOOLEAN     NOT NULL DEFAULT false,

    PRIMARY KEY (id, accessed_at)
) PARTITION BY RANGE (accessed_at);

COMMENT ON TABLE phi_access_log IS 'Fast-write PHI access log for HIPAA minimum-necessary monitoring and breach detection — partitioned annually';

CREATE TABLE phi_access_log_2025 PARTITION OF phi_access_log
    FOR VALUES FROM ('2025-01-01') TO ('2026-01-01');
CREATE TABLE phi_access_log_2026 PARTITION OF phi_access_log
    FOR VALUES FROM ('2026-01-01') TO ('2027-01-01');
CREATE TABLE phi_access_log_future PARTITION OF phi_access_log
    FOR VALUES FROM ('2027-01-01') TO (MAXVALUE);


-- ── 7.3  Data Change History ─────────────────────────────────
-- Row-level change log for critical clinical tables
-- (Supplement to audit_events — captures old/new values)

CREATE TABLE data_change_history (
    id              UUID        NOT NULL DEFAULT gen_random_uuid(),

    changed_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    table_schema    TEXT        NOT NULL,
    table_name      TEXT        NOT NULL,
    record_id       UUID        NOT NULL,

    operation       TEXT        NOT NULL,               -- INSERT, UPDATE, DELETE
    changed_by_type accessor_type,
    changed_by_id   UUID,
    changed_by_name TEXT,

    patient_id      UUID,                               -- Extracted for fast patient-scoped queries

    -- Change data
    old_values      JSONB,                              -- Row before change (NULL for INSERT)
    new_values      JSONB,                              -- Row after change (NULL for DELETE)
    changed_columns TEXT[],                             -- Columns that actually changed (UPDATE only)

    session_id      TEXT,
    request_id      TEXT,

    PRIMARY KEY (id, changed_at)
) PARTITION BY RANGE (changed_at);

COMMENT ON TABLE data_change_history IS 'Row-level before/after change log for clinical data — supports breach investigation and data lineage';

CREATE TABLE data_change_history_2025 PARTITION OF data_change_history
    FOR VALUES FROM ('2025-01-01') TO ('2026-01-01');
CREATE TABLE data_change_history_2026 PARTITION OF data_change_history
    FOR VALUES FROM ('2026-01-01') TO ('2027-01-01');
CREATE TABLE data_change_history_future PARTITION OF data_change_history
    FOR VALUES FROM ('2027-01-01') TO (MAXVALUE);


-- ── 7.4  Failed Authentication Attempts ─────────────────────

CREATE TABLE auth_failure_log (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    occurred_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    attempt_type    TEXT        NOT NULL,               -- login, mfa, password_reset, email_verify
    identifier_hash BYTEA       NOT NULL,               -- HMAC of username/email (never store plaintext)
    ip_address      INET        NOT NULL,
    user_agent      TEXT,
    failure_reason  TEXT        NOT NULL,               -- invalid_password, account_locked, mfa_failed, etc.
    account_id      UUID,                               -- patient_accounts.id if resolvable
    geo_country     VARCHAR(2),
    geo_city        TEXT,
    is_bot_detected BOOLEAN     NOT NULL DEFAULT false
);

COMMENT ON TABLE auth_failure_log IS 'Authentication failure log for brute-force detection and security monitoring';
