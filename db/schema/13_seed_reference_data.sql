-- ============================================================
-- SECTION 14 — REFERENCE / SEED DATA
-- Non-PHI reference records safe to populate at schema init:
--   • Common vital sign LOINC codes
--   • FHIR observation categories
--   • US states lookup
--   • Telehealth appointment types
-- ============================================================

-- ── Common LOINC Vital Signs Reference ────────────────────────
-- Stored as a reference table consumed by the UI and validation

SET search_path TO dev, public;

CREATE TABLE IF NOT EXISTS loinc_vital_signs (
    loinc_code      TEXT        PRIMARY KEY,
    display         TEXT        NOT NULL,
    unit_ucum       TEXT,
    unit_display    TEXT,
    normal_low      NUMERIC(10,2),
    normal_high     NUMERIC(10,2),
    critical_low    NUMERIC(10,2),
    critical_high   NUMERIC(10,2),
    sort_order      SMALLINT    NOT NULL DEFAULT 99
);

INSERT INTO loinc_vital_signs VALUES
-- code          display                        UCUM       display       low   high  c-low  c-high  sort
('8302-2',   'Body Height',                   'cm',      'cm',          NULL, NULL, NULL,  NULL,   1),
('29463-7',  'Body Weight',                   'kg',      'kg',          NULL, NULL, NULL,  NULL,   2),
('39156-5',  'Body Mass Index (BMI)',          'kg/m2',   'kg/m²',       18.5, 24.9, NULL,  NULL,   3),
('8480-6',   'Systolic Blood Pressure',        'mm[Hg]',  'mmHg',        90,   120,  70,    180,    4),
('8462-4',   'Diastolic Blood Pressure',       'mm[Hg]',  'mmHg',        60,   80,   40,    110,    5),
('8867-4',   'Heart Rate',                    '/min',    'bpm',          60,   100,  40,    150,    6),
('9279-1',   'Respiratory Rate',              '/min',    'breaths/min',  12,   20,   8,     30,     7),
('59408-5',  'Oxygen Saturation (Pulse Ox)',   '%',       '%',            95,   100,  88,    NULL,   8),
('8310-5',   'Body Temperature',              'Cel',     '°C',           36.1, 37.2, 35.0,  39.5,   9),
('72514-3',  'Pain Severity (0-10 scale)',     '{score}', '/10',          NULL, 3,    NULL,  10,     10),
('8306-3',   'Head Circumference (infant)',    'cm',      'cm',           NULL, NULL, NULL,  NULL,   11);


-- ── Common Lab LOINC Panels (reference, not exhaustive) ──────

CREATE TABLE IF NOT EXISTS loinc_lab_panels (
    panel_loinc     TEXT        PRIMARY KEY,
    panel_display   TEXT        NOT NULL,
    category        TEXT        NOT NULL,
    component_loincs TEXT[]     NOT NULL DEFAULT '{}'
);

INSERT INTO loinc_lab_panels VALUES
('58410-2', 'CBC with differential panel', 'hematology',
    ARRAY['6690-2','789-8','787-2','785-6','786-4','788-0','770-6','736-7','5905-5','713-8','706-2','4544-3','718-7']),
('24323-8', 'Comprehensive Metabolic Panel (CMP)', 'chemistry',
    ARRAY['2160-0','17861-6','3094-0','2345-7','2028-9','6768-6','2885-2','17656-0','2951-2','2823-3','2075-0','1751-7','1742-6','1920-8','2571-8']),
('4548-4',  'Hemoglobin A1c (HbA1c)', 'endocrinology',
    ARRAY['4548-4']),
('24331-1', 'Lipid Panel', 'cardiology',
    ARRAY['2093-3','13457-7','2085-9','2571-8','9830-1']),
('5792-7',  'Urinalysis macro panel', 'urinalysis',
    ARRAY['5794-3','5767-9','5769-5','5811-5','5778-6','5792-7','33903-8']),
('57021-8', 'CBC without differential', 'hematology',
    ARRAY['6690-2','789-8','787-2','785-6','786-4','788-0','4544-3','718-7']),
('2160-0',  'Creatinine [Mass/volume] in Serum or Plasma', 'chemistry',
    ARRAY['2160-0']),
('33914-3', 'eGFR (CKD-EPI)', 'chemistry',
    ARRAY['33914-3']),
('2093-3',  'Cholesterol Total', 'cardiology',
    ARRAY['2093-3']);


-- ── US States Reference ───────────────────────────────────────

SET search_path TO dev, public;

CREATE TABLE IF NOT EXISTS us_states (
    abbreviation    VARCHAR(2)  PRIMARY KEY,
    name            TEXT        NOT NULL,
    fips_code       VARCHAR(2)
);

INSERT INTO us_states VALUES
('AL','Alabama','01'),('AK','Alaska','02'),('AZ','Arizona','04'),('AR','Arkansas','05'),
('CA','California','06'),('CO','Colorado','08'),('CT','Connecticut','09'),('DE','Delaware','10'),
('FL','Florida','12'),('GA','Georgia','13'),('HI','Hawaii','15'),('ID','Idaho','16'),
('IL','Illinois','17'),('IN','Indiana','18'),('IA','Iowa','19'),('KS','Kansas','20'),
('KY','Kentucky','21'),('LA','Louisiana','22'),('ME','Maine','23'),('MD','Maryland','24'),
('MA','Massachusetts','25'),('MI','Michigan','26'),('MN','Minnesota','27'),('MS','Mississippi','28'),
('MO','Missouri','29'),('MT','Montana','30'),('NE','Nebraska','31'),('NV','Nevada','32'),
('NH','New Hampshire','33'),('NJ','New Jersey','34'),('NM','New Mexico','35'),('NY','New York','36'),
('NC','North Carolina','37'),('ND','North Dakota','38'),('OH','Ohio','39'),('OK','Oklahoma','40'),
('OR','Oregon','41'),('PA','Pennsylvania','42'),('RI','Rhode Island','44'),('SC','South Carolina','45'),
('SD','South Dakota','46'),('TN','Tennessee','47'),('TX','Texas','48'),('UT','Utah','49'),
('VT','Vermont','50'),('VA','Virginia','51'),('WA','Washington','53'),('WV','West Virginia','54'),
('WI','Wisconsin','55'),('WY','Wyoming','56'),('DC','District of Columbia','11'),
('PR','Puerto Rico','72'),('GU','Guam','66'),('VI','U.S. Virgin Islands','78');


-- ── Telehealth Appointment Types ─────────────────────────────

SET search_path TO dev, public;

CREATE TABLE IF NOT EXISTS appointment_type_codes (
    code        TEXT    PRIMARY KEY,
    display     TEXT    NOT NULL,
    description TEXT,
    is_telehealth BOOLEAN NOT NULL DEFAULT false
);

INSERT INTO appointment_type_codes VALUES
('ROUTINE',     'Routine Visit',            'Scheduled routine consultation', true),
('FOLLOWUP',    'Follow-up',                'Follow-up after prior encounter', true),
('CHECKUP',     'Annual Wellness Visit',    'Preventive annual health check',  true),
('URGENT',      'Urgent Care Visit',        'Same-day urgent consultation',    true),
('EMERGENCY',   'Emergency Consultation',   'Emergent telehealth triage',      true),
('PRESCRIPTION','Prescription Renewal',     'Medication renewal discussion',   true),
('LABORDER',    'Lab Review',               'Review of laboratory results',    true),
('MENTALHEALTH','Mental Health Session',    'Behavioral health telehealth',    true),
('NEWPATIENT',  'New Patient Visit',        'Initial consultation',            true),
('WALKIN',      'Walk-in',                  'Unscheduled in-person visit',     false);
