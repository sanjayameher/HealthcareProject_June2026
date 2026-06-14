-- ============================================================
-- DIGITAL HEALTH PLATFORM — PATIENT MODULE
-- PostgreSQL 16+ | HIPAA-Compliant | FHIR R4-Aligned
-- ============================================================
-- Schema Version : 1.0.0
-- Last Updated   : 2026-06-13
-- Standards      : FHIR R4, ICD-10-CM, LOINC, RxNorm, CVX,
--                  SNOMED CT, HL7 v2, NUCC Taxonomy, BCP-47
-- Compliance     : HIPAA Privacy & Security Rules,
--                  HITECH Act, 21st Century Cures Act
-- ============================================================

-- ============================================================
-- SECTION 0 — EXTENSIONS
-- ============================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";      -- UUID generation
CREATE EXTENSION IF NOT EXISTS "pgcrypto";        -- Symmetric/asymmetric encryption, hashing
CREATE EXTENSION IF NOT EXISTS "btree_gist";      -- Exclusion constraints on ranges
CREATE EXTENSION IF NOT EXISTS "pg_trgm";         -- Trigram indexes for fuzzy name search
CREATE EXTENSION IF NOT EXISTS "citext";          -- Case-insensitive text (emails)
CREATE EXTENSION IF NOT EXISTS "intarray";        -- Integer array operations

-- ============================================================
-- SECTION 1 — SCHEMA NAMESPACE
-- ============================================================

-- dev : Single consolidated schema for all healthcare platform tables

CREATE SCHEMA IF NOT EXISTS dev;

COMMENT ON SCHEMA dev IS 'Consolidated development schema containing all healthcare platform tables (patient, clinical, billing, portal, audit)';
