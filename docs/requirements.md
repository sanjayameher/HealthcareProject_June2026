# AI Doctor Assistant — Product Requirements Document (PRD)

> **Product Name**: AI Doctor (working title)
> **Version**: 1.1 — Confirmed
> **Date**: July 2026
> **Author**: AI Labs Team
> **Stakeholders**: Practising Physicians, Clinical Directors, Pharmacy, IT/Compliance
> **Launch Market**: 🇮🇳 **Odisha, India** (Odia + English)
> **Business Model**: SaaS — Annual subscription, multi-tier
> **Regulatory**: India DPDP Act 2023 + HIPAA-ready for future expansion

---

## 1. Executive Summary

AI Doctor is an AI-powered clinical assistant built **for doctors, by doctors**. Launching first in **Odisha, India**, with full **Odia language** support, it addresses three critical pain points in day-to-day medical practice:

| # | Use Case | Core Problem |
|---|----------|-------------|
| **A** | **GenAI-Assisted Diagnosis** | Doctors spend excessive time on documentation and may miss differential diagnoses under cognitive load |
| **B** | **Intelligent Prescription Search** | No single tool maps brand ↔ molecule ↔ monotherapy ↔ multi-drug therapy with guideline sourcing |
| **C** | **Online Patient Follow-up** | Post-prescription drug-response monitoring is almost non-existent; adverse events go unreported |

The vision: a single, unified platform that a doctor opens at the start of every consultation and keeps open until the last follow-up message arrives — **reducing documentation time by 60%, improving diagnostic breadth by 40%, and enabling proactive pharmacovigilance**.

### 1.1 Key Product Decisions (Confirmed)

| Decision | Choice | Rationale |
|----------|--------|----------|
| **Launch Market** | Odisha, India | Regional focus allows deep language + workflow optimisation before national expansion |
| **Primary Language** | Odia (ଓଡ଼ିଆ) + English | Doctors converse in Odia-English code-mixed; patients speak Odia |
| **Drug Database** | Build from open-source data + Indian APIs | Full control, no vendor lock-in; CDSCO/ABDM aligned |
| **LLM Strategy** | Multi-LLM Gateway with private LLM option | Doctor chooses LLM; private LLM for data-sovereign deployments |
| **Voice AI (STT)** | Sarvam AI (primary) + Whisper fine-tuned (fallback) | Best Odia support with medical terminology, code-mixing, diarization |
| **Regulatory** | India DPDP Act 2023 (primary) + HIPAA-ready | Indian compliance mandatory; HIPAA readiness for future US/global expansion |
| **Monetisation** | SaaS — Annual subscription, multi-tier | Predictable revenue; scalable per doctor/clinic/hospital |
| **Classification** | Clinical Reference Tool (not SaMD initially) | Lower regulatory bar for MVP; pursue SaMD classification post-validation |

---

## 2. Competitive Landscape & Market Research

### 2.1 Market Overview

The global AI in healthcare market reached **$32.4B in 2025** and is projected at **$164B by 2030** (CAGR ~38%). The market is shifting from simple chatbots to **agentic AI** — autonomous, multi-step clinical agents embedded into workflows.

### 2.2 Competitor Analysis

#### 2.2.1 Clinical Documentation & Diagnosis

| Competitor | Strengths | Weaknesses | Pricing |
|-----------|-----------|------------|---------|
| **Glass Health** | DDx generation, ambient scribing, evidence-cited A&P drafting, EHR integration | No prescription intelligence; no patient follow-up; US-centric | Free–$200/mo |
| **Sully.ai** | Full "AI team" (Scribe, Triage Nurse, Coder, Pharmacist agents); enterprise-grade | Overkill for solo/small practices; no patient-facing follow-up channel | Enterprise contracts |
| **Heidi Health** | Deep customisation, community templates, "Ask Heidi" clinical Q&A, multilingual | Complex UI; expensive premium tiers; no drug-molecule mapping | Free–$150/mo |
| **Freed AI** | Ultra-simple SOAP notes; fastest onboarding; doctor-built | Limited to outpatient/primary care; no diagnosis or prescription modules | ~$90/mo |
| **Abridge** | Market-leading ambient documentation; deep EHR integration (Epic) | Pure documentation — no clinical decision support or Rx | Enterprise |
| **Microsoft DAX Copilot** | Deep EHR (Epic/Cerner) integration; enterprise trust | Not a diagnostic tool; no Rx intelligence; high cost | Enterprise |

#### 2.2.2 Prescription & Drug Intelligence

| Competitor | Strengths | Weaknesses |
|-----------|-----------|------------|
| **Epocrates (+ AI Assist)** | Gold-standard PoC drug reference; conversational AI queries | No brand↔molecule mapping with therapy recommendations; US drug database |
| **UpToDate + Lexidrug** | Deepest clinical evidence base; GenAI reasoning with citations | Subscription wall; no ambient or diagnostic features |
| **Vera Health** | Fast AI-synthesised answers from peer-reviewed literature | New entrant; limited formulary coverage |
| **Clair** | FDA/NIH-trained; instant multi-drug interaction guidance | US-only; no therapy recommendation engine |
| **Micromedex** | Comprehensive drug DB; AI-powered complex queries | Legacy UI; no integration with diagnosis workflow |

#### 2.2.3 Patient Follow-up & Monitoring

| Competitor | Strengths | Weaknesses |
|-----------|-----------|------------|
| **WhatsGrow AI / HumPum AI** | WhatsApp Business API automation; healthcare templates | Generic chatbots — no clinical intelligence or drug-response logic |
| **Bot MD** | Clinician-focused messaging; high engagement rates | No structured pharmacovigilance; no drug-response protocols |
| **Practo (India)** | Massive patient base; AI care navigation; appointment ecosystem | No GenAI diagnosis; limited prescription intelligence |
| **Eka.care (India)** | EkaScribe ambient notes; ABDM/ABHA integration; patient health reports | No prescription molecule search; no follow-up automation |

#### 2.2.4 Competitive Gap Analysis

```
┌─────────────────────────┬──────────┬──────────┬──────────┬───────────────┐
│ Capability              │ Glass    │ Sully.ai │ Epocrates│ AI Doctor     │
│                         │ Health   │          │          │ (OUR PRODUCT) │
├─────────────────────────┼──────────┼──────────┼──────────┼───────────────┤
│ Voice → Clinical Notes  │ ✅       │ ✅       │ ❌       │ ✅            │
│ GenAI Differential Dx   │ ✅       │ ❌       │ ❌       │ ✅            │
│ Brand ↔ Molecule Search │ ❌       │ ❌       │ Partial  │ ✅            │
│ Mono vs Multi-Drug Rx   │ ❌       │ ❌       │ ❌       │ ✅            │
│ Guideline-Sourced Rx    │ ❌       │ ❌       │ Partial  │ ✅            │
│ Drug Interaction Check  │ ❌       │ ❌       │ ✅       │ ✅            │
│ WhatsApp Follow-up      │ ❌       │ ❌       │ ❌       │ ✅            │
│ Drug Response Tracking  │ ❌       │ ❌       │ ❌       │ ✅            │
│ Patient Consent Mgmt    │ ❌       │ ❌       │ ❌       │ ✅            │
│ India Drug DB + ABDM    │ ❌       │ ❌       │ ❌       │ ✅            │
│ Unified Single Platform │ ❌       │ Partial  │ ❌       │ ✅            │
└─────────────────────────┴──────────┴──────────┴──────────┴───────────────┘
```

> **Key Insight**: No single competitor combines all three use cases. The market is fragmented — doctors use 3–5 different tools. AI Doctor's competitive moat is the **unified clinical workflow** from diagnosis → prescription → follow-up.

---

## 3. User Personas

### 3.1 Dr. Sanjay — General Practitioner in Bhubaneswar (Primary Target)
- **Age**: 42 | **Setting**: Private clinic in Saheed Nagar, 40–60 patients/day
- **Pain**: Spends 3+ hours daily on documentation; prescribes from memory; no time for follow-ups
- **Language**: Speaks Odia with patients, writes notes in English, code-switches frequently
- **Needs**: Fast Odia voice-to-notes, drug lookup by brand or molecule, auto follow-up reminders
- **Tech**: Android phone, basic laptop, WhatsApp-savvy patients

### 3.2 Dr. Mamata — Specialist (Cardiologist) at KIMS Hospital
- **Age**: 52 | **Setting**: Multi-specialty hospital, Bhubaneswar
- **Pain**: Complex polypharmacy; needs guideline-backed multi-drug therapy recommendations
- **Language**: Odia + English + Hindi; patients from rural Odisha speak only Odia
- **Needs**: Drug interaction alerts, evidence-sourced combination therapy, structured follow-up protocols
- **Tech**: iPad, hospital EMR, patients prefer WhatsApp follow-up

### 3.3 Dr. Ankit — Junior Resident at SCB Medical College, Cuttack
- **Age**: 28 | **Setting**: Government teaching hospital
- **Pain**: Unsure about differentials; needs a clinical reasoning partner; sees 80+ patients/day in OPD
- **Language**: Odia primary, English for medical documentation
- **Needs**: DDx generation from symptoms, learning-mode explanations, molecule-to-brand mapping, budget-friendly drug options for patients
- **Tech**: Smartphone-first, budget-conscious

---

## 4. Functional Requirements

### 4.1 Use Case A — GenAI-Assisted Diagnosis

#### 4.1.1 Patient Consent Management

| ID | Requirement | Priority |
|----|------------|----------|
| A-01 | System SHALL capture explicit patient consent before any voice recording begins | P0 |
| A-02 | Consent SHALL be captured digitally (e-signature, OTP, or biometric) with timestamp and audit trail | P0 |
| A-03 | Consent form SHALL clearly explain: what is recorded, how AI processes it, data retention period, right to withdraw | P0 |
| A-04 | System SHALL support consent in **Odia** (primary), English, and Hindi at launch; extensible to other regional languages | P0 |
| A-05 | System SHALL allow patients to revoke consent at any time, triggering data deletion within 72 hours | P0 |
| A-06 | Consent records SHALL be immutable and available for regulatory audit | P0 |

#### 4.1.2 Voice Recording & Transcription

| ID | Requirement | Priority |
|----|------------|----------|
| A-10 | System SHALL record doctor-patient dialogue in real-time with ambient listening capability | P0 |
| A-11 | System SHALL support **Odia + English** transcription at launch via **Sarvam AI Saaras v3** model; Hindi as secondary language | P0 |
| A-12 | Transcription accuracy SHALL exceed 95% for medical terminology in Odia-English (measured via WER) | P0 |
| A-13 | System SHALL handle **Odia-English code-switching** (common in Odisha clinical consultations) | P0 |
| A-14 | System SHALL distinguish between doctor and patient speakers (diarization) | P0 |
| A-15 | System SHALL work in noisy clinical environments (SNR ≥ 10dB) | P1 |
| A-16 | System SHALL support offline recording with sync-on-reconnect for areas with poor connectivity | P2 |

#### 4.1.3 Clinical Input Processing

| ID | Requirement | Priority |
|----|------------|----------|
| A-20 | System SHALL accept inputs: voice transcript, typed symptoms, uploaded medical reports (lab, imaging, discharge summaries) | P0 |
| A-21 | System SHALL extract structured data from unstructured medical reports (OCR + NLP) — lab values, imaging findings, previous diagnoses | P0 |
| A-22 | System SHALL support image upload for reports (photo of paper reports, PDF, DICOM viewer link) | P0 |
| A-23 | System SHALL maintain a temporal clinical history per patient across visits | P1 |

#### 4.1.4 GenAI Diagnostic Engine (Multi-LLM)

| ID | Requirement | Priority |
|----|------------|----------|
| A-30 | System SHALL generate a ranked differential diagnosis (DDx) list from provided symptoms, history, and report data | P0 |
| A-31 | Each DDx entry SHALL include: confidence score, supporting evidence from patient data, and citations to clinical guidelines/literature | P0 |
| A-32 | System SHALL flag "red flag" symptoms requiring urgent action (e.g., chest pain + dyspnoea → rule out MI/PE) | P0 |
| A-33 | System SHALL suggest follow-up questions the doctor should ask to narrow the DDx | P1 |
| A-34 | System SHALL suggest relevant investigations (labs, imaging) to confirm/rule out diagnoses | P1 |
| A-35 | System SHALL auto-generate structured clinical notes (SOAP format) from the consultation | P0 |
| A-36 | System SHALL support specialty-specific diagnostic workflows (Cardiology, Endocrinology, Orthopaedics, Paediatrics, etc.) | P1 |
| A-37 | System SHALL provide an "Explain" mode showing the clinical reasoning chain (for learning/audit) | P2 |
| A-38 | System SHALL clearly state it is a **decision-support tool** — the doctor retains full clinical authority | P0 |
| A-39 | System SHALL support a **Multi-LLM Gateway** allowing doctors/admins to choose between: Private LLM (self-hosted), Gemini, GPT-4o, Claude, or open-source models | P0 |
| A-40 | System SHALL route PHI-sensitive queries through the **Private LLM** by default; anonymised queries may use cloud LLMs | P0 |
| A-41 | System SHALL provide an **LLM Settings** panel for admins to configure model preferences, API keys, and fallback chains | P1 |

---

### 4.2 Use Case B — Intelligent Prescription Search

#### 4.2.1 Drug Search Engine

| ID | Requirement | Priority |
|----|------------|----------|
| B-01 | System SHALL support two primary search modes: **Search by Brand Name** and **Search by Molecule/Salt** | P0 |
| B-02 | Search SHALL support fuzzy matching, autocomplete, and synonym resolution (e.g., "Paracetamol" = "Acetaminophen") | P0 |
| B-03 | Search SHALL cover the Indian drug market (250,000+ formulations) with CDSCO-approved drugs | P0 |
| B-04 | Database SHALL be updated weekly with new drug approvals and price changes | P0 |
| B-05 | System SHALL integrate with India's Unified Drug Registry (ABDM) when available | P1 |

#### 4.2.2 Brand → Molecule Resolution

| ID | Requirement | Priority |
|----|------------|----------|
| B-10 | Given a brand name, system SHALL display: molecule composition, manufacturer, available strengths, dosage forms, MRP | P0 |
| B-11 | System SHALL show all alternative brands for the same molecule composition, sorted by price | P0 |
| B-12 | System SHALL flag if a brand is discontinued, recalled, or has regulatory warnings | P0 |

#### 4.2.3 Molecule → Therapy Recommendations

| ID | Requirement | Priority |
|----|------------|----------|
| B-20 | Given a molecule, system SHALL classify therapy options into: **Monotherapy (Single Pill)** and **Multi-Drug Therapy (Combination)** | P0 |
| B-21 | For **Monotherapy**: system SHALL list all single-ingredient formulations with available brands and pricing | P0 |
| B-22 | For **Multi-Drug Therapy**: system SHALL recommend evidence-based combinations, with filters for: | P0 |
| | — **Patient-Friendly**: Fewer pills, fixed-dose combinations (FDCs), once-daily dosing | |
| | — **Pocket-Friendly**: Lowest cost combinations achieving therapeutic equivalence | |
| B-23 | Each recommendation SHALL cite the source guideline (e.g., "JNC-8 recommends ACEi + CCB for Stage 2 HTN", "ADA 2024 recommends Metformin + SGLT2i for T2DM with CKD") | P0 |
| B-24 | System SHALL display drug-drug interactions for any combination with severity grading (Contraindicated / Major / Moderate / Minor) | P0 |
| B-25 | System SHALL check against patient's existing medications (if available) for interactions | P1 |
| B-26 | System SHALL show pharmacokinetic details: mechanism of action, CYP450 interactions, renal/hepatic dosing adjustments | P1 |
| B-27 | System SHALL support dose calculator for weight-based / renal-adjusted dosing | P2 |

#### 4.2.4 Prescription Generation

| ID | Requirement | Priority |
|----|------------|----------|
| B-30 | System SHALL allow the doctor to select drugs from search results and auto-populate a prescription | P0 |
| B-31 | Prescription SHALL include: drug name (brand + generic), strength, dosage, frequency, duration, special instructions | P0 |
| B-32 | System SHALL generate prescription in printable format (PDF) and shareable digital format | P0 |
| B-33 | System SHALL maintain a prescription history per patient | P1 |

---

### 4.3 Use Case C — Online Patient Follow-up

#### 4.3.1 Follow-up Protocol Engine

| ID | Requirement | Priority |
|----|------------|----------|
| C-01 | System SHALL auto-generate follow-up schedules based on the prescribed drugs and diagnosis | P0 |
| C-02 | Follow-up timing SHALL be configurable by the doctor (e.g., Day 3, Day 7, Day 14 after prescription) | P0 |
| C-03 | System SHALL include drug-specific follow-up questionnaires (e.g., "Are you experiencing any dizziness?" for antihypertensives) | P0 |
| C-04 | System SHALL support symptom-severity scoring (e.g., Visual Analog Scale 1–10, standardised scales like PHQ-9 for depression) | P1 |

#### 4.3.2 WhatsApp Integration

| ID | Requirement | Priority |
|----|------------|----------|
| C-10 | System SHALL send automated follow-up messages via **WhatsApp Business API** | P0 |
| C-11 | Messages SHALL be in the patient's preferred language | P0 |
| C-12 | System SHALL collect patient responses (free text + structured buttons) and parse them with NLP | P0 |
| C-13 | System SHALL support rich media: patients can send photos of symptoms, rashes, wound healing progress | P1 |
| C-14 | System SHALL provide 24/7 automated responses for common queries (e.g., "Can I take this medicine with milk?") | P2 |

#### 4.3.3 App-Based Follow-up

| ID | Requirement | Priority |
|----|------------|----------|
| C-20 | System SHALL provide a patient-facing mobile app (iOS + Android) for follow-up interactions | P1 |
| C-21 | App SHALL display: current medications, dosage schedule, upcoming follow-up dates | P1 |
| C-22 | App SHALL support push notifications for medication reminders and follow-up check-ins | P1 |
| C-23 | App SHALL integrate with wearable devices (pulse, BP, glucose) for passive monitoring data | P2 |

#### 4.3.4 Drug Response Analytics & Alerts

| ID | Requirement | Priority |
|----|------------|----------|
| C-30 | System SHALL aggregate patient responses into a **Drug Response Dashboard** for the doctor | P0 |
| C-31 | Dashboard SHALL show: adherence rate, reported side effects, symptom improvement trends | P0 |
| C-32 | System SHALL flag **adverse drug reactions (ADRs)** using WHO-UMC causality criteria and alert the doctor immediately | P0 |
| C-33 | System SHALL auto-escalate critical responses (e.g., "I'm having chest pain", "I can't breathe") to the doctor via phone call / push notification | P0 |
| C-34 | System SHALL generate structured ADR reports for pharmacovigilance submission (ICSRs) | P2 |
| C-35 | System SHALL track drug efficacy trends across the doctor's patient population ("Drug X works better than Drug Y for HTN in my patients") | P2 |

---

## 5. Non-Functional Requirements

### 5.1 Security & Compliance

| ID | Requirement | Priority |
|----|------------|----------|
| NF-01 | System SHALL comply with **India's DPDP Act 2023** (Digital Personal Data Protection) | P0 |
| NF-02 | System SHALL be **HIPAA-ready** for international deployments | P1 |
| NF-03 | All data SHALL be encrypted at rest (AES-256) and in transit (TLS 1.3) | P0 |
| NF-04 | PHI (Protected Health Information) SHALL NOT leave India's jurisdiction (data residency) | P0 |
| NF-05 | System SHALL maintain complete audit trails for all clinical interactions | P0 |
| NF-06 | System SHALL support role-based access control (Doctor, Nurse, Admin, Patient) | P0 |
| NF-07 | Voice recordings SHALL be auto-deleted after transcription + verification (configurable retention: 24h–90 days) | P0 |

### 5.2 Performance

| ID | Requirement | Priority |
|----|------------|----------|
| NF-10 | Voice transcription latency SHALL be < 2 seconds (real-time streaming) | P0 |
| NF-11 | DDx generation SHALL complete within < 8 seconds of input submission | P0 |
| NF-12 | Drug search results SHALL return in < 500ms | P0 |
| NF-13 | System SHALL support 10,000 concurrent users at launch, scalable to 100,000 | P1 |
| NF-14 | System uptime SHALL be ≥ 99.9% (8.7h downtime/year max) | P0 |

### 5.3 Usability

| ID | Requirement | Priority |
|----|------------|----------|
| NF-20 | Doctor-facing interface SHALL be usable on tablet and desktop (responsive, touch-friendly) | P0 |
| NF-21 | Core workflows (start recording → get DDx → prescribe → set follow-up) SHALL be completable in < 5 minutes per consultation | P0 |
| NF-22 | System SHALL not require more than 30 minutes of training for an average doctor | P0 |
| NF-23 | UI SHALL follow a "progressive disclosure" pattern — simple by default, detailed on demand | P0 |

### 5.4 Integration

| ID | Requirement | Priority |
|----|------------|----------|
| NF-30 | System SHALL provide REST APIs for EMR/EHR integration | P1 |
| NF-31 | System SHALL integrate with **ABDM/ABHA** for patient identity and health record exchange | P1 |
| NF-32 | System SHALL integrate with **WhatsApp Business API** (via approved BSP) | P0 |
| NF-33 | System SHALL support HL7 FHIR for interoperability | P2 |

---

## 6. Data Requirements

### 6.1 Drug Database (Build Strategy — Confirmed)

**Approach**: Build our own drug database from open Indian data sources and APIs.

| Source | Type | Data | Cost |
|--------|------|------|------|
| **ABDM Unified Drug Registry** | Government API | Standardised drug master (SNOMED CT coded) | Free |
| **CDSCO Data Bank (SUGAM)** | Government portal | Approved drugs, recalls, banned substances | Free |
| **Kaggle — All India Drug Database** | Open dataset (CC) | 250,000+ records: brand, generic, manufacturer, MRP, composition | Free |
| **GitHub — Indian Medicine Dataset** | Open-source JSON | Brand names, prices, compositions | Free |
| **DrugSetu API** | Commercial API | Real-time drug data, CDSCO-aligned | ~₹5L/yr |
| **Eka Care Developer API** | Commercial API | Clinician-validated data from National Formulary of India | ~₹5L/yr |
| **DPCO Price Lists** | Government gazette | Ceiling prices for scheduled drugs | Free |

**Build Pipeline**:
1. **Seed**: Ingest Kaggle 250K dataset + GitHub Indian Medicine Dataset → PostgreSQL
2. **Enrich**: Cross-reference with ABDM Drug Registry + CDSCO approvals
3. **Validate**: Pharmacist review pipeline for top 5,000 most-prescribed drugs in Odisha
4. **Maintain**: Weekly ETL sync with CDSCO + ABDM; DrugSetu API for real-time fallback
5. **Regional Focus**: Prioritise drugs commonly prescribed in Odisha (tropical diseases, malaria, dengue, diabetes, HTN)

- **Fields**: Brand name, generic/molecule name(s), manufacturer, strength, dosage form, MRP, composition, schedule (H/H1/X), DPCO ceiling price, ATC code, therapeutic class, FDC flag
- **Update frequency**: Weekly automated sync
- **Size**: 250,000+ formulations at launch

### 6.2 Clinical Knowledge Base
- **Sources**: PubMed, UpToDate (licensed), WHO guidelines, national clinical guidelines (ICMR, API, RSSDI, CSI), specialty society recommendations
- **Regional additions**: Odisha-specific disease prevalence data (malaria, sickle cell disease, leptospirosis, snakebite protocols)
- **Structure**: Vectorised knowledge graph for retrieval-augmented generation (RAG)
- **Update frequency**: Monthly for guidelines; continuous for PubMed abstracts

### 6.3 Drug Interaction Database
- **Sources**: DrugBank (open-source core), FDA drug interaction data, CDSCO adverse event reports
- **Build approach**: Seed from DrugBank open-access + augment with clinical guideline interaction tables
- **Coverage**: ≥ 50,000 drug-drug interaction pairs at launch
- **Severity classification**: Contraindicated / Major / Moderate / Minor with mechanism descriptions

### 6.4 Follow-up Protocol Templates
- **Drug-specific questionnaires**: Mapped to ATC codes (e.g., all ACE inhibitors → check for dry cough)
- **Disease-specific protocols**: Post-MI Day 3/7/30, New DM diagnosis Week 1/2/4, etc.
- **Odisha-specific**: Malaria treatment Day 3/7 follow-up, Dengue platelet monitoring, Sickle cell crisis post-discharge
- **Language**: Follow-up messages in **Odia** with English fallback
- **Customisable**: Doctors can create and share their own protocols

---

## 7. Success Metrics

| Metric | Target (6 months post-launch) | Measurement |
|--------|-------------------------------|-------------|
| Documentation time per consultation | Reduced by 60% (from ~15 min to ~6 min) | In-app timing analytics |
| DDx accuracy | ≥ 85% (correct diagnosis in top-5 suggestions) | Clinical validation study |
| Prescription errors prevented | ≥ 200/month per 1,000 doctors | Interaction alert logs |
| Patient follow-up response rate (WhatsApp) | ≥ 70% | Message delivery + response tracking |
| ADR detection rate | 3× improvement over baseline | Pharmacovigilance dashboard |
| Doctor NPS (Net Promoter Score) | ≥ 60 | Quarterly survey |
| Daily Active Users | 500 doctors in Odisha within 6 months; 5,000 nationally within 12 months | Analytics |

---

## 8. Business Model — SaaS Multi-Tier Subscription

| Tier | Name | Target | Monthly Price | Annual Price | Features |
|------|------|--------|--------------|-------------|----------|
| **Free** | Starter | Medical students, evaluation | ₹0 | ₹0 | 10 consultations/month, basic drug search, no follow-up |
| **Basic** | Practitioner | Solo GPs, small clinics | ₹999/mo | ₹9,999/yr | Unlimited consultations, full drug search, 50 WhatsApp follow-ups/mo, cloud LLM |
| **Pro** | Specialist | Specialists, group practices | ₹2,499/mo | ₹24,999/yr | Everything in Basic + multi-drug therapy, drug interactions, unlimited follow-ups, LLM choice, analytics dashboard |
| **Enterprise** | Hospital | Hospitals, chains | Custom | Custom | Everything in Pro + private LLM, EMR integration, ABDM/ABHA, multi-doctor admin, SLA, dedicated support |

**Revenue Projections (Year 1 — Odisha)**:
- Target: 500 paid doctors × avg ₹15,000/yr = ₹75L ARR
- Expansion to pan-India Year 2: 5,000 doctors × avg ₹18,000/yr = ₹9 Cr ARR

---

## 9. Constraints & Assumptions

### 9.1 Constraints
1. **Regulatory**: AI Doctor launches as a **clinical reference tool** (not SaMD). All outputs require physician verification. Clear disclaimers per CDSCO guidance. SaMD classification to be pursued post-clinical-validation.
2. **Data Privacy**: Compliant with **India DPDP Act 2023** (primary) and **HIPAA-ready** (for future US expansion). Voice recordings and patient data must stay within Indian jurisdiction. No training on patient data without explicit, separate consent.
3. **Liability**: The prescribing physician retains full legal responsibility. AI Doctor provides recommendations, not orders.
4. **Budget**: MVP within ₹1.5 Cr (~$175K) for 6-month build.
5. **Language**: MVP must support **Odia** as the primary voice/chat language. English for medical documentation output.

### 9.2 Regulatory Compliance Matrix

| Regulation | Scope | Status | Action Required |
|-----------|-------|--------|----------------|
| **DPDP Act 2023** (India) | Personal data protection | Primary — Mandatory | Consent framework, DPO appointment, DPIA, breach reporting |
| **CDSCO MDR 2017** | Medical device classification | Monitor — Not SaMD at launch | Position as clinical reference tool; document intended use carefully |
| **ABDM Standards** | Health data interoperability | Integration planned (P1) | ABHA ID support, SNOMED CT drug coding |
| **HIPAA** (US) | Protected health information | Ready — Not mandatory for India launch | Architecture designed for HIPAA compliance for future US expansion |
| **ISO 13485** | QMS for medical devices | Future — Post-validation | Required if pursuing SaMD classification |
| **SOC 2 Type 1** | Security controls | Target for GA launch | Third-party audit during Phase 4 |

### 9.3 Assumptions
1. Doctors in Odisha have access to a tablet, laptop, or smartphone with a microphone.
2. Internet connectivity is available during consultations (2G minimum for text, 4G for voice streaming). Many clinics in Bhubaneswar/Cuttack have 4G+.
3. Patients in Odisha are willing to engage via WhatsApp for follow-ups (95%+ WhatsApp penetration in urban Odisha).
4. Sarvam AI provides production-grade Odia STT with acceptable WER (< 10%) for medical consultations.
5. Open-source Indian drug datasets (Kaggle, GitHub) are sufficiently accurate for MVP with pharmacist validation overlay.

---

## 9. Risks & Mitigations

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| AI hallucination in DDx/Rx | Critical — wrong treatment | Medium | RAG with curated medical KB; mandatory "human-in-the-loop"; confidence thresholds; clinical validation pre-launch |
| Data breach / PHI leak | Critical — legal + trust | Low | End-to-end encryption; SOC 2 compliance; regular pen testing; data residency in India |
| Low doctor adoption | High — no revenue | Medium | Doctor-first design; < 30 min training; pilot with 50 champion doctors; iterative feedback loops |
| Drug database accuracy | High — wrong drug info | Medium | Multiple source cross-validation; pharmacist review pipeline; automated CDSCO sync |
| WhatsApp API policy changes | Medium — follow-up disruption | Low | Multi-channel architecture (WhatsApp + App + SMS fallback) |
| Regulatory changes (DPDP, SaMD) | High — compliance gaps | Medium | Dedicated compliance officer; quarterly regulatory review; modular architecture for quick adaptation |

---

## 11. Out of Scope (v1.0)

- Medical imaging analysis (X-ray, CT, MRI interpretation)
- E-prescribing with pharmacy fulfilment
- Insurance/billing integration
- Telemedicine video consultation
- EMR replacement (we integrate, not replace)
- International drug databases (US/EU) — Odisha/India-first approach
- Languages beyond Odia, English, Hindi (expandable post-launch)
- SaMD certification (pursued post-clinical-validation study)

---

## 12. Glossary

| Term | Definition |
|------|-----------|
| **DDx** | Differential Diagnosis — a ranked list of possible diagnoses |
| **FDC** | Fixed-Dose Combination — multiple drugs in a single pill |
| **ADR** | Adverse Drug Reaction |
| **ABDM** | Ayushman Bharat Digital Mission |
| **ABHA** | Ayushman Bharat Health Account (patient digital ID) |
| **CDSCO** | Central Drugs Standard Control Organisation (India's FDA equivalent) |
| **ICSR** | Individual Case Safety Report (pharmacovigilance standard) |
| **RAG** | Retrieval-Augmented Generation (LLM technique grounded in source documents) |
| **SaMD** | Software as a Medical Device |
| **SOAP** | Subjective, Objective, Assessment, Plan (clinical note format) |
| **PHI** | Protected Health Information |
| **WER** | Word Error Rate (speech recognition accuracy metric) |
