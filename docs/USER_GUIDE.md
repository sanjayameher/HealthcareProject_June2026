# Healthcare Platform — Employee User Guide

**System:** HealthCare Clinical Portal  
**Audience:** Clinical staff, administrative staff, billing coordinators, compliance officers

---

## Table of Contents

1. [Getting Started](#1-getting-started)
2. [Dashboard Overview](#2-dashboard-overview)
3. [Step 1 — Set Up an Organization](#3-step-1--set-up-an-organization)
4. [Step 2 — Register a Practitioner](#4-step-2--register-a-practitioner)
5. [Step 3 — Add an Insurance Payer](#5-step-3--add-an-insurance-payer)
6. [Step 4 — Register a Patient](#6-step-4--register-a-patient)
7. [Step 5 — Create an Encounter (Visit)](#7-step-5--create-an-encounter-visit)
8. [Step 6 — Add Insurance Coverage for a Patient](#8-step-6--add-insurance-coverage-for-a-patient)
9. [Managing Existing Records](#9-managing-existing-records)
10. [Audit Trail](#10-audit-trail)
11. [Navigation Reference](#11-navigation-reference)
12. [Field Rules & Validation](#12-field-rules--validation)
13. [Recommended First-Time Setup Order](#13-recommended-first-time-setup-order)

---

## 1. Getting Started

Open your browser and go to the application URL (e.g., `http://localhost:3000` for local development).

The left sidebar is always visible. Click the **chevron (< / >)** at the bottom of the sidebar to collapse or expand it.

**Sidebar menu items:**

| Icon | Label | What it does |
|------|-------|-------------|
| Grid | Dashboard | Home screen with stats and recent patients |
| Building | Organizations | Manage healthcare organizations (hospitals, clinics) |
| User Check | Practitioners | Manage doctors, nurses, providers |
| Users | Patients | Browse and manage patient records |
| Stethoscope | New Encounter | Shortcut to create a clinical encounter |
| Credit Card | Billing | Manage payers and insurance |
| Shield | Audit Trail | HIPAA-compliant access log |

---

## 2. Dashboard Overview

The Dashboard is the first screen you see. It shows:

- **Total Patients** — how many patient records exist in the system
- **Active Patients** — patients currently marked as active
- **Active Coverage** — (live counter, coming soon)
- **Audit Events** — (live counter, coming soon)

**Quick Actions** buttons let you jump straight to the most common tasks:
- Register Patient
- New Encounter
- Add Coverage
- New Organization

The **Recent Patients** table at the bottom shows the last 10 registered patients. Click any row to open that patient's full record.

---

## 3. Step 1 — Set Up an Organization

An organization represents a hospital, clinic, or practice. Patients and practitioners can be linked to an organization. **Set this up first** before registering patients if you want to assign them to a facility.

**How to create an organization:**

1. Click **Organizations** in the sidebar.
2. Click the **New Organization** button (top right of the list page).
3. Fill in the form:

| Field | Required | Notes |
|-------|----------|-------|
| Organization Name | Yes | Full legal name, e.g. "City General Hospital" |
| NPI | No | 10-digit National Provider Identifier |
| Type Code | No | Short code, e.g. `hosp`, `prov`, `clinic` |
| Type Display | No | Human-readable label, e.g. "Hospital" |
| Phone | No | Main contact number |
| Fax | No | Fax number |
| Email | No | Contact email |
| City | No | City where the organization is located |
| State | No | Exactly 2 uppercase letters, e.g. `TX` |
| Postal Code | No | ZIP code |

4. Click **Create Organization**.
5. You are taken to the Organization Detail page where you can review the record.

---

## 4. Step 2 — Register a Practitioner

A practitioner is a healthcare provider (doctor, nurse, therapist, etc.). Register practitioners before they are assigned to encounters.

**How to register a practitioner:**

1. Click **Practitioners** in the sidebar.
2. Click **Register Practitioner** (top right).
3. Fill in the form:

| Field | Required | Notes |
|-------|----------|-------|
| NPI | No | 10-digit National Provider Identifier |
| Prefix | No | e.g. `Dr.`, `Mr.`, `Ms.` |
| Suffix | No | e.g. `MD`, `PhD`, `Jr.` |
| First Name | Yes | Given name |
| Last Name | Yes | Family/surname |
| Gender | No | Male / Female / Other / Unknown |
| Date of Birth | No | Must be a past date |

4. Click **Register Practitioner**.
5. You are taken to the Practitioner Detail page.

---

## 5. Step 3 — Add an Insurance Payer

A payer is an insurance company (e.g., Blue Cross Blue Shield, Aetna, Medicare). You must add at least one payer before you can add insurance coverage to a patient.

**How to add a payer:**

1. Click **Billing** in the sidebar.
2. Click **Add Payer** (top right of the payer list).
3. Fill in the form:

| Field | Required | Notes |
|-------|----------|-------|
| Payer Name | Yes | e.g. "Blue Cross Blue Shield" |
| Type | No | e.g. `Commercial`, `Medicare`, `Medicaid` |
| Payer ID | No | Payer's EDI/clearinghouse ID, e.g. `00001` |
| Phone | No | Payer contact number |
| Email | No | Payer contact email |

4. Click **Add Payer**.
5. The payer is now available in the coverage form dropdown.

---

## 6. Step 4 — Register a Patient

Registering a patient is a **5-step wizard**. You can go back to any previous step before final submission.

**How to register a patient:**

Navigate to **Patients → Register Patient** (or use the Quick Action on the Dashboard).

### Step 1 of 5 — Basic Info

| Field | Required | Notes |
|-------|----------|-------|
| Gender | Yes | Male / Female / Other / Unknown |
| Date of Birth | Yes | Must be a past date |
| Preferred Language | No | e.g. `English`, `Spanish` |
| Managing Organization | No | Select from the organizations you created in Step 1 |

Click **Next**.

### Step 2 of 5 — Name

| Field | Required | Notes |
|-------|----------|-------|
| Name Use | Yes | `Official` (legal name), `Usual`, `Nickname`, `Maiden` |
| Prefix | No | e.g. `Mr.`, `Mrs.`, `Dr.` |
| Suffix | No | e.g. `Jr.`, `III`, `MD` |
| First Name(s) | Yes | Space-separated if multiple given names, e.g. `John Michael` |
| Last Name | Yes | Family/surname |

Click **Next**.

### Step 3 of 5 — Contact

| Field | Required | Notes |
|-------|----------|-------|
| Phone | No | e.g. `+1 555-000-0000` |
| Email | No | Must be a valid email format if entered |

Click **Next**.

### Step 4 of 5 — Address

Address is fully optional. If you fill in any address field, both **Street Address** and **City** become required.

| Field | Required | Notes |
|-------|----------|-------|
| Street Address (Line 1) | Conditional | Required if any address field is filled |
| Street Address (Line 2) | No | Apartment, suite, floor |
| City | Conditional | Required if any address field is filled |
| State | No | Exactly 2 uppercase letters, e.g. `TX`. The field auto-uppercases. |
| Postal Code | No | 5-digit ZIP, e.g. `75019` |
| Country | No | e.g. `US` |

Click **Review**.

### Step 5 of 5 — Review

A summary of all entered data is shown. Verify everything is correct.

- Click **Back** to go back and correct anything.
- Click **Register Patient** to save.

After registration, you are taken to the **Patient Detail page**. The system automatically assigns a unique **MRN** (Medical Record Number) to the patient.

---

## 7. Step 5 — Create an Encounter (Visit)

An encounter records a clinical visit or interaction between a patient and the healthcare system (in-person, virtual, emergency, etc.).

**How to create an encounter:**

You can reach the encounter form two ways:
- Click **New Encounter** in the sidebar or Dashboard
- Open a patient record → **Encounters tab** → click **New Encounter** (this pre-fills the patient)

**Form fields:**

| Field | Required | Notes |
|-------|----------|-------|
| Patient | Yes | Select the patient from the dropdown |
| Status | Yes | See status values below |
| Encounter Class | Yes | See class values below |
| Type Display | No | Free text description, e.g. "Follow-up visit", "Initial consultation" |
| Telehealth Platform | Only if Virtual | e.g. `Zoom Health`, `Doximity`. Appears only when Class = Virtual |
| Period Start | No | Date and time the encounter begins |
| Period End | No | Date and time the encounter ends |
| Chief Complaint | No | Patient's primary reason for the visit |

**Encounter Status values:**

| Value | Meaning |
|-------|---------|
| Planned | Scheduled but not yet started |
| Arrived | Patient has arrived |
| In Progress | Encounter is actively happening |
| Finished | Encounter is complete |
| Cancelled | Encounter was cancelled |

**Encounter Class values:**

| Value | Meaning |
|-------|---------|
| Outpatient | Patient visits a facility and leaves same day |
| Inpatient | Patient is admitted overnight |
| Ambulatory | Ambulatory/walk-in care |
| Emergency | Emergency department visit |
| Home | Care provided at patient's home |
| Virtual / Telehealth | Remote video/phone visit |
| Observation | Patient under observation without full admission |

Click **Create Encounter**. You are taken back to the patient record where the new encounter appears in the Encounters tab.

---

## 8. Step 6 — Add Insurance Coverage for a Patient

Coverage links a patient to an insurance payer with a specific plan.

**How to add coverage:**

You can reach the coverage form two ways:
- Dashboard → **Add Coverage** quick action
- Open a patient record → **Coverage tab** → **Add Coverage** button (this pre-fills the patient)

**Form fields:**

| Field | Required | Notes |
|-------|----------|-------|
| Patient | Yes | Select from the patient list |
| Payer | Yes | Select from the payers you created in Step 3 |
| Plan Name | Yes | e.g. `Gold PPO 2024` |
| Coverage Type | Yes | Medical / Dental / Vision / Pharmacy / Other |
| Status | Yes | Active / Cancelled / Draft |
| Order of Benefit | Yes | 1 = primary, 2 = secondary, etc. |
| Subscriber Relationship | Yes | Self / Spouse / Child / Parent / Other |
| Subscriber ID | Yes | Member ID on the insurance card, e.g. `MEM123456` |
| Group Number | No | Employer group number, e.g. `GRP001` |
| Period Start | Yes | Date coverage begins |
| Period End | No | Leave blank for ongoing coverage |

Click **Add Coverage**. You are returned to the patient record with the new coverage plan visible in the Coverage tab.

To remove a coverage plan, open the patient record → Coverage tab → click **Remove** on the coverage card and confirm.

---

## 9. Managing Existing Records

### Viewing Patients

Click **Patients** in the sidebar to see the patient list. Click any row to open the patient detail page.

The **Patient Detail page** has four tabs:

| Tab | Contents |
|-----|----------|
| Demographics | Personal info, contact info, address |
| Encounters | All clinical encounters for this patient |
| Coverage | Insurance plans linked to this patient |
| Audit | Access log showing who viewed or changed this patient's record |

### Editing a Patient

Open the patient → click **Edit** (top right of the patient header).

You can update: **Gender**, **Date of Birth**, **Preferred Language**.

> Note: Name, contact, and address changes are not editable through this form in the current version.

### Deleting a Patient

Open the patient → click **Delete** (top right, red button) → confirm in the dialog.

Deletion is a **soft delete** — the record is deactivated, not permanently removed.

### Viewing Practitioners

Click **Practitioners** in the sidebar. Click a practitioner row to see their detail page.

### Viewing Organizations

Click **Organizations** in the sidebar. Click an organization row to see its detail page.

---

## 10. Audit Trail

The Audit Trail is a **HIPAA-compliant log** of all access and changes to protected health information (PHI). It is read-only — entries cannot be edited or deleted.

**Accessing the audit trail — two ways:**

**1. Audit Trail page (global search):**

Click **Audit Trail** in the sidebar.

- Enter a **Patient ID** (UUID) to see all events for that patient.
- Or enter a **User ID** (UUID) to see all events performed by that user.
- Optionally set a **From Date** and **To Date** to narrow the time range. If left blank, results default to the last 30 days.
- Click **Search Audit Trail**.

The results table shows: Time, Action, Entity, User, Outcome, IP Address.

Click **Clear** to reset the search.

**2. Patient Audit tab:**

Open any patient record → click the **Audit** tab. Shows the last 30 days of audit events for that patient automatically.

---

## 11. Navigation Reference

| URL Path | Page |
|----------|------|
| `/` | Dashboard |
| `/organizations` | Organization list |
| `/organizations/new` | Create organization |
| `/organizations/:id` | Organization detail |
| `/practitioners` | Practitioner list |
| `/practitioners/new` | Register practitioner |
| `/practitioners/:id` | Practitioner detail |
| `/patients` | Patient list |
| `/patients/new` | Register patient (5-step wizard) |
| `/patients/:id` | Patient detail (Demographics / Encounters / Coverage / Audit) |
| `/patients/:id/edit` | Edit patient demographics |
| `/encounters/new` | Create encounter (optionally `?patientId=UUID` pre-fills patient) |
| `/billing/payers` | Payer list |
| `/billing/payers/new` | Add payer |
| `/billing/coverage/new` | Add coverage (optionally `?patientId=UUID` pre-fills patient) |
| `/audit` | Global audit trail search |

---

## 12. Field Rules & Validation

| Field | Rule |
|-------|------|
| State (all forms) | Exactly 2 uppercase letters — the form auto-uppercases as you type |
| Postal Code | 5-digit ZIP (`75019`) or ZIP+4 (`75019-1234`) |
| NPI | Exactly 10 digits |
| Email | Standard email format |
| Date of Birth | Must be in the past |
| Period Start / End (encounters) | Date and time picker — both fields are optional |
| Subscriber ID (coverage) | Any alphanumeric string from the insurance card |

---

## 13. Recommended First-Time Setup Order

Follow this order when setting up the system from scratch to avoid missing dependencies:

```
1. Add Insurance Payers          (Billing → Add Payer)
        ↓
2. Create Organizations          (Organizations → New Organization)
        ↓
3. Register Practitioners        (Practitioners → Register Practitioner)
        ↓
4. Register Patients             (Patients → Register Patient)
   └── optionally assign to an organization during registration
        ↓
5. Add Insurance Coverage        (Patient record → Coverage tab → Add Coverage)
        ↓
6. Create Encounters             (Patient record → Encounters tab → New Encounter)
```

Payers and Organizations have no dependencies, so either can be created first. Patients depend on Organizations being available if you want to assign a managing organization. Coverage depends on both a Patient and a Payer existing. Encounters depend only on a Patient existing.

---

*For technical issues, contact your system administrator.*
