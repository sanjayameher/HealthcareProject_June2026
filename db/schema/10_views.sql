-- ============================================================
-- SECTION 11 — VIEWS & MATERIALIZED VIEWS
-- Provide denormalized, application-friendly read surfaces.
-- All views on PHI tables must be SECURITY INVOKER (default)
-- so RLS policies on base tables are honoured.
-- ============================================================

-- ── 11.1  Patient Summary (Dashboard) ────────────────────────
-- Single-query patient header card — no PHI joins (identifiers excluded)

SET search_path TO dev, public;

CREATE OR REPLACE VIEW v_patient_summary AS
SELECT
    p.id,
    p.fhir_id,
    p.mrn,
    p.active,
    p.gender,
    p.birth_date,
    DATE_PART('year', AGE(p.birth_date))::INT        AS age_years,
    p.deceased_boolean,
    p.deceased_date_time,

    -- Primary name
    pn.family                                         AS name_family,
    pn.given                                          AS name_given,
    pn.prefix                                         AS name_prefix,
    pn.suffix                                         AS name_suffix,
    (
        COALESCE(array_to_string(pn.prefix, ' ') || ' ', '') ||
        array_to_string(pn.given, ' ') || ' ' || pn.family ||
        COALESCE(' ' || array_to_string(pn.suffix, ' '), '')
    )                                                 AS full_name,

    -- Primary address
    pa.city                                           AS address_city,
    pa.state                                          AS address_state,
    pa.postal_code                                    AS address_postal_code,
    pa.country                                        AS address_country,

    -- Preferred language
    pl.language_display                               AS preferred_language,
    pl.interpreter_needed,

    -- Managing org
    o.name                                            AS managing_org_name,

    -- Counts (non-PHI aggregates)
    (SELECT COUNT(*)
       FROM conditions c
      WHERE c.patient_id = p.id
        AND c.clinical_status = 'active'
        AND c.deleted_at IS NULL)::INT               AS active_conditions_count,

    (SELECT COUNT(*)
       FROM allergy_intolerances ai
      WHERE ai.patient_id = p.id
        AND ai.clinical_status = 'active'
        AND ai.deleted_at IS NULL)::INT              AS active_allergies_count,

    (SELECT COUNT(*)
       FROM medication_requests mr
      WHERE mr.patient_id = p.id
        AND mr.status = 'active'
        AND mr.deleted_at IS NULL)::INT              AS active_medications_count,

    -- Next appointment
    (SELECT apt.start_time
       FROM appointments apt
      WHERE apt.patient_id = p.id
        AND apt.status IN ('booked', 'pending')
        AND apt.start_time >= NOW()
        AND apt.deleted_at IS NULL
      ORDER BY apt.start_time ASC
      LIMIT 1)                                        AS next_appointment_at,

    p.created_at,
    p.updated_at
FROM
    patients p

LEFT JOIN patient_names pn
       ON pn.patient_id = p.id
      AND pn.is_primary  = true

LEFT JOIN patient_addresses pa
       ON pa.patient_id = p.id
      AND pa.is_primary  = true

LEFT JOIN patient_languages pl
       ON pl.patient_id = p.id
      AND pl.preferred   = true

LEFT JOIN organizations o
       ON o.id = p.managing_organization_id

WHERE p.deleted_at IS NULL;

COMMENT ON VIEW v_patient_summary IS 'Denormalized patient header — used for patient list, dashboard card, and encounter context';


-- ── 11.2  Active Problem List ─────────────────────────────────

SET search_path TO dev, public;

CREATE OR REPLACE VIEW v_problem_list AS
SELECT
    c.id,
    c.patient_id,
    c.fhir_id,
    c.clinical_status,
    c.verification_status,
    c.code_system,
    c.code,
    c.code_display,
    c.severity_display,
    c.onset_date_time,
    c.onset_string,
    c.is_chronic,
    c.is_principal_diagnosis,
    c.recorded_date,
    pr.family_name                          AS recorder_family,
    pr.given_name                           AS recorder_given,
    c.note,
    c.created_at,
    c.updated_at
FROM
    conditions c
LEFT JOIN practitioners pr ON pr.id = c.recorder_id
WHERE
    c.category_code = 'problem-list-item'
    AND c.deleted_at IS NULL
ORDER BY
    c.is_chronic DESC,
    c.onset_date_time DESC NULLS LAST;

COMMENT ON VIEW v_problem_list IS 'Active problem list — patient-facing and clinical dashboard';


-- ── 11.3  Current Medications ────────────────────────────────

CREATE OR REPLACE VIEW v_current_medications AS
SELECT
    mr.id,
    mr.patient_id,
    mr.fhir_id,
    mr.status,
    mr.medication_code_system,
    mr.medication_code,
    mr.medication_display,
    mr.medication_brand_name,
    mr.medication_strength,
    mr.dosage_text,
    mr.dosage_patient_instruction,
    mr.dosage_timing_code,
    mr.dosage_route_display,
    mr.dosage_dose_value,
    mr.dosage_dose_unit,
    mr.is_controlled_substance,
    mr.dea_schedule,
    mr.dispense_refills_allowed,
    mr.dosage_as_needed                     AS as_needed,
    pr.family_name                          AS prescriber_family,
    pr.given_name                           AS prescriber_given,
    pr.specialty_displays[1]                AS prescriber_specialty,
    mr.recorded_date,
    mr.dispense_validity_end                AS valid_through,
    -- Fill counts
    (SELECT COUNT(*)
       FROM medication_dispenses md
      WHERE md.medication_request_id = mr.id
        AND md.status = 'completed')::INT  AS fills_dispensed,
    mr.note,
    mr.created_at
FROM
    medication_requests mr
LEFT JOIN practitioners pr ON pr.id = mr.requester_id
WHERE
    mr.status IN ('active', 'on_hold')
    AND mr.deleted_at IS NULL
ORDER BY
    mr.is_controlled_substance DESC,
    mr.recorded_date DESC;

COMMENT ON VIEW v_current_medications IS 'Active and on-hold medication orders — medication reconciliation list';


-- ── 11.4  Latest Vital Signs Per LOINC Code ──────────────────

CREATE OR REPLACE VIEW v_latest_vitals AS
SELECT DISTINCT ON (o.patient_id, o.code)
    o.patient_id,
    o.code                                  AS loinc_code,
    o.code_display,
    o.value_quantity,
    o.value_quantity_unit,
    o.interpretation_code,
    o.interpretation_display,
    o.reference_range_low,
    o.reference_range_high,
    o.effective_date_time,
    o.created_at
FROM
    observations o
WHERE
    o.category_code = 'vital-signs'
    AND o.status    = 'final'
ORDER BY
    o.patient_id,
    o.code,
    o.effective_date_time DESC NULLS LAST;

COMMENT ON VIEW v_latest_vitals IS 'Most recent vital sign per LOINC code per patient — vital signs summary panel';


-- ── 11.5  Upcoming Appointments ──────────────────────────────

SET search_path TO dev, public;

CREATE OR REPLACE VIEW v_upcoming_appointments AS
SELECT
    apt.id,
    apt.patient_id,
    apt.fhir_id,
    apt.status,
    apt.appointment_type_code,
    apt.service_type_display,
    apt.specialty_display,
    apt.start_time,
    apt.end_time,
    apt.duration_minutes,
    apt.telehealth_url,
    apt.patient_instruction,
    apt.comment,

    -- Primary practitioner
    ap.actor_practitioner_id                AS practitioner_id,
    pr.given_name                           AS practitioner_given,
    pr.family_name                          AS practitioner_family,
    pr.specialty_displays[1]               AS practitioner_specialty,
    pr.prefix                               AS practitioner_prefix,

    apt.created_at
FROM
    appointments apt

LEFT JOIN appointment_participants ap
       ON ap.appointment_id = apt.id
      AND ap.type_code = 'ATND'

LEFT JOIN practitioners pr ON pr.id = ap.actor_practitioner_id

WHERE
    apt.start_time >= NOW()
    AND apt.status IN ('booked', 'pending', 'checked_in', 'arrived')
    AND apt.deleted_at IS NULL

ORDER BY apt.start_time ASC;

COMMENT ON VIEW v_upcoming_appointments IS 'Future booked appointments — patient portal appointment list';


-- ── 11.6  Allergy Alert Summary (Safety-Critical) ───────────

SET search_path TO dev, public;

CREATE OR REPLACE VIEW v_allergy_summary AS
SELECT
    ai.id,
    ai.patient_id,
    ai.fhir_id,
    ai.clinical_status,
    ai.verification_status,
    ai.allergy_type,
    ai.categories,
    ai.criticality,
    ai.code,
    ai.code_display,
    ai.last_occurrence,
    -- Worst reaction severity
    (SELECT ar.severity
       FROM allergy_reactions ar
      WHERE ar.allergy_intolerance_id = ai.id
      ORDER BY CASE ar.severity
               WHEN 'severe'   THEN 1
               WHEN 'moderate' THEN 2
               WHEN 'mild'     THEN 3
               END ASC
      LIMIT 1)                                AS worst_reaction_severity,
    -- All reaction manifestations
    ARRAY(
        SELECT ar.manifestation_display
          FROM allergy_reactions ar
         WHERE ar.allergy_intolerance_id = ai.id
    )                                         AS reaction_manifestations,
    ai.note,
    ai.created_at
FROM
    allergy_intolerances ai
WHERE
    ai.clinical_status = 'active'
    AND ai.deleted_at IS NULL
ORDER BY
    CASE ai.criticality
        WHEN 'high'              THEN 1
        WHEN 'unable_to_assess'  THEN 2
        WHEN 'low'               THEN 3
    END;

COMMENT ON VIEW v_allergy_summary IS 'Safety-critical allergy overview sorted by criticality — used in prescription safety checks and encounter headers';


-- ── 11.7  Coverage Summary ────────────────────────────────────

SET search_path TO dev, public;

CREATE OR REPLACE VIEW v_active_coverage AS
SELECT
    cov.id,
    cov.patient_id,
    cov.fhir_id,
    cov.type,
    cov.status,
    cov.plan_name,
    cov.group_number,
    cov.order_of_benefit,
    cov.is_primary,
    cov.period_start,
    cov.period_end,
    cov.copay_primary_care,
    cov.copay_specialist,
    cov.deductible_individual,
    cov.deductible_met,
    cov.out_of_pocket_max_individual,
    cov.coinsurance_rate,
    cov.requires_referral,
    -- Payer info (non-PHI)
    pay.name                                AS payer_name,
    pay.payer_id                            AS payer_electronic_id,
    pay.phone                               AS payer_phone,
    -- Last eligibility check
    (SELECT ec.is_eligible
       FROM eligibility_checks ec
      WHERE ec.coverage_id = cov.id
      ORDER BY ec.checked_at DESC
      LIMIT 1)                              AS last_eligibility_result,
    (SELECT ec.checked_at
       FROM eligibility_checks ec
      WHERE ec.coverage_id = cov.id
      ORDER BY ec.checked_at DESC
      LIMIT 1)                              AS last_eligibility_checked_at,
    cov.updated_at
FROM
    coverage cov
JOIN payers pay ON pay.id = cov.payer_id
WHERE
    cov.status = 'active'
    AND cov.deleted_at IS NULL
    AND (cov.period_end IS NULL OR cov.period_end >= CURRENT_DATE)
ORDER BY
    cov.patient_id,
    cov.order_of_benefit;

COMMENT ON VIEW v_active_coverage IS 'Active insurance coverage with payer info — billing sidebar and eligibility display';


-- ── 11.8  Materialized: Patient Care Gap Summary ─────────────
-- Expensive aggregation — refresh nightly via pg_cron or scheduler

SET search_path TO dev, public;

CREATE MATERIALIZED VIEW mv_patient_care_gaps AS
SELECT
    p.id                                    AS patient_id,
    p.mrn,
    DATE_PART('year', AGE(p.birth_date))::INT AS age_years,
    p.gender,

    -- Overdue preventive screenings (simplified rule engine)
    -- A real implementation would use CDS Hooks / HEDIS rules
    CASE
        WHEN p.gender = 'female'
             AND DATE_PART('year', AGE(p.birth_date)) BETWEEN 21 AND 65
             AND NOT EXISTS (
                 SELECT 1 FROM service_requests sr
                  WHERE sr.patient_id = p.id
                    AND sr.code IN ('10524-7', '47527-7')  -- Pap smear LOINC
                    AND sr.authored_on >= NOW() - INTERVAL '3 years'
             )
        THEN true ELSE false
    END                                     AS needs_cervical_screening,

    CASE
        WHEN DATE_PART('year', AGE(p.birth_date)) >= 50
             AND NOT EXISTS (
                 SELECT 1 FROM service_requests sr
                  WHERE sr.patient_id = p.id
                    AND sr.code IN ('28010-7')  -- Colonoscopy LOINC
                    AND sr.authored_on >= NOW() - INTERVAL '10 years'
             )
        THEN true ELSE false
    END                                     AS needs_colorectal_screening,

    CASE
        WHEN EXISTS (
                 SELECT 1 FROM conditions c
                  WHERE c.patient_id = p.id
                    AND c.code IN ('E11','E11.9','E11.65')  -- Type 2 DM ICD-10
                    AND c.clinical_status = 'active'
                    AND c.deleted_at IS NULL
             )
             AND NOT EXISTS (
                 SELECT 1 FROM observations o
                  WHERE o.patient_id = p.id
                    AND o.code = '4548-4'  -- HbA1c LOINC
                    AND o.effective_date_time >= NOW() - INTERVAL '6 months'
             )
        THEN true ELSE false
    END                                     AS needs_hba1c,

    NOW()                                   AS computed_at

FROM patients p
WHERE p.active = true AND p.deleted_at IS NULL;

CREATE UNIQUE INDEX ON mv_patient_care_gaps (patient_id);
CREATE INDEX ON mv_patient_care_gaps (needs_hba1c) WHERE needs_hba1c = true;
CREATE INDEX ON mv_patient_care_gaps (needs_cervical_screening) WHERE needs_cervical_screening = true;
CREATE INDEX ON mv_patient_care_gaps (needs_colorectal_screening) WHERE needs_colorectal_screening = true;

COMMENT ON MATERIALIZED VIEW mv_patient_care_gaps IS 'Nightly-refreshed care gap summary for population health dashboards — refresh with: REFRESH MATERIALIZED VIEW CONCURRENTLY mv_patient_care_gaps';
