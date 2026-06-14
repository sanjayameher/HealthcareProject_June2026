# Healthcare Platform — Patient Service
## Developer Setup & API Reference

> **Stack:** Java 21 · Spring Boot 3 · PostgreSQL 16 · Apache Maven 3.9+  
> **Port:** 8081 · **Swagger UI:** http://localhost:8081/swagger-ui.html  
> **Compliance:** HIPAA · FHIR R4

---

## Table of Contents

1. [Prerequisites Installation](#1-prerequisites-installation)
   - [Java 21](#11-java-21-jdk)
   - [Apache Maven](#12-apache-maven-39)
   - [PostgreSQL 16](#13-postgresql-16)
   - [Git](#14-git)
2. [Database Setup](#2-database-setup)
3. [Project Setup](#3-project-setup)
4. [Running the Application](#4-running-the-application)
5. [REST API Reference](#5-rest-api-reference)
   - [Organizations](#51-organizations-api)
   - [Practitioners](#52-practitioners-api)
   - [Patients](#53-patients-api)
6. [Enum Reference](#6-enum-reference)
7. [Troubleshooting](#7-troubleshooting)
8. [Push to GitHub](#8-push-to-github)

---

## 1. Prerequisites Installation

### 1.1 Java 21 (JDK)

1. Go to **https://adoptium.net**
2. Select **Temurin 21 (LTS)** → Windows → x64 → `.msi` installer
3. Run the installer — check both options:
   - ✅ Set `JAVA_HOME` variable
   - ✅ Add to `PATH`
4. If the installer did not set them automatically, set manually:

**Setting environment variables on Windows 11:**

```
1. Press  Win + S  → search "Environment Variables"
2. Click "Edit the system environment variables"
3. Click "Environment Variables..." button
4. Under "System variables" → click "New":
      Variable name:  JAVA_HOME
      Variable value: C:\Program Files\Eclipse Adoptium\jdk-21.x.x-hotspot
5. Find "Path" in System variables → click "Edit" → "New":
      %JAVA_HOME%\bin
6. Click OK on all dialogs
7. Open a NEW terminal and verify:
```

```powershell
java -version
# Expected output:
# openjdk version "21.x.x" ...
```

---

### 1.2 Apache Maven 3.9+

1. Go to **https://maven.apache.org/download.cgi**
2. Download **Binary zip archive** (e.g. `apache-maven-3.9.x-bin.zip`)
3. Extract to `C:\Program Files\Maven\apache-maven-3.9.x`
4. Set environment variables:

```
Variable name:  MAVEN_HOME
Variable value: C:\Program Files\Maven\apache-maven-3.9.x
```

Add to `Path`:
```
%MAVEN_HOME%\bin
```

5. Open a new terminal and verify:

```powershell
mvn -version
# Expected output:
# Apache Maven 3.9.x ...
# Java version: 21.x.x
```

---

### 1.3 PostgreSQL 16

1. Go to **https://www.postgresql.org/download/windows**
2. Download the installer for PostgreSQL 16
3. Run the installer with these settings:
   - Installation directory: default
   - Port: **5432** (default)
   - Superuser password: set a strong password and **remember it**
   - Locale: default
4. Verify:

```powershell
psql --version
# Expected: psql (PostgreSQL) 16.x
```

> **Note:** Add PostgreSQL bin to PATH if `psql` is not found:
> `C:\Program Files\PostgreSQL\16\bin`

---

### 1.4 Git

1. Go to **https://git-scm.com/download/win**
2. Download and run the installer with default options
3. Verify:

```powershell
git --version
# Expected: git version 2.x.x.windows.x
```

---

## 2. Database Setup

### Step 1 — Create the Database

Open PowerShell and connect to PostgreSQL as superuser:

```powershell
psql -U postgres
```

Then run:

```sql
CREATE DATABASE healthdb;
\q
```

---

### Step 2 — Navigate to Schema Directory

```powershell
cd C:\SANJAYA\PROJECT\HealthcareProject\db\schema
```

---

### Step 3 — Run the Master Schema Script

```powershell
psql -U postgres -d healthdb -f 00_master.sql
```

This runs all 14 schema files in order:

| File | Description |
|------|-------------|
| `00_extensions_and_schemas.sql` | Installs `citext`, `pgcrypto`, `uuid-ossp` extensions; creates `dev` schema |
| `01_enums.sql` | All PostgreSQL enum types (gender, flag_status, telecom_system, etc.) |
| `02_patient_schema.sql` | Core tables: organizations, practitioners, patients, patient_names, patient_addresses, patient_telecoms, patient_contacts, patient_identifiers, patient_flags, patient_languages, patient_race_ethnicities, patient_links |
| `03_billing_schema.sql` | Payers, coverage, eligibility |
| `04_clinical_schema.sql` | Encounters, observations, conditions, orders |
| `05_portal_schema.sql` | Accounts, consents, appointments, messaging |
| `06_audit_schema.sql` | Audit events, PHI access log, change history |
| `07_indexes.sql` | Performance indexes |
| `08_rls_policies.sql` | Row-level security policies |
| `09_triggers.sql` | Auto-update triggers |
| `10_views.sql` | Views and materialized views |
| `11_functions.sql` | Utility functions |
| `12_roles_and_grants.sql` | DB roles and privilege grants |
| `13_seed_reference_data.sql` | Reference / seed data |

---

### Step 4 — Verify Schema

```powershell
psql -U postgres -d healthdb
```

```sql
\dn
-- Expected: shows "dev" schema

\dt dev.*
-- Expected: lists all tables (organizations, patients, practitioners, etc.)

\q
```

---

## 3. Project Setup

### Project Location

```
C:\SANJAYA\PROJECT\HealthcareProject
```

### Project Structure

```
HealthcareProject/
├── backend/
│   ├── patient-service/              ← Main service (port 8081)
│   │   ├── src/main/java/com/healthcare/patient/
│   │   │   ├── controller/           PatientController
│   │   │   │                         OrganizationController
│   │   │   │                         PractitionerController
│   │   │   ├── domain/
│   │   │   │   ├── entity/           Patient, Organization, Practitioner,
│   │   │   │   │                     PatientName, PatientAddress,
│   │   │   │   │                     PatientTelecom, PatientContact,
│   │   │   │   │                     PatientIdentifier, PatientFlag
│   │   │   │   └── enums/            Gender, FlagStatus, IdentifierSystem,
│   │   │   │                         ContactRelationship, NameUse, etc.
│   │   │   ├── dto/
│   │   │   │   ├── request/          CreatePatientRequest
│   │   │   │   │                     UpdatePatientRequest
│   │   │   │   │                     CreateOrganizationRequest
│   │   │   │   │                     CreatePractitionerRequest
│   │   │   │   └── response/         PatientResponse
│   │   │   │                         OrganizationResponse
│   │   │   │                         PractitionerResponse
│   │   │   ├── service/              PatientService
│   │   │   │                         OrganizationService
│   │   │   │                         PractitionerService
│   │   │   ├── repository/           JPA repositories
│   │   │   └── config/               SecurityConfig (production)
│   │   │                             LocalSecurityConfig (local dev)
│   │   └── src/main/resources/
│   │       ├── application.yml       Production configuration
│   │       └── application-local.yml Local development configuration
│   └── healthcare-common/            Shared library (exceptions, DTOs, crypto)
└── db/
    └── schema/                       14 SQL schema files
```

### Local Profile Configuration

The file `application-local.yml` is pre-configured for local development:

| Setting | Value |
|---------|-------|
| Database URL | `jdbc:postgresql://127.0.0.1:5432/healthdb` |
| DB Username | `postgres` |
| Schema validation | Disabled (`ddl-auto: none`) |
| Eureka | Disabled |
| Redis | Disabled |
| OAuth2 / Keycloak | Disabled |
| Kafka | Graceful (no crash if offline) |
| Security | Permit all (no token required) |

---

## 4. Running the Application

### Option A — Local Profile (Recommended)

No external services needed. Use this for all local development and Swagger testing.

```powershell
cd C:\SANJAYA\PROJECT\HealthcareProject\backend\patient-service
mvn spring-boot:run "-Dspring-boot.run.profiles=local"
```

### Option B — Default Profile with Explicit Credentials

```powershell
$env:DB_USER="postgres"
$env:DB_PASSWORD="your_postgres_password"
mvn spring-boot:run
```

### Successful Startup

Look for this in the logs:

```
Started PatientServiceApplication in x.xxx seconds
Tomcat started on port(s): 8081
```

Then open Swagger UI:

```
http://localhost:8081/swagger-ui.html
```

> **Note:** Kafka, Eureka, and Redis warnings in the log are **background noise** when
> using the local profile. The service is running correctly — ignore them and
> open Swagger directly.

> **Security:** The local profile disables authentication (`LocalSecurityConfig`
> permits all requests). No Bearer token is required in Swagger.

---

## 5. REST API Reference

> **Base URL:** `http://localhost:8081`  
> **Content-Type:** `application/json`  
> **Auth:** Not required when running with local profile

> **Recommended creation order:** Organization → Practitioner → Patient
> (Patient requires an Organization ID)

---

### 5.1 Organizations API

**Base path:** `/api/v1/organizations`

---

#### POST /api/v1/organizations — Create Organization

**Request Body:**

```json
{
  "name": "City General Hospital",
  "typeCode": "prov",
  "typeDisplay": "Healthcare Provider",
  "npi": "1234567890",
  "phone": "555-100-2000",
  "fax": "555-100-2001",
  "email": "admin@citygeneral.com",
  "city": "Boston",
  "state": "MA",
  "postalCode": "02101",
  "alias": ["CGH", "City General"],
  "parentId": null
}
```

**Validation Rules:**
- `name` — required
- `npi` — exactly 10 digits (optional)
- `state` — 2-letter uppercase code (e.g. `MA`, `CA`, `NY`)

**Success Response — 201 Created:**

```json
{
  "success": true,
  "message": "Resource created successfully",
  "data": {
    "id": "c4725e26-9d77-4a8b-98a5-4ce305cf0b5d",
    "npi": "1234567890",
    "name": "City General Hospital",
    "typeCode": "prov",
    "typeDisplay": "Healthcare Provider",
    "phone": "555-100-2000",
    "email": "admin@citygeneral.com",
    "city": "Boston",
    "state": "MA",
    "postalCode": "02101",
    "active": true,
    "parentId": null,
    "createdAt": "2026-06-14T17:29:23.160-05:00"
  }
}
```

> **Important:** Copy the `id` from this response — you will need it when creating a Patient.

---

#### GET /api/v1/organizations/{id} — Get by ID

```
GET /api/v1/organizations/c4725e26-9d77-4a8b-98a5-4ce305cf0b5d
```

**Success Response — 200 OK:** returns the organization object inside `data`.

---

#### GET /api/v1/organizations — List Organizations

```
GET /api/v1/organizations?name=City&page=0&size=20
```

| Parameter | Required | Description |
|-----------|----------|-------------|
| `name` | No | Filter by name (case-insensitive, partial match) |
| `page` | No | Page number, default `0` |
| `size` | No | Page size, default `20` |
| `sort` | No | Leave **blank** in Swagger — do not use the placeholder `string` |

---

### 5.2 Practitioners API

**Base path:** `/api/v1/practitioners`

---

#### POST /api/v1/practitioners — Create Practitioner

**Request Body:**

```json
{
  "npi": "9876543210",
  "familyName": "Smith",
  "givenName": "John",
  "prefix": "Dr.",
  "suffix": "MD",
  "gender": "male",
  "birthDate": "1975-06-15"
}
```

**Validation Rules:**
- `familyName` — required
- `givenName` — required
- `npi` — exactly 10 digits (optional)
- `gender` — see Enum Reference below
- `birthDate` — format `YYYY-MM-DD`

**Success Response — 201 Created:**

```json
{
  "success": true,
  "message": "Resource created successfully",
  "data": {
    "id": "<uuid>",
    "npi": "9876543210",
    "givenName": "John",
    "familyName": "Smith",
    "fullNameDisplay": "Dr. John Smith MD",
    "prefix": "Dr.",
    "suffix": "MD",
    "gender": "male",
    "birthDate": "1975-06-15",
    "active": true,
    "createdAt": "<timestamp>"
  }
}
```

**Additional Test Examples:**

```json
{
  "npi": "1122334455",
  "familyName": "Williams",
  "givenName": "Sarah",
  "prefix": "Dr.",
  "suffix": "DO",
  "gender": "female",
  "birthDate": "1980-09-22"
}
```

```json
{
  "npi": "5566778899",
  "familyName": "Davis",
  "givenName": "Michael",
  "prefix": "Mr.",
  "suffix": "NP",
  "gender": "male",
  "birthDate": "1985-03-10"
}
```

---

#### GET /api/v1/practitioners/{id} — Get by ID

```
GET /api/v1/practitioners/<uuid>
```

---

#### GET /api/v1/practitioners — List Practitioners

```
GET /api/v1/practitioners?familyName=Smith&page=0&size=20
```

| Parameter | Required | Description |
|-----------|----------|-------------|
| `familyName` | No | Filter by family name (partial match) |
| `page` | No | Page number, default `0` |
| `size` | No | Page size, default `20` |
| `sort` | No | Leave **blank** — valid values: `familyName,asc` / `familyName,desc` / `createdAt,desc` |

---

### 5.3 Patients API

**Base path:** `/api/v1/patients`

> **Prerequisite:** Create an Organization first and copy its `id`.

---

#### POST /api/v1/patients — Create Patient

**Request Body:**

```json
{
  "gender": "female",
  "birthDate": "1990-03-25",
  "managingOrganizationId": "c4725e26-9d77-4a8b-98a5-4ce305cf0b5d",
  "names": [
    {
      "use": "official",
      "family": "Johnson",
      "given": ["Emily", "Rose"],
      "prefix": "Ms.",
      "suffix": null
    }
  ],
  "addresses": [
    {
      "use": "home",
      "type": "physical",
      "line1": "123 Maple Street",
      "line2": "Apt 4B",
      "city": "Boston",
      "state": "MA",
      "postalCode": "02101",
      "country": "US"
    }
  ],
  "telecoms": [
    {
      "system": "phone",
      "value": "555-987-6543",
      "use": "mobile",
      "rank": 1
    },
    {
      "system": "email",
      "value": "emily.johnson@email.com",
      "use": "home",
      "rank": 2
    }
  ]
}
```

**Validation Rules:**
- `gender` — required
- `birthDate` — required, must be in the past, format `YYYY-MM-DD`
- `names` — at least one name required
- `names[].family` — required
- `names[].given` — at least one given name required
- `state` — 2-letter uppercase code
- `postalCode` — format `12345` or `12345-6789`
- `telecom.rank` — positive integer, `1` = highest preference

**Success Response — 201 Created:**

```json
{
  "success": true,
  "message": "Resource created successfully",
  "data": {
    "id": "302afbe3-98fe-488c-b492-4fa21def0b70",
    "mrn": "MRN1781476577393",
    "gender": "female",
    "birthDate": "1990-03-25",
    "active": true,
    "managingOrganizationId": "c4725e26-9d77-4a8b-98a5-4ce305cf0b5d",
    "managingOrganizationName": "City General Hospital",
    "names": [
      {
        "id": "<uuid>",
        "use": "official",
        "family": "Johnson",
        "given": ["Emily", "Rose"],
        "prefix": ["Ms."],
        "suffix": null,
        "text": "Emily Rose Johnson"
      }
    ],
    "addresses": [...],
    "telecoms": [...]
  }
}
```

> **Important:** Copy the `id` and `mrn` — you need them for GET and PUT requests.

---

#### PUT /api/v1/patients/{id} — Update Patient

> **Critical:** The `version` field is **required** for optimistic locking.
> Always use the `version` value from the latest GET or POST response.

| Scenario | version to send |
|----------|----------------|
| Just created (never updated) | `0` |
| After 1st update | `1` |
| After 2nd update | `2` |

**URL:**
```
PUT /api/v1/patients/302afbe3-98fe-488c-b492-4fa21def0b70
```

**Request Body:**

```json
{
  "gender": "female",
  "birthDate": "1992-07-10",
  "preferredLanguage": "en",
  "active": true,
  "managingOrganizationId": "c4725e26-9d77-4a8b-98a5-4ce305cf0b5d",
  "version": 0
}
```

**Success Response — 200 OK:** returns updated patient object.

---

#### GET /api/v1/patients/{id} — Get by ID

```
GET /api/v1/patients/302afbe3-98fe-488c-b492-4fa21def0b70
```

---

#### GET /api/v1/patients/by-mrn/{mrn} — Get by MRN

```
GET /api/v1/patients/by-mrn/MRN1781476577393
```

---

#### GET /api/v1/patients/search — Search Patients

```
GET /api/v1/patients/search?name=Johnson&page=0&size=20
GET /api/v1/patients/search?mrn=MRN1781476577393
```

| Parameter | Required | Description |
|-----------|----------|-------------|
| `name` | No | Search by patient name (partial match) |
| `mrn` | No | Search by exact MRN |
| `page` | No | Page number, default `0` |
| `size` | No | Page size, default `20` |

---

#### DELETE /api/v1/patients/{id} — Soft Delete Patient

```
DELETE /api/v1/patients/302afbe3-98fe-488c-b492-4fa21def0b70
```

**Success Response — 204 No Content**

> This is a **soft delete** — it sets `deleted_at` timestamp. The record remains
> in the database but is excluded from all queries.

---

## 6. Enum Reference

### Gender

| Value | Description |
|-------|-------------|
| `male` | Male |
| `female` | Female |
| `other` | Other |
| `unknown` | Unknown |

### Name Use

| Value | Description |
|-------|-------------|
| `official` | Legal name |
| `usual` | Preferred everyday name |
| `temp` | Temporary name |
| `nickname` | Informal name |
| `anonymous` | Anonymous |
| `old` | Previous name |
| `maiden` | Name before marriage |

### Address Use

| Value | Description |
|-------|-------------|
| `home` | Home address |
| `work` | Work address |
| `temp` | Temporary address |
| `old` | Previous address |
| `billing` | Billing address |

### Address Type

| Value | Description |
|-------|-------------|
| `postal` | Mailing address |
| `physical` | Physical/visit address |
| `both` | Both postal and physical |

### Telecom System

| Value | Description |
|-------|-------------|
| `phone` | Phone number |
| `fax` | Fax number |
| `email` | Email address |
| `pager` | Pager |
| `url` | Website/URL |
| `sms` | SMS number |
| `other` | Other |

### Telecom Use

| Value | Description |
|-------|-------------|
| `home` | Home contact |
| `work` | Work contact |
| `temp` | Temporary |
| `old` | Old/previous |
| `mobile` | Mobile number |

### Identifier System

| Value | Description |
|-------|-------------|
| `ssn` | Social Security Number |
| `mrn` | Medical Record Number |
| `npi` | National Provider Identifier |
| `dea` | DEA number |
| `driver_license` | Driver's license |
| `passport` | Passport number |
| `insurance_member_id` | Insurance member ID |
| `employee_id` | Employee ID |
| `medicaid_id` | Medicaid ID |
| `medicare_id` | Medicare ID |
| `itin` | Individual Taxpayer ID |
| `other` | Other identifier |

### Flag Status

| Value | Description |
|-------|-------------|
| `active` | Flag is active |
| `inactive` | Flag is inactive |
| `entered_in_error` | Created in error |

### Contact Relationship

| Value | Description |
|-------|-------------|
| `emergency` | Emergency contact |
| `next_of_kin` | Next of kin |
| `guardian` | Legal guardian |
| `power_of_attorney` | Power of attorney |
| `parent` | Parent |
| `spouse` | Spouse |
| `sibling` | Sibling |
| `child` | Child |
| `grandparent` | Grandparent |
| `caregiver` | Caregiver |
| `employer` | Employer |
| `friend` | Friend |
| `other` | Other |

---

## 7. Troubleshooting

### Error: `password authentication failed for user "postgres"`

**Cause:** Wrong or missing DB credentials.

**Fix:**
```powershell
# Option A — Pass credentials inline
$env:DB_USER="postgres"; $env:DB_PASSWORD="your_password"; mvn spring-boot:run

# Option B — Use local profile (credentials already in application-local.yml)
mvn spring-boot:run "-Dspring-boot.run.profiles=local"
```

---

### Error: `Schema-validation: wrong column type / missing column`

**Cause:** Hibernate schema validation fails against the PostgreSQL schema.

**Fix:** Use local profile which sets `ddl-auto: none` (skips validation):
```powershell
mvn spring-boot:run "-Dspring-boot.run.profiles=local"
```

---

### Kafka / Eureka / Redis warnings in logs

**Cause:** These external services are not running locally.

**These are not errors.** The service starts successfully regardless.

**Fix:** Use local profile to silence all these warnings:
```powershell
mvn spring-boot:run "-Dspring-boot.run.profiles=local"
```
Then open Swagger directly: `http://localhost:8081/swagger-ui.html`

---

### HTTP 409 Conflict on PUT /api/v1/patients/{id}

**Cause:** The `version` field in the request does not match the current version in the database (optimistic locking).

**Fix:** Always use the version from the most recent GET or POST response:

```json
{
  "version": 0
}
```

| Situation | Correct version |
|-----------|----------------|
| Patient just created | `0` |
| After first update | `1` |
| After second update | `2` |

---

### HTTP 500 on GET /api/v1/practitioners (list)

**Cause:** Swagger sends `sort=string` (the literal placeholder text) which is not a valid entity field.

**Fix:** In the Swagger form, **clear the `sort` field completely** before clicking Execute.

Valid sort values if needed:
```
familyName,asc
familyName,desc
createdAt,desc
givenName,asc
```

---

### YAML parse error on startup

**Cause:** Duplicate YAML keys in `application-local.yml` (e.g. two `spring:` blocks).

**Fix:** Open `application-local.yml` and ensure each top-level key appears only once. All `spring.*` properties must be nested under a single `spring:` block.

---

### Port 8081 already in use

**Fix:** Find and stop the process using port 8081:
```powershell
netstat -ano | findstr :8081
taskkill /PID <PID_NUMBER> /F
```

---

---

## 8. Push to GitHub

> **Repository:** https://github.com/sanjayameher/HealthcareProject_June2026

### Step 1 — Initialize Git

Open PowerShell in the project root and run:

```powershell
cd C:\SANJAYA\PROJECT\HealthcareProject
git init
```

---

### Step 2 — Create `.gitignore`

Create a `.gitignore` file to exclude build artifacts and sensitive files:

```powershell
notepad .gitignore
```

Paste the following content and save:

```
# Maven build output
target/
*.class
*.jar
*.war

# IDE files
.idea/
*.iml
.vscode/
*.code-workspace

# Spring Boot local config with credentials — never commit this
backend/patient-service/src/main/resources/application-local.yml

# OS files
.DS_Store
Thumbs.db

# Logs
*.log
logs/
```

> **Important:** `application-local.yml` contains your database password.
> It is excluded above so credentials are never pushed to GitHub.

---

### Step 3 — Stage All Files

```powershell
git add .
```

Verify what will be committed:

```powershell
git status
```

---

### Step 4 — Create First Commit

```powershell
git commit -m "Initial commit — Healthcare Platform Patient Service"
```

---

### Step 5 — Connect to GitHub Repository

```powershell
git remote add origin https://github.com/sanjayameher/HealthcareProject_June2026.git
```

Verify the remote was added:

```powershell
git remote -v
# Expected:
# origin  https://github.com/sanjayameher/HealthcareProject_June2026.git (fetch)
# origin  https://github.com/sanjayameher/HealthcareProject_June2026.git (push)
```

---

### Step 6 — Push to GitHub

```powershell
git branch -M main
git push -u origin main
```

When prompted:
- **Username:** your GitHub username (`sanjayameher`)
- **Password:** your GitHub Personal Access Token (PAT) — **not** your GitHub login password

#### How to generate a Personal Access Token (PAT)

1. Go to **GitHub → Settings → Developer Settings → Personal Access Tokens → Tokens (classic)**
2. Click **Generate new token (classic)**
3. Give it a name (e.g. `HealthcareProject`)
4. Select scope: ✅ `repo`
5. Click **Generate token**
6. Copy the token immediately — GitHub shows it only once
7. Use it as the password when `git push` prompts you

---

### All Commands in One Block

```powershell
cd C:\SANJAYA\PROJECT\HealthcareProject
git init
git add .
git commit -m "Initial commit — Healthcare Platform Patient Service"
git remote add origin https://github.com/sanjayameher/HealthcareProject_June2026.git
git branch -M main
git push -u origin main
```

---

### Verify on GitHub

After a successful push, open your browser:

```
https://github.com/sanjayameher/HealthcareProject_June2026
```

You should see all project files including:
- `backend/patient-service/` — Spring Boot service
- `db/schema/` — 14 SQL schema files
- `docs/` — this documentation

---

### Future Commits (after making changes)

```powershell
git add .
git commit -m "describe your change here"
git push
```

---

*Last updated: 2026-06-14 | Patient Service v1.0.0-SNAPSHOT*
