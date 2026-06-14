-- ============================================================
-- TEST / SAMPLE DATA — Patient Module
-- 3 sample patients with full clinical history
-- ============================================================
-- Patients:  John Smith (45M), Sarah Johnson (32F), Maria Garcia (67F)
-- Doctors:   Dr. Emily Chen (PCP), Dr. Michael Roberts (Cardiologist)
-- Insurance: Blue Cross Blue Shield, Aetna
-- ============================================================

BEGIN;

-- ── Fixed UUIDs for cross-reference ──────────────────────────
DO $$
DECLARE
    -- Organizations
    v_org_main      UUID := 'aaaaaaaa-0001-0001-0001-000000000001';
    v_org_hospital  UUID := 'aaaaaaaa-0001-0001-0001-000000000002';
    v_org_lab       UUID := 'aaaaaaaa-0001-0001-0001-000000000003';
    v_org_pharmacy  UUID := 'aaaaaaaa-0001-0001-0001-000000000004';

    -- Payers
    v_payer_bcbs    UUID := 'bbbbbbbb-0001-0001-0001-000000000001';
    v_payer_aetna   UUID := 'bbbbbbbb-0001-0001-0001-000000000002';

    -- Practitioners
    v_dr_chen       UUID := 'cccccccc-0001-0001-0001-000000000001';
    v_dr_roberts    UUID := 'cccccccc-0001-0001-0001-000000000002';

    -- Patients
    v_pat_john      UUID := 'dddddddd-0001-0001-0001-000000000001';
    v_pat_sarah     UUID := 'dddddddd-0001-0001-0001-000000000002';
    v_pat_maria     UUID := 'dddddddd-0001-0001-0001-000000000003';

    -- Encounters
    v_enc_john1     UUID := 'eeeeeeee-0001-0001-0001-000000000001';
    v_enc_sarah1    UUID := 'eeeeeeee-0001-0001-0001-000000000002';
    v_enc_maria1    UUID := 'eeeeeeee-0001-0001-0001-000000000003';
    v_enc_maria2    UUID := 'eeeeeeee-0001-0001-0001-000000000004';

    -- Appointments
    v_appt_john1    UUID := 'ffffffff-0001-0001-0001-000000000001';
    v_appt_sarah1   UUID := 'ffffffff-0001-0001-0001-000000000002';
    v_appt_maria1   UUID := 'ffffffff-0001-0001-0001-000000000003';
    v_appt_future   UUID := 'ffffffff-0001-0001-0001-000000000004';

    -- Coverage
    v_cov_john      UUID := '11111111-0001-0001-0001-000000000001';
    v_cov_sarah     UUID := '11111111-0001-0001-0001-000000000002';
    v_cov_maria     UUID := '11111111-0001-0001-0001-000000000003';

    -- Portal accounts
    v_acct_john     UUID := '22222222-0001-0001-0001-000000000001';
    v_acct_sarah    UUID := '22222222-0001-0001-0001-000000000002';
    v_acct_maria    UUID := '22222222-0001-0001-0001-000000000003';

    -- Care teams
    v_team_john     UUID := '33333333-0001-0001-0001-000000000001';
    v_team_maria    UUID := '33333333-0001-0001-0001-000000000002';

    -- Message threads
    v_thread1       UUID := '44444444-0001-0001-0001-000000000001';
    v_thread2       UUID := '44444444-0001-0001-0001-000000000002';

    -- Service requests (lab orders)
    v_srq_john1     UUID := '55555555-0001-0001-0001-000000000001';
    v_srq_maria1    UUID := '55555555-0001-0001-0001-000000000002';

    -- Diagnostic reports
    v_drep_john1    UUID := '66666666-0001-0001-0001-000000000001';
    v_drep_maria1   UUID := '66666666-0001-0001-0001-000000000002';

    -- Care plans
    v_cp_maria      UUID := '77777777-0001-0001-0001-000000000001';

    -- Consents
    v_consent_john  UUID := '88888888-0001-0001-0001-000000000001';
    v_consent_sarah UUID := '88888888-0001-0001-0001-000000000002';
    v_consent_maria UUID := '88888888-0001-0001-0001-000000000003';

    v_enc_key TEXT := 'test_encrypt_key_32bytes_exactly';

BEGIN

-- ============================================================
-- ORGANIZATIONS
-- ============================================================
INSERT INTO organizations
    (id, fhir_id, name, alias, active, type_code, type_display, npi,
     address_line1, city, state, postal_code, phone, email, website)
VALUES
    (v_org_main, gen_random_uuid(), 'HealthCare Platform Medical Group',
     ARRAY['HCPMG','TeleHealth Clinic'], true, 'prov', 'Healthcare Provider', '1234567890',
     '100 Medical Plaza Dr', 'Chicago', 'IL', '60601', '312-555-0100',
     'admin@hcpmg.com', 'https://hcpmg.com'),

    (v_org_hospital, gen_random_uuid(), 'City General Hospital',
     ARRAY['CGH'], true, 'prov', 'Hospital', '0987654321',
     '200 Hospital Ave', 'Chicago', 'IL', '60602', '312-555-0200',
     'info@cgh.org', 'https://citygeneralhospital.org'),

    (v_org_lab, gen_random_uuid(), 'LabCorp Diagnostics',
     ARRAY['LabCorp'], true, 'prov', 'Laboratory', '1122334455',
     '300 Lab Center Blvd', 'Chicago', 'IL', '60603', '312-555-0300',
     'results@labcorp.com', 'https://labcorp.com'),

    (v_org_pharmacy, gen_random_uuid(), 'CVS Pharmacy #4521',
     ARRAY['CVS'], true, 'prov', 'Pharmacy', '5544332211',
     '450 Main Street', 'Chicago', 'IL', '60604', '312-555-0400',
     NULL, 'https://cvs.com');


-- ============================================================
-- PRACTITIONERS
-- ============================================================
INSERT INTO practitioners
    (id, fhir_id, organization_id, active, npi, gender, birth_date,
     prefix, given_name, family_name, suffix,
     specialty_codes, specialty_displays, qualification_codes,
     languages, is_telehealth_enabled, telehealth_platform)
VALUES
    (v_dr_chen, gen_random_uuid(), v_org_main, true, '1111111111',
     'female', '1978-04-15',
     'Dr.', 'Emily', 'Chen', 'MD',
     ARRAY['207Q00000X'], ARRAY['Family Medicine'],
     ARRAY['MD'], ARRAY['en','zh'], true, 'native'),

    (v_dr_roberts, gen_random_uuid(), v_org_hospital, true, '2222222222',
     'male', '1970-09-22',
     'Dr.', 'Michael', 'Roberts', 'MD, FACC',
     ARRAY['207RC0000X'], ARRAY['Cardiovascular Disease (Cardiology)'],
     ARRAY['MD'], ARRAY['en'], true, 'native');

INSERT INTO practitioner_roles
    (practitioner_id, organization_id, role_code, role_display,
     specialty_code, specialty_display, is_active)
VALUES
    (v_dr_chen, v_org_main, 'doctor', 'Primary Care Physician',
     '394814009', 'General practice', true),
    (v_dr_roberts, v_org_hospital, 'doctor', 'Attending Cardiologist',
     '394579002', 'Cardiology', true);


-- ============================================================
-- PAYERS (Insurance Companies)
-- ============================================================
INSERT INTO payers
    (id, fhir_id, name, short_name, payer_id, npi,
     address_line1, city, state, postal_code,
     phone, website, supports_electronic_claims, is_active)
VALUES
    (v_payer_bcbs, gen_random_uuid(),
     'Blue Cross Blue Shield of Illinois', 'BCBS IL', 'BCBSIL', '3344556677',
     '300 E Randolph St', 'Chicago', 'IL', '60601',
     '800-654-7385', 'https://bcbsil.com', true, true),

    (v_payer_aetna, gen_random_uuid(),
     'Aetna Health Insurance', 'Aetna', 'AETNA', '4455667788',
     '151 Farmington Ave', 'Hartford', 'CT', '06156',
     '800-872-3862', 'https://aetna.com', true, true);


-- ============================================================
-- PATIENTS
-- ============================================================
INSERT INTO patients
    (id, fhir_id, mrn, active, gender, birth_date,
     marital_status, managing_organization_id)
VALUES
    (v_pat_john, gen_random_uuid(), 'HP240100001', true,
     'male', '1979-03-15', 'M', v_org_main),

    (v_pat_sarah, gen_random_uuid(), 'HP240100002', true,
     'female', '1992-07-28', 'S', v_org_main),

    (v_pat_maria, gen_random_uuid(), 'HP240100003', true,
     'female', '1957-11-05', 'W', v_org_main);


-- ============================================================
-- PATIENT NAMES
-- ============================================================
INSERT INTO patient_names
    (patient_id, use, text, family, given, prefix, suffix, is_primary)
VALUES
    (v_pat_john,  'official', 'Mr. John Michael Smith',    'Smith',   ARRAY['John','Michael'],  ARRAY['Mr.'], ARRAY[]::TEXT[], true),
    (v_pat_john,  'nickname', 'Johnny',                    'Smith',   ARRAY['Johnny'],           ARRAY[]::TEXT[], ARRAY[]::TEXT[], false),
    (v_pat_sarah, 'official', 'Ms. Sarah Elizabeth Johnson','Johnson',ARRAY['Sarah','Elizabeth'],ARRAY['Ms.'], ARRAY[]::TEXT[], true),
    (v_pat_maria, 'official', 'Mrs. Maria Elena Garcia',   'Garcia',  ARRAY['Maria','Elena'],    ARRAY['Mrs.'],ARRAY[]::TEXT[], true);


-- ============================================================
-- PATIENT ADDRESSES
-- ============================================================
INSERT INTO patient_addresses
    (patient_id, use, type, line1, line2, city, state, postal_code, country, is_primary)
VALUES
    (v_pat_john,  'home', 'both', '123 Oak Street', 'Apt 4B', 'Chicago', 'IL', '60614', 'US', true),
    (v_pat_sarah, 'home', 'both', '456 Maple Ave',  NULL,     'Evanston', 'IL', '60201', 'US', true),
    (v_pat_maria, 'home', 'both', '789 Pine Road',  NULL,     'Oak Park', 'IL', '60302', 'US', true);


-- ============================================================
-- PATIENT TELECOMS
-- ============================================================
INSERT INTO patient_telecoms
    (patient_id, system, value, value_hash, use, rank, is_verified)
VALUES
    (v_pat_john,  'phone', pgp_sym_encrypt('312-555-1001', v_enc_key)::bytea,
     hmac('312-555-1001', v_enc_key, 'sha256'), 'mobile', 1, true),
    (v_pat_john,  'email', pgp_sym_encrypt('john.smith@email.com', v_enc_key)::bytea,
     hmac('john.smith@email.com', v_enc_key, 'sha256'), 'home', 2, true),

    (v_pat_sarah, 'phone', pgp_sym_encrypt('847-555-2002', v_enc_key)::bytea,
     hmac('847-555-2002', v_enc_key, 'sha256'), 'mobile', 1, true),
    (v_pat_sarah, 'email', pgp_sym_encrypt('sarah.johnson@email.com', v_enc_key)::bytea,
     hmac('sarah.johnson@email.com', v_enc_key, 'sha256'), 'home', 2, true),

    (v_pat_maria, 'phone', pgp_sym_encrypt('708-555-3003', v_enc_key)::bytea,
     hmac('708-555-3003', v_enc_key, 'sha256'), 'home', 1, true),
    (v_pat_maria, 'email', pgp_sym_encrypt('maria.garcia@email.com', v_enc_key)::bytea,
     hmac('maria.garcia@email.com', v_enc_key, 'sha256'), 'home', 2, false);


-- ============================================================
-- PATIENT IDENTIFIERS (SSN, etc.)
-- ============================================================
INSERT INTO patient_identifiers
    (patient_id, system, value, value_hash, display, assigner_name, is_active)
VALUES
    (v_pat_john,  'ssn', pgp_sym_encrypt('123-45-6789', v_enc_key)::bytea,
     hmac('123-45-6789', v_enc_key, 'sha256'), 'SSN on file', 'Social Security Administration', true),
    (v_pat_sarah, 'ssn', pgp_sym_encrypt('234-56-7890', v_enc_key)::bytea,
     hmac('234-56-7890', v_enc_key, 'sha256'), 'SSN on file', 'Social Security Administration', true),
    (v_pat_maria, 'ssn', pgp_sym_encrypt('345-67-8901', v_enc_key)::bytea,
     hmac('345-67-8901', v_enc_key, 'sha256'), 'SSN on file', 'Social Security Administration', true),
    (v_pat_maria, 'medicare_id', pgp_sym_encrypt('1EG4-TE5-MK72', v_enc_key)::bytea,
     hmac('1EG4-TE5-MK72', v_enc_key, 'sha256'), 'Medicare ID', 'CMS', true);


-- ============================================================
-- PATIENT LANGUAGES
-- ============================================================
INSERT INTO patient_languages
    (patient_id, language_code, language_display, preferred, proficiency, interpreter_needed)
VALUES
    (v_pat_john,  'en', 'English',  true,  'excellent', false),
    (v_pat_sarah, 'en', 'English',  true,  'excellent', false),
    (v_pat_sarah, 'fr', 'French',   false, 'good',      false),
    (v_pat_maria, 'es', 'Spanish',  true,  'excellent', false),
    (v_pat_maria, 'en', 'English',  false, 'fair',      true);


-- ============================================================
-- RACE / ETHNICITY (US Core)
-- ============================================================
INSERT INTO patient_race_ethnicities
    (patient_id, category, code, display, detailed_code, detailed_display)
VALUES
    (v_pat_john,  'race',      '2106-3', 'White',                     NULL,    NULL),
    (v_pat_john,  'ethnicity', '2186-5', 'Not Hispanic or Latino',    NULL,    NULL),
    (v_pat_sarah, 'race',      '2054-5', 'Black or African American', NULL,    NULL),
    (v_pat_sarah, 'ethnicity', '2186-5', 'Not Hispanic or Latino',    NULL,    NULL),
    (v_pat_maria, 'race',      '2131-1', 'Other Race',                NULL,    NULL),
    (v_pat_maria, 'ethnicity', '2135-2', 'Hispanic or Latino',        '2148-5','Mexican');


-- ============================================================
-- PATIENT EMERGENCY CONTACTS
-- ============================================================
INSERT INTO patient_contacts
    (patient_id, relationship, priority, name_family, name_given,
     phone, phone_hash, address_city, address_state, is_active)
VALUES
    (v_pat_john, 'spouse', 1, 'Smith', ARRAY['Jennifer'],
     pgp_sym_encrypt('312-555-1002', v_enc_key)::bytea,
     hmac('312-555-1002', v_enc_key, 'sha256'), 'Chicago', 'IL', true),

    (v_pat_sarah, 'parent', 1, 'Johnson', ARRAY['Robert'],
     pgp_sym_encrypt('773-555-2005', v_enc_key)::bytea,
     hmac('773-555-2005', v_enc_key, 'sha256'), 'Chicago', 'IL', true),

    (v_pat_maria, 'child', 1, 'Garcia', ARRAY['Carlos'],
     pgp_sym_encrypt('708-555-4004', v_enc_key)::bytea,
     hmac('708-555-4004', v_enc_key, 'sha256'), 'Oak Park', 'IL', true);


-- ============================================================
-- PATIENT FLAGS / ALERTS
-- ============================================================
INSERT INTO patient_flags
    (patient_id, status, category_code, category_display,
     code, code_system, display, severity, author_id)
VALUES
    (v_pat_maria, 'active', 'safety', 'Safety Alert',
     '73595000', 'SNOMED-CT', 'Fall risk', 'high', v_dr_chen),
    (v_pat_john,  'active', 'drug',   'Drug Alert',
     '416098002', 'SNOMED-CT', 'Penicillin allergy — documented', 'medium', v_dr_chen);


-- ============================================================
-- INSURANCE COVERAGE
-- ============================================================
INSERT INTO coverage
    (id, fhir_id, patient_id, payer_id, status, type,
     subscriber_id, subscriber_id_hash,
     group_number, group_name, plan_name, plan_id,
     subscriber_relationship,
     period_start, order_of_benefit,
     copay_primary_care, copay_specialist, copay_emergency,
     deductible_individual, deductible_met,
     out_of_pocket_max_individual, coinsurance_rate,
     requires_referral, pcp_provider_id, last_verified_at)
VALUES
    (v_cov_john, gen_random_uuid(), v_pat_john, v_payer_bcbs,
     'active', 'medical',
     pgp_sym_encrypt('XYZ987654321', v_enc_key)::bytea,
     hmac('XYZ987654321', v_enc_key, 'sha256'),
     'GRP-12345', 'Smith Employer Group', 'PPO Blue Choice', 'PPO-BLUE-01',
     'self', '2024-01-01', 1,
     25.00, 50.00, 150.00, 1500.00, 450.00, 5000.00, 0.20,
     false, v_dr_chen, NOW() - INTERVAL '30 days'),

    (v_cov_sarah, gen_random_uuid(), v_pat_sarah, v_payer_aetna,
     'active', 'medical',
     pgp_sym_encrypt('AET112233445', v_enc_key)::bytea,
     hmac('AET112233445', v_enc_key, 'sha256'),
     'GRP-67890', 'Johnson Employer Group', 'Aetna Choice POS II', 'AETNA-POS-01',
     'self', '2024-01-01', 1,
     20.00, 40.00, 100.00, 2000.00, 200.00, 6000.00, 0.20,
     false, v_dr_chen, NOW() - INTERVAL '15 days'),

    (v_cov_maria, gen_random_uuid(), v_pat_maria, v_payer_bcbs,
     'active', 'medicare',
     pgp_sym_encrypt('1EG4TE5MK72', v_enc_key)::bytea,
     hmac('1EG4TE5MK72', v_enc_key, 'sha256'),
     NULL, 'Medicare Part B', 'Medicare Advantage Blue', 'MADVB-01',
     'self', '2020-01-01', 1,
     0.00, 0.00, 0.00, 226.00, 226.00, 7050.00, 0.20,
     false, v_dr_chen, NOW() - INTERVAL '7 days');


-- ============================================================
-- PORTAL PATIENT ACCOUNTS
-- ============================================================
INSERT INTO patient_accounts
    (id, patient_id,
     email, email_hash, email_verified, email_verified_at,
     phone, phone_hash, phone_verified,
     username, password_hash, password_changed_at,
     mfa_enabled, is_active,
     terms_version_accepted, terms_accepted_at,
     privacy_policy_version, privacy_policy_accepted_at,
     hipaa_notice_version, hipaa_notice_acknowledged_at)
VALUES
    (v_acct_john, v_pat_john,
     pgp_sym_encrypt('john.smith@email.com', v_enc_key)::bytea,
     hmac('john.smith@email.com', v_enc_key, 'sha256'),
     true, NOW() - INTERVAL '180 days',
     pgp_sym_encrypt('312-555-1001', v_enc_key)::bytea,
     hmac('312-555-1001', v_enc_key, 'sha256'), true,
     'john.smith', crypt('Test@1234', gen_salt('bf', 12)),
     NOW() - INTERVAL '180 days',
     true, true,
     'v2.1', NOW() - INTERVAL '180 days',
     'v1.5', NOW() - INTERVAL '180 days',
     'v1.0', NOW() - INTERVAL '180 days'),

    (v_acct_sarah, v_pat_sarah,
     pgp_sym_encrypt('sarah.johnson@email.com', v_enc_key)::bytea,
     hmac('sarah.johnson@email.com', v_enc_key, 'sha256'),
     true, NOW() - INTERVAL '90 days',
     pgp_sym_encrypt('847-555-2002', v_enc_key)::bytea,
     hmac('847-555-2002', v_enc_key, 'sha256'), true,
     'sarah.johnson', crypt('Test@5678', gen_salt('bf', 12)),
     NOW() - INTERVAL '90 days',
     false, true,
     'v2.1', NOW() - INTERVAL '90 days',
     'v1.5', NOW() - INTERVAL '90 days',
     'v1.0', NOW() - INTERVAL '90 days'),

    (v_acct_maria, v_pat_maria,
     pgp_sym_encrypt('maria.garcia@email.com', v_enc_key)::bytea,
     hmac('maria.garcia@email.com', v_enc_key, 'sha256'),
     true, NOW() - INTERVAL '365 days',
     pgp_sym_encrypt('708-555-3003', v_enc_key)::bytea,
     hmac('708-555-3003', v_enc_key, 'sha256'), false,
     'maria.garcia', crypt('Test@9012', gen_salt('bf', 12)),
     NOW() - INTERVAL '365 days',
     false, true,
     'v2.1', NOW() - INTERVAL '365 days',
     'v1.5', NOW() - INTERVAL '365 days',
     'v1.0', NOW() - INTERVAL '365 days');


-- ============================================================
-- HIPAA CONSENTS
-- ============================================================
INSERT INTO consents
    (id, fhir_id, patient_id, status, scope_code, scope_display,
     category_codes, category_displays,
     policy_uri, date_time, period_start,
     grantor_patient_id, is_verified, verified_with_code, verified_at)
VALUES
    (v_consent_john, gen_random_uuid(), v_pat_john,
     'active', 'patient_privacy', 'HIPAA Privacy Consent',
     ARRAY['HIPAA','TREAT'], ARRAY['HIPAA Authorization','Treatment Consent'],
     'https://hcpmg.com/privacy-policy/v1.5',
     NOW() - INTERVAL '180 days', NOW() - INTERVAL '180 days',
     v_pat_john, true, 'patient', NOW() - INTERVAL '180 days'),

    (v_consent_sarah, gen_random_uuid(), v_pat_sarah,
     'active', 'patient_privacy', 'HIPAA Privacy Consent',
     ARRAY['HIPAA','TREAT'], ARRAY['HIPAA Authorization','Treatment Consent'],
     'https://hcpmg.com/privacy-policy/v1.5',
     NOW() - INTERVAL '90 days', NOW() - INTERVAL '90 days',
     v_pat_sarah, true, 'patient', NOW() - INTERVAL '90 days'),

    (v_consent_maria, gen_random_uuid(), v_pat_maria,
     'active', 'patient_privacy', 'HIPAA Privacy Consent',
     ARRAY['HIPAA','TREAT'], ARRAY['HIPAA Authorization','Treatment Consent'],
     'https://hcpmg.com/privacy-policy/v1.5',
     NOW() - INTERVAL '365 days', NOW() - INTERVAL '365 days',
     v_pat_maria, true, 'patient', NOW() - INTERVAL '365 days');


-- ============================================================
-- APPOINTMENTS (Telehealth)
-- ============================================================
INSERT INTO appointments
    (id, fhir_id, patient_id, status,
     service_type_code, service_type_display,
     specialty_code, specialty_display,
     appointment_type_code,
     reason_codes, reason_displays,
     start_time, end_time,
     telehealth_url, telehealth_meeting_id,
     patient_instruction, comment,
     reminder_24h_sent, reminder_2h_sent)
VALUES
    -- Past appointments (completed)
    (v_appt_john1, gen_random_uuid(), v_pat_john, 'fulfilled',
     '11429006', 'Consultation',
     '394814009', 'General practice', 'FOLLOWUP',
     ARRAY['38341003'], ARRAY['Hypertension follow-up'],
     NOW() - INTERVAL '30 days', NOW() - INTERVAL '30 days' + INTERVAL '30 min',
     'https://telehealth.hcpmg.com/session/abc123', 'MTG-ABC123',
     'Join 5 minutes early. Have your BP readings ready.', 'Routine BP check',
     true, true),

    (v_appt_sarah1, gen_random_uuid(), v_pat_sarah, 'fulfilled',
     '11429006', 'Consultation',
     '394814009', 'General practice', 'CHECKUP',
     ARRAY['185349003'], ARRAY['Annual wellness visit'],
     NOW() - INTERVAL '14 days', NOW() - INTERVAL '14 days' + INTERVAL '45 min',
     'https://telehealth.hcpmg.com/session/def456', 'MTG-DEF456',
     'Please complete wellness questionnaire before visit.', 'Annual checkup',
     true, true),

    (v_appt_maria1, gen_random_uuid(), v_pat_maria, 'fulfilled',
     '11429006', 'Consultation',
     '394814009', 'General practice', 'FOLLOWUP',
     ARRAY['73211009'], ARRAY['Diabetes management review'],
     NOW() - INTERVAL '7 days', NOW() - INTERVAL '7 days' + INTERVAL '30 min',
     'https://telehealth.hcpmg.com/session/ghi789', 'MTG-GHI789',
     'Bring glucose log from last 2 weeks.', 'Diabetes follow-up',
     true, true),

    -- Future appointment
    (v_appt_future, gen_random_uuid(), v_pat_john, 'booked',
     '11429006', 'Consultation',
     '394814009', 'General practice', 'FOLLOWUP',
     ARRAY['38341003'], ARRAY['Hypertension follow-up'],
     NOW() + INTERVAL '14 days', NOW() + INTERVAL '14 days' + INTERVAL '30 min',
     'https://telehealth.hcpmg.com/session/future01', 'MTG-FUT001',
     'Please check your blood pressure daily and record values.', 'BP follow-up',
     false, false);


-- ============================================================
-- APPOINTMENT PARTICIPANTS
-- ============================================================
INSERT INTO appointment_participants
    (appointment_id, type_code, type_display, actor_practitioner_id, actor_patient_id, required, status)
VALUES
    (v_appt_john1,  'ATND', 'Attending', v_dr_chen,    NULL,        'required', 'accepted'),
    (v_appt_john1,  'PART', 'Patient',   NULL,          v_pat_john,  'required', 'accepted'),
    (v_appt_sarah1, 'ATND', 'Attending', v_dr_chen,    NULL,        'required', 'accepted'),
    (v_appt_sarah1, 'PART', 'Patient',   NULL,          v_pat_sarah, 'required', 'accepted'),
    (v_appt_maria1, 'ATND', 'Attending', v_dr_chen,    NULL,        'required', 'accepted'),
    (v_appt_maria1, 'PART', 'Patient',   NULL,          v_pat_maria, 'required', 'accepted'),
    (v_appt_future, 'ATND', 'Attending', v_dr_chen,    NULL,        'required', 'accepted'),
    (v_appt_future, 'PART', 'Patient',   NULL,          v_pat_john,  'required', 'needs_action');


-- ============================================================
-- NOTIFICATION PREFERENCES
-- ============================================================
INSERT INTO notification_preferences
    (patient_id, appointment_reminders, appointment_reminder_hours,
     lab_results_available, prescription_status, message_received,
     channels, timezone)
VALUES
    (v_pat_john,  true, ARRAY[24,2], true, true, true, ARRAY['email','sms']::notification_channel[], 'America/Chicago'),
    (v_pat_sarah, true, ARRAY[24,2], true, true, true, ARRAY['email','push']::notification_channel[], 'America/Chicago'),
    (v_pat_maria, true, ARRAY[24],   true, true, true, ARRAY['sms']::notification_channel[], 'America/Chicago');


-- ============================================================
-- ENCOUNTERS (Telehealth Visits)
-- ============================================================
INSERT INTO encounters
    (id, fhir_id, patient_id, status, class,
     type_code, type_display, service_type_code, service_type_display,
     primary_practitioner_id, organization_id,
     period_start, period_end,
     appointment_id,
     reason_codes, reason_displays,
     telehealth_platform, telehealth_session_id,
     chief_complaint, assessment_plan)
VALUES
    (v_enc_john1, gen_random_uuid(), v_pat_john,
     'finished', 'virtual',
     '11429006', 'Consultation', '394814009', 'General practice',
     v_dr_chen, v_org_main,
     NOW() - INTERVAL '30 days', NOW() - INTERVAL '30 days' + INTERVAL '28 min',
     v_appt_john1,
     ARRAY['38341003'], ARRAY['Essential hypertension'],
     'native', 'SESSION-JOHN-001',
     'Patient reports blood pressure has been elevated at home, averaging 145/92.',
     'BP remains above target. Increase lisinopril to 20mg. Continue dietary modifications. Follow up in 4 weeks.'),

    (v_enc_sarah1, gen_random_uuid(), v_pat_sarah,
     'finished', 'virtual',
     '185349003', 'Annual wellness visit', '394814009', 'General practice',
     v_dr_chen, v_org_main,
     NOW() - INTERVAL '14 days', NOW() - INTERVAL '14 days' + INTERVAL '42 min',
     v_appt_sarah1,
     ARRAY['185349003'], ARRAY['Encounter for check-up'],
     'native', 'SESSION-SARAH-001',
     'Annual wellness exam. Patient reports feeling well. No acute complaints.',
     'All wellness screenings up to date. BMI 22.4 (normal). Ordered routine labs.'),

    (v_enc_maria1, gen_random_uuid(), v_pat_maria,
     'finished', 'virtual',
     '11429006', 'Consultation', '394814009', 'General practice',
     v_dr_chen, v_org_main,
     NOW() - INTERVAL '7 days', NOW() - INTERVAL '7 days' + INTERVAL '31 min',
     v_appt_maria1,
     ARRAY['73211009'], ARRAY['Type 2 diabetes mellitus'],
     'native', 'SESSION-MARIA-001',
     'Diabetes management review. HbA1c from last month was 7.8%. Patient reports some hypoglycemic episodes.',
     'HbA1c trending down from 8.4% to 7.8% — good progress. Adjusted metformin timing. Ordered repeat HbA1c in 3 months. Referred to endocrinology.'),

    (v_enc_maria2, gen_random_uuid(), v_pat_maria,
     'finished', 'virtual',
     '11429006', 'Consultation', '394579002', 'Cardiology',
     v_dr_roberts, v_org_hospital,
     NOW() - INTERVAL '60 days', NOW() - INTERVAL '60 days' + INTERVAL '25 min',
     NULL,
     ARRAY['44054006','38341003'], ARRAY['Type 2 diabetes','Hypertension'],
     'native', 'SESSION-MARIA-CARD-001',
     'Cardiology consult for diabetic patient with hypertension. EKG sent prior to visit.',
     'EKG normal. No signs of cardiac involvement. Continue current BP medications. Annual stress test recommended.');


-- Update appointments with encounter links
UPDATE appointments SET encounter_id = v_enc_john1  WHERE id = v_appt_john1;
UPDATE appointments SET encounter_id = v_enc_sarah1 WHERE id = v_appt_sarah1;
UPDATE appointments SET encounter_id = v_enc_maria1 WHERE id = v_appt_maria1;


-- ============================================================
-- ENCOUNTER PARTICIPANTS
-- ============================================================
INSERT INTO encounter_participants
    (encounter_id, practitioner_id, type_code, type_display,
     period_start, period_end)
VALUES
    (v_enc_john1,  v_dr_chen,    'ATND', 'Attender', NOW() - INTERVAL '30 days', NOW() - INTERVAL '30 days' + INTERVAL '28 min'),
    (v_enc_sarah1, v_dr_chen,    'ATND', 'Attender', NOW() - INTERVAL '14 days', NOW() - INTERVAL '14 days' + INTERVAL '42 min'),
    (v_enc_maria1, v_dr_chen,    'ATND', 'Attender', NOW() - INTERVAL '7 days',  NOW() - INTERVAL '7 days'  + INTERVAL '31 min'),
    (v_enc_maria2, v_dr_roberts, 'ATND', 'Attender', NOW() - INTERVAL '60 days', NOW() - INTERVAL '60 days' + INTERVAL '25 min');


-- ============================================================
-- CONDITIONS / DIAGNOSES
-- ============================================================
INSERT INTO conditions
    (patient_id, encounter_id, clinical_status, verification_status,
     category_code, severity_code, severity_display,
     code_system, code, code_display,
     onset_date_time, recorded_date, recorder_id,
     is_principal_diagnosis, is_chronic, note)
VALUES
    -- John: Hypertension
    (v_pat_john, v_enc_john1, 'active', 'confirmed',
     'problem-list-item', '6736007', 'Moderate',
     'ICD-10-CM', 'I10', 'Essential (primary) hypertension',
     '2020-03-10', '2020-03-10', v_dr_chen,
     false, true, 'Patient monitors BP at home. Goal <130/80 mmHg.'),

    -- John: Hyperlipidemia
    (v_pat_john, v_enc_john1, 'active', 'confirmed',
     'problem-list-item', '255604002', 'Mild',
     'ICD-10-CM', 'E78.5', 'Hyperlipidemia, unspecified',
     '2021-06-15', '2021-06-15', v_dr_chen,
     false, true, 'On statin therapy. LDL target <100 mg/dL.'),

    -- Sarah: Anxiety disorder
    (v_pat_sarah, v_enc_sarah1, 'active', 'confirmed',
     'problem-list-item', '255604002', 'Mild',
     'ICD-10-CM', 'F41.1', 'Generalized anxiety disorder',
     '2023-02-20', '2023-02-20', v_dr_chen,
     false, false, 'Managed with therapy. No pharmacological treatment at this time.'),

    -- Sarah: Migraine
    (v_pat_sarah, v_enc_sarah1, 'active', 'confirmed',
     'problem-list-item', '6736007', 'Moderate',
     'ICD-10-CM', 'G43.909', 'Migraine, unspecified, not intractable, without status migrainosus',
     '2022-08-05', '2022-08-05', v_dr_chen,
     false, false, 'Episodic migraines ~2x/month. Triggers: stress, dehydration.'),

    -- Maria: Type 2 Diabetes
    (v_pat_maria, v_enc_maria1, 'active', 'confirmed',
     'problem-list-item', '6736007', 'Moderate',
     'ICD-10-CM', 'E11.65', 'Type 2 diabetes mellitus with hyperglycemia',
     '2015-09-12', '2015-09-12', v_dr_chen,
     true, true, 'HbA1c target <7.5%. Currently 7.8%.'),

    -- Maria: Hypertension
    (v_pat_maria, v_enc_maria2, 'active', 'confirmed',
     'problem-list-item', '6736007', 'Moderate',
     'ICD-10-CM', 'I10', 'Essential (primary) hypertension',
     '2016-03-20', '2016-03-20', v_dr_chen,
     false, true, 'BP target <130/80 for diabetic patient.'),

    -- Maria: CKD Stage 2
    (v_pat_maria, v_enc_maria2, 'active', 'confirmed',
     'problem-list-item', '6736007', 'Moderate',
     'ICD-10-CM', 'N18.2', 'Chronic kidney disease, stage 2 (mild)',
     '2021-01-15', '2021-01-15', v_dr_roberts,
     false, true, 'Related to long-standing diabetes. Annual nephrology referral.');


-- ============================================================
-- ALLERGY / INTOLERANCES
-- ============================================================
INSERT INTO allergy_intolerances
    (patient_id, clinical_status, verification_status, allergy_type,
     categories, criticality, code_system, code, code_display,
     recorder_id, recorded_date, last_occurrence)
VALUES
    (v_pat_john, 'active', 'confirmed', 'allergy',
     ARRAY['medication']::allergy_category[],
     'high', 'RxNorm', '7980', 'Penicillin',
     v_dr_chen, '2015-05-10', '2015-05-10'),

    (v_pat_sarah, 'active', 'confirmed', 'intolerance',
     ARRAY['food']::allergy_category[],
     'low', 'SNOMED-CT', '102259006', 'Caffeine',
     v_dr_chen, '2022-03-15', NULL),

    (v_pat_maria, 'active', 'confirmed', 'allergy',
     ARRAY['medication']::allergy_category[],
     'high', 'RxNorm', '1191', 'Aspirin',
     v_dr_chen, '2010-07-20', '2010-07-20'),

    (v_pat_maria, 'active', 'confirmed', 'intolerance',
     ARRAY['food']::allergy_category[],
     'low', 'SNOMED-CT', '227493005', 'Shellfish',
     v_dr_chen, '2005-01-01', NULL);


-- ============================================================
-- ALLERGY REACTIONS
-- ============================================================
INSERT INTO allergy_reactions
    (allergy_intolerance_id, substance_display, manifestation_code,
     manifestation_system, manifestation_display, severity, description)
SELECT ai.id, ai.code_display,
    CASE ai.code WHEN '7980' THEN '39579001' WHEN '1191' THEN '126485001' ELSE '271807003' END,
    'SNOMED-CT',
    CASE ai.code WHEN '7980' THEN 'Anaphylaxis' WHEN '1191' THEN 'Urticaria' ELSE 'Rash' END,
    CASE ai.code WHEN '7980' THEN 'severe' WHEN '1191' THEN 'moderate' ELSE 'mild' END::reaction_severity,
    CASE ai.code WHEN '7980' THEN 'Anaphylactic reaction requiring epinephrine in 2015'
                 WHEN '1191' THEN 'Hives and stomach pain within 1 hour of ingestion'
                 ELSE 'Mild GI discomfort' END
FROM allergy_intolerances ai
WHERE ai.patient_id IN (v_pat_john, v_pat_maria, v_pat_sarah);


-- ============================================================
-- IMMUNIZATIONS
-- ============================================================
INSERT INTO immunizations
    (patient_id, status, vaccine_code_system, vaccine_code, vaccine_display,
     occurrence_date_time, performer_id, performer_org_id,
     lot_number, site_display, route_display, dose_quantity, dose_unit,
     series_name, dose_number_in_series, series_doses_recommended)
VALUES
    (v_pat_john, 'completed', 'CVX', '141', 'Influenza, seasonal, injectable',
     '2024-10-05 10:00:00', v_dr_chen, v_org_main,
     'LOT-FLU-2024A', 'Left arm', 'Intramuscular injection', 0.5, 'mL',
     'Annual Influenza', 1, 1),

    (v_pat_john, 'completed', 'CVX', '212', 'COVID-19 mRNA vaccine, bivalent booster',
     '2024-09-15 09:30:00', v_dr_chen, v_org_main,
     'LOT-COV-BIV-001', 'Right arm', 'Intramuscular injection', 0.3, 'mL',
     'COVID-19 Bivalent Booster', 1, 1),

    (v_pat_sarah, 'completed', 'CVX', '141', 'Influenza, seasonal, injectable',
     '2024-10-12 14:00:00', v_dr_chen, v_org_main,
     'LOT-FLU-2024B', 'Left arm', 'Intramuscular injection', 0.5, 'mL',
     'Annual Influenza', 1, 1),

    (v_pat_maria, 'completed', 'CVX', '141', 'Influenza, seasonal, injectable',
     '2024-10-02 11:00:00', v_dr_chen, v_org_main,
     'LOT-FLU-2024A', 'Left arm', 'Intramuscular injection', 0.5, 'mL',
     'Annual Influenza', 1, 1),

    (v_pat_maria, 'completed', 'CVX', '33', 'Pneumococcal polysaccharide PPV23',
     '2023-03-20 10:00:00', v_dr_chen, v_org_main,
     'LOT-PNV-2023A', 'Right arm', 'Intramuscular injection', 0.5, 'mL',
     'Pneumococcal vaccination', 1, 1);


-- ============================================================
-- OBSERVATIONS — Vital Signs
-- ============================================================
INSERT INTO observations
    (id, fhir_id, patient_id, encounter_id, status,
     category_code, category_display,
     code_system, code, code_display,
     effective_date_time, issued, performer_id,
     value_quantity, value_quantity_unit, value_quantity_code,
     interpretation_code, interpretation_display,
     reference_range_low, reference_range_high,
     created_at)
VALUES
    -- John visit vitals
    (gen_random_uuid(), gen_random_uuid(), v_pat_john, v_enc_john1, 'final',
     'vital-signs', 'Vital Signs', 'http://loinc.org', '8480-6', 'Systolic Blood Pressure',
     NOW() - INTERVAL '30 days', NOW() - INTERVAL '30 days', v_dr_chen,
     142, 'mmHg', 'mm[Hg]', 'H', 'High', 90, 120,
     NOW() - INTERVAL '30 days'),

    (gen_random_uuid(), gen_random_uuid(), v_pat_john, v_enc_john1, 'final',
     'vital-signs', 'Vital Signs', 'http://loinc.org', '8462-4', 'Diastolic Blood Pressure',
     NOW() - INTERVAL '30 days', NOW() - INTERVAL '30 days', v_dr_chen,
     91, 'mmHg', 'mm[Hg]', 'H', 'High', 60, 80,
     NOW() - INTERVAL '30 days'),

    (gen_random_uuid(), gen_random_uuid(), v_pat_john, v_enc_john1, 'final',
     'vital-signs', 'Vital Signs', 'http://loinc.org', '8867-4', 'Heart Rate',
     NOW() - INTERVAL '30 days', NOW() - INTERVAL '30 days', v_dr_chen,
     74, 'bpm', '/min', 'N', 'Normal', 60, 100,
     NOW() - INTERVAL '30 days'),

    (gen_random_uuid(), gen_random_uuid(), v_pat_john, v_enc_john1, 'final',
     'vital-signs', 'Vital Signs', 'http://loinc.org', '29463-7', 'Body Weight',
     NOW() - INTERVAL '30 days', NOW() - INTERVAL '30 days', v_dr_chen,
     82.5, 'kg', 'kg', 'N', 'Normal', NULL, NULL,
     NOW() - INTERVAL '30 days'),

    -- Sarah vitals
    (gen_random_uuid(), gen_random_uuid(), v_pat_sarah, v_enc_sarah1, 'final',
     'vital-signs', 'Vital Signs', 'http://loinc.org', '8480-6', 'Systolic Blood Pressure',
     NOW() - INTERVAL '14 days', NOW() - INTERVAL '14 days', v_dr_chen,
     118, 'mmHg', 'mm[Hg]', 'N', 'Normal', 90, 120,
     NOW() - INTERVAL '14 days'),

    (gen_random_uuid(), gen_random_uuid(), v_pat_sarah, v_enc_sarah1, 'final',
     'vital-signs', 'Vital Signs', 'http://loinc.org', '8462-4', 'Diastolic Blood Pressure',
     NOW() - INTERVAL '14 days', NOW() - INTERVAL '14 days', v_dr_chen,
     76, 'mmHg', 'mm[Hg]', 'N', 'Normal', 60, 80,
     NOW() - INTERVAL '14 days'),

    (gen_random_uuid(), gen_random_uuid(), v_pat_sarah, v_enc_sarah1, 'final',
     'vital-signs', 'Vital Signs', 'http://loinc.org', '39156-5', 'Body Mass Index (BMI)',
     NOW() - INTERVAL '14 days', NOW() - INTERVAL '14 days', v_dr_chen,
     22.4, 'kg/m2', 'kg/m2', 'N', 'Normal', 18.5, 24.9,
     NOW() - INTERVAL '14 days'),

    -- Maria vitals
    (gen_random_uuid(), gen_random_uuid(), v_pat_maria, v_enc_maria1, 'final',
     'vital-signs', 'Vital Signs', 'http://loinc.org', '8480-6', 'Systolic Blood Pressure',
     NOW() - INTERVAL '7 days', NOW() - INTERVAL '7 days', v_dr_chen,
     135, 'mmHg', 'mm[Hg]', 'H', 'High', 90, 120,
     NOW() - INTERVAL '7 days'),

    (gen_random_uuid(), gen_random_uuid(), v_pat_maria, v_enc_maria1, 'final',
     'vital-signs', 'Vital Signs', 'http://loinc.org', '8462-4', 'Diastolic Blood Pressure',
     NOW() - INTERVAL '7 days', NOW() - INTERVAL '7 days', v_dr_chen,
     84, 'mmHg', 'mm[Hg]', 'H', 'High', 60, 80,
     NOW() - INTERVAL '7 days'),

    (gen_random_uuid(), gen_random_uuid(), v_pat_maria, v_enc_maria1, 'final',
     'vital-signs', 'Vital Signs', 'http://loinc.org', '72514-3', 'Pain Severity 0-10',
     NOW() - INTERVAL '7 days', NOW() - INTERVAL '7 days', v_dr_chen,
     1, '/10', '{score}', 'N', 'Normal', 0, 3,
     NOW() - INTERVAL '7 days');


-- ============================================================
-- OBSERVATIONS — Lab Results
-- ============================================================
INSERT INTO observations
    (id, fhir_id, patient_id, encounter_id, status,
     category_code, category_display,
     code_system, code, code_display,
     effective_date_time, issued, performer_id,
     value_quantity, value_quantity_unit, value_quantity_code,
     interpretation_code, interpretation_display,
     reference_range_low, reference_range_high,
     created_at)
VALUES
    -- John: HbA1c
    (gen_random_uuid(), gen_random_uuid(), v_pat_john, NULL, 'final',
     'laboratory', 'Laboratory', 'http://loinc.org', '4548-4', 'Hemoglobin A1c/Hemoglobin.total in Blood',
     NOW() - INTERVAL '25 days', NOW() - INTERVAL '25 days', v_dr_chen,
     5.4, '%', '%', 'N', 'Normal', NULL, 5.7,
     NOW() - INTERVAL '25 days'),

    -- John: Total Cholesterol
    (gen_random_uuid(), gen_random_uuid(), v_pat_john, NULL, 'final',
     'laboratory', 'Laboratory', 'http://loinc.org', '2093-3', 'Cholesterol [Mass/volume] in Serum or Plasma',
     NOW() - INTERVAL '25 days', NOW() - INTERVAL '25 days', v_dr_chen,
     210, 'mg/dL', 'mg/dL', 'H', 'High', NULL, 200,
     NOW() - INTERVAL '25 days'),

    -- John: LDL
    (gen_random_uuid(), gen_random_uuid(), v_pat_john, NULL, 'final',
     'laboratory', 'Laboratory', 'http://loinc.org', '13457-7', 'Cholesterol in LDL [Mass/volume] in Serum or Plasma by calculation',
     NOW() - INTERVAL '25 days', NOW() - INTERVAL '25 days', v_dr_chen,
     128, 'mg/dL', 'mg/dL', 'H', 'High', NULL, 100,
     NOW() - INTERVAL '25 days'),

    -- Maria: HbA1c
    (gen_random_uuid(), gen_random_uuid(), v_pat_maria, v_enc_maria1, 'final',
     'laboratory', 'Laboratory', 'http://loinc.org', '4548-4', 'Hemoglobin A1c/Hemoglobin.total in Blood',
     NOW() - INTERVAL '35 days', NOW() - INTERVAL '35 days', v_dr_chen,
     7.8, '%', '%', 'H', 'High', NULL, 7.5,
     NOW() - INTERVAL '35 days'),

    -- Maria: Creatinine
    (gen_random_uuid(), gen_random_uuid(), v_pat_maria, NULL, 'final',
     'laboratory', 'Laboratory', 'http://loinc.org', '2160-0', 'Creatinine [Mass/volume] in Serum or Plasma',
     NOW() - INTERVAL '35 days', NOW() - INTERVAL '35 days', v_dr_chen,
     1.3, 'mg/dL', 'mg/dL', 'H', 'High', 0.5, 1.1,
     NOW() - INTERVAL '35 days'),

    -- Sarah: TSH
    (gen_random_uuid(), gen_random_uuid(), v_pat_sarah, v_enc_sarah1, 'final',
     'laboratory', 'Laboratory', 'http://loinc.org', '3016-3', 'Thyrotropin [Units/volume] in Serum or Plasma',
     NOW() - INTERVAL '12 days', NOW() - INTERVAL '12 days', v_dr_chen,
     2.1, 'mIU/L', 'mIU/L', 'N', 'Normal', 0.4, 4.0,
     NOW() - INTERVAL '12 days');


-- ============================================================
-- MEDICATION REQUESTS (Prescriptions)
-- ============================================================
INSERT INTO medication_requests
    (patient_id, encounter_id, status, intent,
     medication_code_system, medication_code, medication_display,
     medication_brand_name, medication_strength,
     is_controlled_substance, requester_id,
     dosage_text, dosage_patient_instruction,
     dosage_timing_code, dosage_route_display,
     dosage_dose_value, dosage_dose_unit,
     dispense_quantity_value, dispense_quantity_unit,
     dispense_refills_allowed, dispense_days_supply,
     dispense_validity_start, dispense_validity_end,
     substitution_allowed_boolean,
     reason_codes, reason_displays, note)
VALUES
    -- John: Lisinopril (BP)
    (v_pat_john, v_enc_john1, 'active', 'order',
     'http://www.nlm.nih.gov/research/umls/rxnorm', '29046', 'Lisinopril',
     'Zestril', '20 mg',
     false, v_dr_chen,
     'Take one tablet by mouth once daily in the morning',
     'Take 1 tablet every morning. Do not skip doses.',
     'QD', 'Oral', 20, 'mg',
     90, 'tablet', 3, 90,
     CURRENT_DATE, CURRENT_DATE + 365,
     true,
     ARRAY['I10'], ARRAY['Essential hypertension'], 'Increased dose from 10mg due to inadequate BP control.'),

    -- John: Atorvastatin (cholesterol)
    (v_pat_john, v_enc_john1, 'active', 'order',
     'http://www.nlm.nih.gov/research/umls/rxnorm', '617310', 'Atorvastatin',
     'Lipitor', '40 mg',
     false, v_dr_chen,
     'Take one tablet by mouth once daily at bedtime',
     'Take 1 tablet every night at bedtime.',
     'QD', 'Oral', 40, 'mg',
     90, 'tablet', 3, 90,
     CURRENT_DATE, CURRENT_DATE + 365,
     true,
     ARRAY['E78.5'], ARRAY['Hyperlipidemia'], 'LDL target <100 mg/dL.'),

    -- Sarah: Sumatriptan (migraine)
    (v_pat_sarah, v_enc_sarah1, 'active', 'order',
     'http://www.nlm.nih.gov/research/umls/rxnorm', '41493', 'Sumatriptan',
     'Imitrex', '50 mg',
     false, v_dr_chen,
     'Take one tablet at onset of migraine. May repeat in 2 hours if needed. Max 2 tablets/24h.',
     'Take 1 tablet when migraine starts. Can take a 2nd tablet 2 hours later if needed.',
     NULL, 'Oral', 50, 'mg',
     9, 'tablet', 2, 90,
     CURRENT_DATE, CURRENT_DATE + 365,
     true,
     ARRAY['G43.909'], ARRAY['Migraine'], 'PRN for acute migraine attacks.'),

    -- Maria: Metformin (diabetes)
    (v_pat_maria, v_enc_maria1, 'active', 'order',
     'http://www.nlm.nih.gov/research/umls/rxnorm', '860974', 'Metformin Hydrochloride',
     'Glucophage', '1000 mg',
     false, v_dr_chen,
     'Take one tablet by mouth twice daily with meals',
     'Take 1 tablet with breakfast and 1 tablet with dinner.',
     'BID', 'Oral', 1000, 'mg',
     60, 'tablet', 5, 30,
     CURRENT_DATE, CURRENT_DATE + 365,
     true,
     ARRAY['E11.65'], ARRAY['Type 2 diabetes mellitus'], 'Changed timing to with meals to reduce GI side effects.'),

    -- Maria: Lisinopril (BP + kidney protection)
    (v_pat_maria, v_enc_maria2, 'active', 'order',
     'http://www.nlm.nih.gov/research/umls/rxnorm', '29046', 'Lisinopril',
     'Zestril', '10 mg',
     false, v_dr_roberts,
     'Take one tablet by mouth once daily',
     'Take 1 tablet every morning.',
     'QD', 'Oral', 10, 'mg',
     90, 'tablet', 3, 90,
     CURRENT_DATE, CURRENT_DATE + 365,
     true,
     ARRAY['I10','N18.2'], ARRAY['Hypertension','CKD stage 2'], 'ACE inhibitor preferred for diabetic nephroprotection.');


-- ============================================================
-- SERVICE REQUESTS (Lab Orders)
-- ============================================================
INSERT INTO service_requests
    (id, fhir_id, patient_id, encounter_id, status, intent,
     category_code, category_display, priority,
     code_system, code, code_display,
     requester_id, requester_org_id,
     authored_on, patient_instruction,
     result_available, result_available_at)
VALUES
    (v_srq_john1, gen_random_uuid(), v_pat_john, v_enc_john1,
     'completed', 'order', 'laboratory', 'Laboratory', 'routine',
     'http://loinc.org', '24331-1', 'Lipid Panel',
     v_dr_chen, v_org_main,
     NOW() - INTERVAL '30 days',
     'Fast for 12 hours before blood draw. Water is okay.',
     true, NOW() - INTERVAL '25 days'),

    (v_srq_maria1, gen_random_uuid(), v_pat_maria, v_enc_maria1,
     'completed', 'order', 'laboratory', 'Laboratory', 'routine',
     'http://loinc.org', '24323-8', 'Comprehensive Metabolic Panel',
     v_dr_chen, v_org_main,
     NOW() - INTERVAL '7 days',
     'Fast for 8 hours. Morning visit to the lab preferred.',
     true, NOW() - INTERVAL '35 days');


-- ============================================================
-- DIAGNOSTIC REPORTS
-- ============================================================
INSERT INTO diagnostic_reports
    (id, fhir_id, patient_id, encounter_id, service_request_id,
     status, category_code, category_display,
     code_system, code, code_display,
     effective_date_time, issued,
     performer_id, performer_org_id,
     conclusion, conclusion_code, conclusion_code_display)
VALUES
    (v_drep_john1, gen_random_uuid(), v_pat_john, v_enc_john1, v_srq_john1,
     'final', 'LAB', 'Laboratory',
     'http://loinc.org', '24331-1', 'Lipid Panel',
     NOW() - INTERVAL '25 days', NOW() - INTERVAL '25 days',
     v_dr_chen, v_org_lab,
     'Total cholesterol mildly elevated at 210 mg/dL. LDL 128 mg/dL above target of 100 mg/dL. Continue statin therapy and dietary modifications.',
     'E78.5', 'Hyperlipidemia'),

    (v_drep_maria1, gen_random_uuid(), v_pat_maria, v_enc_maria1, v_srq_maria1,
     'final', 'LAB', 'Laboratory',
     'http://loinc.org', '24323-8', 'Comprehensive Metabolic Panel',
     NOW() - INTERVAL '35 days', NOW() - INTERVAL '35 days',
     v_dr_chen, v_org_lab,
     'HbA1c 7.8% - above target of 7.5% for patient age. Creatinine mildly elevated at 1.3 mg/dL consistent with CKD stage 2. eGFR 62. Monitor closely.',
     'E11.65', 'Type 2 diabetes mellitus with hyperglycemia');


-- ============================================================
-- CARE TEAMS
-- ============================================================
INSERT INTO care_teams
    (id, fhir_id, patient_id, status, name, category_code, managing_org_id,
     period_start)
VALUES
    (v_team_john, gen_random_uuid(), v_pat_john, 'active',
     'John Smith Primary Care Team', 'longitudinal',
     v_org_main, '2020-03-10'),

    (v_team_maria, gen_random_uuid(), v_pat_maria, 'active',
     'Maria Garcia Chronic Disease Management Team', 'longitudinal',
     v_org_main, '2015-09-12');

INSERT INTO care_team_participants
    (care_team_id, role_code, role_display, practitioner_id, period_start, is_active)
VALUES
    (v_team_john,  '446050000', 'Primary Care Physician', v_dr_chen,    '2020-03-10', true),
    (v_team_maria, '446050000', 'Primary Care Physician', v_dr_chen,    '2015-09-12', true),
    (v_team_maria, '17561000',  'Cardiologist',           v_dr_roberts, '2021-01-15', true);


-- ============================================================
-- CARE PLANS
-- ============================================================
INSERT INTO care_plans
    (id, fhir_id, patient_id, encounter_id, status, intent,
     title, description, period_start,
     created_by_id,
     addresses_condition_ids,
     goals,
     activities,
     note)
VALUES
    (v_cp_maria, gen_random_uuid(), v_pat_maria, v_enc_maria1,
     'active', 'plan',
     'Diabetes & Hypertension Management Plan',
     'Comprehensive management plan for Type 2 Diabetes with comorbid hypertension and early CKD.',
     CURRENT_DATE,
     v_dr_chen,
     ARRAY[]::UUID[],
     ARRAY[
         'Achieve HbA1c < 7.5% within 6 months',
         'Maintain blood pressure < 130/80 mmHg',
         'Preserve kidney function (eGFR stable)',
         'Complete annual diabetic eye exam',
         'Walk 30 minutes daily 5 days/week'
     ],
     '[
         {"category":"medication","status":"active","description":"Continue Metformin 1000mg BID with meals","scheduled_date":null},
         {"category":"medication","status":"active","description":"Continue Lisinopril 10mg QD for BP and kidney protection","scheduled_date":null},
         {"category":"observation","status":"active","description":"Home BP monitoring daily - log results","scheduled_date":null},
         {"category":"procedure","status":"planned","description":"HbA1c recheck in 3 months","scheduled_date":"2026-09-13"},
         {"category":"referral","status":"planned","description":"Annual ophthalmology referral for diabetic eye exam","scheduled_date":"2026-12-01"},
         {"category":"education","status":"completed","description":"Diabetes self-management education completed","scheduled_date":null}
     ]'::jsonb,
     'Patient is engaged and motivated. Spanish interpreter available for all visits.');


-- ============================================================
-- SECURE MESSAGES
-- ============================================================
INSERT INTO message_threads
    (id, patient_id, practitioner_id, subject, is_urgent, last_message_at)
VALUES
    (v_thread1, v_pat_john,  v_dr_chen,    'Question about blood pressure medication', false, NOW() - INTERVAL '5 days'),
    (v_thread2, v_pat_maria, v_dr_chen,    'Glucose readings and medication timing',   false, NOW() - INTERVAL '2 days');

INSERT INTO messages
    (thread_id, sender_practitioner_id, recipient_patient_id,
     body, body_hash, status, sent_at, delivered_at, read_at, is_urgent)
VALUES
    (v_thread1, v_dr_chen, v_pat_john,
     pgp_sym_encrypt('Hello John, regarding your lisinopril increase to 20mg — please check your BP every morning for the next 2 weeks and share those readings with me. Call us immediately if you experience dizziness or a persistent dry cough, as those can be side effects. Looking forward to your follow-up in 2 weeks.', v_enc_key)::bytea,
     hmac('message_1', v_enc_key, 'sha256'),
     'read', NOW() - INTERVAL '5 days', NOW() - INTERVAL '5 days', NOW() - INTERVAL '4 days', false),

    (v_thread2, v_dr_chen, v_pat_maria,
     pgp_sym_encrypt('Hola Maria, revisando sus lecturas de glucosa. El cambio de horario de la metformina (tomarlo con las comidas) debería ayudar con las molestias estomacales. Por favor registre sus niveles de azúcar en ayunas cada mañana. Su próximo control de HbA1c está programado en 3 meses. ¿Tiene alguna pregunta?', v_enc_key)::bytea,
     hmac('message_2', v_enc_key, 'sha256'),
     'delivered', NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days', NULL, false);

-- Update thread counters
UPDATE message_threads SET message_count = 1, unread_count = 0 WHERE id = v_thread1;
UPDATE message_threads SET message_count = 1, unread_count = 1 WHERE id = v_thread2;


-- ============================================================
-- NOTIFICATIONS
-- ============================================================
INSERT INTO notifications
    (id, patient_id, channel, status, notification_type,
     title, body, data,
     related_resource_type, related_resource_id,
     scheduled_for, sent_at, delivered_at, read_at,
     created_at)
VALUES
    (gen_random_uuid(), v_pat_john, 'email', 'read',
     'appointment_reminder',
     'Appointment Reminder — Tomorrow at 10:00 AM',
     'You have a telehealth appointment with Dr. Emily Chen tomorrow. Join here: https://telehealth.hcpmg.com/session/future01',
     '{"appointment_type":"FOLLOWUP","practitioner":"Dr. Emily Chen"}'::jsonb,
     'Appointment', v_appt_future,
     NOW() - INTERVAL '15 days' + INTERVAL '24 hours',
     NOW() - INTERVAL '15 days' + INTERVAL '24 hours',
     NOW() - INTERVAL '15 days' + INTERVAL '24 hours',
     NOW() - INTERVAL '14 days',
     NOW() - INTERVAL '15 days'),

    (gen_random_uuid(), v_pat_john, 'sms', 'delivered',
     'lab_results_available',
     'Your Lab Results Are Ready',
     'Your Lipid Panel results from LabCorp are now available in your patient portal.',
     '{"report_type":"Lipid Panel","lab":"LabCorp"}'::jsonb,
     'DiagnosticReport', v_drep_john1,
     NOW() - INTERVAL '25 days',
     NOW() - INTERVAL '25 days',
     NOW() - INTERVAL '25 days',
     NULL,
     NOW() - INTERVAL '25 days'),

    (gen_random_uuid(), v_pat_maria, 'sms', 'delivered',
     'message_received',
     'New Message from Dr. Emily Chen',
     'You have a new secure message from Dr. Emily Chen. Log in to view it.',
     '{"thread_subject":"Glucose readings and medication timing"}'::jsonb,
     'Communication', v_thread2,
     NOW() - INTERVAL '2 days',
     NOW() - INTERVAL '2 days',
     NOW() - INTERVAL '2 days',
     NULL,
     NOW() - INTERVAL '2 days');


-- ============================================================
-- AUDIT — PHI Access Log samples
-- ============================================================
INSERT INTO phi_access_log
    (id, accessed_at, accessor_type, accessor_id, accessor_name,
     accessor_role, patient_id, resource_type, resource_id,
     action, fields_accessed, purpose,
     ip_address, session_id, was_authorized)
VALUES
    (gen_random_uuid(), NOW() - INTERVAL '30 days',
     'practitioner', v_dr_chen, 'Dr. Emily Chen', 'clinician',
     v_pat_john, 'Encounter', v_enc_john1,
     'view', ARRAY['chief_complaint','assessment_plan','period_start'], 'TPO',
     '10.0.1.55', 'SESSION-CHEN-001', true),

    (gen_random_uuid(), NOW() - INTERVAL '7 days',
     'practitioner', v_dr_chen, 'Dr. Emily Chen', 'clinician',
     v_pat_maria, 'Observation', NULL,
     'view', ARRAY['value_quantity','code_display','interpretation_code'], 'TPO',
     '10.0.1.55', 'SESSION-CHEN-002', true),

    (gen_random_uuid(), NOW() - INTERVAL '1 day',
     'patient', v_acct_john, 'John Smith', 'patient',
     v_pat_john, 'MedicationRequest', NULL,
     'view', ARRAY['medication_display','dosage_text'], 'TPO',
     '192.168.1.100', 'SESSION-PAT-001', true);

END;
$$;

COMMIT;

-- ============================================================
-- VERIFY: Quick row count across all schemas
-- ============================================================
SELECT
    schemaname                  AS schema,
    relname                     AS "table",
    n_live_tup                  AS approx_rows
FROM pg_stat_user_tables
WHERE schemaname IN ('patient','clinical','billing','portal','audit')
ORDER BY schemaname, relname;
