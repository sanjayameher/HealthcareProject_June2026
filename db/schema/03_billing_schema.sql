-- ============================================================
-- SECTION 4 — BILLING SCHEMA
-- FHIR Resources: Organization (payer), Coverage,
--                 CoverageEligibilityRequest/Response
-- ============================================================

SET search_path TO dev, public;

-- ── 4.1  Payers (Insurance Companies) ──────────────────────

CREATE TABLE payers (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    fhir_id         UUID        UNIQUE NOT NULL DEFAULT gen_random_uuid(),

    name            TEXT        NOT NULL,
    short_name      TEXT,
    payer_id        VARCHAR(20) UNIQUE,                 -- Electronic payer ID (EDI 270/271)
    npi             VARCHAR(10),                        -- Payer NPI (if applicable)
    tax_id          BYTEA,                              -- [PHI-ENCRYPTED] EIN

    -- Contact
    address_line1   TEXT,
    address_line2   TEXT,
    city            TEXT,
    state           VARCHAR(2),
    postal_code     VARCHAR(10),
    country         VARCHAR(2)  NOT NULL DEFAULT 'US',
    phone           TEXT,
    fax             TEXT,
    website         TEXT,
    claims_address  TEXT,
    appeals_address TEXT,

    -- Capabilities
    supports_electronic_claims BOOLEAN NOT NULL DEFAULT true,
    supports_eligibility_check BOOLEAN NOT NULL DEFAULT true,
    eligibility_api_endpoint   TEXT,

    is_active       BOOLEAN     NOT NULL DEFAULT true,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at      TIMESTAMPTZ,

    CONSTRAINT payers_npi_format CHECK (npi IS NULL OR npi ~ '^\d{10}$')
);

COMMENT ON TABLE payers IS 'Insurance companies and government payers (FHIR Organization with type=ins)';


-- ── 4.2  Coverage (Insurance Plans) ─────────────────────────

CREATE TABLE coverage (
    id                      UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    fhir_id                 UUID        UNIQUE NOT NULL DEFAULT gen_random_uuid(),

    patient_id              UUID        NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    payer_id                UUID        NOT NULL REFERENCES payers(id) ON DELETE RESTRICT,

    status                  coverage_status  NOT NULL DEFAULT 'active',
    type                    coverage_type    NOT NULL DEFAULT 'medical',

    -- Policy details — all PHI encrypted at application layer
    subscriber_id           BYTEA       NOT NULL,       -- [PHI-ENCRYPTED] Member/subscriber ID
    subscriber_id_hash      BYTEA       NOT NULL,       -- HMAC for lookup
    group_number            TEXT,
    group_name              TEXT,
    plan_name               TEXT        NOT NULL,
    plan_id                 TEXT,

    -- Subscriber (may differ from patient — e.g., child on parent's plan)
    subscriber_relationship subscriber_relationship NOT NULL DEFAULT 'self',
    subscriber_name_family  TEXT,
    subscriber_name_given   TEXT,
    subscriber_birth_date   DATE,
    subscriber_gender       gender,

    -- Coverage dates
    period_start            DATE        NOT NULL,
    period_end              DATE,

    -- Priority (primary=1, secondary=2, tertiary=3)
    order_of_benefit        SMALLINT    NOT NULL DEFAULT 1,
    is_primary              BOOLEAN     GENERATED ALWAYS AS (order_of_benefit = 1) STORED,

    -- Benefit details
    copay_primary_care      NUMERIC(10, 2),
    copay_specialist        NUMERIC(10, 2),
    copay_emergency         NUMERIC(10, 2),
    deductible_individual   NUMERIC(10, 2),
    deductible_family       NUMERIC(10, 2),
    deductible_met          NUMERIC(10, 2),
    out_of_pocket_max_individual NUMERIC(10, 2),
    out_of_pocket_max_family     NUMERIC(10, 2),
    coinsurance_rate        NUMERIC(5, 2),              -- e.g., 0.20 = 20%

    -- Network
    network_name            TEXT,
    requires_referral       BOOLEAN     NOT NULL DEFAULT false,
    pcp_required            BOOLEAN     NOT NULL DEFAULT false,
    pcp_provider_id         UUID        REFERENCES practitioners(id) ON DELETE SET NULL,

    -- Coordination of benefits
    coordination_of_benefits_description TEXT,

    -- Verification
    last_verified_at        TIMESTAMPTZ,
    verification_source     TEXT,                       -- 'electronic', 'phone', 'portal'

    version                 INTEGER     NOT NULL DEFAULT 1,
    created_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at              TIMESTAMPTZ,

    CONSTRAINT coverage_period_check CHECK (
        period_end IS NULL OR period_end >= period_start
    ),
    CONSTRAINT coverage_order_positive CHECK (order_of_benefit >= 1),
    CONSTRAINT coverage_coinsurance_range CHECK (
        coinsurance_rate IS NULL OR (coinsurance_rate >= 0 AND coinsurance_rate <= 1)
    )
);

COMMENT ON TABLE  coverage IS 'Patient insurance coverage / health plan enrollment (FHIR Coverage)';
COMMENT ON COLUMN coverage.subscriber_id IS '[PHI-ENCRYPTED] Member or subscriber ID number';
COMMENT ON COLUMN coverage.order_of_benefit IS '1=primary, 2=secondary, 3=tertiary per COB rules';


-- ── 4.3  Eligibility Checks ─────────────────────────────────

CREATE TABLE eligibility_checks (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    coverage_id     UUID        NOT NULL REFERENCES coverage(id) ON DELETE CASCADE,
    patient_id      UUID        NOT NULL REFERENCES patients(id) ON DELETE CASCADE,

    checked_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    service_date    DATE,                               -- Date of intended service
    service_type    TEXT,                               -- Type of service being checked

    status          eligibility_status NOT NULL DEFAULT 'pending',
    is_eligible     BOOLEAN,
    response_code   TEXT,
    response_message TEXT,

    -- Raw EDI or API response (for debugging and audit)
    raw_request     JSONB,
    raw_response    JSONB,

    -- Derived benefit info at time of check
    deductible_met  NUMERIC(10, 2),
    oop_met         NUMERIC(10, 2),
    copay_amount    NUMERIC(10, 2),
    coinsurance_rate NUMERIC(5, 2),

    initiated_by    UUID        REFERENCES practitioners(id) ON DELETE SET NULL,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE eligibility_checks IS 'Real-time insurance eligibility verification history (FHIR CoverageEligibilityRequest/Response)';
