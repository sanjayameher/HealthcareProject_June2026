# Feature Development Prompt — Multi-Role Healthcare Portal
## Aligned with Existing PostgreSQL Schema (`dev` schema)

---

## Project Context

You are extending an existing Java 21 / Spring Boot 3 / React 19 healthcare platform that is already
built on a FHIR R4-aligned PostgreSQL 16 schema in the `dev` schema. The existing database already
contains the following tables you must reuse and build on:

- `practitioners` — doctor/provider records (`active` boolean, `organization_id` FK, `gender`, `npi`, etc.)
- `patients` — patient demographics (HIPAA-compliant, PHI-encrypted columns)
- `patient_accounts` — patient portal authentication (`email` [AES-256-GCM encrypted], `email_hash`,
  `password_hash` [bcrypt], `is_active`, `must_change_password`, `failed_login_attempts`, `locked_until`, etc.)
- `appointments` — bookings with `status` enum (`proposed`, `pending`, `booked`, `arrived`, `fulfilled`,
  `cancelled`, `noshow`, `checked_in`, `waitlist`), `start_time`, `end_time`, `patient_id`, `slot_id`
- `appointment_participants` — links practitioners and patients to an appointment (`actor_practitioner_id`,
  `actor_patient_id`, `status` enum: `accepted`, `declined`, `tentative`, `needs_action`)
- `encounters` — clinical visit records, linked to appointments via `appointment_id`
- `medication_requests` — prescriptions (`status` enum: `active`, `on_hold`, `cancelled`, `completed`, etc.)
- `notifications` — outbound alerts (email, SMS, push, in_app) with `notification_type`, `scheduled_for`
- `notification_preferences` — per-patient channel settings
- DB roles: `db_admin`, `db_clinician`, `db_patient`, `db_system`, `db_auditor`

The application already has:
- `patient-service` (port 8081) — patient, practitioner, organization CRUD
- `clinical-service` (port 8082) — encounters, prescriptions
- `portal-service` (port 8084) — appointments, messages, consents
- `audit-service` (port 8085) — HIPAA audit trail
- `healthcare-ui` (React + Vite + TanStack Query, port 3000) — currently supports admin-facing
  patient and practitioner management

---

## New Tables Required

Before building features, add the following tables to the `dev` schema to support authentication
for practitioners and admins (patient auth already exists via `patient_accounts`):

### `practitioner_accounts`
Mirror the structure of `patient_accounts` but for doctors:
```
practitioner_id   UUID FK → practitioners.id  (UNIQUE, NOT NULL)
email             BYTEA  [PHI-ENCRYPTED]
email_hash        BYTEA  UNIQUE (for lookup)
email_verified    BOOLEAN DEFAULT false
password_hash     TEXT   (bcrypt, cost ≥ 12)
must_change_password BOOLEAN DEFAULT true   ← set true on admin-created accounts
is_active         BOOLEAN DEFAULT true
failed_login_attempts SMALLINT DEFAULT 0
locked_until      TIMESTAMPTZ
last_login_at     TIMESTAMPTZ
created_at / updated_at
```

### `admin_accounts`
```
id                UUID PK
email             TEXT UNIQUE NOT NULL (plain — admin email is not PHI)
password_hash     TEXT (bcrypt, cost ≥ 12)
full_name         TEXT NOT NULL
is_super_admin    BOOLEAN DEFAULT false
is_active         BOOLEAN DEFAULT true
must_change_password BOOLEAN DEFAULT false
created_by        UUID FK → admin_accounts.id (self-ref, nullable for root admin)
last_login_at     TIMESTAMPTZ
created_at / updated_at
```

### `practitioner_availability_slots`
For doctor calendar management (reuse `slot_id` FK already in `appointments`):
```
id                UUID PK
practitioner_id   UUID FK → practitioners.id
slot_date         DATE NOT NULL
start_time        TIME NOT NULL
end_time          TIME NOT NULL
is_available      BOOLEAN DEFAULT true    ← false = blocked/leave
slot_type         TEXT  (regular, leave, blocked)
recurrence_rule   TEXT  (iCal RRULE string for repeating slots)
max_appointments  SMALLINT DEFAULT 1
notes             TEXT
created_at / updated_at
UNIQUE (practitioner_id, slot_date, start_time)
```

---

## Role 1 — Hospital Admin

### 1.1 Admin Authentication

**Login page** (`/admin/login`):
- Email + password form
- On success → issue JWT with role `ADMIN`, redirect to `/admin/dashboard`
- Lock account after 5 failed attempts (update `admin_accounts.failed_login_attempts`)
- Super Admin is seeded via a startup script or `application-local.yml`

**Registration of new Admins** (`/admin/register` — Super Admin only):
- Super Admin (`is_super_admin = true`) can create new admin accounts
- Fields: Full Name, Email, Password (auto-generated or manually set)
- New admin account has `must_change_password = true`; they are forced to set a new password on first login

---

### 1.2 Doctor (Practitioner) Management

Reuses the existing `practitioners` table. Add a `practitioner_accounts` record when a doctor is
created or activated.

**List Doctors** (`/admin/doctors`):
- Table showing: Name, NPI, Specialty, Status (active/inactive), Last Login
- Filter by active/inactive, by organization
- Click row → Doctor Detail

**Add Doctor** (`/admin/doctors/new`):
- Fields map to `practitioners`: Given name, Family name, NPI, Gender, Specialty (`practitioner_roles`),
  Organization, Email (stored in `practitioner_accounts.email`)
- On save:
  1. INSERT into `practitioners` (set `active = true`)
  2. INSERT into `practitioner_accounts` (generate temp password, set `must_change_password = true`)
  3. Send email notification via `notifications` table (type: `doctor_welcome`, channel: `email`)
     containing a secure one-time link to `/doctor/set-password?token=<jwt>` so the doctor can set their password
- Validation: NPI must be 10 digits if provided; email must be unique across `practitioner_accounts`

**Edit Doctor** (`/admin/doctors/:id/edit`):
- Update `practitioners`: name fields, NPI, Gender, Organization
- Cannot change email through this form (separate flow)

**Activate / Deactivate Doctor**:
- Toggle `practitioners.active` AND `practitioner_accounts.is_active`
- Show confirmation dialog: "Deactivating Dr. Smith will prevent login and remove them from future
  appointment slots. Existing booked appointments are not cancelled automatically."
- Deactivation records `deactivated_at` timestamp

---

### 1.3 Patient Management

Reuses existing `patients` + `patient_accounts` tables.

**List Patients** (`/admin/patients`):
- Table: MRN, Name, DOB, Status, Last Login, Organization
- Filter by active/inactive
- Click row → Patient Detail (existing page, extend with Admin actions)

**Add Patient** (`/admin/patients/new`):
- Same 5-step wizard as existing `/patients/new`
- On save:
  1. INSERT into `patients` (existing flow)
  2. INSERT into `patient_accounts` (set `must_change_password = true`, `is_active = true`)
  3. Send welcome email via `notifications` (type: `patient_welcome`) with a one-time link
     to `/patient/set-password?token=<jwt>` so the patient can set their password

**Edit Patient**: existing `/patients/:id/edit` (unchanged)

**Activate / Deactivate Patient**:
- Toggle `patient_accounts.is_active`
- Sets `patient_accounts.deactivated_at` and `deactivation_reason`
- Confirmation dialog required

---

### 1.4 Doctor Availability Calendar Management (Admin View)

**Calendar page** (`/admin/doctors/:id/calendar`):
- Month/week view of the selected doctor's availability
- Reads from `practitioner_availability_slots` for the selected doctor
- Admin can:
  - Add availability blocks (date, start time, end time, slot type: `regular`)
  - Block time (mark slots as `is_available = false`, slot type: `leave` or `blocked`)
  - Delete a slot
- Slots that already have a booked appointment (`appointments` row with matching `slot_id`) are shown
  as "booked" and cannot be deleted

---

### 1.5 Appointment Booking (Admin)

**Book Appointment** (`/admin/appointments/new`):
- Step 1: Select Patient (search by MRN or name → `patients` table)
- Step 2: Select Doctor (search by name/specialty → `practitioners` where `active = true`)
- Step 3: Select Date → load available slots from `practitioner_availability_slots`
  where `is_available = true` and no booked appointment already occupies the slot
- Step 4: Confirm — Summary card showing patient, doctor, date/time, appointment type
- On confirm:
  1. INSERT into `appointments` (`patient_id`, `status = booked`, `start_time`, `end_time`, `slot_id`,
     `appointment_type_code`, `description`)
  2. INSERT into `appointment_participants` (one row `actor_practitioner_id`, one row `actor_patient_id`,
     both `status = accepted`)
  3. Mark `practitioner_availability_slots.is_available = false`
  4. INSERT notification for patient (type: `appointment_booked`, channel: `email`)
  5. INSERT notification for doctor (type: `appointment_assigned`, channel: `email`)

---

### 1.6 Appointment Queue — Assign Doctor

**Today's Queue** (`/admin/queue`):
- Lists all appointments for today where `status IN (booked, arrived, checked_in)`
- Each row shows: Patient name, appointment time, current status, assigned doctor
- Admin can:
  - **Change assigned doctor**: reassigns by updating `appointment_participants` (delete old practitioner
    row, insert new one) — only if `status != in_progress`
  - **Update appointment status**: move from `booked` → `arrived` → `checked_in` → (encounter created
    on check-in)
- Filter by doctor, by status

---

## Role 2 — Doctor (Practitioner) Portal

### 2.1 Doctor Authentication

**Login** (`/doctor/login`):
- Email + password against `practitioner_accounts`
- Issues JWT with role `CLINICIAN`, redirects to `/doctor/dashboard`
- On first login (`must_change_password = true`), force redirect to `/doctor/set-password`

**Set Password** (`/doctor/set-password`):
- Accepts `token` query param (one-time JWT issued at account creation)
- Sets new password, clears `must_change_password = true`

---

### 2.2 Doctor Dashboard (`/doctor/dashboard`)

Displays:
- Today's appointment queue (from `appointments` where this practitioner is a participant and date = today)
- Upcoming appointments (next 7 days)
- Pending prescriptions (from `medication_requests` where this practitioner is `requester_practitioner_id`
  and `status = draft`)

---

### 2.3 Create Prescription

**Prescription form** (`/doctor/prescriptions/new?patientId=&encounterId=`):
- Linked to an existing encounter (from `encounters` table where `primary_practitioner_id = current doctor`)
- Fields map to `medication_requests`:
  - Patient (auto-filled if `patientId` query param present)
  - Encounter (dropdown of this doctor's encounters for the patient)
  - Medication name / code (`medication_code_value`, `medication_display`)
  - Dosage instructions (`dosage_instruction_text`)
  - Frequency, route (`dosage_route_code`, `dosage_route_display`)
  - Start date, End date (`dispense_validity_period_start`, `dispense_validity_period_end`)
  - Quantity, refills (`dispense_quantity`, `refills_allowed`)
  - Notes (`note`)
  - Status defaults to `active`
- On save:
  1. INSERT into `medication_requests`
  2. INSERT notification to patient (type: `prescription_issued`, channel: `email` / `in_app`)

**Prescription list** (`/doctor/prescriptions`):
- Lists prescriptions issued by this doctor, grouped by patient
- Can update status (`active` → `on_hold` / `stopped` / `completed`)

---

### 2.4 Book Follow-up Appointment (Doctor)

Same flow as Admin booking but:
- Patient must be an existing patient of this doctor (appear in their encounter history)
- Doctor is pre-selected as the practitioner
- Route: `/doctor/appointments/new?patientId=`

---

### 2.5 Doctor Availability Calendar (Doctor Self-Management)

**Calendar** (`/doctor/calendar`):
- Week/month view of own slots from `practitioner_availability_slots`
- Doctor can:
  - Add availability blocks (regular working slots)
  - Mark leave/block (set `is_available = false`, `slot_type = leave`)
  - Cannot delete a slot that has a booked appointment
- Changes here reflect in the patient-facing booking calendar in real time

---

### 2.6 Appointment Queue — Self Assign

**Today's queue** (`/doctor/queue`):
- Lists today's appointments where this doctor is a participant
- Doctor can:
  - Mark patient as `arrived` or `checked_in`
  - Start an encounter (auto-creates `encounters` record linked to the appointment via `appointment_id`,
    status = `in_progress`)
  - Finish encounter (set `encounters.status = finished`, `encounters.period_end = now()`,
    set `appointments.status = fulfilled`)

---

## Role 3 — Patient Portal

### 3.1 Patient Authentication

**Login** (`/patient/login`):
- Email + password against `patient_accounts` (email lookup via `email_hash` HMAC)
- Issues JWT with role `PATIENT`
- Account lockout after 5 failed attempts (update `patient_accounts.failed_login_attempts`,
  set `patient_accounts.locked_until`)
- On first login (`must_change_password = true`), force redirect to `/patient/set-password`

**Set Password** (`/patient/set-password`):
- Validates one-time token, sets password, clears `must_change_password`

---

### 3.2 Patient Dashboard (`/patient/dashboard`)

Displays:
- Upcoming appointments (from `appointments` + `appointment_participants` filtered to this patient)
- Recent prescriptions (from `medication_requests` where `patient_id = current patient` and `status = active`)
- Unread notifications count

---

### 3.3 View Prescriptions

**Prescription list** (`/patient/prescriptions`):
- Reads `medication_requests` where `patient_id = current patient`
- Columns: Medication, Dosage, Frequency, Start Date, End Date, Status, Prescribed by
- Filter by `status` (active / completed / on_hold)
- Detail view: full dosage instructions, refills remaining, prescribing doctor contact

---

### 3.4 View Doctor Availability Calendar

**Doctor availability** (`/patient/doctors/:doctorId/availability`):
- Month/week calendar view of `practitioner_availability_slots` where `is_available = true`
  and no appointment already booked on that slot
- Shows available (green) and fully booked (grey) slots
- Patient can click an available slot to start the booking flow

---

### 3.5 Book Appointment

**Booking flow** (`/patient/appointments/new`):
- Step 1: Browse/search doctors by name or specialty (`practitioners` where `active = true`)
- Step 2: Select doctor → view their availability calendar (available slots only)
- Step 3: Click a slot → appointment type selection (Routine, Follow-up, Urgent)
- Step 4: Chief complaint / notes (`appointments.description`)
- Step 5: Review and confirm
- On confirm:
  1. INSERT into `appointments` (`patient_id = current patient`, `status = booked`, `slot_id`,
     `start_time`, `end_time`, `appointment_type_code`, `description`)
  2. INSERT into `appointment_participants` (one for patient, one for practitioner)
  3. Update `practitioner_availability_slots.is_available = false`
  4. INSERT notification to patient (`appointment_booked`, channel from `notification_preferences`)
  5. INSERT notification to doctor (`appointment_assigned`)

**My Appointments** (`/patient/appointments`):
- Lists all this patient's appointments from `appointments` joined with `appointment_participants`
- Filter by status (upcoming / past / cancelled)
- Cancel button → set `appointments.status = cancelled`, free up the slot
  (`practitioner_availability_slots.is_available = true`), send cancellation notifications

---

## Cross-Cutting Technical Requirements

### Authentication & JWT

- Three separate login endpoints, each issuing a JWT with a `role` claim:
  - `POST /api/v1/auth/admin/login` → `role: ADMIN`
  - `POST /api/v1/auth/doctor/login` → `role: CLINICIAN`
  - `POST /api/v1/auth/patient/login` → `role: PATIENT`
- Password reset via one-time JWT tokens (15-minute expiry) sent in the `notifications` table
  (type: `password_reset`, channel: `email`)
- All tokens validated in `portal-service` or a new `auth-service`

### Email Notifications (align with existing `notifications` table)

All emails INSERT a row into the `notifications` table with appropriate `notification_type`, then a
background worker (or existing `@KafkaListener`) sends the actual email:

| Event | `notification_type` | Recipient |
|-------|--------------------|----|
| Doctor account created | `doctor_welcome` | Doctor email |
| Patient account created | `patient_welcome` | Patient email |
| Password reset requested | `password_reset` | User email |
| Appointment booked | `appointment_booked` | Patient |
| Appointment assigned | `appointment_assigned` | Doctor |
| Appointment cancelled | `appointment_cancelled` | Both |
| Prescription issued | `prescription_issued` | Patient |

### Security & HIPAA

- Row-Level Security (RLS) policies already exist in the DB — respect them. Patients can only see
  their own rows; clinicians see their own patients.
- PHI columns (`patient_accounts.email`, `practitioner_accounts.email`) must be encrypted with
  `PhiEncryptionConverter` (AES-256-GCM) exactly as other PHI columns in the existing codebase.
- HMAC column (`email_hash`) used for equality lookups — never decrypt to query.
- All authentication events must INSERT into `auth_failure_log` (failed logins) and
  `audit_events` (successful logins) in the `dev` schema.
- Passwords: bcrypt, cost factor ≥ 12. Never log or return passwords.

### DB Schema Alignment

- All new tables go in the `dev` schema (single schema — no separate `auth` or `admin` schema)
- Follow naming conventions: `snake_case`, `_at` suffix for timestamps, `_id` suffix for UUIDs
- Add `created_at TIMESTAMPTZ DEFAULT NOW()` and `updated_at TIMESTAMPTZ DEFAULT NOW()` to all tables
- Add the update trigger (`fn_set_updated_at`) to all new tables (already defined in `09_triggers.sql`)
- Grant permissions following `12_roles_and_grants.sql`: `db_admin` manages all, `db_clinician`
  manages clinical data, `db_patient` sees own data

### API Design

Keep to existing conventions:
- REST: `GET /api/v1/...`, `POST /api/v1/...`, `PUT /api/v1/...`, `DELETE /api/v1/...`
- Response wrapper: `ApiResponse<T>` from `healthcare-common`
- Pagination: `Page<T>` from Spring Data for list endpoints
- Error handling: `GlobalExceptionHandler` from `healthcare-common`

### Frontend

- New pages follow the existing React + TanStack Query + React Hook Form + Zod + shadcn/ui pattern
- Add three separate layout trees: `AdminLayout`, `DoctorLayout`, `PatientLayout` each with their
  own sidebar navigation
- Route guards per role using the JWT role claim stored in `localStorage` or a Zustand store
- URL structure:
  - Admin: `/admin/...`
  - Doctor: `/doctor/...`
  - Patient: `/patient/...`
