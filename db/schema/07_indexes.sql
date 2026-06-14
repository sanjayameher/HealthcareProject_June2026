-- ============================================================
-- SECTION 8 — INDEXES
-- Strategy:
--   B-Tree  : Equality / range on scalar columns (default)
--   GIN     : Array columns, JSONB, full-text search
--   GiST    : Exclusion constraints, date ranges, geographic
--   BRIN    : Monotonically increasing timestamps on large tables
--   Trigram : Fuzzy name / medication search (pg_trgm)
-- ============================================================

-- ── patient schema ────────────────────────────────────────────
SET search_path TO dev, public;

-- ── organizations ────────────────────────────────────────────
CREATE INDEX idx_orgs_name_trgm         ON organizations USING GIN (name gin_trgm_ops);
CREATE INDEX idx_orgs_npi               ON organizations (npi) WHERE npi IS NOT NULL;
CREATE INDEX idx_orgs_type              ON organizations (type_code) WHERE deleted_at IS NULL;
CREATE INDEX idx_orgs_parent            ON organizations (parent_org_id) WHERE parent_org_id IS NOT NULL;
CREATE INDEX idx_orgs_active            ON organizations (active) WHERE deleted_at IS NULL;

-- ── practitioners ────────────────────────────────────────────
CREATE INDEX idx_pract_family_trgm      ON practitioners USING GIN (family_name gin_trgm_ops);
CREATE INDEX idx_pract_npi              ON practitioners (npi) WHERE npi IS NOT NULL;
CREATE INDEX idx_pract_org              ON practitioners (organization_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_pract_specialty        ON practitioners USING GIN (specialty_codes);
CREATE INDEX idx_pract_active           ON practitioners (active) WHERE deleted_at IS NULL;

-- ── patients ─────────────────────────────────────────────────
CREATE UNIQUE INDEX idx_patients_mrn    ON patients (mrn) WHERE deleted_at IS NULL;
CREATE INDEX idx_patients_fhir_id       ON patients (fhir_id);
CREATE INDEX idx_patients_gender_dob    ON patients (gender, birth_date) WHERE deleted_at IS NULL;
CREATE INDEX idx_patients_managing_org  ON patients (managing_organization_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_patients_active        ON patients (active) WHERE deleted_at IS NULL;

-- ── patient_identifiers ──────────────────────────────────────
CREATE INDEX idx_pat_ids_patient        ON patient_identifiers (patient_id);
CREATE INDEX idx_pat_ids_system_hash    ON patient_identifiers (system, value_hash);
-- Lookup pattern: WHERE system = 'ssn' AND value_hash = hmac(input, key)

-- ── patient_names ────────────────────────────────────────────
CREATE INDEX idx_pat_names_patient      ON patient_names (patient_id);
CREATE INDEX idx_pat_names_family_trgm  ON patient_names USING GIN (family gin_trgm_ops);
CREATE INDEX idx_pat_names_primary      ON patient_names (patient_id) WHERE is_primary = true;

-- ── patient_addresses ────────────────────────────────────────
CREATE INDEX idx_pat_addr_patient       ON patient_addresses (patient_id);
CREATE INDEX idx_pat_addr_state_zip     ON patient_addresses (state, postal_code);
CREATE INDEX idx_pat_addr_geo           ON patient_addresses (latitude, longitude)
    WHERE latitude IS NOT NULL AND longitude IS NOT NULL;
CREATE INDEX idx_pat_addr_primary       ON patient_addresses (patient_id) WHERE is_primary = true;

-- ── patient_telecoms ─────────────────────────────────────────
CREATE INDEX idx_pat_tel_patient        ON patient_telecoms (patient_id);
CREATE INDEX idx_pat_tel_system_hash    ON patient_telecoms (system, value_hash);
-- Lookup: WHERE system = 'email' AND value_hash = hmac(input, key)

-- ── patient_contacts ─────────────────────────────────────────
CREATE INDEX idx_pat_contacts_patient   ON patient_contacts (patient_id);
CREATE INDEX idx_pat_contacts_priority  ON patient_contacts (patient_id, priority) WHERE is_active = true;

-- ── patient_flags ────────────────────────────────────────────
CREATE INDEX idx_pat_flags_patient      ON patient_flags (patient_id) WHERE status = 'active';
CREATE INDEX idx_pat_flags_code         ON patient_flags (code) WHERE status = 'active';

-- ── billing schema ────────────────────────────────────────────
SET search_path TO dev, public;

-- ── coverage ─────────────────────────────────────────────────
CREATE INDEX idx_coverage_patient       ON coverage (patient_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_coverage_patient_type  ON coverage (patient_id, type) WHERE status = 'active';
CREATE INDEX idx_coverage_payer         ON coverage (payer_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_coverage_period        ON coverage (period_start, period_end) WHERE deleted_at IS NULL;
CREATE INDEX idx_coverage_primary       ON coverage (patient_id) WHERE is_primary = true AND status = 'active';
CREATE INDEX idx_coverage_sub_hash      ON coverage (subscriber_id_hash);

-- ── eligibility_checks ───────────────────────────────────────
CREATE INDEX idx_elig_coverage          ON eligibility_checks (coverage_id);
CREATE INDEX idx_elig_patient_date      ON eligibility_checks (patient_id, checked_at DESC);

-- ── clinical schema ───────────────────────────────────────────
SET search_path TO dev, public;

-- ── encounters ──────────────────────────────────────────────
CREATE INDEX idx_enc_patient            ON encounters (patient_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_enc_patient_status     ON encounters (patient_id, status) WHERE deleted_at IS NULL;
CREATE INDEX idx_enc_period             ON encounters (period_start DESC, period_end DESC);
CREATE INDEX idx_enc_practitioner       ON encounters (primary_practitioner_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_enc_org                ON encounters (organization_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_enc_appointment        ON encounters (appointment_id) WHERE appointment_id IS NOT NULL;
CREATE INDEX idx_enc_class_status       ON encounters (class, status) WHERE deleted_at IS NULL;
-- BRIN for very large tables — efficient on monotonic created_at
CREATE INDEX idx_enc_created_brin       ON encounters USING BRIN (created_at);

-- ── observations (per partition — inherited) ────────────────
-- NOTE: Index created on parent propagates to all partitions
CREATE INDEX idx_obs_patient_code       ON observations (patient_id, code, created_at DESC);
CREATE INDEX idx_obs_patient_cat        ON observations (patient_id, category_code, created_at DESC);
CREATE INDEX idx_obs_encounter          ON observations (encounter_id) WHERE encounter_id IS NOT NULL;
CREATE INDEX idx_obs_effective          ON observations (patient_id, effective_date_time DESC);
CREATE INDEX idx_obs_status             ON observations (status) WHERE status != 'entered_in_error';
CREATE INDEX idx_obs_specimen           ON observations (specimen_id) WHERE specimen_id IS NOT NULL;
-- BRIN on partition key (created_at)
CREATE INDEX idx_obs_created_brin       ON observations USING BRIN (created_at);

-- ── conditions ──────────────────────────────────────────────
CREATE INDEX idx_cond_patient           ON conditions (patient_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_cond_patient_active    ON conditions (patient_id) WHERE clinical_status = 'active' AND deleted_at IS NULL;
CREATE INDEX idx_cond_code              ON conditions (code_system, code) WHERE deleted_at IS NULL;
CREATE INDEX idx_cond_encounter         ON conditions (encounter_id) WHERE encounter_id IS NOT NULL;
CREATE INDEX idx_cond_chronic           ON conditions (patient_id) WHERE is_chronic = true AND deleted_at IS NULL;
-- Composite for problem list
CREATE INDEX idx_cond_problem_list      ON conditions (patient_id, clinical_status, category_code)
    WHERE category_code = 'problem-list-item' AND deleted_at IS NULL;

-- ── allergy_intolerances ────────────────────────────────────
CREATE INDEX idx_allergy_patient        ON allergy_intolerances (patient_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_allergy_active         ON allergy_intolerances (patient_id) WHERE clinical_status = 'active' AND deleted_at IS NULL;
CREATE INDEX idx_allergy_code           ON allergy_intolerances (code) WHERE deleted_at IS NULL;
CREATE INDEX idx_allergy_criticality    ON allergy_intolerances (patient_id, criticality) WHERE clinical_status = 'active';

-- ── immunizations ───────────────────────────────────────────
CREATE INDEX idx_immun_patient          ON immunizations (patient_id);
CREATE INDEX idx_immun_vaccine_code     ON immunizations (vaccine_code, occurrence_date_time DESC);
CREATE INDEX idx_immun_patient_vaccine  ON immunizations (patient_id, vaccine_code);

-- ── medication_requests ─────────────────────────────────────
CREATE INDEX idx_medrx_patient          ON medication_requests (patient_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_medrx_patient_active   ON medication_requests (patient_id) WHERE status = 'active' AND deleted_at IS NULL;
CREATE INDEX idx_medrx_encounter        ON medication_requests (encounter_id) WHERE encounter_id IS NOT NULL;
CREATE INDEX idx_medrx_requester        ON medication_requests (requester_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_medrx_medication_trgm  ON medication_requests USING GIN (medication_display gin_trgm_ops);
CREATE INDEX idx_medrx_code             ON medication_requests (medication_code_system, medication_code);
CREATE INDEX idx_medrx_controlled       ON medication_requests (patient_id, dea_schedule)
    WHERE is_controlled_substance = true AND deleted_at IS NULL;

-- ── service_requests ────────────────────────────────────────
CREATE INDEX idx_srq_patient            ON service_requests (patient_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_srq_patient_active     ON service_requests (patient_id) WHERE status = 'active' AND deleted_at IS NULL;
CREATE INDEX idx_srq_encounter          ON service_requests (encounter_id) WHERE encounter_id IS NOT NULL;
CREATE INDEX idx_srq_category           ON service_requests (category_code, status) WHERE deleted_at IS NULL;
CREATE INDEX idx_srq_result_pending     ON service_requests (patient_id) WHERE result_available = false AND status = 'active';

-- ── diagnostic_reports ──────────────────────────────────────
CREATE INDEX idx_drep_patient           ON diagnostic_reports (patient_id);
CREATE INDEX idx_drep_service_req       ON diagnostic_reports (service_request_id);
CREATE INDEX idx_drep_issued            ON diagnostic_reports (patient_id, issued DESC);

-- ── documents ───────────────────────────────────────────────
CREATE INDEX idx_doc_patient            ON documents (patient_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_doc_encounter          ON documents (encounter_id) WHERE encounter_id IS NOT NULL;
CREATE INDEX idx_doc_type               ON documents (type_code) WHERE status = 'current';
CREATE INDEX idx_doc_authored           ON documents (patient_id, authored_at DESC) WHERE status = 'current';

-- ── portal schema ─────────────────────────────────────────────
SET search_path TO dev, public;

-- ── appointments ──────────────────────────────────────────────
CREATE INDEX idx_appt_patient           ON appointments (patient_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_appt_patient_upcoming  ON appointments (patient_id, start_time)
    WHERE status IN ('booked', 'arrived', 'checked_in') AND deleted_at IS NULL;
CREATE INDEX idx_appt_start_time        ON appointments (start_time) WHERE deleted_at IS NULL;
CREATE INDEX idx_appt_status            ON appointments (status) WHERE deleted_at IS NULL;
CREATE INDEX idx_appt_reminders         ON appointments (start_time, reminder_24h_sent, reminder_2h_sent)
    WHERE status = 'booked' AND deleted_at IS NULL;

-- ── consents ──────────────────────────────────────────────────
CREATE INDEX idx_consent_patient        ON consents (patient_id);
CREATE INDEX idx_consent_active         ON consents (patient_id) WHERE status = 'active';
CREATE INDEX idx_consent_scope          ON consents (patient_id, scope_code) WHERE status = 'active';

-- ── message_threads ───────────────────────────────────────────
CREATE INDEX idx_thread_patient         ON message_threads (patient_id);
CREATE INDEX idx_thread_last_msg        ON message_threads (patient_id, last_message_at DESC);
CREATE INDEX idx_thread_unread          ON message_threads (patient_id) WHERE unread_count > 0;

-- ── messages ──────────────────────────────────────────────────
CREATE INDEX idx_msg_thread             ON messages (thread_id, sent_at DESC);
CREATE INDEX idx_msg_sender_patient     ON messages (sender_patient_id) WHERE sender_patient_id IS NOT NULL;
CREATE INDEX idx_msg_recipient_patient  ON messages (recipient_patient_id) WHERE recipient_patient_id IS NOT NULL;
CREATE INDEX idx_msg_unread             ON messages (thread_id) WHERE status = 'delivered' AND read_at IS NULL;

-- ── notifications ─────────────────────────────────────────────
CREATE INDEX idx_notif_patient_pending  ON notifications (patient_id, scheduled_for)
    WHERE status = 'pending';
CREATE INDEX idx_notif_patient_unread   ON notifications (patient_id) WHERE read_at IS NULL AND status = 'delivered';
CREATE INDEX idx_notif_created_brin     ON notifications USING BRIN (created_at);

-- ── audit schema ──────────────────────────────────────────────
SET search_path TO dev, public;

-- ── audit_events ─────────────────────────────────────────────
CREATE INDEX idx_audit_patient          ON audit_events (patient_id, recorded DESC) WHERE patient_id IS NOT NULL;
CREATE INDEX idx_audit_entity           ON audit_events (entity_type, entity_id, recorded DESC);
CREATE INDEX idx_audit_agent            ON audit_events (agent_user_id, recorded DESC) WHERE agent_user_id IS NOT NULL;
CREATE INDEX idx_audit_action_recorded  ON audit_events (action, recorded DESC);
CREATE INDEX idx_audit_outcome          ON audit_events (outcome, recorded DESC) WHERE outcome != 'success';
CREATE INDEX idx_audit_recorded_brin    ON audit_events USING BRIN (recorded);

-- ── phi_access_log ─────────────────────────────────────────
CREATE INDEX idx_phi_patient            ON phi_access_log (patient_id, accessed_at DESC);
CREATE INDEX idx_phi_accessor           ON phi_access_log (accessor_id, accessed_at DESC);
CREATE INDEX idx_phi_breach             ON phi_access_log (patient_id, accessed_at DESC) WHERE breach_indicator = true;
CREATE INDEX idx_phi_unauthorized       ON phi_access_log (accessed_at DESC) WHERE was_authorized = false;
CREATE INDEX idx_phi_accessed_brin      ON phi_access_log USING BRIN (accessed_at);
