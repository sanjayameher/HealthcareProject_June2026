-- ============================================================
-- SECTION 3 — PATIENT SCHEMA
-- FHIR Resources: Organization, Practitioner, Patient,
--                 RelatedPerson, Flag, PatientLink
-- ============================================================
-- PHI Encryption Note:
--   Columns marked [PHI-ENCRYPTED] must use application-level
--   AES-256-GCM encryption or pgcrypto pgp_sym_encrypt() with
--   an externally managed key (AWS KMS / HashiCorp Vault).
--   Never store encryption keys in the database.
-- ============================================================

SET search_path TO dev, public;

-- ── 3.1  Organizations ──────────────────────────────────────
-- Hospitals, clinics, telehealth providers, labs, pharmacies

CREATE TABLE organizations (
    id                  UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    fhir_id             UUID        UNIQUE NOT NULL DEFAULT gen_random_uuid(),

    name                TEXT        NOT NULL,
    alias               TEXT[],                          -- Trade/DBA names
    active              BOOLEAN     NOT NULL DEFAULT true,
    type_code           TEXT        NOT NULL,            -- FHIR org-type: prov, dept, team, govt, ins, pay, edu, reli, cg, bus, other
    type_display        TEXT,

    -- Federal identifiers
    npi                 VARCHAR(10) UNIQUE,              -- National Provider Identifier
    tax_id              BYTEA,                           -- [PHI-ENCRYPTED] EIN / TIN

    -- Contact
    address_line1       TEXT,
    address_line2       TEXT,
    city                TEXT,
    state               VARCHAR(2),
    postal_code         VARCHAR(10),
    country             VARCHAR(2)  NOT NULL DEFAULT 'US',
    phone               TEXT,
    fax                 TEXT,
    email               CITEXT,
    website             TEXT,

    -- Hierarchy
    parent_org_id       UUID        REFERENCES organizations(id) ON DELETE SET NULL,

    -- FHIR metadata
    fhir_version_id     TEXT        NOT NULL DEFAULT '1',
    fhir_last_updated   TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at          TIMESTAMPTZ,

    CONSTRAINT organizations_npi_format CHECK (npi IS NULL OR npi ~ '^\d{10}$')
);

COMMENT ON TABLE  organizations IS 'Healthcare organizations: providers, labs, pharmacies, insurers (FHIR Organization)';
COMMENT ON COLUMN organizations.tax_id IS '[PHI-ENCRYPTED] Federal EIN stored encrypted via pgcrypto or KMS';


-- ── 3.2  Practitioners ──────────────────────────────────────
-- Physicians, NPs, PAs, RNs, therapists, pharmacists

CREATE TABLE practitioners (
    id                  UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    fhir_id             UUID        UNIQUE NOT NULL DEFAULT gen_random_uuid(),

    organization_id     UUID        REFERENCES organizations(id) ON DELETE SET NULL,
    active              BOOLEAN     NOT NULL DEFAULT true,

    -- Identity
    npi                 VARCHAR(10) UNIQUE,              -- Individual NPI (Type 1)
    dea_number          BYTEA,                           -- [PHI-ENCRYPTED] DEA license
    state_license       TEXT,
    state_license_state VARCHAR(2),

    -- Demographics
    gender              gender,
    birth_date          DATE,

    -- Name (primary — full name history in practitioner_names)
    prefix              TEXT,                            -- Dr., Mr., Ms.
    given_name          TEXT        NOT NULL,
    family_name         TEXT        NOT NULL,
    suffix              TEXT,                            -- MD, DO, PhD
    full_name_display   TEXT GENERATED ALWAYS AS (
                            COALESCE(prefix || ' ', '') ||
                            given_name || ' ' ||
                            family_name ||
                            COALESCE(' ' || suffix, '')
                        ) STORED,

    -- Professional
    specialty_codes     TEXT[]      NOT NULL DEFAULT '{}', -- NUCC taxonomy codes
    specialty_displays  TEXT[]      NOT NULL DEFAULT '{}',
    qualification_codes TEXT[]      NOT NULL DEFAULT '{}', -- FHIR Practitioner.qualification
    languages           VARCHAR(10)[] NOT NULL DEFAULT '{}', -- BCP-47 codes

    -- Telehealth availability
    is_telehealth_enabled BOOLEAN   NOT NULL DEFAULT true,
    telehealth_platform TEXT,

    fhir_version_id     TEXT        NOT NULL DEFAULT '1',
    fhir_last_updated   TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at          TIMESTAMPTZ,

    CONSTRAINT practitioners_npi_format CHECK (npi IS NULL OR npi ~ '^\d{10}$')
);

COMMENT ON TABLE  practitioners IS 'Licensed clinicians and care team members (FHIR Practitioner)';
COMMENT ON COLUMN practitioners.dea_number IS '[PHI-ENCRYPTED] DEA registration number for controlled substance prescribing';

CREATE TABLE practitioner_roles (
    id                  UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    practitioner_id     UUID        NOT NULL REFERENCES practitioners(id) ON DELETE CASCADE,
    organization_id     UUID        REFERENCES organizations(id) ON DELETE SET NULL,
    role_code           TEXT        NOT NULL,            -- SNOMED / custom role
    role_display        TEXT        NOT NULL,
    specialty_code      TEXT,
    specialty_display   TEXT,
    period_start        DATE,
    period_end          DATE,
    is_active           BOOLEAN     NOT NULL DEFAULT true,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);


-- ── 3.3  Patients  ──────────────────────────────────────────
-- Core demographic record — FHIR Patient resource

CREATE TABLE patients (
    id                      UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    fhir_id                 UUID        UNIQUE NOT NULL DEFAULT gen_random_uuid(),

    -- Medical Record Number — human-readable, org-scoped
    mrn                     VARCHAR(20) UNIQUE NOT NULL,
    active                  BOOLEAN     NOT NULL DEFAULT true,

    -- Administrative demographics
    gender                  gender NOT NULL DEFAULT 'unknown',

    -- [PHI] Date of birth stored as DATE (restrict via RLS + column privilege)
    birth_date              DATE        NOT NULL,
    birth_time              TIME,                        -- For neonates
    birth_place_city        TEXT,
    birth_place_state       VARCHAR(2),
    birth_place_country     VARCHAR(2),

    -- Deceased
    deceased_boolean        BOOLEAN,
    deceased_date_time      TIMESTAMPTZ,

    -- Multiple birth
    multiple_birth_boolean  BOOLEAN,
    multiple_birth_order    SMALLINT,                   -- Birth order if multiple birth

    -- Marital status
    marital_status          marital_status,

    -- Primary managing organization
    managing_organization_id UUID       REFERENCES organizations(id) ON DELETE SET NULL,

    -- US Core extensions
    -- Race/Ethnicity stored as separate table (multi-valued per US Core R4)
    -- Disability, SDOH captured as Observations

    -- Optimistic locking
    version                 INTEGER     NOT NULL DEFAULT 1,

    -- FHIR metadata
    fhir_version_id         TEXT        NOT NULL DEFAULT '1',
    fhir_last_updated       TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    created_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at              TIMESTAMPTZ,

    CONSTRAINT patients_mrn_format CHECK (mrn ~ '^[A-Z0-9\-]{4,20}$'),
    CONSTRAINT patients_birth_date_reasonable CHECK (
        birth_date >= '1900-01-01' AND birth_date <= CURRENT_DATE
    ),
    CONSTRAINT patients_deceased_logic CHECK (
        deceased_date_time IS NULL OR deceased_boolean IS DISTINCT FROM false
    ),
    CONSTRAINT patients_multiple_birth_order CHECK (
        multiple_birth_order IS NULL OR (multiple_birth_boolean = true AND multiple_birth_order >= 1)
    )
);

COMMENT ON TABLE  patients IS 'Core patient demographic record — root entity for the entire patient module (FHIR Patient)';
COMMENT ON COLUMN patients.mrn IS 'Medical Record Number — unique per managing organization, human-readable';
COMMENT ON COLUMN patients.birth_date IS '[PHI] Restrict column access via PostgreSQL column-level privileges or RLS';
COMMENT ON COLUMN patients.version IS 'Optimistic locking counter — increment on every UPDATE';


-- ── 3.4  Patient Identifiers ────────────────────────────────
-- SSN, MRN, Passport, Driver License, Insurance IDs, etc.

CREATE TABLE patient_identifiers (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id      UUID        NOT NULL REFERENCES patients(id) ON DELETE CASCADE,

    system          identifier_system NOT NULL,
    value           BYTEA       NOT NULL,               -- [PHI-ENCRYPTED] identifier value
    value_hash      BYTEA       NOT NULL,               -- HMAC-SHA256 for exact-match lookups
    display         TEXT,                               -- Non-sensitive label

    assigner_name   TEXT,                               -- Issuing authority
    assigner_org_id UUID        REFERENCES organizations(id) ON DELETE SET NULL,

    period_start    DATE,
    period_end      DATE,
    is_active       BOOLEAN     NOT NULL DEFAULT true,

    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT patient_identifiers_period CHECK (
        period_end IS NULL OR period_start IS NULL OR period_end >= period_start
    )
);

COMMENT ON TABLE  patient_identifiers IS 'External identifiers for a patient (SSN, passport, insurance IDs — FHIR Patient.identifier)';
COMMENT ON COLUMN patient_identifiers.value IS '[PHI-ENCRYPTED] Raw identifier encrypted with AES-256-GCM via application or pgcrypto';
COMMENT ON COLUMN patient_identifiers.value_hash IS 'HMAC-SHA256(value, secret_key) — used for equality lookups without decryption';


-- ── 3.5  Patient Names ──────────────────────────────────────
-- Supports maiden name, legal name changes, aliases

CREATE TABLE patient_names (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id      UUID        NOT NULL REFERENCES patients(id) ON DELETE CASCADE,

    use             name_use NOT NULL DEFAULT 'official',
    text            TEXT,                               -- Full text representation
    family          TEXT        NOT NULL,               -- [PHI]
    given           TEXT[]      NOT NULL DEFAULT '{}',  -- [PHI] First + middle names
    prefix          TEXT[],                             -- Mr., Mrs., Dr.
    suffix          TEXT[],                             -- Jr., Sr., III, MD
    period_start    DATE,
    period_end      DATE,
    is_primary      BOOLEAN     NOT NULL DEFAULT false,

    CONSTRAINT patient_names_period CHECK (
        period_end IS NULL OR period_start IS NULL OR period_end >= period_start
    )
);

COMMENT ON TABLE patient_names IS 'All name records for a patient including maiden, legal, and preferred names (FHIR Patient.name)';


-- ── 3.6  Patient Addresses ──────────────────────────────────

CREATE TABLE patient_addresses (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id      UUID        NOT NULL REFERENCES patients(id) ON DELETE CASCADE,

    use             address_use  NOT NULL DEFAULT 'home',
    type            address_type NOT NULL DEFAULT 'both',

    -- [PHI] Street address stored encrypted at application level
    line1           TEXT,
    line2           TEXT,
    city            TEXT,
    district        TEXT,                               -- County
    state           VARCHAR(2),
    postal_code     VARCHAR(10),
    country         VARCHAR(2)  NOT NULL DEFAULT 'US',

    -- Geocoded coordinates (for care gap analysis, not for tracking)
    latitude        NUMERIC(9, 6),
    longitude       NUMERIC(9, 6),

    period_start    DATE,
    period_end      DATE,
    is_primary      BOOLEAN     NOT NULL DEFAULT false,

    CONSTRAINT patient_addresses_period CHECK (
        period_end IS NULL OR period_start IS NULL OR period_end >= period_start
    ),
    CONSTRAINT patient_addresses_postal_us CHECK (
        country != 'US' OR postal_code IS NULL OR postal_code ~ '^\d{5}(-\d{4})?$'
    )
);

COMMENT ON TABLE patient_addresses IS 'Patient mailing and residential addresses (FHIR Patient.address)';


-- ── 3.7  Patient Telecoms ───────────────────────────────────

CREATE TABLE patient_telecoms (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id      UUID        NOT NULL REFERENCES patients(id) ON DELETE CASCADE,

    system          telecom_system NOT NULL,
    value           BYTEA       NOT NULL,               -- [PHI-ENCRYPTED]
    value_hash      BYTEA       NOT NULL,               -- HMAC for lookup
    use             telecom_use,
    rank            SMALLINT    NOT NULL DEFAULT 1,     -- 1 = highest preference
    period_start    DATE,
    period_end      DATE,
    is_verified     BOOLEAN     NOT NULL DEFAULT false,
    verified_at     TIMESTAMPTZ,

    CONSTRAINT patient_telecoms_rank_positive CHECK (rank > 0),
    CONSTRAINT patient_telecoms_period CHECK (
        period_end IS NULL OR period_start IS NULL OR period_end >= period_start
    )
);

COMMENT ON TABLE  patient_telecoms IS 'Phone, email, SMS contacts for a patient (FHIR Patient.telecom)';
COMMENT ON COLUMN patient_telecoms.value IS '[PHI-ENCRYPTED] Raw contact value (phone number, email address)';
COMMENT ON COLUMN patient_telecoms.rank  IS 'Contact preference order; 1 is most preferred per system+use combination';


-- ── 3.8  Patient Emergency Contacts / Related Persons ───────
-- FHIR Patient.contact + RelatedPerson

CREATE TABLE patient_contacts (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id      UUID        NOT NULL REFERENCES patients(id) ON DELETE CASCADE,

    relationship    contact_relationship NOT NULL,
    priority        SMALLINT    NOT NULL DEFAULT 1,     -- 1 = primary emergency contact

    -- Name
    name_family     TEXT,                               -- [PHI]
    name_given      TEXT[],                             -- [PHI]
    name_prefix     TEXT[],
    name_suffix     TEXT[],

    -- Contact details
    phone           BYTEA,                              -- [PHI-ENCRYPTED]
    phone_hash      BYTEA,
    email           BYTEA,                              -- [PHI-ENCRYPTED]
    email_hash      BYTEA,
    fax             TEXT,

    -- Address (optional)
    address_line1   TEXT,
    address_city    TEXT,
    address_state   VARCHAR(2),
    address_postal  VARCHAR(10),
    address_country VARCHAR(2)  DEFAULT 'US',

    -- Affiliation
    organization    TEXT,
    gender          gender,
    birth_date      DATE,

    period_start    DATE,
    period_end      DATE,
    is_active       BOOLEAN     NOT NULL DEFAULT true,
    notes           TEXT,

    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT patient_contacts_priority_positive CHECK (priority > 0)
);

COMMENT ON TABLE patient_contacts IS 'Emergency contacts and related persons for a patient (FHIR Patient.contact / RelatedPerson)';


-- ── 3.9  Patient Languages ──────────────────────────────────

CREATE TABLE patient_languages (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id      UUID        NOT NULL REFERENCES patients(id) ON DELETE CASCADE,

    language_code   VARCHAR(10) NOT NULL,               -- BCP-47 (en, es, zh-CN, etc.)
    language_display TEXT       NOT NULL,
    preferred       BOOLEAN     NOT NULL DEFAULT false,  -- Primary language
    proficiency     language_proficiency,
    interpreter_needed BOOLEAN  NOT NULL DEFAULT false,

    CONSTRAINT patient_languages_unique UNIQUE (patient_id, language_code)
);

COMMENT ON TABLE patient_languages IS 'Spoken/written languages and interpreter needs (FHIR Patient.communication)';


-- ── 3.10  Patient Race / Ethnicity (US Core) ────────────────
-- US Core R4 requires separate multi-valued race and ethnicity

CREATE TABLE patient_race_ethnicities (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id      UUID        NOT NULL REFERENCES patients(id) ON DELETE CASCADE,

    category        TEXT        NOT NULL CHECK (category IN ('race', 'ethnicity')),
    code            VARCHAR(20) NOT NULL,               -- OMB race/ethnicity code
    display         TEXT        NOT NULL,               -- Human-readable label
    code_system     TEXT        NOT NULL DEFAULT 'urn:oid:2.16.840.1.113883.6.238', -- CDC Race & Ethnicity codes
    detailed_code   VARCHAR(20),                        -- Detailed subcategory
    detailed_display TEXT,

    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT patient_race_ethnicities_unique UNIQUE (patient_id, category, code)
);

COMMENT ON TABLE patient_race_ethnicities IS 'OMB race and ethnicity classifications per US Core R4 extension';


-- ── 3.11  Patient Flags / Alerts ────────────────────────────
-- Safety alerts: fall risk, DNR, latex allergy flag, isolation precautions

CREATE TABLE patient_flags (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    fhir_id         UUID        UNIQUE NOT NULL DEFAULT gen_random_uuid(),
    patient_id      UUID        NOT NULL REFERENCES patients(id) ON DELETE CASCADE,

    status          flag_status NOT NULL DEFAULT 'active',
    category_code   TEXT,                               -- safety, drug, lab, admin, behavioral, research
    category_display TEXT,
    code            TEXT        NOT NULL,               -- SNOMED or custom code
    code_system     TEXT        NOT NULL DEFAULT 'SNOMED-CT',
    display         TEXT        NOT NULL,
    description     TEXT,
    severity        TEXT        CHECK (severity IN ('low', 'medium', 'high', 'critical')),

    -- Who set the flag
    author_id       UUID        REFERENCES practitioners(id) ON DELETE SET NULL,
    author_org_id   UUID        REFERENCES organizations(id) ON DELETE SET NULL,

    period_start    TIMESTAMPTZ,
    period_end      TIMESTAMPTZ,

    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE patient_flags IS 'Clinical safety alerts and administrative flags attached to a patient (FHIR Flag)';


-- ── 3.12  Patient Links ─────────────────────────────────────
-- Duplicate patient merges, patient matching across organizations

CREATE TABLE patient_links (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id      UUID        NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    other_patient_id UUID       NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    link_type       link_type NOT NULL,
    reason          TEXT,

    asserted_by     UUID        REFERENCES practitioners(id) ON DELETE SET NULL,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT patient_links_no_self UNIQUE (patient_id, other_patient_id),
    CONSTRAINT patient_links_not_same CHECK (patient_id != other_patient_id)
);

COMMENT ON TABLE patient_links IS 'Links between patient records (duplicates, cross-org references — FHIR Patient.link)';
