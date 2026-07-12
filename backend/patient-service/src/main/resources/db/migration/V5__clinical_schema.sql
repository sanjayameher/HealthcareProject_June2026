-- ============================================================
-- SECTION 5 — CLINICAL SCHEMA
-- FHIR Resources: Encounter, Observation, Condition,
--   MedicationRequest, MedicationDispense, AllergyIntolerance,
--   Immunization, ServiceRequest, DiagnosticReport,
--   CarePlan, CareTeam, DocumentReference, Specimen
-- ============================================================

SET search_path TO dev, public;

-- ── 5.1  Encounters ─────────────────────────────────────────
-- Telehealth video visits, phone consultations, async messaging encounters

CREATE TABLE encounters (
    id                      UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    fhir_id                 UUID        UNIQUE NOT NULL DEFAULT gen_random_uuid(),

    patient_id              UUID        NOT NULL REFERENCES patients(id) ON DELETE RESTRICT,
    status                  encounter_status NOT NULL DEFAULT 'planned',
    class                   encounter_class  NOT NULL DEFAULT 'virtual',

    -- Type / service
    type_code               TEXT,                       -- SNOMED encounter type
    type_display            TEXT,
    service_type_code       TEXT,                       -- SNOMED service type
    service_type_display    TEXT,
    priority_code           TEXT    DEFAULT 'routine',  -- routine, urgent, asap, stat

    -- Primary clinician
    primary_practitioner_id UUID    REFERENCES practitioners(id) ON DELETE SET NULL,
    organization_id         UUID    REFERENCES organizations(id) ON DELETE SET NULL,

    -- Timing
    period_start            TIMESTAMPTZ,
    period_end              TIMESTAMPTZ,
    length_minutes          INTEGER GENERATED ALWAYS AS (
                                CASE WHEN period_end IS NOT NULL AND period_start IS NOT NULL
                                     THEN EXTRACT(EPOCH FROM (period_end - period_start))::INTEGER / 60
                                     ELSE NULL
                                END
                            ) STORED,

    -- Appointment link
    appointment_id          UUID,                       -- FK added after appointments created

    -- Reason
    reason_codes            TEXT[]  NOT NULL DEFAULT '{}',
    reason_displays         TEXT[]  NOT NULL DEFAULT '{}',

    -- Telehealth-specific
    telehealth_platform     TEXT,                       -- 'zoom', 'doxy.me', 'native', etc.
    telehealth_session_id   TEXT,
    telehealth_session_url  TEXT,
    telehealth_recording_url TEXT,                      -- [PHI] stored encrypted in object storage
    connection_quality      TEXT,                       -- 'good', 'fair', 'poor'

    -- Hospitalization (for non-virtual encounters)
    hospitalization_admit_source TEXT,
    hospitalization_discharge_disposition TEXT,
    hospitalization_location TEXT,

    -- Clinical notes
    chief_complaint         TEXT,
    assessment_plan         TEXT,

    version                 INTEGER     NOT NULL DEFAULT 1,
    fhir_version_id         TEXT        NOT NULL DEFAULT '1',
    fhir_last_updated       TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    created_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at              TIMESTAMPTZ,

    CONSTRAINT encounters_period_check CHECK (
        period_end IS NULL OR period_start IS NULL OR period_end >= period_start
    ),
    CONSTRAINT encounters_telehealth_consistency CHECK (
        class != 'virtual' OR telehealth_platform IS NOT NULL
    )
);

COMMENT ON TABLE  encounters IS 'Clinical visit records — telehealth video, phone, async, in-person (FHIR Encounter)';
COMMENT ON COLUMN encounters.telehealth_recording_url IS '[PHI] Object storage reference — must be access-controlled and encrypted at rest';


CREATE TABLE encounter_participants (
    id                  UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    encounter_id        UUID        NOT NULL REFERENCES encounters(id) ON DELETE CASCADE,
    practitioner_id     UUID        NOT NULL REFERENCES practitioners(id) ON DELETE CASCADE,
    type_code           TEXT        NOT NULL DEFAULT 'PART',   -- HL7 ParticipationType: ATND, CON, REF, PART, SPRF, PPRF
    type_display        TEXT,
    period_start        TIMESTAMPTZ,
    period_end          TIMESTAMPTZ,

    CONSTRAINT encounter_participants_unique UNIQUE (encounter_id, practitioner_id, type_code)
);

COMMENT ON TABLE encounter_participants IS 'Practitioners who participated in an encounter (FHIR Encounter.participant)';


-- ── 5.2  Observations ───────────────────────────────────────
-- Vital signs, lab results, social history, survey responses
-- Partitioned by created_at for performance at scale
-- LOINC codes used for code system

CREATE TABLE observations (
    id                          UUID        NOT NULL DEFAULT gen_random_uuid(),
    fhir_id                     UUID        NOT NULL DEFAULT gen_random_uuid(),

    patient_id                  UUID        NOT NULL REFERENCES patients(id) ON DELETE RESTRICT,
    encounter_id                UUID        REFERENCES encounters(id) ON DELETE SET NULL,

    status                      observation_status NOT NULL DEFAULT 'final',

    -- Category (FHIR Observation category value set)
    category_code               TEXT        NOT NULL,   -- vital-signs, laboratory, social-history, survey, imaging, procedure, activity
    category_display            TEXT        NOT NULL,

    -- What was observed (LOINC primary)
    code_system                 TEXT        NOT NULL DEFAULT 'http://loinc.org',
    code                        TEXT        NOT NULL,   -- LOINC code e.g., '8480-6' (systolic BP)
    code_display                TEXT        NOT NULL,

    -- Timing
    effective_date_time         TIMESTAMPTZ,
    effective_period_start      TIMESTAMPTZ,
    effective_period_end        TIMESTAMPTZ,
    issued                      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Who performed
    performer_id                UUID        REFERENCES practitioners(id) ON DELETE SET NULL,
    performer_org_id            UUID        REFERENCES organizations(id) ON DELETE SET NULL,

    -- Value — exactly one value field should be non-null
    value_quantity              NUMERIC(15, 4),
    value_quantity_unit         TEXT,
    value_quantity_code         TEXT,                   -- UCUM unit code e.g., 'mm[Hg]'
    value_string                TEXT,
    value_boolean               BOOLEAN,
    value_integer               INTEGER,
    value_codeable_concept_code TEXT,
    value_codeable_concept_system TEXT,
    value_codeable_concept_display TEXT,
    value_range_low             NUMERIC(15, 4),
    value_range_high            NUMERIC(15, 4),
    value_ratio_numerator       NUMERIC(15, 4),
    value_ratio_denominator     NUMERIC(15, 4),
    value_time                  TIME,
    value_date_time             TIMESTAMPTZ,

    -- Absent data
    data_absent_reason_code     TEXT,
    data_absent_reason_display  TEXT,

    -- Interpretation flag (HL7 ObservationInterpretation)
    interpretation_code         TEXT,                   -- H, HH, L, LL, N, A, AA, U, IE, R, S, VS, I
    interpretation_display      TEXT,

    -- Reference range
    reference_range_low         NUMERIC(15, 4),
    reference_range_high        NUMERIC(15, 4),
    reference_range_text        TEXT,
    reference_range_applies_to  TEXT,                   -- who this range applies to

    -- Component observations (e.g., Blood Pressure has systolic + diastolic)
    -- Each element: {code, code_display, code_system, value_quantity, value_unit, value_code}
    components                  JSONB       NOT NULL DEFAULT '[]',

    -- Note / comment
    note                        TEXT,

    -- Derivation chain
    derived_from_ids            UUID[]      NOT NULL DEFAULT '{}',

    -- Specimen
    specimen_id                 UUID,                   -- FK set after specimens table

    fhir_version_id             TEXT        NOT NULL DEFAULT '1',
    fhir_last_updated           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at                  TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Partition key
    PRIMARY KEY (id, created_at),

    CONSTRAINT observations_fhir_unique UNIQUE (fhir_id, created_at),
    CONSTRAINT observations_effective_check CHECK (
        effective_date_time IS NOT NULL OR effective_period_start IS NOT NULL
    ),
    CONSTRAINT observations_single_value CHECK (
        (
            (value_quantity         IS NOT NULL)::INT +
            (value_string           IS NOT NULL)::INT +
            (value_boolean          IS NOT NULL)::INT +
            (value_integer          IS NOT NULL)::INT +
            (value_codeable_concept_code IS NOT NULL)::INT +
            (value_range_low        IS NOT NULL OR value_range_high IS NOT NULL)::INT +
            (value_ratio_numerator  IS NOT NULL)::INT +
            (value_time             IS NOT NULL)::INT +
            (value_date_time        IS NOT NULL)::INT
        ) <= 1
    )
) PARTITION BY RANGE (created_at);

COMMENT ON TABLE observations IS 'Clinical observations: vitals, lab results, social history, surveys (FHIR Observation) — range-partitioned by created_at';
COMMENT ON COLUMN observations.components IS 'JSONB array for compound observations (e.g., BP = [{systolic}, {diastolic}])';

-- Partitions — create quarterly going forward; automate via pg_partman
CREATE TABLE observations_2024_q1 PARTITION OF observations
    FOR VALUES FROM ('2024-01-01') TO ('2024-04-01');
CREATE TABLE observations_2024_q2 PARTITION OF observations
    FOR VALUES FROM ('2024-04-01') TO ('2024-07-01');
CREATE TABLE observations_2024_q3 PARTITION OF observations
    FOR VALUES FROM ('2024-07-01') TO ('2024-10-01');
CREATE TABLE observations_2024_q4 PARTITION OF observations
    FOR VALUES FROM ('2024-10-01') TO ('2025-01-01');
CREATE TABLE observations_2025_q1 PARTITION OF observations
    FOR VALUES FROM ('2025-01-01') TO ('2025-04-01');
CREATE TABLE observations_2025_q2 PARTITION OF observations
    FOR VALUES FROM ('2025-04-01') TO ('2025-07-01');
CREATE TABLE observations_2025_q3 PARTITION OF observations
    FOR VALUES FROM ('2025-07-01') TO ('2025-10-01');
CREATE TABLE observations_2025_q4 PARTITION OF observations
    FOR VALUES FROM ('2025-10-01') TO ('2026-01-01');
CREATE TABLE observations_2026_q1 PARTITION OF observations
    FOR VALUES FROM ('2026-01-01') TO ('2026-04-01');
CREATE TABLE observations_2026_q2 PARTITION OF observations
    FOR VALUES FROM ('2026-04-01') TO ('2026-07-01');
CREATE TABLE observations_2026_q3 PARTITION OF observations
    FOR VALUES FROM ('2026-07-01') TO ('2026-10-01');
CREATE TABLE observations_2026_q4 PARTITION OF observations
    FOR VALUES FROM ('2026-10-01') TO ('2027-01-01');
CREATE TABLE observations_future   PARTITION OF observations
    FOR VALUES FROM ('2027-01-01') TO (MAXVALUE);


-- ── 5.3  Conditions (Diagnoses) ─────────────────────────────
-- ICD-10-CM primary; SNOMED CT supported via code_system

CREATE TABLE conditions (
    id                          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    fhir_id                     UUID        UNIQUE NOT NULL DEFAULT gen_random_uuid(),

    patient_id                  UUID        NOT NULL REFERENCES patients(id) ON DELETE RESTRICT,
    encounter_id                UUID        REFERENCES encounters(id) ON DELETE SET NULL,

    clinical_status             condition_clinical_status     NOT NULL DEFAULT 'active',
    verification_status         condition_verification_status NOT NULL DEFAULT 'unconfirmed',

    -- Category
    category_code               TEXT        NOT NULL DEFAULT 'problem-list-item',
    -- 'problem-list-item', 'encounter-diagnosis', 'health-concern', 'wellness'

    -- Severity (SNOMED)
    severity_code               TEXT,                   -- 255604002=Mild, 6736007=Moderate, 24484000=Severe
    severity_display            TEXT,

    -- Diagnosis code
    code_system                 TEXT        NOT NULL DEFAULT 'ICD-10-CM',
    code                        TEXT        NOT NULL,
    code_display                TEXT        NOT NULL,

    -- Additional coding (SNOMED equivalents)
    secondary_code_system       TEXT,
    secondary_code              TEXT,
    secondary_code_display      TEXT,

    -- Body site
    body_site_code              TEXT,                   -- SNOMED body structure
    body_site_display           TEXT,
    laterality                  TEXT,                   -- left, right, bilateral

    -- Onset
    onset_date_time             TIMESTAMPTZ,
    onset_age_value             NUMERIC(5, 1),
    onset_age_unit              TEXT        DEFAULT 'a', -- UCUM: 'a'=years, 'mo'=months
    onset_string                TEXT,                   -- Free-text if date unknown

    -- Abatement (resolution)
    abatement_date_time         TIMESTAMPTZ,
    abatement_age_value         NUMERIC(5, 1),
    abatement_age_unit          TEXT,
    abatement_string            TEXT,

    -- Recording
    recorded_date               DATE,
    recorder_id                 UUID        REFERENCES practitioners(id) ON DELETE SET NULL,
    asserter_id                 UUID        REFERENCES practitioners(id) ON DELETE SET NULL,

    -- Billing relevance
    is_principal_diagnosis      BOOLEAN     NOT NULL DEFAULT false,
    is_chronic                  BOOLEAN     NOT NULL DEFAULT false,

    -- Stage (for oncology, etc.)
    stage_summary_code          TEXT,
    stage_summary_display       TEXT,
    stage_type_code             TEXT,

    note                        TEXT,

    version                     INTEGER     NOT NULL DEFAULT 1,
    fhir_version_id             TEXT        NOT NULL DEFAULT '1',
    fhir_last_updated           TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    created_at                  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at                  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at                  TIMESTAMPTZ,

    CONSTRAINT conditions_abatement_after_onset CHECK (
        abatement_date_time IS NULL OR onset_date_time IS NULL OR
        abatement_date_time >= onset_date_time
    ),
    CONSTRAINT conditions_inactive_needs_abatement CHECK (
        clinical_status NOT IN ('inactive', 'remission', 'resolved') OR
        abatement_date_time IS NOT NULL OR abatement_string IS NOT NULL OR
        abatement_age_value IS NOT NULL
    )
);

COMMENT ON TABLE conditions IS 'Patient diagnoses and problems — problem list and encounter diagnoses (FHIR Condition)';


-- ── 5.4  Allergy / Intolerances ─────────────────────────────

CREATE TABLE allergy_intolerances (
    id                      UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    fhir_id                 UUID        UNIQUE NOT NULL DEFAULT gen_random_uuid(),

    patient_id              UUID        NOT NULL REFERENCES patients(id) ON DELETE RESTRICT,

    clinical_status         allergy_clinical_status     NOT NULL DEFAULT 'active',
    verification_status     allergy_verification_status NOT NULL DEFAULT 'confirmed',
    allergy_type            allergy_type,
    categories              allergy_category[] NOT NULL DEFAULT '{}',
    criticality             allergy_criticality,

    -- Substance
    code_system             TEXT        NOT NULL DEFAULT 'RxNorm',
    code                    TEXT,
    code_display            TEXT        NOT NULL,

    -- Recording
    recorder_id             UUID        REFERENCES practitioners(id) ON DELETE SET NULL,
    asserter_id             UUID        REFERENCES practitioners(id) ON DELETE SET NULL,
    onset_date_time         TIMESTAMPTZ,
    recorded_date           DATE        NOT NULL DEFAULT CURRENT_DATE,
    last_occurrence         TIMESTAMPTZ,

    note                    TEXT,

    fhir_version_id         TEXT        NOT NULL DEFAULT '1',
    fhir_last_updated       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at              TIMESTAMPTZ
);

COMMENT ON TABLE allergy_intolerances IS 'Patient allergy and intolerance records (FHIR AllergyIntolerance)';


CREATE TABLE allergy_reactions (
    id                      UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    allergy_intolerance_id  UUID        NOT NULL REFERENCES allergy_intolerances(id) ON DELETE CASCADE,

    substance_code          TEXT,
    substance_system        TEXT,
    substance_display       TEXT,

    -- Manifestation (SNOMED finding)
    manifestation_code      TEXT        NOT NULL,
    manifestation_system    TEXT        NOT NULL DEFAULT 'SNOMED-CT',
    manifestation_display   TEXT        NOT NULL,

    description             TEXT,
    onset                   TIMESTAMPTZ,
    severity                reaction_severity,
    exposure_route_code     TEXT,
    exposure_route_display  TEXT,
    note                    TEXT,

    created_at              TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE allergy_reactions IS 'Specific reactions observed per allergy/intolerance event (FHIR AllergyIntolerance.reaction)';


-- ── 5.5  Immunizations ──────────────────────────────────────

CREATE TABLE immunizations (
    id                          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    fhir_id                     UUID        UNIQUE NOT NULL DEFAULT gen_random_uuid(),

    patient_id                  UUID        NOT NULL REFERENCES patients(id) ON DELETE RESTRICT,
    encounter_id                UUID        REFERENCES encounters(id) ON DELETE SET NULL,

    status                      immunization_status NOT NULL DEFAULT 'completed',
    status_reason_code          TEXT,
    status_reason_display       TEXT,

    -- Vaccine
    vaccine_code_system         TEXT        NOT NULL DEFAULT 'CVX',
    vaccine_code                TEXT        NOT NULL,
    vaccine_display             TEXT        NOT NULL,
    brand_name                  TEXT,

    -- Administration
    occurrence_date_time        TIMESTAMPTZ NOT NULL,
    recorded                    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    lot_number                  TEXT,
    expiration_date             DATE,
    site_code                   TEXT,                   -- SNOMED: injection site
    site_display                TEXT,
    route_code                  TEXT,                   -- SNOMED: intramuscular, subcutaneous, etc.
    route_display               TEXT,
    dose_quantity               NUMERIC(10, 4),
    dose_unit                   TEXT,

    -- Subpotency
    is_subpotent                BOOLEAN     NOT NULL DEFAULT false,
    subpotent_reason_code       TEXT,
    subpotent_reason_display    TEXT,

    -- Adverse reaction at time of administration
    reaction_date               TIMESTAMPTZ,
    reaction_detail_code        TEXT,
    reaction_detail_display     TEXT,
    reaction_reported           BOOLEAN     NOT NULL DEFAULT false,

    -- Protocol / series
    series_name                 TEXT,                   -- e.g., 'Hepatitis B 3-dose series'
    dose_number_in_series       SMALLINT,
    series_doses_recommended    SMALLINT,

    -- Performer
    performer_id                UUID        REFERENCES practitioners(id) ON DELETE SET NULL,
    performer_org_id            UUID        REFERENCES organizations(id) ON DELETE SET NULL,

    -- Education
    education_pub_date          DATE,
    education_presented_date    DATE,

    note                        TEXT,
    is_reported_by_patient      BOOLEAN     NOT NULL DEFAULT false,

    fhir_version_id             TEXT        NOT NULL DEFAULT '1',
    fhir_last_updated           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at                  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at                  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE immunizations IS 'Patient immunization records using CVX codes (FHIR Immunization)';


-- ── 5.6  Specimens ──────────────────────────────────────────

CREATE TABLE specimens (
    id                  UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    fhir_id             UUID        UNIQUE NOT NULL DEFAULT gen_random_uuid(),
    patient_id          UUID        NOT NULL REFERENCES patients(id) ON DELETE RESTRICT,

    type_code           TEXT        NOT NULL,           -- SNOMED specimen type
    type_display        TEXT        NOT NULL,

    -- Collection
    collected_date_time TIMESTAMPTZ,
    collection_method_code TEXT,
    collection_method_display TEXT,
    collection_body_site_code TEXT,
    collection_body_site_display TEXT,
    collection_duration_value NUMERIC,
    collection_duration_unit TEXT,
    collection_quantity_value NUMERIC,
    collection_quantity_unit TEXT,
    collector_id        UUID        REFERENCES practitioners(id) ON DELETE SET NULL,

    -- Container
    container_type_code TEXT,
    container_type_display TEXT,
    container_capacity  NUMERIC,
    container_additive  TEXT,

    -- Processing
    processing_description TEXT,
    processing_time     TIMESTAMPTZ,
    processing_additive TEXT,

    -- Handling
    condition_codes     TEXT[],
    condition_displays  TEXT[],

    accession_id        TEXT        UNIQUE,             -- Lab accession number
    note                TEXT,

    received_at         TIMESTAMPTZ,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE specimens IS 'Biological specimens collected for laboratory analysis (FHIR Specimen)';

-- Back-fill FK on observations
ALTER TABLE observations ADD CONSTRAINT observations_specimen_fk
    FOREIGN KEY (specimen_id) REFERENCES specimens(id) ON DELETE SET NULL;


-- ── 5.7  Medication Requests (Prescriptions / Orders) ───────

CREATE TABLE medication_requests (
    id                              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    fhir_id                         UUID        UNIQUE NOT NULL DEFAULT gen_random_uuid(),

    patient_id                      UUID        NOT NULL REFERENCES patients(id) ON DELETE RESTRICT,
    encounter_id                    UUID        REFERENCES encounters(id) ON DELETE SET NULL,

    status                          medication_request_status  NOT NULL DEFAULT 'active',
    status_reason_code              TEXT,
    status_reason_display           TEXT,
    status_changed_at               TIMESTAMPTZ,

    intent                          medication_request_intent  NOT NULL DEFAULT 'order',

    -- Medication
    medication_code_system          TEXT        NOT NULL DEFAULT 'http://www.nlm.nih.gov/research/umls/rxnorm',
    medication_code                 TEXT        NOT NULL,   -- RxNorm RxCUI
    medication_display              TEXT        NOT NULL,   -- Generic name
    medication_brand_name           TEXT,
    medication_form                 TEXT,                   -- tablet, capsule, liquid, patch, etc.
    medication_strength             TEXT,                   -- e.g., '500 mg'

    -- Controlled substance
    is_controlled_substance         BOOLEAN     NOT NULL DEFAULT false,
    dea_schedule                    TEXT CHECK (dea_schedule IN ('II', 'III', 'IV', 'V')),
    requires_dea_authorization      BOOLEAN     NOT NULL DEFAULT false,

    -- Prescriber
    requester_id                    UUID        NOT NULL REFERENCES practitioners(id) ON DELETE RESTRICT,
    requester_org_id                UUID        REFERENCES organizations(id) ON DELETE SET NULL,
    recorded_date                   TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Dosage instruction
    dosage_text                     TEXT,                   -- Human-readable instruction
    dosage_patient_instruction      TEXT,                   -- Simplified for patient
    dosage_sequence                 SMALLINT    DEFAULT 1,
    dosage_as_needed                BOOLEAN     NOT NULL DEFAULT false,   -- PRN
    dosage_as_needed_reason         TEXT,
    dosage_timing_code              TEXT,                   -- HL7 GTSAbbreviation: QD, BID, TID, QID, Q8H, etc.
    dosage_timing_frequency         SMALLINT,               -- e.g., 2 (twice)
    dosage_timing_period            NUMERIC(10, 2),         -- e.g., 1
    dosage_timing_period_unit       TEXT        DEFAULT 'd', -- UCUM: s, min, h, d, wk, mo, a
    dosage_route_code               TEXT,                   -- SNOMED route
    dosage_route_display            TEXT,
    dosage_method_code              TEXT,                   -- SNOMED method
    dosage_method_display           TEXT,
    dosage_dose_value               NUMERIC(10, 4),
    dosage_dose_unit                TEXT,
    dosage_dose_unit_code           TEXT,                   -- UCUM
    dosage_max_dose_per_period_value NUMERIC(10, 4),
    dosage_max_dose_per_period_unit TEXT,

    -- Dispense request
    dispense_initial_fill_quantity  NUMERIC(10, 2),
    dispense_quantity_value         NUMERIC(10, 2),
    dispense_quantity_unit          TEXT,
    dispense_refills_allowed        SMALLINT    NOT NULL DEFAULT 0,
    dispense_days_supply            SMALLINT,
    dispense_validity_start         DATE,
    dispense_validity_end           DATE,
    expected_supply_duration_value  NUMERIC(10, 2),
    expected_supply_duration_unit   TEXT,
    dispense_performer_org_id       UUID        REFERENCES organizations(id) ON DELETE SET NULL,

    -- Substitution
    substitution_allowed_boolean    BOOLEAN     NOT NULL DEFAULT true,
    substitution_allowed_code       TEXT,
    substitution_reason_code        TEXT,
    substitution_reason_display     TEXT,

    -- Chain
    prior_prescription_id           UUID        REFERENCES medication_requests(id) ON DELETE SET NULL,
    based_on_id                     UUID        REFERENCES medication_requests(id) ON DELETE SET NULL,

    -- Reason
    reason_codes                    TEXT[]      NOT NULL DEFAULT '{}',
    reason_displays                 TEXT[]      NOT NULL DEFAULT '{}',
    reason_condition_ids            UUID[]      NOT NULL DEFAULT '{}',

    note                            TEXT,

    version                         INTEGER     NOT NULL DEFAULT 1,
    fhir_version_id                 TEXT        NOT NULL DEFAULT '1',
    fhir_last_updated               TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    created_at                      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at                      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at                      TIMESTAMPTZ,

    CONSTRAINT med_req_dispense_validity CHECK (
        dispense_validity_end IS NULL OR dispense_validity_start IS NULL OR
        dispense_validity_end >= dispense_validity_start
    ),
    CONSTRAINT med_req_refills_non_negative CHECK (dispense_refills_allowed >= 0),
    CONSTRAINT med_req_dea_schedule_requires_flag CHECK (
        dea_schedule IS NULL OR is_controlled_substance = true
    )
);

COMMENT ON TABLE  medication_requests IS 'Prescription and medication orders (FHIR MedicationRequest) — RxNorm coded';
COMMENT ON COLUMN medication_requests.dea_schedule IS 'DEA schedule (II-V) for controlled substances — requires practitioner DEA authorization';


-- ── 5.8  Medication Dispenses ───────────────────────────────

CREATE TABLE medication_dispenses (
    id                      UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    fhir_id                 UUID        UNIQUE NOT NULL DEFAULT gen_random_uuid(),

    medication_request_id   UUID        NOT NULL REFERENCES medication_requests(id) ON DELETE RESTRICT,
    patient_id              UUID        NOT NULL REFERENCES patients(id) ON DELETE RESTRICT,

    status                  dispense_status NOT NULL DEFAULT 'completed',
    status_reason_code      TEXT,
    status_reason_display   TEXT,

    -- Medication (denormalized from request for immutability)
    medication_code         TEXT        NOT NULL,
    medication_display      TEXT        NOT NULL,
    medication_lot_number   TEXT,

    fill_number             SMALLINT    NOT NULL DEFAULT 1,

    quantity_value          NUMERIC(10, 2) NOT NULL,
    quantity_unit           TEXT        NOT NULL,
    days_supply             SMALLINT,
    when_prepared           TIMESTAMPTZ,
    when_handed_over        TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Pharmacy
    pharmacy_name           TEXT,
    pharmacy_npi            VARCHAR(10),
    pharmacy_ncpdp          TEXT,                       -- NCPDP Provider ID

    -- Dispenser
    dispenser_id            UUID        REFERENCES practitioners(id) ON DELETE SET NULL,

    -- Destination / pickup
    destination             TEXT,                       -- 'counter', 'mail', 'delivery'
    receiver_name           TEXT,

    substitution_performed  BOOLEAN     NOT NULL DEFAULT false,
    substitution_reason     TEXT,

    dosage_instruction      TEXT,
    note                    TEXT,

    created_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at              TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE medication_dispenses IS 'Pharmacy dispense records for prescribed medications (FHIR MedicationDispense)';


-- ── 5.9  Service Requests (Lab / Imaging Orders) ────────────

CREATE TABLE service_requests (
    id                      UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    fhir_id                 UUID        UNIQUE NOT NULL DEFAULT gen_random_uuid(),

    patient_id              UUID        NOT NULL REFERENCES patients(id) ON DELETE RESTRICT,
    encounter_id            UUID        REFERENCES encounters(id) ON DELETE SET NULL,
    based_on_id             UUID        REFERENCES service_requests(id) ON DELETE SET NULL,

    status                  service_request_status NOT NULL DEFAULT 'active',
    intent                  service_request_intent NOT NULL DEFAULT 'order',

    -- Category
    category_code           TEXT        NOT NULL,       -- laboratory, imaging, counseling, education, surgical-procedure
    category_display        TEXT        NOT NULL,

    priority                TEXT        NOT NULL DEFAULT 'routine',  -- routine, urgent, asap, stat

    do_not_perform          BOOLEAN     NOT NULL DEFAULT false,

    -- Order code (LOINC for labs; CPT/SNOMED for procedures)
    code_system             TEXT        NOT NULL DEFAULT 'http://loinc.org',
    code                    TEXT        NOT NULL,
    code_display            TEXT        NOT NULL,

    -- Ordering details
    order_details           TEXT,                       -- Additional specifics
    reason_codes            TEXT[]      NOT NULL DEFAULT '{}',
    reason_displays         TEXT[]      NOT NULL DEFAULT '{}',

    -- Requester / performer
    requester_id            UUID        NOT NULL REFERENCES practitioners(id) ON DELETE RESTRICT,
    requester_org_id        UUID        REFERENCES organizations(id) ON DELETE SET NULL,
    performer_id            UUID        REFERENCES practitioners(id) ON DELETE SET NULL,
    performer_org_id        UUID        REFERENCES organizations(id) ON DELETE SET NULL,
    performer_type_code     TEXT,

    -- Specimen
    specimen_id             UUID        REFERENCES specimens(id) ON DELETE SET NULL,

    -- Timing
    authored_on             TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    occurrence_date_time    TIMESTAMPTZ,
    occurrence_period_start TIMESTAMPTZ,
    occurrence_period_end   TIMESTAMPTZ,

    -- Patient instruction
    patient_instruction     TEXT,
    note                    TEXT,

    -- Result tracking
    result_available        BOOLEAN     NOT NULL DEFAULT false,
    result_available_at     TIMESTAMPTZ,

    version                 INTEGER     NOT NULL DEFAULT 1,
    fhir_version_id         TEXT        NOT NULL DEFAULT '1',
    fhir_last_updated       TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    created_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at              TIMESTAMPTZ
);

COMMENT ON TABLE service_requests IS 'Lab orders, imaging orders, and referrals (FHIR ServiceRequest) — LOINC and CPT coded';


-- ── 5.10  Diagnostic Reports ────────────────────────────────

CREATE TABLE diagnostic_reports (
    id                      UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    fhir_id                 UUID        UNIQUE NOT NULL DEFAULT gen_random_uuid(),

    patient_id              UUID        NOT NULL REFERENCES patients(id) ON DELETE RESTRICT,
    encounter_id            UUID        REFERENCES encounters(id) ON DELETE SET NULL,
    service_request_id      UUID        REFERENCES service_requests(id) ON DELETE SET NULL,

    status                  diagnostic_report_status NOT NULL DEFAULT 'final',

    -- Category
    category_code           TEXT        NOT NULL,
    category_display        TEXT        NOT NULL,

    -- Report type (LOINC panel code)
    code_system             TEXT        NOT NULL DEFAULT 'http://loinc.org',
    code                    TEXT        NOT NULL,
    code_display            TEXT        NOT NULL,

    -- Timing
    effective_date_time     TIMESTAMPTZ,
    issued                  TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Performer
    performer_id            UUID        REFERENCES practitioners(id) ON DELETE SET NULL,
    performer_org_id        UUID        REFERENCES organizations(id) ON DELETE SET NULL,

    -- Results — array of observation IDs
    result_observation_ids  UUID[]      NOT NULL DEFAULT '{}',

    -- Specimens
    specimen_ids            UUID[]      NOT NULL DEFAULT '{}',

    -- Conclusion
    conclusion              TEXT,
    conclusion_code         TEXT,
    conclusion_code_system  TEXT        DEFAULT 'SNOMED-CT',
    conclusion_code_display TEXT,

    -- Attached media (links to document_references)
    media_ids               UUID[]      NOT NULL DEFAULT '{}',

    note                    TEXT,

    fhir_version_id         TEXT        NOT NULL DEFAULT '1',
    fhir_last_updated       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at              TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE diagnostic_reports IS 'Lab panel results, imaging reports, pathology findings (FHIR DiagnosticReport)';


-- ── 5.11  Care Plans ─────────────────────────────────────────

CREATE TABLE care_plans (
    id                      UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    fhir_id                 UUID        UNIQUE NOT NULL DEFAULT gen_random_uuid(),

    patient_id              UUID        NOT NULL REFERENCES patients(id) ON DELETE RESTRICT,
    encounter_id            UUID        REFERENCES encounters(id) ON DELETE SET NULL,

    status                  care_plan_status NOT NULL DEFAULT 'active',
    intent                  TEXT        NOT NULL DEFAULT 'plan',  -- proposal, plan, order, option, directive

    title                   TEXT        NOT NULL,
    description             TEXT,

    -- Categories
    category_codes          TEXT[]      NOT NULL DEFAULT '{}',    -- SNOMED / LOINC plan categories
    category_displays       TEXT[]      NOT NULL DEFAULT '{}',

    -- Period
    period_start            DATE,
    period_end              DATE,

    -- Author / contributor
    created_by_id           UUID        REFERENCES practitioners(id) ON DELETE SET NULL,
    contributor_ids         UUID[]      NOT NULL DEFAULT '{}',

    -- Addresses (linked conditions / problems)
    addresses_condition_ids UUID[]      NOT NULL DEFAULT '{}',

    -- Goals (free text for MVP; link to Goal resource for full FHIR compliance)
    goals                   TEXT[]      NOT NULL DEFAULT '{}',

    -- Activities stored as JSONB array for flexibility
    -- [{category, status, code, scheduled_date, description, note}]
    activities              JSONB       NOT NULL DEFAULT '[]',

    note                    TEXT,

    fhir_version_id         TEXT        NOT NULL DEFAULT '1',
    fhir_last_updated       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at              TIMESTAMPTZ,

    CONSTRAINT care_plans_period_check CHECK (
        period_end IS NULL OR period_start IS NULL OR period_end >= period_start
    )
);

COMMENT ON TABLE care_plans IS 'Longitudinal care plans addressing chronic conditions (FHIR CarePlan)';


-- ── 5.12  Care Teams ─────────────────────────────────────────

CREATE TABLE care_teams (
    id                      UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    fhir_id                 UUID        UNIQUE NOT NULL DEFAULT gen_random_uuid(),

    patient_id              UUID        NOT NULL REFERENCES patients(id) ON DELETE RESTRICT,

    status                  TEXT        NOT NULL DEFAULT 'active',
    -- proposed, active, suspended, inactive, entered-in-error

    name                    TEXT        NOT NULL,
    category_code           TEXT,
    category_display        TEXT,

    period_start            DATE,
    period_end              DATE,

    managing_org_id         UUID        REFERENCES organizations(id) ON DELETE SET NULL,
    reason_codes            TEXT[]      NOT NULL DEFAULT '{}',
    reason_displays         TEXT[]      NOT NULL DEFAULT '{}',

    note                    TEXT,
    fhir_version_id         TEXT        NOT NULL DEFAULT '1',
    fhir_last_updated       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at              TIMESTAMPTZ NOT NULL DEFAULT NOW()
);


CREATE TABLE care_team_participants (
    id                  UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    care_team_id        UUID        NOT NULL REFERENCES care_teams(id) ON DELETE CASCADE,

    role_code           TEXT        NOT NULL,           -- SNOMED care team role
    role_display        TEXT        NOT NULL,

    practitioner_id     UUID        REFERENCES practitioners(id) ON DELETE SET NULL,
    practitioner_org_id UUID        REFERENCES organizations(id) ON DELETE SET NULL,

    period_start        DATE,
    period_end          DATE,
    is_active           BOOLEAN     NOT NULL DEFAULT true,

    on_behalf_of_org_id UUID        REFERENCES organizations(id) ON DELETE SET NULL,

    CONSTRAINT care_team_participants_period_check CHECK (
        period_end IS NULL OR period_start IS NULL OR period_end >= period_start
    )
);

COMMENT ON TABLE care_teams IS 'Multidisciplinary care team for a patient (FHIR CareTeam)';
COMMENT ON TABLE care_team_participants IS 'Individual practitioner role within a care team (FHIR CareTeam.participant)';


-- ── 5.13  Document References ────────────────────────────────
-- Clinical notes, consent forms, lab PDFs, images, CCDA documents

CREATE TABLE documents (
    id                      UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    fhir_id                 UUID        UNIQUE NOT NULL DEFAULT gen_random_uuid(),

    patient_id              UUID        NOT NULL REFERENCES patients(id) ON DELETE RESTRICT,
    encounter_id            UUID        REFERENCES encounters(id) ON DELETE SET NULL,

    status                  document_status NOT NULL DEFAULT 'current',

    -- Type (LOINC document ontology)
    type_code               TEXT        NOT NULL,
    type_display            TEXT        NOT NULL,
    type_code_system        TEXT        NOT NULL DEFAULT 'http://loinc.org',

    -- Category
    category_code           TEXT,
    category_display        TEXT,

    -- Date the document was authored
    authored_at             TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- People
    author_id               UUID        REFERENCES practitioners(id) ON DELETE SET NULL,
    author_org_id           UUID        REFERENCES organizations(id) ON DELETE SET NULL,
    authenticator_id        UUID        REFERENCES practitioners(id) ON DELETE SET NULL,
    custodian_org_id        UUID        REFERENCES organizations(id) ON DELETE SET NULL,

    description             TEXT,

    -- Content — stored in object storage, reference held here
    content_type            TEXT        NOT NULL,       -- MIME type: application/pdf, text/plain, etc.
    content_language        VARCHAR(10) DEFAULT 'en',
    content_url             TEXT        NOT NULL,       -- [PHI] Object storage path (S3/GCS/Azure Blob)
    content_size_bytes      BIGINT,
    content_sha256          TEXT        NOT NULL,       -- SHA-256 integrity hash
    content_title           TEXT,
    content_creation_time   TIMESTAMPTZ,
    is_content_encrypted    BOOLEAN     NOT NULL DEFAULT true,  -- Must be true for PHI documents

    -- Relationships to other documents
    relates_to_id           UUID        REFERENCES documents(id) ON DELETE SET NULL,
    relates_to_code         TEXT,                       -- replaces, transforms, signs, appends

    -- Context
    context_period_start    TIMESTAMPTZ,
    context_period_end      TIMESTAMPTZ,
    context_event_codes     TEXT[]      NOT NULL DEFAULT '{}',
    context_facility_type   TEXT,
    context_practice_setting TEXT,

    -- Confidentiality
    confidentiality_code    TEXT        NOT NULL DEFAULT 'N',   -- N=Normal, R=Restricted, V=Very Restricted
    security_labels         TEXT[]      NOT NULL DEFAULT '{}',

    fhir_version_id         TEXT        NOT NULL DEFAULT '1',
    fhir_last_updated       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at              TIMESTAMPTZ,

    CONSTRAINT documents_content_url_nonempty CHECK (content_url != ''),
    CONSTRAINT documents_sha256_format CHECK (content_sha256 ~ '^[a-f0-9]{64}$')
);

COMMENT ON TABLE  documents IS 'Clinical document references: notes, PDFs, CCDA, forms (FHIR DocumentReference)';
COMMENT ON COLUMN documents.content_url IS '[PHI] Object storage reference — must be pre-signed URL or private bucket path, never publicly accessible';
COMMENT ON COLUMN documents.is_content_encrypted IS 'Documents containing PHI must be encrypted at rest (AES-256)';
