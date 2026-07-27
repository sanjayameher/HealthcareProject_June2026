package com.healthcare.cds.service;

import com.healthcare.cds.client.OllamaEmbeddingClient;
import com.healthcare.cds.repository.KnowledgeChunkRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;

import java.util.List;

/**
 * Seeds dev.cds_knowledge_chunks on first startup so the RAG pipeline has something to
 * retrieve against locally. This is illustrative sample content for demoing the retrieval
 * pipeline — NOT a vetted clinical reference set. Replace with a real, curated, licensed
 * knowledge source before this ever informs an actual clinical decision.
 */
@Component
@Order
@RequiredArgsConstructor
@Slf4j
public class KnowledgeSeedLoader implements ApplicationRunner {

    private final KnowledgeChunkRepository knowledgeChunkRepository;
    private final OllamaEmbeddingClient embeddingClient;

    @Override
    public void run(ApplicationArguments args) {
        if (knowledgeChunkRepository.hasAnyChunks()) {
            log.info("CDS knowledge base already seeded — skipping.");
            return;
        }

        log.info("Seeding CDS knowledge base with {} sample reference chunks (illustrative only, not clinically validated)...",
                SAMPLE_CHUNKS.size());
        int seeded = 0;
        for (SeedChunk chunk : SAMPLE_CHUNKS) {
            try {
                float[] embedding = embeddingClient.embed(chunk.content());
                knowledgeChunkRepository.insert(chunk.sourceType(), chunk.sourceRef(), chunk.content(), embedding);
                seeded++;
            } catch (Exception e) {
                log.warn("Skipping seed chunk '{}' — embedding failed (is Ollama running with nomic-embed-text pulled?): {}",
                        chunk.sourceRef(), e.getMessage());
            }
        }
        log.info("CDS knowledge base seeding complete: {}/{} chunks embedded and stored.", seeded, SAMPLE_CHUNKS.size());
    }

    private record SeedChunk(String sourceType, String sourceRef, String content) {}

    private static final List<SeedChunk> SAMPLE_CHUNKS = List.of(
            new SeedChunk("clinical_guideline", "Common Cold — Symptomatic Management",
                    "The common cold (viral upper respiratory infection) is typically self-limiting, lasting 7-10 days. " +
                    "Management is supportive: rest, oral hydration, and antipyretics/analgesics such as acetaminophen " +
                    "or ibuprofen for fever and myalgia. Antibiotics are not indicated for uncomplicated viral URIs. " +
                    "Decongestants (e.g., pseudoephedrine) or intranasal saline may relieve nasal congestion. " +
                    "Advise return precautions if symptoms persist beyond 10 days, fever exceeds 39C, or focal " +
                    "findings suggest bacterial superinfection (e.g., sinusitis, otitis media)."),

            new SeedChunk("clinical_guideline", "Influenza — Outpatient Management",
                    "Influenza presents with abrupt onset fever, myalgia, headache, and cough. In otherwise healthy, " +
                    "low-risk adults presenting >48 hours after symptom onset, supportive care (rest, fluids, " +
                    "acetaminophen or ibuprofen for fever/myalgia) is generally sufficient. Oseltamivir 75 mg twice " +
                    "daily for 5 days may be considered within 48 hours of onset, particularly in high-risk patients " +
                    "(age 65+, pregnancy, chronic cardiopulmonary disease, immunocompromise)."),

            new SeedChunk("clinical_guideline", "Acute Pharyngitis — When to Treat with Antibiotics",
                    "Most acute pharyngitis is viral and self-limited. Group A Streptococcus (GAS) accounts for a " +
                    "minority of cases and is suggested by the Centor criteria (fever, tonsillar exudate, tender " +
                    "anterior cervical adenopathy, absence of cough). Rapid antigen testing or throat culture should " +
                    "confirm GAS before antibiotics. First-line treatment for confirmed GAS pharyngitis is penicillin " +
                    "V or amoxicillin for 10 days; use azithromycin or a cephalosporin if penicillin-allergic, with " +
                    "caution given partial cross-reactivity."),

            new SeedChunk("clinical_guideline", "Hypertension — First-Line Pharmacotherapy",
                    "For most adults with stage 1-2 essential hypertension without compelling comorbid indications, " +
                    "first-line agents include thiazide/thiazide-like diuretics (e.g., chlorthalidone, hydrochlorothiazide), " +
                    "ACE inhibitors (e.g., lisinopril), ARBs (e.g., losartan), or calcium channel blockers (e.g., " +
                    "amlodipine). ACE inhibitors and ARBs should not be combined. ACE inhibitors are contraindicated " +
                    "in pregnancy and should be used cautiously with a history of angioedema or bilateral renal " +
                    "artery stenosis. Target blood pressure is generally <130/80 mmHg for most adults."),

            new SeedChunk("clinical_guideline", "Hypertension — ACE Inhibitor Dosing and Monitoring",
                    "Lisinopril is typically initiated at 10 mg once daily (5 mg in patients with reduced renal " +
                    "function or on diuretics) and titrated to 20-40 mg daily as tolerated. Check serum creatinine " +
                    "and potassium within 1-2 weeks of initiation or dose change; a rise in creatinine up to 30% is " +
                    "expected and acceptable. Common side effect: dry cough (occurs in up to 20% of patients) — " +
                    "switch to an ARB if it develops. Contraindicated in pregnancy and with history of ACE " +
                    "inhibitor-induced angioedema."),

            new SeedChunk("clinical_guideline", "Hypertension — Thiazide Diuretic Considerations",
                    "Hydrochlorothiazide (12.5-25 mg daily) and chlorthalidone (12.5-25 mg daily) are effective " +
                    "first-line agents, particularly in Black patients and older adults. Monitor electrolytes " +
                    "(hypokalemia, hyponatremia), uric acid (can precipitate gout), and glucose. Use with caution " +
                    "in patients with a history of gout or significant hyponatremia. Chlorthalidone has a longer " +
                    "half-life and more robust outcomes data than hydrochlorothiazide at equivalent doses."),

            new SeedChunk("clinical_guideline", "Type 2 Diabetes Mellitus — Metformin First-Line Therapy",
                    "Metformin is the preferred initial pharmacologic agent for most patients with type 2 diabetes, " +
                    "absent contraindications. Typical starting dose is 500 mg once or twice daily with meals, " +
                    "titrated by 500 mg weekly to a target of 1000 mg twice daily (max 2550 mg/day) as tolerated to " +
                    "minimize GI side effects (diarrhea, nausea, abdominal discomfort). Contraindicated in eGFR <30 " +
                    "mL/min/1.73m2; dose reduce for eGFR 30-45. Hold before iodinated contrast studies in patients " +
                    "with reduced renal function due to rare risk of lactic acidosis."),

            new SeedChunk("clinical_guideline", "Type 2 Diabetes Mellitus — Glycemic Targets and Second-Line Agents",
                    "General HbA1c target is <7% for most non-pregnant adults, individualized based on comorbidities " +
                    "and hypoglycemia risk. If metformin monotherapy is insufficient after 3 months, consider adding " +
                    "a GLP-1 receptor agonist or SGLT2 inhibitor, particularly in patients with established " +
                    "cardiovascular disease, heart failure, or chronic kidney disease, given their demonstrated " +
                    "cardiorenal benefits. Sulfonylureas are effective but carry higher hypoglycemia and weight-gain risk."),

            new SeedChunk("clinical_guideline", "Acute Bronchitis — Antibiotic Stewardship",
                    "Acute bronchitis in otherwise healthy adults is almost always viral; cough may persist 2-3 " +
                    "weeks even after resolution of infection. Antibiotics do not meaningfully shorten illness " +
                    "duration and are not routinely recommended. Consider antibiotics only if there is strong " +
                    "suspicion of bacterial pneumonia (e.g., focal crackles, hypoxia, high fever with tachycardia) " +
                    "or in patients with significant comorbid pulmonary disease with a change in sputum character."),

            new SeedChunk("drug_db", "Amoxicillin — Indications and Dosing for Adult URTI/Otitis Media/Sinusitis",
                    "Amoxicillin 500 mg three times daily (or 875 mg twice daily) for 5-10 days is first-line for " +
                    "confirmed bacterial sinusitis, otitis media, and streptococcal pharyngitis. Amoxicillin/clavulanate " +
                    "(875/125 mg twice daily) is preferred when there is concern for beta-lactamase-producing " +
                    "organisms or treatment failure on amoxicillin alone. Not appropriate for uncomplicated viral " +
                    "URI or bronchitis."),

            new SeedChunk("drug_db", "Azithromycin — Use as Penicillin-Allergy Alternative",
                    "Azithromycin (500 mg day 1, then 250 mg daily for 4 days) is a reasonable alternative for " +
                    "respiratory infections in patients with a true penicillin allergy who cannot tolerate " +
                    "cephalosporins. Note rising macrolide resistance rates for Streptococcus pyogenes and " +
                    "S. pneumoniae in many regions — reserve for documented allergy rather than convenience. " +
                    "Caution: QT prolongation risk, especially combined with other QT-prolonging agents."),

            new SeedChunk("drug_db", "Ibuprofen (NSAID) — Dosing, Contraindications, and Interactions",
                    "Ibuprofen 400-600 mg every 6-8 hours as needed (max 3200 mg/day) is effective for pain, fever, " +
                    "and inflammation. Avoid in patients with a documented NSAID/aspirin allergy or history of " +
                    "NSAID-induced bronchospasm or urticaria — cross-reactivity among NSAIDs is common and this is " +
                    "a class effect, not limited to one agent. Use cautiously in renal impairment, heart failure, " +
                    "peptic ulcer disease, and in patients on anticoagulants (bleeding risk) or ACE inhibitors/diuretics " +
                    "(reduced antihypertensive effect, risk of acute kidney injury — the 'triple whammy')."),

            new SeedChunk("drug_db", "Acetaminophen — Safer Analgesic/Antipyretic Alternative to NSAIDs",
                    "Acetaminophen 500-1000 mg every 6 hours as needed (max 3000-4000 mg/day depending on liver " +
                    "health) is preferred over NSAIDs for fever/pain in patients with NSAID allergy, peptic ulcer " +
                    "disease, renal impairment, or anticoagulant use. Use caution and reduce max daily dose in " +
                    "patients with hepatic impairment or heavy alcohol use, given hepatotoxicity risk in overdose."),

            new SeedChunk("drug_db", "Oseltamivir — Dosing and Renal Adjustment",
                    "Oseltamivir 75 mg orally twice daily for 5 days is standard adult dosing for influenza treatment, " +
                    "most effective when started within 48 hours of symptom onset. Renal dose adjustment required " +
                    "for CrCl 30-60 mL/min (30 mg twice daily) and CrCl 10-30 mL/min (30 mg once daily). Common " +
                    "side effects include nausea and vomiting, reduced by taking with food."),

            new SeedChunk("drug_db", "Lisinopril — Drug Interactions and Monitoring Requirements",
                    "Avoid combining lisinopril with potassium-sparing diuretics, potassium supplements, or " +
                    "trimethoprim-sulfamethoxazole due to hyperkalemia risk. Concurrent NSAID use blunts " +
                    "antihypertensive effect and increases acute kidney injury risk, particularly with volume " +
                    "depletion. Do not combine with an ARB or direct renin inhibitor (dual RAAS blockade increases " +
                    "risk of hyperkalemia and renal impairment without added benefit)."),

            new SeedChunk("allergy_contraindication", "Penicillin Allergy — Cross-Reactivity with Cephalosporins",
                    "True IgE-mediated penicillin allergy (urticaria, angioedema, anaphylaxis) confers a low but " +
                    "non-zero cross-reactivity risk with cephalosporins, historically cited around 1-2% for " +
                    "second/third-generation agents and lower still for structurally dissimilar side chains. " +
                    "For patients reporting only a remote, mild, non-anaphylactic reaction (e.g., isolated rash), " +
                    "a cephalosporin or amoxicillin challenge may be reasonable per allergy/immunology guidance. " +
                    "For patients with a history of anaphylaxis, angioedema, or Stevens-Johnson syndrome, avoid " +
                    "all beta-lactams and use a non-beta-lactam alternative (e.g., azithromycin, doxycycline)."),

            new SeedChunk("allergy_contraindication", "NSAID Allergy / Aspirin-Exacerbated Respiratory Disease",
                    "Patients with a history of NSAID-induced bronchospasm, urticaria, or angioedema should avoid " +
                    "all NSAIDs (ibuprofen, naproxen, diclofenac, aspirin) as this is typically a class effect from " +
                    "COX-1 inhibition rather than a true IgE-mediated allergy to a single agent. Acetaminophen is " +
                    "generally safe as first-line alternative for pain/fever. COX-2 selective inhibitors (e.g., " +
                    "celecoxib) carry lower but non-zero cross-reactivity risk and should be used cautiously, " +
                    "ideally with specialist input, in patients with aspirin-exacerbated respiratory disease."),

            new SeedChunk("allergy_contraindication", "Sulfa (Sulfonamide) Allergy Considerations",
                    "A reported sulfa allergy most often refers to antibiotic sulfonamides (e.g., " +
                    "trimethoprim-sulfamethoxazole) and does not reliably predict cross-reactivity with non-antibiotic " +
                    "sulfonamides (e.g., thiazide diuretics, some loop diuretics, sulfonylureas), which have a " +
                    "different chemical structure. However, given inconsistent evidence, use clinical judgment and " +
                    "consider alternatives when a documented severe reaction (e.g., Stevens-Johnson syndrome) exists."),

            new SeedChunk("clinical_guideline", "Acute Sinusitis — Diagnostic Criteria for Bacterial vs Viral",
                    "Most acute rhinosinusitis is viral. Bacterial sinusitis is suggested by symptoms persisting " +
                    "beyond 10 days without improvement, severe symptoms (fever >=39C with purulent discharge or " +
                    "facial pain for 3-4 consecutive days at onset), or 'double-sickening' (initial improvement " +
                    "followed by worsening). First-line antibiotic when bacterial sinusitis is diagnosed is " +
                    "amoxicillin-clavulanate rather than amoxicillin alone, given rising resistance patterns."),

            new SeedChunk("clinical_guideline", "Fever Management in Adults — General Approach",
                    "Fever itself is rarely dangerous in adults and treatment is primarily for comfort. Antipyretics " +
                    "(acetaminophen or ibuprofen, respecting the allergy/contraindication profile above) can be used " +
                    "for fever associated with discomfort. Evaluate for underlying source — focal signs (cough, " +
                    "dysuria, rash, neck stiffness) should guide further workup rather than treating fever as an " +
                    "isolated finding."),

            new SeedChunk("clinical_guideline", "Hypertension — When to Refer or Escalate Urgently",
                    "Blood pressure >=180/120 mmHg with signs of acute end-organ damage (chest pain, dyspnea, " +
                    "neurologic deficit, visual changes, or acute kidney injury) constitutes a hypertensive " +
                    "emergency requiring immediate emergency department referral for IV therapy. Asymptomatic " +
                    "severe hypertension (>=180/120 without end-organ damage) can typically be managed in the " +
                    "outpatient setting with close follow-up and oral medication adjustment rather than emergency referral.")
    );
}
