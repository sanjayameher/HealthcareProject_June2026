# Healthcare UI

Production-quality React frontend for the Healthcare Platform microservices.

## Tech Stack

| Tool | Purpose |
|---|---|
| React 18 + TypeScript (strict) | UI framework |
| Vite | Build tool & dev server |
| React Router v6 | Client-side routing |
| TanStack Query v5 | Server state, caching, polling |
| Zustand | Client state (sidebar, session) |
| Axios | HTTP client with interceptors |
| React Hook Form + Zod | Form validation |
| Tailwind CSS v3 | Styling |
| shadcn/ui (Radix primitives) | UI components |
| Lucide React | Icons |
| Sonner | Toast notifications |
| date-fns | Date formatting |

## Prerequisites

All backend services must be running:

| Service | Port |
|---|---|
| patient-service | 8081 |
| clinical-service | 8082 |
| billing-service | 8083 |
| portal-service | 8084 |
| audit-service | 8085 |

## Setup

```bash
cd healthcare-ui
npm install
npm run dev
```

App runs at **http://localhost:3000**

## Environment

No `.env` file required — all services run on localhost with no auth in dev profile.

## Routes

| Route | Description |
|---|---|
| `/` | Dashboard with stats and recent patients |
| `/organizations` | Organization list |
| `/organizations/new` | Create organization |
| `/organizations/:id` | Organization detail |
| `/practitioners` | Practitioner list |
| `/practitioners/new` | Register practitioner |
| `/practitioners/:id` | Practitioner detail |
| `/patients` | Patient list with search by name or MRN |
| `/patients/new` | Multi-step patient registration (5 steps) |
| `/patients/:id` | Patient 360 — Demographics, Encounters, Coverage, Audit tabs |
| `/patients/:id/edit` | Update patient |
| `/encounters/new` | Create encounter (telehealth platform shown for virtual class) |
| `/billing/payers` | Payer list |
| `/billing/payers/new` | Add payer |
| `/billing/coverage/new` | Add insurance coverage |
| `/audit` | Audit trail search by patient ID or user ID |

## HIPAA Notes

- No PHI in URL params — IDs only, values via request body
- Session timeout warning at 14 min idle, auto-logout toast at 15 min
- Audit tab on every patient detail page
- Coverage subscriber ID shown in read-only collapsed card

## Build

```bash
npm run build      # production build → dist/
npm run preview    # preview production build locally
```
