-- ============================================================
-- DIGITAL HEALTH PLATFORM — PATIENT MODULE
-- Master Execution Script
-- PostgreSQL 16+  |  HIPAA-Compliant  |  FHIR R4-Aligned
-- ============================================================
-- Run as superuser or a role with CREATE SCHEMA/EXTENSION rights
-- Usage:
--   psql -U postgres -d healthdb -f 00_master.sql
-- ============================================================

\set ON_ERROR_STOP on
\set QUIET on

\echo '→ [0/13] Extensions and schemas...'
\i 00_extensions_and_schemas.sql

\echo '→ [1/13] Enumerated types...'
\i 01_enums.sql

\echo '→ [2/13] Patient schema (organizations, practitioners, demographics)...'
\i 02_patient_schema.sql

\echo '→ [3/13] Billing schema (payers, coverage, eligibility)...'
\i 03_billing_schema.sql

\echo '→ [4/13] Clinical schema (encounters, observations, conditions, orders)...'
\i 04_clinical_schema.sql

\echo '→ [5/13] Portal schema (accounts, consents, appointments, messaging)...'
\i 05_portal_schema.sql

\echo '→ [6/13] Audit schema (audit events, PHI access log, change history)...'
\i 06_audit_schema.sql

\echo '→ [7/13] Indexes...'
\i 07_indexes.sql

\echo '→ [8/13] Row-level security policies...'
\i 08_rls_policies.sql

\echo '→ [9/13] Triggers...'
\i 09_triggers.sql

\echo '→ [10/13] Views and materialized views...'
\i 10_views.sql

\echo '→ [11/13] Utility functions...'
\i 11_functions.sql

\echo '→ [12/13] Roles and privilege grants...'
\i 12_roles_and_grants.sql

\echo '→ [13/13] Reference / seed data...'
\i 13_seed_reference_data.sql

\echo ''
\echo '✓ Patient module schema deployed successfully.'
\echo ''
\echo 'Post-deployment checklist:'
\echo '  □ Rotate all service account passwords in 12_roles_and_grants.sql'
\echo '  □ Configure external key management (AWS KMS / HashiCorp Vault)'
\echo '  □ Set up pg_cron for: mv_patient_care_gaps refresh (nightly)'
\echo '  □ Set up pg_partman for: observations + audit_events auto-partitioning'
\echo '  □ Configure archive/pg_dump retention policy (6 yr HIPAA minimum)'
\echo '  □ Enable SSL (ssl=on, ssl_cert_file, ssl_key_file in postgresql.conf)'
\echo '  □ Set pgaudit.log in postgresql.conf for DB-level statement auditing'
\echo '  □ Apply network-level encryption (TLS 1.3 between app and DB)'
\echo '  □ Test RLS policies with all four role contexts before go-live'
