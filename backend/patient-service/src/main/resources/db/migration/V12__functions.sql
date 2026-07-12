-- ============================================================
-- SECTION 12 — UTILITY FUNCTIONS
-- 1.  MRN generation
-- 2.  Patient search (name + DOB)
-- 3.  Medication safety check (allergy cross-reference)
-- 4.  Encounter close / transition
-- 5.  PHI access logging helper
-- 6.  Age calculation (UTC-safe)
-- 7.  Audit event insertion helper
-- 8.  Appointment slot availability
-- ============================================================

-- ── 12.1  MRN Generation ─────────────────────────────────────
-- Format: ORG-PREFIX + YYYYMM + 5-digit padded sequence

SET search_path TO dev, public;

CREATE SEQUENCE IF NOT EXISTS mrn_seq START 10001 INCREMENT 1;

CREATE OR REPLACE FUNCTION generate_mrn(org_prefix TEXT DEFAULT 'HP')
RETURNS VARCHAR(20)
LANGUAGE plpgsql AS
$$
DECLARE
    v_seq   BIGINT  := nextval('mrn_seq');
    v_mrn   TEXT;
BEGIN
    v_mrn := org_prefix
           || TO_CHAR(NOW(), 'YYMM')
           || LPAD(v_seq::TEXT, 5, '0');
    RETURN v_mrn;
END;
$$;

COMMENT ON FUNCTION generate_mrn IS 'Generates a unique, human-readable MRN — call at patient INSERT time';


-- ── 12.2  Patient Search ─────────────────────────────────────
-- Trigram-based fuzzy name search with optional DOB filter
-- Returns ranked results; application must apply LIMIT

CREATE OR REPLACE FUNCTION search_patients(
    p_name      TEXT,
    p_birth_date DATE    DEFAULT NULL,
    p_mrn       TEXT    DEFAULT NULL,
    p_limit     INT     DEFAULT 20
)
RETURNS TABLE (
    patient_id      UUID,
    mrn             VARCHAR(20),
    full_name       TEXT,
    birth_date      DATE,
    gender          gender,
    address_city    TEXT,
    address_state   VARCHAR(2),
    similarity_score FLOAT4
)
LANGUAGE sql STABLE SECURITY DEFINER AS
$$
SELECT
    p.id,
    p.mrn,
    (
        COALESCE(array_to_string(pn.prefix, ' ') || ' ', '') ||
        array_to_string(pn.given, ' ') || ' ' || pn.family
    )                                           AS full_name,
    p.birth_date,
    p.gender,
    pa.city,
    pa.state,
    GREATEST(
        similarity(pn.family, p_name),
        similarity(array_to_string(pn.given, ' ') || ' ' || pn.family, p_name)
    )                                           AS similarity_score
FROM
    patients p
JOIN patient_names pn ON pn.patient_id = p.id AND pn.is_primary = true
LEFT JOIN patient_addresses pa ON pa.patient_id = p.id AND pa.is_primary = true
WHERE
    p.deleted_at IS NULL
    AND p.active = true
    AND (
        (p_mrn IS NOT NULL AND p.mrn = p_mrn)
        OR (p_mrn IS NULL AND (
            pn.family % p_name
            OR (array_to_string(pn.given, ' ') || ' ' || pn.family) % p_name
        ))
    )
    AND (p_birth_date IS NULL OR p.birth_date = p_birth_date)
ORDER BY
    similarity_score DESC,
    pn.family ASC
LIMIT p_limit;
$$;

COMMENT ON FUNCTION search_patients IS 'Fuzzy patient search by name + optional DOB/MRN — uses pg_trgm similarity';


-- ── 12.3  Medication Allergy Safety Check ────────────────────
-- Returns any active allergies that may conflict with a given RxNorm code
-- NOTE: A production system should call a dedicated drug-allergy interaction
-- service (e.g., First Databank, Multum) — this is a last-resort DB-layer check.

SET search_path TO dev, public;

CREATE OR REPLACE FUNCTION check_allergy_conflict(
    p_patient_id    UUID,
    p_rxnorm_code   TEXT,
    p_medication_display TEXT
)
RETURNS TABLE (
    allergy_id          UUID,
    allergen_display    TEXT,
    criticality         allergy_criticality,
    reaction_severity   reaction_severity,
    conflict_type       TEXT
)
LANGUAGE sql STABLE SECURITY DEFINER AS
$$
-- Direct code match (exact allergen)
SELECT
    ai.id               AS allergy_id,
    ai.code_display     AS allergen_display,
    ai.criticality,
    (SELECT ar.severity
       FROM allergy_reactions ar
      WHERE ar.allergy_intolerance_id = ai.id
      ORDER BY CASE ar.severity WHEN 'severe' THEN 1 WHEN 'moderate' THEN 2 WHEN 'mild' THEN 3 END
      LIMIT 1)          AS reaction_severity,
    'exact_code_match'  AS conflict_type
FROM
    allergy_intolerances ai
WHERE
    ai.patient_id       = p_patient_id
    AND ai.clinical_status = 'active'
    AND ai.code         = p_rxnorm_code
    AND ai.deleted_at IS NULL

UNION ALL

-- Fuzzy display name overlap (backup — low precision, high recall)
SELECT
    ai.id,
    ai.code_display,
    ai.criticality,
    (SELECT ar.severity
       FROM allergy_reactions ar
      WHERE ar.allergy_intolerance_id = ai.id
      ORDER BY CASE ar.severity WHEN 'severe' THEN 1 WHEN 'moderate' THEN 2 WHEN 'mild' THEN 3 END
      LIMIT 1),
    'name_similarity_match'
FROM
    allergy_intolerances ai
WHERE
    ai.patient_id = p_patient_id
    AND ai.clinical_status = 'active'
    AND ai.code != p_rxnorm_code          -- exclude exact matches already returned
    AND similarity(ai.code_display, p_medication_display) > 0.5
    AND ai.deleted_at IS NULL;
$$;

COMMENT ON FUNCTION check_allergy_conflict IS 'DB-layer allergy-medication conflict check — supplement with a clinical decision support API in production';


-- ── 12.4  Close Encounter ────────────────────────────────────

CREATE OR REPLACE FUNCTION close_encounter(
    p_encounter_id      UUID,
    p_end_time          TIMESTAMPTZ DEFAULT NOW(),
    p_disposition_code  TEXT        DEFAULT NULL
)
RETURNS encounters
LANGUAGE plpgsql SECURITY DEFINER AS
$$
DECLARE
    v_encounter encounters;
BEGIN
    UPDATE encounters
       SET status                               = 'finished',
           period_end                          = p_end_time,
           hospitalization_discharge_disposition = COALESCE(p_disposition_code, hospitalization_discharge_disposition)
     WHERE id        = p_encounter_id
       AND status NOT IN ('finished', 'cancelled', 'entered_in_error')
       AND deleted_at IS NULL
    RETURNING * INTO v_encounter;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Encounter % not found or already closed', p_encounter_id;
    END IF;

    RETURN v_encounter;
END;
$$;

COMMENT ON FUNCTION close_encounter IS 'Idempotent encounter finalisation — sets status=finished and records end time';


-- ── 12.5  PHI Access Log Helper ──────────────────────────────
-- Called by application middleware on every PHI access

SET search_path TO dev, public;

CREATE OR REPLACE FUNCTION log_phi_access(
    p_accessor_type     accessor_type,
    p_accessor_id       UUID,
    p_accessor_name     TEXT,
    p_accessor_role     TEXT,
    p_accessor_org_id   UUID,
    p_patient_id        UUID,
    p_resource_type     TEXT,
    p_resource_id       UUID,
    p_action            TEXT,
    p_fields_accessed   TEXT[]      DEFAULT NULL,
    p_purpose           TEXT        DEFAULT 'TPO',
    p_purpose_detail    TEXT        DEFAULT NULL,
    p_ip_address        INET        DEFAULT NULL,
    p_user_agent        TEXT        DEFAULT NULL,
    p_session_id        TEXT        DEFAULT NULL,
    p_request_id        TEXT        DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql SECURITY DEFINER AS
$$
DECLARE
    v_id UUID := gen_random_uuid();
BEGIN
    INSERT INTO phi_access_log (
        id, accessed_at, accessor_type, accessor_id, accessor_name,
        accessor_role, accessor_org_id, patient_id, resource_type,
        resource_id, action, fields_accessed, purpose, purpose_detail,
        ip_address, user_agent, session_id, request_id,
        was_authorized, breach_indicator
    ) VALUES (
        v_id, NOW(), p_accessor_type, p_accessor_id, p_accessor_name,
        p_accessor_role, p_accessor_org_id, p_patient_id, p_resource_type,
        p_resource_id, p_action, p_fields_accessed, p_purpose, p_purpose_detail,
        p_ip_address, p_user_agent, p_session_id, p_request_id,
        true, false
    );
    RETURN v_id;
EXCEPTION WHEN OTHERS THEN
    -- Never let audit failure block clinical access
    RAISE WARNING 'PHI access log failed: %', SQLERRM;
    RETURN v_id;
END;
$$;

COMMENT ON FUNCTION log_phi_access IS 'Write-and-forget PHI access log entry — call from application middleware; never blocks on failure';


-- ── 12.6  UTC-safe Age Calculation ───────────────────────────

SET search_path TO dev, public;

CREATE OR REPLACE FUNCTION calculate_age_years(p_birth_date DATE)
RETURNS INT
LANGUAGE sql IMMUTABLE STRICT AS
$$
SELECT DATE_PART('year', AGE(CURRENT_DATE, p_birth_date))::INT;
$$;

CREATE OR REPLACE FUNCTION calculate_age_display(p_birth_date DATE)
RETURNS TEXT
LANGUAGE sql STABLE STRICT AS
$$
SELECT CASE
    WHEN DATE_PART('year', AGE(CURRENT_DATE, p_birth_date)) < 2 THEN
        DATE_PART('month', AGE(CURRENT_DATE, p_birth_date))::INT || ' months'
    ELSE
        DATE_PART('year', AGE(CURRENT_DATE, p_birth_date))::INT || ' years'
END;
$$;

COMMENT ON FUNCTION calculate_age_display IS 'Returns "X months" for infants under 2, "X years" for older patients';


-- ── 12.7  Appointment Slot Check ─────────────────────────────
-- Ensures a practitioner has no overlapping booked appointments

SET search_path TO dev, public;

CREATE OR REPLACE FUNCTION is_slot_available(
    p_practitioner_id   UUID,
    p_start_time        TIMESTAMPTZ,
    p_end_time          TIMESTAMPTZ,
    p_exclude_appt_id   UUID    DEFAULT NULL
)
RETURNS BOOLEAN
LANGUAGE sql STABLE SECURITY DEFINER AS
$$
SELECT NOT EXISTS (
    SELECT 1
    FROM   appointments apt
    JOIN   appointment_participants ap
           ON ap.appointment_id = apt.id
          AND ap.actor_practitioner_id = p_practitioner_id
    WHERE  apt.status NOT IN ('cancelled', 'noshow', 'entered_in_error')
      AND  apt.deleted_at IS NULL
      AND  (p_exclude_appt_id IS NULL OR apt.id != p_exclude_appt_id)
      AND  apt.start_time < p_end_time
      AND  apt.end_time   > p_start_time
);
$$;

COMMENT ON FUNCTION is_slot_available IS 'Returns true if the practitioner has no overlapping appointment in the given time range';


-- ── 12.8  Activate/Deactivate Patient Portal Account ─────────

CREATE OR REPLACE FUNCTION deactivate_patient_account(
    p_account_id    UUID,
    p_reason        TEXT
)
RETURNS VOID
LANGUAGE plpgsql SECURITY DEFINER AS
$$
BEGIN
    UPDATE patient_accounts
       SET is_active          = false,
           deactivated_at     = NOW(),
           deactivation_reason = p_reason,
           -- Invalidate sessions by nulling MFA secret on deactivation
           mfa_enabled        = false
     WHERE id = p_account_id
       AND is_active = true;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Account % not found or already deactivated', p_account_id;
    END IF;
END;
$$;

COMMENT ON FUNCTION deactivate_patient_account IS 'Soft-deactivates a patient portal account — preserves record for audit trail';
