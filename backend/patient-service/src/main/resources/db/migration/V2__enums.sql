-- ============================================================
-- SECTION 2 — ENUMERATED TYPES
-- All enums are aligned with FHIR R4 value sets and HL7 codes
-- ============================================================

-- ── patient schema ──────────────────────────────────────────
SET search_path TO dev, public;

CREATE TYPE gender AS ENUM (
    'male', 'female', 'other', 'unknown'
);

-- HL7 v3 Marital Status codes
CREATE TYPE marital_status AS ENUM (
    'A',  -- Annulled
    'D',  -- Divorced
    'I',  -- Interlocutory
    'L',  -- Legally separated
    'M',  -- Married
    'C',  -- Common Law
    'P',  -- Polygamous
    'T',  -- Domestic Partner
    'U',  -- Unmarried
    'W',  -- Widowed
    'S',  -- Never Married
    'UNK' -- Unknown
);

CREATE TYPE contact_relationship AS ENUM (
    'emergency', 'next_of_kin', 'guardian', 'power_of_attorney',
    'parent', 'spouse', 'sibling', 'child', 'grandparent',
    'caregiver', 'employer', 'friend', 'other'
);

CREATE TYPE address_use AS ENUM (
    'home', 'work', 'temp', 'old', 'billing'
);

CREATE TYPE address_type AS ENUM (
    'postal', 'physical', 'both'
);

CREATE TYPE telecom_system AS ENUM (
    'phone', 'fax', 'email', 'pager', 'url', 'sms', 'other'
);

CREATE TYPE telecom_use AS ENUM (
    'home', 'work', 'temp', 'old', 'mobile'
);

CREATE TYPE name_use AS ENUM (
    'usual', 'official', 'temp', 'nickname', 'anonymous', 'old', 'maiden'
);

CREATE TYPE identifier_system AS ENUM (
    'ssn', 'mrn', 'npi', 'dea', 'driver_license', 'passport',
    'insurance_member_id', 'employee_id', 'medicaid_id',
    'medicare_id', 'itin', 'other'
);

CREATE TYPE language_proficiency AS ENUM (
    'excellent', 'good', 'fair', 'poor'
);

CREATE TYPE flag_status AS ENUM (
    'active', 'inactive', 'entered_in_error'
);

CREATE TYPE link_type AS ENUM (
    'replaced_by',   -- This patient resource is replaced by another
    'replaces',      -- This patient resource replaces another
    'refer',         -- Both resources refer to the same patient
    'seealso'        -- Two records that may be about the same individual
);

-- ── clinical schema ─────────────────────────────────────────
SET search_path TO dev, public;

CREATE TYPE encounter_status AS ENUM (
    'planned', 'arrived', 'triaged', 'in_progress', 'on_leave',
    'finished', 'cancelled', 'entered_in_error', 'unknown'
);

CREATE TYPE encounter_class AS ENUM (
    'inpatient', 'outpatient', 'ambulatory', 'emergency',
    'home', 'virtual', 'observation', 'short_stay'
);

CREATE TYPE observation_status AS ENUM (
    'registered', 'preliminary', 'final', 'amended',
    'corrected', 'cancelled', 'entered_in_error', 'unknown'
);

CREATE TYPE condition_clinical_status AS ENUM (
    'active', 'recurrence', 'relapse', 'inactive', 'remission',
    'resolved', 'unknown'
);

CREATE TYPE condition_verification_status AS ENUM (
    'unconfirmed', 'provisional', 'differential', 'confirmed',
    'refuted', 'entered_in_error'
);

CREATE TYPE medication_request_status AS ENUM (
    'active', 'on_hold', 'cancelled', 'completed',
    'entered_in_error', 'stopped', 'draft', 'unknown'
);

CREATE TYPE medication_request_intent AS ENUM (
    'proposal', 'plan', 'order', 'original_order',
    'reflex_order', 'filler_order', 'instance_order', 'option'
);

CREATE TYPE service_request_status AS ENUM (
    'draft', 'active', 'on_hold', 'revoked',
    'completed', 'entered_in_error', 'unknown'
);

CREATE TYPE service_request_intent AS ENUM (
    'proposal', 'plan', 'directive', 'order', 'original_order',
    'reflex_order', 'filler_order', 'instance_order', 'option'
);

CREATE TYPE allergy_type AS ENUM (
    'allergy', 'intolerance'
);

CREATE TYPE allergy_category AS ENUM (
    'food', 'medication', 'environment', 'biologic'
);

CREATE TYPE allergy_criticality AS ENUM (
    'low', 'high', 'unable_to_assess'
);

CREATE TYPE allergy_clinical_status AS ENUM (
    'active', 'inactive', 'resolved'
);

CREATE TYPE allergy_verification_status AS ENUM (
    'unconfirmed', 'presumed', 'confirmed', 'refuted', 'entered_in_error'
);

CREATE TYPE reaction_severity AS ENUM (
    'mild', 'moderate', 'severe'
);

CREATE TYPE document_status AS ENUM (
    'current', 'superseded', 'entered_in_error'
);

CREATE TYPE care_plan_status AS ENUM (
    'draft', 'active', 'on_hold', 'revoked',
    'completed', 'entered_in_error', 'unknown'
);

CREATE TYPE diagnostic_report_status AS ENUM (
    'registered', 'partial', 'preliminary', 'final',
    'amended', 'corrected', 'appended', 'cancelled', 'entered_in_error'
);

CREATE TYPE immunization_status AS ENUM (
    'completed', 'entered_in_error', 'not_done'
);

CREATE TYPE dispense_status AS ENUM (
    'preparation', 'in_progress', 'cancelled', 'on_hold',
    'completed', 'entered_in_error', 'stopped', 'declined', 'unknown'
);

-- ── billing schema ───────────────────────────────────────────
SET search_path TO dev, public;

CREATE TYPE coverage_status AS ENUM (
    'active', 'cancelled', 'draft', 'entered_in_error'
);

CREATE TYPE coverage_type AS ENUM (
    'medical', 'dental', 'vision', 'pharmacy', 'mental_health',
    'substance_abuse', 'long_term_care', 'workers_comp',
    'liability', 'medicare', 'medicaid', 'tricare', 'other'
);

CREATE TYPE subscriber_relationship AS ENUM (
    'self', 'spouse', 'child', 'common', 'injured', 'parent',
    'other', 'unknown'
);

CREATE TYPE eligibility_status AS ENUM (
    'active', 'inactive', 'pending', 'error'
);

-- ── portal schema ─────────────────────────────────────────
SET search_path TO dev, public;

CREATE TYPE consent_status AS ENUM (
    'draft', 'proposed', 'active', 'rejected', 'inactive', 'entered_in_error'
);

CREATE TYPE consent_scope AS ENUM (
    'adr',            -- Advanced Directive
    'research',       -- Research authorization
    'patient_privacy',-- HIPAA Privacy Consent
    'treatment'       -- Treatment consent
);

CREATE TYPE appointment_status AS ENUM (
    'proposed', 'pending', 'booked', 'arrived', 'fulfilled',
    'cancelled', 'noshow', 'entered_in_error', 'checked_in', 'waitlist'
);

CREATE TYPE participant_required AS ENUM (
    'required', 'optional', 'information_only'
);

CREATE TYPE participant_status AS ENUM (
    'accepted', 'declined', 'tentative', 'needs_action'
);

CREATE TYPE message_status AS ENUM (
    'draft', 'sent', 'delivered', 'read', 'archived', 'deleted'
);

CREATE TYPE notification_channel AS ENUM (
    'email', 'sms', 'push', 'in_app'
);

CREATE TYPE notification_status AS ENUM (
    'pending', 'sent', 'delivered', 'read', 'failed', 'cancelled'
);

-- ── audit schema ─────────────────────────────────────────
SET search_path TO dev, public;

-- FHIR AuditEvent action codes
CREATE TYPE event_action AS ENUM (
    'C',  -- Create
    'R',  -- Read/View
    'U',  -- Update
    'D',  -- Delete
    'E'   -- Execute
);

CREATE TYPE event_outcome AS ENUM (
    'success',
    'minor_failure',
    'serious_failure',
    'major_failure'
);

CREATE TYPE accessor_type AS ENUM (
    'patient', 'practitioner', 'admin',
    'system', 'third_party', 'anonymous'
);
