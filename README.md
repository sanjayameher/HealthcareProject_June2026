# 🏥 Healthcare Platform — Patient Module

> **Enterprise Digital Health Platform — HIPAA-Compliant, FHIR R4-Aligned**  
> Stack: Java 21 · Spring Boot 3.3 · Spring Cloud 2023 · React 19 · TypeScript · PostgreSQL 16

---

## 📋 Table of Contents

1. [Project Overview](#project-overview)
2. [Architecture](#architecture)
3. [Prerequisites](#prerequisites)
4. [Port Reference](#port-reference)
5. [Getting Started](#getting-started)
6. [Accessing the Application](#accessing-the-application)
7. [Application Routes](#application-routes)
8. [API Documentation (Swagger)](#api-documentation-swagger)
9. [Project Structure](#project-structure)
10. [Tech Stack](#tech-stack)
11. [HIPAA Compliance Notes](#hipaa-compliance-notes)
12. [Troubleshooting](#troubleshooting)

---

## Project Overview

A production-quality, multi-service healthcare platform for managing patients, clinical encounters, billing, portal access, and audit trails. The backend is composed of independently deployable Spring Boot microservices behind a single API Gateway, with a modern React frontend consuming those services.

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│  React Frontend (Vite + TypeScript)          :5000              │
└──────────────────────────┬──────────────────────────────────────┘
                           │  Proxied via Vite dev server
                           ▼
┌─────────────────────────────────────────────────────────────────┐
│               API Gateway (Spring Cloud Gateway)   :7080        │
│        Rate Limiting │ Auth Filter │ Circuit Breaker            │
└──┬──────────┬──────────┬──────────┬──────────┬─────────────────┘
   ▼          ▼          ▼          ▼          ▼
:7081      :7082      :7083      :7084      :7085
patient   clinical   billing    portal     audit
service   service    service    service    service
   │          │          │          │          │
   └──────────┴──────────┴────┬─────┴──────────┘
                              ▼
                    PostgreSQL :5432  (healthdb)
```

---

## Prerequisites

| Tool | Version | Notes |
|---|---|---|
| Java (JDK) | 21 (LTS) | https://adoptium.net — Temurin 21 |
| Apache Maven | 3.9+ | https://maven.apache.org/download.cgi |
| Node.js | 18+ | https://nodejs.org |
| npm | 9+ | Bundled with Node.js |
| PostgreSQL | 16 | https://www.postgresql.org/download/ |
| Git | Latest | https://git-scm.com |

**Verify installations:**

```bash
java -version        # openjdk 21.x.x
mvn -version         # Apache Maven 3.9.x
node -v              # v18.x.x or higher
npm -v               # 9.x.x or higher
psql --version       # psql (PostgreSQL) 16.x
```

---

## Port Reference

| Service | Port | URL |
|---|---|---|
| **Frontend (React / Vite)** | **5000** | http://localhost:5000 |
| **API Gateway** | **7080** | http://localhost:7080 |
| **patient-service** | **7081** | http://localhost:7081 |
| **clinical-service** | **7082** | http://localhost:7082 |
| **billing-service** | **7083** | http://localhost:7083 |
| **portal-service** | **7084** | http://localhost:7084 |
| **audit-service** | **7085** | http://localhost:7085 |
| PostgreSQL | 5432 | localhost:5432 |

---

## Getting Started

### Step 1 — Database Setup

```sql
-- Connect to PostgreSQL as superuser
psql -U postgres

-- Create the application user
CREATE USER healthcare_user WITH PASSWORD 'healthcare_pass';

-- Create the database
CREATE DATABASE healthdb OWNER healthcare_user;

-- Grant privileges
GRANT ALL PRIVILEGES ON DATABASE healthdb TO healthcare_user;

\q
```

> Schema creation is handled automatically by Hibernate on first startup with the `local` Spring profile.

---

### Step 2 — Start Backend Services

Services must start in dependency order (shared library first, gateway last).

#### Option A — Windows (Batch Script)

Double-click **`start-all-services.bat`** in the project root, or run from a terminal:

```bat
start-all-services.bat
```

Each service opens in its own minimized Command Prompt window.  
**Wait ~60 seconds** for all six services to fully initialize.

#### Option B — Manual (macOS / Linux / Windows)

Open **seven separate terminals** and run each command:

```bash
# Terminal 1 — Install shared library (run once; re-run after changes to healthcare-common)
cd backend
mvn install -DskipTests -pl healthcare-common

# Terminal 2 — patient-service  (port 7081)
cd backend/patient-service
mvn clean spring-boot:run -Dspring-boot.run.profiles=local

# Terminal 3 — clinical-service  (port 7082)
cd backend/clinical-service
mvn clean spring-boot:run -Dspring-boot.run.profiles=local

# Terminal 4 — billing-service  (port 7083)
cd backend/billing-service
mvn clean spring-boot:run -Dspring-boot.run.profiles=local

# Terminal 5 — portal-service  (port 7084)
cd backend/portal-service
mvn clean spring-boot:run -Dspring-boot.run.profiles=local

# Terminal 6 — audit-service  (port 7085)
cd backend/audit-service
mvn clean spring-boot:run -Dspring-boot.run.profiles=local

# Terminal 7 — api-gateway  (port 7080) — start LAST
cd backend/api-gateway
mvn clean spring-boot:run -Dspring-boot.run.profiles=local
```

> **Note:** Always start `api-gateway` last — it will fail to route if downstream services are not yet registered.

#### Verify backend is up

```bash
curl http://localhost:7080/actuator/health
# Expected: {"status":"UP"}
```

---

### Step 3 — Start Frontend

```bash
cd healthcare-ui
npm install          # first time only
npm run dev
```

The Vite dev server starts at **http://localhost:5000**.

---

## Accessing the Application

| Action | URL |
|---|---|
| **Login (Admin)** | http://localhost:5000/login/admin |
| **Dashboard / Home** | http://localhost:5000 |

> No `.env` file is required — all services run on `localhost` with the `local` Spring profile (no external auth in dev mode).

---

## Application Routes

| Route | Description |
|---|---|
| `/` | Dashboard — stats and recent patients |
| `/organizations` | Organization list |
| `/organizations/new` | Create organization |
| `/organizations/:id` | Organization detail |
| `/practitioners` | Practitioner list |
| `/practitioners/new` | Register practitioner |
| `/practitioners/:id` | Practitioner detail |
| `/patients` | Patient list — search by name or MRN |
| `/patients/new` | Multi-step patient registration (5 steps) |
| `/patients/:id` | Patient 360 — Demographics, Encounters, Coverage, Audit tabs |
| `/patients/:id/edit` | Update patient demographics |
| `/encounters/new` | Create encounter (telehealth for virtual class) |
| `/billing/payers` | Payer list |
| `/billing/payers/new` | Add payer |
| `/billing/coverage/new` | Add insurance coverage |
| `/audit` | Audit trail — search by patient ID or user ID |

---

## API Documentation (Swagger)

Each service exposes a Swagger UI when running in the `local` profile:

| Service | Swagger UI URL |
|---|---|
| patient-service | http://localhost:7081/swagger-ui.html |
| clinical-service | http://localhost:7082/swagger-ui.html |
| billing-service | http://localhost:7083/swagger-ui.html |
| portal-service | http://localhost:7084/swagger-ui.html |
| audit-service | http://localhost:7085/swagger-ui.html |

---

## Project Structure

```
HealthcareProject_June2026/
├── backend/                        # Spring Boot microservices (Maven multi-module)
│   ├── healthcare-common/          # Shared DTOs, exceptions, utilities
│   ├── api-gateway/                # Spring Cloud Gateway — port 7080
│   ├── patient-service/            # Patient, Organization, Practitioner — port 7081
│   ├── clinical-service/           # Encounters, Clinical Notes — port 7082
│   ├── billing-service/            # Payers, Coverage, Claims — port 7083
│   ├── portal-service/             # Patient Portal access — port 7084
│   ├── audit-service/              # HIPAA Audit Trail — port 7085
│   └── pom.xml                     # Parent POM (Java 21, Spring Boot 3.3)
├── healthcare-ui/                  # React 19 + TypeScript frontend — port 5000
│   ├── src/
│   │   ├── components/             # Reusable UI components
│   │   ├── pages/                  # Route-level page components
│   │   ├── services/               # Axios API clients
│   │   └── stores/                 # Zustand state stores
│   ├── vite.config.ts              # Vite dev server (port 5000) + API proxies
│   └── package.json
├── db/
│   └── schema/                     # SQL schema migration scripts
├── docs/
│   ├── ARCHITECTURE.md             # Detailed architecture documentation
│   ├── PATIENT_SERVICE_SETUP.md    # Full developer setup guide
│   ├── USER_GUIDE.md               # End-user guide
│   └── FEATURE_PROMPT.md           # Feature specification prompts
├── start-all-services.bat          # Windows: start all 6 backend services
└── README.md                       # This file
```

---

## Tech Stack

### Backend

| Technology | Version | Purpose |
|---|---|---|
| Java | 21 (LTS) | Application runtime |
| Spring Boot | 3.3.4 | Microservice framework |
| Spring Cloud Gateway | 2023.0.3 | API Gateway & routing |
| Spring Data JPA | — | ORM / persistence |
| PostgreSQL | 16 | Primary relational database |
| Lombok | 1.18.32 | Boilerplate reduction |
| MapStruct | 1.5.5 | DTO ↔ Entity mapping |
| SpringDoc OpenAPI | 2.5.0 | Swagger UI / API docs |
| Resilience4j | 2.2.0 | Circuit breaker, retry |

### Frontend

| Technology | Version | Purpose |
|---|---|---|
| React | 19 | UI framework |
| TypeScript | 6.x (strict) | Type safety |
| Vite | 8.x | Build tool & dev server (port 5000) |
| React Router | v6 | Client-side routing |
| TanStack Query | v5 | Server state & caching |
| Zustand | 5.x | Client-side state |
| Axios | 1.x | HTTP client with interceptors |
| React Hook Form + Zod | — | Form validation |
| Tailwind CSS | 3.x | Utility-first styling |
| shadcn/ui (Radix) | — | Accessible UI components |
| Lucide React | — | Icons |
| Sonner | — | Toast notifications |

---

## HIPAA Compliance Notes

- **No PHI in URLs** — patient IDs only; PHI values travel via request body
- **Session timeout** — warning at 14 minutes idle; auto-logout at 15 minutes
- **Audit trail** — every patient-data access event is logged to `audit-service` (:7085)
- **Audit tab** — available on every Patient 360 detail page
- **Coverage subscriber ID** — displayed in read-only collapsed card only
- All inter-service communication uses HTTPS in production; the `local` profile uses HTTP for development convenience

---

## Troubleshooting

| Problem | Solution |
|---|---|
| `Port 708x already in use` | macOS/Linux: `lsof -i :7081` · Windows: `netstat -ano \| findstr 7081` — kill the process |
| `Port 5000 already in use` | Change `port` in `healthcare-ui/vite.config.ts` |
| Maven build fails — `healthcare-common not found` | Run `mvn install -DskipTests -pl healthcare-common` from `backend/` first |
| Services start but Swagger shows no routes | Wait ~60 s for full initialization; check individual service console logs |
| Database connection refused | Verify PostgreSQL is running: `pg_ctl status` (Linux/macOS) or check Windows Services |
| `JAVA_HOME not set` | Set `JAVA_HOME` to JDK 21 install dir; add `%JAVA_HOME%\bin` to `PATH` |
| Frontend shows blank page / API errors | Confirm all backend services are running and healthy before starting the UI |

---

## Build for Production

```bash
# Backend — package all services
cd backend
mvn clean package -DskipTests

# Frontend — production bundle
cd healthcare-ui
npm run build        # Output → healthcare-ui/dist/
npm run preview      # Preview production build locally
```

---

> **Version:** 1.0.0-SNAPSHOT · **Compliance:** HIPAA · FHIR R4-aligned · **License:** Internal use only
