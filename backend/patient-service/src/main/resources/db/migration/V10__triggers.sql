-- ============================================================
-- SECTION 10 — TRIGGERS
-- 1. updated_at auto-maintenance
-- 2. FHIR metadata sync (version_id, last_updated)
-- 3. Audit trail (data_change_history) for clinical tables
-- 4. PHI access auto-logging
-- 5. Patient account security (brute-force lockout)
-- 6. Appointment reminder flag reset on reschedule
-- 7. Message thread counters
-- ============================================================

-- ── 10.1  Generic updated_at trigger ─────────────────────────

CREATE OR REPLACE FUNCTION public.fn_set_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql AS
$$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;

-- Apply to all tables with updated_at
DO $$ DECLARE t TEXT; BEGIN
    FOREACH t IN ARRAY ARRAY[
        'organizations',
        'practitioners',
        'patients',
        'patient_identifiers',
        'patient_contacts',
        'payers',
        'coverage',
        'encounters',
        'conditions',
        'allergy_intolerances',
        'medication_requests',
        'medication_dispenses',
        'service_requests',
        'documents',
        'care_plans',
        'care_teams',
        'patient_accounts',
        'consents',
        'appointments',
        'message_threads',
        'notification_preferences',
        'notifications'
    ]
    LOOP
        EXECUTE format(
            'CREATE TRIGGER trg_set_updated_at
             BEFORE UPDATE ON %s
             FOR EACH ROW EXECUTE FUNCTION public.fn_set_updated_at()',
            t
        );
    END LOOP;
END $$;


-- ── 10.2  FHIR metadata trigger ──────────────────────────────
-- Bumps fhir_version_id (sequential) and fhir_last_updated on every change

CREATE OR REPLACE FUNCTION public.fn_fhir_metadata()
RETURNS TRIGGER
LANGUAGE plpgsql AS
$$
BEGIN
    NEW.fhir_version_id   = (COALESCE(OLD.fhir_version_id, '0')::BIGINT + 1)::TEXT;
    NEW.fhir_last_updated = NOW();
    RETURN NEW;
END;
$$;

DO $$ DECLARE t TEXT; BEGIN
    FOREACH t IN ARRAY ARRAY[
        'organizations',
        'practitioners',
        'patients',
        'coverage',
        'encounters',
        'conditions',
        'allergy_intolerances',
        'medication_requests',
        'service_requests',
        'diagnostic_reports',
        'care_plans',
        'care_teams',
        'documents',
        'immunizations',
        'consents',
        'appointments'
    ]
    LOOP
        EXECUTE format(
            'CREATE TRIGGER trg_fhir_metadata
             BEFORE UPDATE ON %s
             FOR EACH ROW EXECUTE FUNCTION public.fn_fhir_metadata()',
            t
        );
    END LOOP;
END $$;


-- ── 10.3  Optimistic locking (version bump) ──────────────────

CREATE OR REPLACE FUNCTION public.fn_bump_version()
RETURNS TRIGGER
LANGUAGE plpgsql AS
$$
BEGIN
    IF NEW.version IS NOT DISTINCT FROM OLD.version THEN
        NEW.version = OLD.version + 1;
    ELSIF NEW.version != OLD.version + 1 THEN
        RAISE EXCEPTION 'Optimistic lock conflict: expected version %, got %',
                        OLD.version + 1, NEW.version
              USING ERRCODE = 'P0001';
    END IF;
    RETURN NEW;
END;
$$;

DO $$ DECLARE t TEXT; BEGIN
    FOREACH t IN ARRAY ARRAY[
        'patients',
        'coverage',
        'encounters',
        'conditions',
        'medication_requests',
        'appointments'
    ]
    LOOP
        EXECUTE format(
            'CREATE TRIGGER trg_optimistic_lock
             BEFORE UPDATE ON %s
             FOR EACH ROW EXECUTE FUNCTION public.fn_bump_version()',
            t
        );
    END LOOP;
END $$;


-- ── 10.4  Audit change history for clinical data ─────────────
-- Captures before/after JSON for INSERT/UPDATE/DELETE on clinical tables

SET search_path TO dev, public;

CREATE OR REPLACE FUNCTION fn_log_data_change()
RETURNS TRIGGER
LANGUAGE plpgsql SECURITY DEFINER AS
$$
DECLARE
    v_old       JSONB   := NULL;
    v_new       JSONB   := NULL;
    v_changed   TEXT[]  := '{}';
    v_key       TEXT;
    v_patient   UUID;
BEGIN
    IF TG_OP = 'INSERT' THEN
        v_new := to_jsonb(NEW);
    ELSIF TG_OP = 'UPDATE' THEN
        v_old := to_jsonb(OLD);
        v_new := to_jsonb(NEW);
        -- Capture only changed columns
        SELECT array_agg(key)
          INTO v_changed
          FROM jsonb_each_text(v_old)
         WHERE value IS DISTINCT FROM (v_new ->> key);
    ELSIF TG_OP = 'DELETE' THEN
        v_old := to_jsonb(OLD);
    END IF;

    -- Extract patient_id if present
    v_patient := CASE
        WHEN v_new ? 'patient_id' THEN (v_new->>'patient_id')::UUID
        WHEN v_old ? 'patient_id' THEN (v_old->>'patient_id')::UUID
        ELSE NULL
    END;

    INSERT INTO data_change_history (
        changed_at, table_schema, table_name, record_id,
        operation, changed_by_type, changed_by_id, changed_by_name,
        patient_id, old_values, new_values, changed_columns,
        session_id, request_id
    ) VALUES (
        NOW(), TG_TABLE_SCHEMA, TG_TABLE_NAME,
        COALESCE(
            (v_new->>'id')::UUID,
            (v_old->>'id')::UUID
        ),
        TG_OP,
        NULLIF(current_setting('app.user_role', true), '')::dev.accessor_type,
        NULLIF(current_setting('app.current_user_id', true), '')::UUID,
        current_setting('app.current_user_name', true),
        v_patient,
        v_old,
        v_new,
        v_changed,
        current_setting('app.session_id', true),
        current_setting('app.request_id', true)
    );

    RETURN COALESCE(NEW, OLD);
EXCEPTION WHEN OTHERS THEN
    -- Never let audit failure block clinical writes
    RAISE WARNING 'Audit log failed: %', SQLERRM;
    RETURN COALESCE(NEW, OLD);
END;
$$;

-- Apply audit trigger to sensitive clinical tables
DO $$ DECLARE t TEXT; BEGIN
    FOREACH t IN ARRAY ARRAY[
        'patients',
        'patient_identifiers',
        'conditions',
        'allergy_intolerances',
        'medication_requests',
        'service_requests',
        'diagnostic_reports',
        'documents',
        'coverage',
        'consents'
    ]
    LOOP
        EXECUTE format(
            'CREATE TRIGGER trg_audit_change
             AFTER INSERT OR UPDATE OR DELETE ON %s
             FOR EACH ROW EXECUTE FUNCTION fn_log_data_change()',
            t
        );
    END LOOP;
END $$;


-- ── 10.5  Patient account brute-force lockout ────────────────

SET search_path TO dev, public;

CREATE OR REPLACE FUNCTION fn_check_account_lockout()
RETURNS TRIGGER
LANGUAGE plpgsql AS
$$
BEGIN
    -- Lock account after 10 consecutive failures
    IF NEW.failed_login_attempts >= 10 AND OLD.failed_login_attempts < 10 THEN
        NEW.locked_until = NOW() + INTERVAL '30 minutes';
    END IF;
    -- Reset lockout when failures reset (successful login)
    IF NEW.failed_login_attempts = 0 THEN
        NEW.locked_until = NULL;
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_account_lockout
    BEFORE UPDATE OF failed_login_attempts ON patient_accounts
    FOR EACH ROW
    EXECUTE FUNCTION fn_check_account_lockout();


-- ── 10.6  Message thread counter maintenance ─────────────────

CREATE OR REPLACE FUNCTION fn_update_thread_counters()
RETURNS TRIGGER
LANGUAGE plpgsql SECURITY DEFINER AS
$$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE message_threads
           SET message_count   = message_count + 1,
               last_message_at = NEW.sent_at,
               unread_count    = unread_count + 1
         WHERE id = NEW.thread_id;
    ELSIF TG_OP = 'UPDATE' AND OLD.read_at IS NULL AND NEW.read_at IS NOT NULL THEN
        UPDATE message_threads
           SET unread_count = GREATEST(unread_count - 1, 0)
         WHERE id = NEW.thread_id;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE message_threads
           SET message_count = GREATEST(message_count - 1, 0)
         WHERE id = OLD.thread_id;
    END IF;
    RETURN COALESCE(NEW, OLD);
END;
$$;

CREATE TRIGGER trg_thread_counters
    AFTER INSERT OR UPDATE OF read_at OR DELETE ON messages
    FOR EACH ROW
    EXECUTE FUNCTION fn_update_thread_counters();


-- ── 10.7  Appointment reminder reset on reschedule ───────────

CREATE OR REPLACE FUNCTION fn_reset_reminders_on_reschedule()
RETURNS TRIGGER
LANGUAGE plpgsql AS
$$
BEGIN
    IF NEW.start_time IS DISTINCT FROM OLD.start_time THEN
        NEW.reminder_24h_sent    = false;
        NEW.reminder_2h_sent     = false;
        NEW.reminder_24h_sent_at = NULL;
        NEW.reminder_2h_sent_at  = NULL;
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_reset_reminders
    BEFORE UPDATE OF start_time ON appointments
    FOR EACH ROW
    EXECUTE FUNCTION fn_reset_reminders_on_reschedule();


-- ── 10.8  Prevent soft-deleted record modification ───────────

CREATE OR REPLACE FUNCTION public.fn_prevent_deleted_record_update()
RETURNS TRIGGER
LANGUAGE plpgsql AS
$$
BEGIN
    IF OLD.deleted_at IS NOT NULL THEN
        RAISE EXCEPTION 'Cannot modify a soft-deleted record (%.%, id=%)',
              TG_TABLE_SCHEMA, TG_TABLE_NAME, OLD.id
              USING ERRCODE = 'P0002';
    END IF;
    RETURN NEW;
END;
$$;

DO $$ DECLARE t TEXT; BEGIN
    FOREACH t IN ARRAY ARRAY[
        'patients',
        'encounters',
        'conditions',
        'medication_requests',
        'appointments',
        'documents'
    ]
    LOOP
        EXECUTE format(
            'CREATE TRIGGER trg_prevent_deleted_update
             BEFORE UPDATE ON %s
             FOR EACH ROW
             WHEN (OLD.deleted_at IS NOT NULL AND NEW.deleted_at IS NOT NULL)
             EXECUTE FUNCTION public.fn_prevent_deleted_record_update()',
            t
        );
    END LOOP;
END $$;


-- ── 10.9  Encounter result availability flag ─────────────────
-- When a diagnostic report is inserted/finalised → mark linked service request done

SET search_path TO dev, public;

CREATE OR REPLACE FUNCTION fn_mark_service_request_resulted()
RETURNS TRIGGER
LANGUAGE plpgsql SECURITY DEFINER AS
$$
BEGIN
    IF NEW.status = 'final' AND NEW.service_request_id IS NOT NULL THEN
        UPDATE service_requests
           SET result_available    = true,
               result_available_at = NOW(),
               status              = 'completed'
         WHERE id = NEW.service_request_id
           AND result_available = false;
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_service_request_resulted
    AFTER INSERT OR UPDATE OF status ON diagnostic_reports
    FOR EACH ROW
    WHEN (NEW.status = 'final')
    EXECUTE FUNCTION fn_mark_service_request_resulted();
