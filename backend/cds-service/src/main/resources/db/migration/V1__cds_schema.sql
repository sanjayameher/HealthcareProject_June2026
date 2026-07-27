-- ============================================================
-- CDS SERVICE — RAG-based Clinical Decision Support
-- Tables owned exclusively by cds-service (schema dev, shared DB)
-- ============================================================

CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION IF NOT EXISTS vector;

CREATE SCHEMA IF NOT EXISTS dev;

-- ============================================================
-- Knowledge base for retrieval-augmented generation
-- ============================================================

CREATE TABLE IF NOT EXISTS dev.cds_knowledge_chunks (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    source_type TEXT NOT NULL,          -- 'clinical_guideline' | 'drug_db' | 'allergy_contraindication' | 'icd10'
    source_ref  TEXT,                   -- e.g. guideline name, drug name
    content     TEXT NOT NULL,
    embedding   vector(768),            -- nomic-embed-text dimension
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS cds_knowledge_chunks_embedding_idx
    ON dev.cds_knowledge_chunks USING ivfflat (embedding vector_cosine_ops);

CREATE INDEX IF NOT EXISTS cds_knowledge_chunks_source_type_idx
    ON dev.cds_knowledge_chunks (source_type);

-- ============================================================
-- One row per "doctor asked CDS for a suggestion" interaction
-- ============================================================

CREATE TABLE IF NOT EXISTS dev.cds_diagnose_sessions (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id      UUID NOT NULL,
    doctor_id       UUID NOT NULL,
    input_payload   JSONB NOT NULL,
    llm_response    JSONB,
    status          TEXT NOT NULL DEFAULT 'pending',  -- pending | accepted | edited | discarded
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS cds_diagnose_sessions_patient_idx
    ON dev.cds_diagnose_sessions (patient_id);

CREATE INDEX IF NOT EXISTS cds_diagnose_sessions_doctor_idx
    ON dev.cds_diagnose_sessions (doctor_id);

-- ============================================================
-- Prescriptions confirmed by a doctor (accepted or edited CDS output)
-- ============================================================

CREATE TABLE IF NOT EXISTS dev.prescriptions (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    cds_session_id    UUID REFERENCES dev.cds_diagnose_sessions(id),
    patient_id        UUID NOT NULL,
    doctor_id         UUID NOT NULL,
    diagnosis_codes   TEXT[],
    drugs             JSONB NOT NULL,
    notes             TEXT,
    confirmed_at      TIMESTAMPTZ,
    created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS prescriptions_patient_idx
    ON dev.prescriptions (patient_id);
