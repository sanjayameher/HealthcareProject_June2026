# Digital Health Platform — Patient Module
## High-Level Architecture Document
**Stack:** Java 21 · Spring Boot 3.3 · Spring Cloud 2023 · PostgreSQL 16 · Kafka · Redis · Keycloak

---

## 1. System Context Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        EXTERNAL ACTORS                                       │
│                                                                               │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐    │
│  │   Patient    │  │  Clinician   │  │  Admin Staff │  │ Third-Party  │    │
│  │  (Browser /  │  │  (Browser /  │  │  (Browser)   │  │  EHR / Lab   │    │
│  │  Mobile App) │  │  Mobile App) │  │              │  │  System      │    │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘    │
└─────────┼─────────────────┼─────────────────┼─────────────────┼─────────────┘
          │  HTTPS/TLS 1.3  │                 │                 │
          ▼                 ▼                 ▼                 ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                         PLATFORM BOUNDARY                                    │
│                                                                               │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │                       API GATEWAY (Spring Cloud Gateway)             │    │
│  │   Rate Limiting │ Auth Filter │ Request Logging │ Circuit Breaker    │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                                    │                                          │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │                    IDENTITY PROVIDER (Keycloak)                      │    │
│  │             OAuth 2.0 / OIDC │ RBAC │ JWT Issuance                  │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Microservices Architecture

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                              API GATEWAY :8080                                   │
│              Spring Cloud Gateway  │  JWT Validation  │  Rate Limiter            │
└──────┬──────────┬──────────┬──────────┬──────────┬─────────────────────────────┘
       │          │          │          │          │
       ▼          ▼          ▼          ▼          ▼
  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐
  │ PATIENT │ │CLINICAL │ │BILLING  │ │ PORTAL  │ │  AUDIT  │
  │SERVICE  │ │SERVICE  │ │SERVICE  │ │SERVICE  │ │SERVICE  │
  │  :8081  │ │  :8082  │ │  :8083  │ │  :8084  │ │  :8085  │
  └────┬────┘ └────┬────┘ └────┬────┘ └────┬────┘ └────┬────┘
       │           │           │           │            │
       └───────────┴───────────┴─────┬─────┴────────────┘
                                     │
              ┌──────────────────────┼──────────────────────┐
              ▼                      ▼                      ▼
       ┌─────────────┐      ┌──────────────┐      ┌──────────────┐
       │  PostgreSQL  │      │     Redis    │      │    Kafka     │
       │   healthdb  │      │   (Cache /   │      │  (Async      │
       │  :5432      │      │   Session)   │      │   Events)    │
       └─────────────┘      └──────────────┘      └──────────────┘
              │
       ┌──────┴──────────────────────────────┐
       │  Schemas:                            │
       │  patient │ clinical │ billing        │
       │  portal  │ audit                    │
       └─────────────────────────────────────┘
```

---

## 3. Patient Service — Internal Architecture (Hexagonal)

```
┌─────────────────────────────────────────────────────────────────────────┐
│                          PATIENT SERVICE                                  │
│                                                                           │
│  ┌─────────────────────────────────────────────────────────────────┐    │
│  │                    INBOUND ADAPTERS (Driving)                    │    │
│  │                                                                   │    │
│  │  ┌──────────────────────┐    ┌──────────────────────────────┐   │    │
│  │  │   REST Controllers   │    │   Kafka Event Consumers      │   │    │
│  │  │  PatientController   │    │  (PatientEventConsumer)      │   │    │
│  │  │  OrgController       │    └──────────────────────────────┘   │    │
│  │  │  PractitionerCtrl    │                                        │    │
│  │  └──────────┬───────────┘                                        │    │
│  └─────────────┼───────────────────────────────────────────────────┘    │
│                │                                                           │
│  ┌─────────────▼───────────────────────────────────────────────────┐    │
│  │                    APPLICATION CORE (Domain)                     │    │
│  │                                                                   │    │
│  │  ┌─────────────────────────────────────────────────────────┐   │    │
│  │  │                    SERVICE LAYER                         │   │    │
│  │  │  PatientService │ OrgService │ PractitionerService       │   │    │
│  │  │  PatientDemographicsService │ PatientSearchService       │   │    │
│  │  └─────────────────────────────────────────────────────────┘   │    │
│  │                                                                   │    │
│  │  ┌─────────────────────────────────────────────────────────┐   │    │
│  │  │                    DOMAIN ENTITIES                       │   │    │
│  │  │  Patient │ Organization │ Practitioner                   │   │    │
│  │  │  PatientName │ PatientAddress │ PatientTelecom           │   │    │
│  │  │  PatientContact │ PatientIdentifier │ PatientFlag        │   │    │
│  │  └─────────────────────────────────────────────────────────┘   │    │
│  └─────────────────────────────────────────────────────────────────┘    │
│                │                                                           │
│  ┌─────────────▼───────────────────────────────────────────────────┐    │
│  │                    OUTBOUND ADAPTERS (Driven)                    │    │
│  │                                                                   │    │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────┐  │    │
│  │  │  JPA Repos   │  │ Kafka Event  │  │  PHI Encryption      │  │    │
│  │  │  (Spring     │  │  Producers   │  │  Service (AES-256)   │  │    │
│  │  │   Data JPA)  │  │              │  │                      │  │    │
│  │  └──────┬───────┘  └──────────────┘  └──────────────────────┘  │    │
│  └─────────┼───────────────────────────────────────────────────────┘    │
└────────────┼─────────────────────────────────────────────────────────────┘
             ▼
     PostgreSQL healthdb
     schema: patient.*
```

---

## 4. Service Responsibilities

| Service | Port | Schema(s) | Responsibility |
|---------|------|-----------|----------------|
| **api-gateway** | 8080 | — | Routing, Auth filter, Rate limiting, Circuit breaking |
| **patient-service** | 8081 | `patient` | Demographics, identifiers, names, addresses, contacts, flags, organizations, practitioners |
| **clinical-service** | 8082 | `clinical` | Encounters, observations (vitals/labs), conditions, medications, lab orders, reports, care plans, documents |
| **billing-service** | 8083 | `billing` | Insurance payers, coverage, eligibility verification |
| **portal-service** | 8084 | `portal` | Patient accounts, consents, appointments, secure messaging, notifications |
| **audit-service** | 8085 | `audit` | HIPAA audit trail, PHI access log, change history |
| **notification-service** | 8086 | `portal` | Email/SMS/push delivery via SendGrid/Twilio |

---

## 5. Technology Stack

| Layer | Technology | Version |
|-------|-----------|---------|
| Language | Java (Virtual Threads) | 21 LTS |
| Framework | Spring Boot | 3.3.4 |
| Cloud | Spring Cloud | 2023.0.3 |
| API Gateway | Spring Cloud Gateway | 4.1.x |
| Service Discovery | Spring Cloud Eureka | 4.1.x |
| Security | Spring Security + Keycloak | 6.x |
| Persistence | Spring Data JPA + Hibernate | 6.4 |
| Database | PostgreSQL | 16+ |
| Mapping | MapStruct | 1.5.5 |
| Caching | Spring Cache + Redis | 7.x |
| Messaging | Apache Kafka | 3.7 |
| API Docs | SpringDoc OpenAPI | 2.5 |
| Resilience | Resilience4j | 2.2 |
| Observability | Micrometer + Actuator | 1.13 |
| Logging | Logback (JSON structured) | 1.5 |
| Build | Maven | 3.9 |

---

## 6. Security Architecture

```
Client Request
     │
     ▼
┌─────────────────────────────────────────────────────────┐
│  API GATEWAY                                             │
│  1. Extract Bearer JWT from Authorization header        │
│  2. Validate JWT signature against Keycloak JWKS URI    │
│  3. Extract roles: ROLE_PATIENT, ROLE_CLINICIAN, etc.   │
│  4. Forward enriched headers to downstream services     │
└────────────────────────────┬────────────────────────────┘
                             │ X-User-Id, X-User-Role,
                             │ X-Organization-Id headers
                             ▼
┌─────────────────────────────────────────────────────────┐
│  MICROSERVICE (e.g., patient-service)                   │
│                                                          │
│  Spring Security Resource Server                        │
│  ├── Method-level @PreAuthorize on service methods      │
│  ├── RLS context set via SET LOCAL app.* params         │
│  ├── PHI fields decrypted only for authorized roles     │
│  └── All access logged to audit.phi_access_log          │
└─────────────────────────────────────────────────────────┘
```

---

## 7. PHI Data Protection Flow

```
Application Write:               Application Read:
                                 
Patient.name (plaintext)         DB returns encrypted BYTEA
        │                                 │
        ▼                                 ▼
PhiEncryptionConverter           PhiEncryptionConverter
  AES-256-GCM encrypt              AES-256-GCM decrypt
  Key from AWS KMS / Vault          Key from AWS KMS / Vault
        │                                 │
        ▼                                 ▼
  Store as BYTEA               Return plaintext to caller
  in PostgreSQL                       │
                                       ▼
                              AuditAspect logs access
                              to audit.phi_access_log
```

---

## 8. Event-Driven Architecture (Kafka Topics)

| Topic | Producer | Consumers | Purpose |
|-------|----------|-----------|---------|
| `patient.created` | patient-service | audit-service, portal-service | New patient registered |
| `patient.updated` | patient-service | audit-service, clinical-service | Demographic change |
| `encounter.finished` | clinical-service | billing-service, audit-service | Trigger billing workflow |
| `lab.result.available` | clinical-service | portal-service, notification-service | Notify patient |
| `appointment.booked` | portal-service | notification-service, clinical-service | Send reminders |
| `prescription.created` | clinical-service | portal-service, notification-service, audit-service | Drug safety check |
| `phi.accessed` | All services | audit-service | HIPAA audit stream |

---

## 9. API Design Conventions

- **Base URL**: `https://api.healthplatform.com/api/v1`
- **Versioning**: URI path (`/api/v1/`, `/api/v2/`)
- **Auth**: Bearer JWT in `Authorization` header
- **Content-Type**: `application/json`
- **FHIR Alignment**: Resource endpoints map to FHIR R4 resource names
- **Pagination**: `?page=0&size=20&sort=createdAt,desc`
- **Search**: Query params aligned to FHIR search parameters

### Patient Service Endpoints

| Method | Path | Description |
|--------|------|-------------|
| `POST` | `/api/v1/patients` | Register new patient |
| `GET` | `/api/v1/patients/{id}` | Get patient by ID |
| `PUT` | `/api/v1/patients/{id}` | Update patient |
| `DELETE` | `/api/v1/patients/{id}` | Soft-delete patient |
| `GET` | `/api/v1/patients/search` | Search patients (name, DOB, MRN) |
| `GET` | `/api/v1/patients/{id}/summary` | Patient dashboard summary |
| `GET` | `/api/v1/patients/{id}/names` | Patient name history |
| `POST` | `/api/v1/patients/{id}/names` | Add patient name |
| `GET` | `/api/v1/patients/{id}/addresses` | Patient addresses |
| `POST` | `/api/v1/patients/{id}/addresses` | Add address |
| `GET` | `/api/v1/patients/{id}/telecoms` | Contact details |
| `POST` | `/api/v1/patients/{id}/telecoms` | Add contact |
| `GET` | `/api/v1/patients/{id}/contacts` | Emergency contacts |
| `GET` | `/api/v1/patients/{id}/flags` | Safety flags/alerts |
| `GET` | `/api/v1/organizations` | List organizations |
| `POST` | `/api/v1/organizations` | Create organization |
| `GET` | `/api/v1/practitioners` | List practitioners |
| `POST` | `/api/v1/practitioners` | Register practitioner |

---

## 10. Project Directory Structure

```
healthcare-platform/
├── pom.xml                          ← Parent POM (multi-module)
├── healthcare-common/               ← Shared library
│   ├── pom.xml
│   └── src/main/java/com/healthcare/common/
│       ├── crypto/PhiEncryptionService.java
│       ├── dto/ApiResponse.java
│       ├── audit/AuditContext.java
│       ├── exception/
│       └── security/SecurityUtils.java
├── api-gateway/                     ← Spring Cloud Gateway
│   ├── pom.xml
│   └── src/main/
│       ├── java/com/healthcare/gateway/
│       └── resources/application.yml
├── patient-service/                 ← Core patient module ★
│   ├── pom.xml
│   └── src/main/java/com/healthcare/patient/
│       ├── PatientServiceApplication.java
│       ├── config/
│       ├── domain/entity/          ← JPA Entities
│       ├── domain/enums/           ← Java enums
│       ├── repository/             ← Spring Data JPA Repositories
│       ├── service/                ← Business logic
│       ├── controller/             ← REST Controllers
│       ├── dto/request/            ← Inbound DTOs (Java Records)
│       ├── dto/response/           ← Outbound DTOs (Java Records)
│       ├── mapper/                 ← MapStruct Mappers
│       ├── converter/              ← JPA AttributeConverters (encryption)
│       ├── aspect/                 ← AOP: Audit, PHI logging
│       └── exception/              ← Custom exceptions + handler
├── clinical-service/
├── billing-service/
├── portal-service/
└── audit-service/
```
