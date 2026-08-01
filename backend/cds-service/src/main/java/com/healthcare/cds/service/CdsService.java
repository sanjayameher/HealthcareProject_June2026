package com.healthcare.cds.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.healthcare.cds.client.AnthropicLlmClient;
import com.healthcare.cds.client.GroqClient;
import com.healthcare.cds.client.LlmClient;
import com.healthcare.cds.client.OllamaEmbeddingClient;
import com.healthcare.cds.client.PatientContextClient;
import com.healthcare.cds.domain.entity.CdsDiagnoseSession;
import com.healthcare.cds.domain.entity.Prescription;
import com.healthcare.cds.dto.internal.ChunkMatch;
import com.healthcare.cds.dto.internal.LlmCdsResult;
import com.healthcare.cds.dto.internal.PatientClinicalContext;
import com.healthcare.cds.dto.request.DiagnosisInputRequest;
import com.healthcare.cds.dto.request.SavePrescriptionRequest;
import com.healthcare.cds.dto.request.SummarizeTranscriptRequest;
import com.healthcare.cds.dto.request.TestReportAttachmentDto;
import com.healthcare.cds.dto.request.VitalSignsDto;
import com.healthcare.cds.dto.response.CdsResponse;
import com.healthcare.cds.dto.response.PrescriptionDto;
import com.healthcare.cds.dto.response.PrescriptionResponse;
import com.healthcare.cds.dto.response.SourceChunkDto;
import com.healthcare.cds.dto.response.SuggestedDrugDto;
import com.healthcare.cds.dto.response.SummarizeTranscriptResponse;
import com.healthcare.cds.repository.CdsDiagnoseSessionRepository;
import com.healthcare.cds.repository.KnowledgeChunkRepository;
import com.healthcare.cds.repository.PrescriptionRepository;
import com.healthcare.common.exception.BusinessException;
import com.healthcare.common.exception.ResourceNotFoundException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.apache.pdfbox.Loader;
import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.text.PDFTextStripper;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.OffsetDateTime;
import java.util.Base64;
import java.util.List;
import java.util.Set;
import java.util.UUID;

@Service
@Slf4j
@RequiredArgsConstructor
public class CdsService {

    // nomic-embed-text produces a compressed similarity range on narrow-domain
    // (all-clinical) short text — even unrelated chunks score ~0.40+, while
    // genuinely relevant matches land around 0.55-0.70. 0.75 was too strict and
    // filtered out every real match; 0.45 was calibrated against actual scores.
    private static final double SIMILARITY_THRESHOLD = 0.45;
    private static final int TOP_K = 8;

    private static final int MAX_ATTACHMENT_BYTES = 8 * 1024 * 1024;
    private static final Set<String> ALLOWED_ATTACHMENT_MIME_TYPES = Set.of(
            "application/pdf", "image/jpeg", "image/jpg", "image/png", "image/gif", "image/webp");

    private static final String SYSTEM_PROMPT = """
            You are a clinical decision support assistant. Use ONLY the provided clinical
            knowledge context to generate differential diagnoses and a suggested prescription.
            Always flag potential drug allergies and contraindications in redFlags. Return ONLY
            valid JSON matching the CdsResponse schema below — no prose, no markdown fences.
            Do not make up drugs or dosages not supported by the context. If the context is
            insufficient to safely suggest a prescription, return an empty suggestedPrescription
            array and explain why in redFlags.

            Required JSON schema:
            {
              "differentialDiagnoses": [
                { "icd10Code": "string", "display": "string", "confidencePct": 0-100, "rationale": "string" }
              ],
              "suggestedPrescription": [
                { "drugName": "string", "dose": "string", "frequency": "string", "duration": "string", "notes": "string" }
              ],
              "redFlags": ["string"],
              "sourceChunkIds": ["uuid"]
            }
            """;

    private static final String TRANSCRIPT_SUMMARY_SYSTEM_PROMPT = """
            You are a medical scribe assistant. You will be given a raw, unedited speech-to-text
            transcript of a conversation between a doctor and a patient. It may contain filler words,
            false starts, repetition, small talk, and transcription errors. Extract and rewrite ONLY the
            patient's chief complaint as a single concise clinical sentence — the presenting symptoms and
            their duration, in the clear clinical language a doctor would write on a chart. Do not
            diagnose, do not suggest treatment, and do not add any detail that was not actually stated in
            the transcript. Return ONLY the chief complaint sentence — no preamble, no labels, no
            quotation marks, no markdown.
            """;

    private final PatientContextClient patientContextClient;
    private final OllamaEmbeddingClient embeddingClient;
    private final GroqClient groqClient;
    private final AnthropicLlmClient anthropicLlmClient;
    private final KnowledgeChunkRepository knowledgeChunkRepository;
    private final CdsDiagnoseSessionRepository sessionRepository;
    private final PrescriptionRepository prescriptionRepository;
    private final ObjectMapper objectMapper;

    @Transactional
    public CdsResponse diagnose(DiagnosisInputRequest request, UUID doctorId, String bearerToken) {
        PatientClinicalContext context = patientContextClient.fetch(request.patientId(), bearerToken);

        String queryText = buildEmbeddingQuery(request, context);
        float[] queryEmbedding = embeddingClient.embed(queryText);

        List<ChunkMatch> matches = knowledgeChunkRepository.similaritySearch(queryEmbedding, TOP_K, SIMILARITY_THRESHOLD);

        LlmClient llmClient = resolveLlmClient(request.provider());
        String userPrompt = buildUserPrompt(request, context, matches);

        TestReportAttachmentDto attachment = request.testReportAttachment();
        String rawLlmOutput;
        if (attachment != null && llmClient.supportsAttachments()) {
            validateAttachment(attachment);
            rawLlmOutput = llmClient.completeWithAttachment(SYSTEM_PROMPT, userPrompt, attachment);
        } else {
            if (attachment != null) {
                validateAttachment(attachment);
                userPrompt = userPrompt + "\n\n" + buildAttachmentFallbackContext(attachment);
            }
            rawLlmOutput = llmClient.complete(SYSTEM_PROMPT, userPrompt);
        }
        LlmCdsResult parsed = parseLlmResponse(rawLlmOutput);

        String disclaimer = matches.isEmpty()
                ? "No matching clinical guidelines found in the knowledge base — this response is based on the "
                + "model's general training data only and has not been grounded in verified clinical sources. "
                + "Independently verify before acting."
                : null;

        CdsDiagnoseSession session = new CdsDiagnoseSession();
        session.setPatientId(request.patientId());
        session.setDoctorId(doctorId);
        session.setInputPayload(toJson(request));
        session.setLlmResponse(toJson(parsed));
        session.setStatus(CdsDiagnoseSession.PENDING);
        session = sessionRepository.save(session);

        List<SourceChunkDto> sourceChunks = matches.stream()
                .map(m -> new SourceChunkDto(m.id(), m.sourceType(), m.sourceRef(), m.content(), m.similarity()))
                .toList();

        return new CdsResponse(
                session.getId(),
                parsed.differentialDiagnoses(),
                parsed.suggestedPrescription(),
                parsed.redFlags(),
                sourceChunks,
                disclaimer
        );
    }

    public SummarizeTranscriptResponse summarizeTranscript(SummarizeTranscriptRequest request) {
        String gist = resolveLlmClient(request.provider()).complete(TRANSCRIPT_SUMMARY_SYSTEM_PROMPT, request.transcript());
        return new SummarizeTranscriptResponse(stripQuotes(gist.trim()));
    }

    private String stripQuotes(String text) {
        if (text.length() >= 2 && text.startsWith("\"") && text.endsWith("\"")) {
            return text.substring(1, text.length() - 1).trim();
        }
        return text;
    }

    private LlmClient resolveLlmClient(String provider) {
        if (provider != null && (provider.equalsIgnoreCase("claude") || provider.equalsIgnoreCase("anthropic"))) {
            return anthropicLlmClient;
        }
        return groqClient;
    }

    private void validateAttachment(TestReportAttachmentDto attachment) {
        if (!ALLOWED_ATTACHMENT_MIME_TYPES.contains(attachment.mimeType().toLowerCase())) {
            throw new BusinessException("Unsupported test report file type: " + attachment.mimeType(),
                    HttpStatus.BAD_REQUEST, "ATTACHMENT_UNSUPPORTED_TYPE");
        }
        byte[] decoded;
        try {
            decoded = Base64.getDecoder().decode(attachment.base64Data());
        } catch (IllegalArgumentException e) {
            throw new BusinessException("Attached test report is not valid file data",
                    HttpStatus.BAD_REQUEST, "ATTACHMENT_INVALID");
        }
        if (decoded.length > MAX_ATTACHMENT_BYTES) {
            throw new BusinessException("Attached test report exceeds the 8 MB size limit",
                    HttpStatus.PAYLOAD_TOO_LARGE, "ATTACHMENT_TOO_LARGE");
        }
    }

    private String buildAttachmentFallbackContext(TestReportAttachmentDto attachment) {
        if ("application/pdf".equalsIgnoreCase(attachment.mimeType())) {
            String extracted = extractPdfText(attachment.base64Data());
            if (extracted != null && !extracted.isBlank()) {
                return "ATTACHED TEST REPORT (" + attachment.filename() + ", extracted text):\n" + extracted.trim();
            }
        }
        return "NOTE: The doctor attached a test report file (" + attachment.filename() + ") but the selected AI "
                + "provider cannot read its contents directly. Base the assessment on the reported symptoms and "
                + "vitals only, and mention in redFlags that the attached report should be reviewed manually.";
    }

    private String extractPdfText(String base64Data) {
        try (PDDocument document = Loader.loadPDF(Base64.getDecoder().decode(base64Data))) {
            return new PDFTextStripper().getText(document);
        } catch (Exception e) {
            log.warn("Failed to extract text from attached PDF test report: {}", e.getMessage());
            return null;
        }
    }

    @Transactional
    public PrescriptionResponse savePrescription(SavePrescriptionRequest request, UUID doctorId) {
        Prescription rx = new Prescription();
        rx.setCdsSessionId(request.sessionId());
        rx.setPatientId(request.patientId());
        rx.setDoctorId(doctorId);
        rx.setDiagnosisCodes(request.diagnosisCodes() == null
                ? new String[0]
                : request.diagnosisCodes().toArray(new String[0]));
        rx.setDrugs(toJson(request.drugs()));
        rx.setNotes(request.notes());
        rx.setConfirmedAt(OffsetDateTime.now());
        rx = prescriptionRepository.save(rx);

        if (request.sessionId() != null) {
            sessionRepository.findById(request.sessionId()).ifPresent(session -> {
                session.setStatus(request.accepted() ? CdsDiagnoseSession.ACCEPTED : CdsDiagnoseSession.EDITED);
                sessionRepository.save(session);
            });
        }

        return new PrescriptionResponse(rx.getId());
    }

    @Transactional(readOnly = true)
    public List<PrescriptionDto> listPrescriptions(UUID patientId) {
        return prescriptionRepository.findByPatientIdOrderByCreatedAtDesc(patientId).stream()
                .map(this::toDto)
                .toList();
    }

    @Transactional(readOnly = true)
    public PrescriptionDto getPrescription(UUID id) {
        return prescriptionRepository.findById(id)
                .map(this::toDto)
                .orElseThrow(() -> new ResourceNotFoundException("Prescription", id));
    }

    // ── Prompt construction ─────────────────────────────────────────────

    private String buildEmbeddingQuery(DiagnosisInputRequest request, PatientClinicalContext context) {
        StringBuilder sb = new StringBuilder();
        sb.append(request.chiefComplaint());
        if (request.symptoms() != null && !request.symptoms().isEmpty()) {
            sb.append(". Symptoms: ").append(String.join(", ", request.symptoms()));
        }
        if (request.clinicalNotes() != null && !request.clinicalNotes().isBlank()) {
            sb.append(". Notes: ").append(request.clinicalNotes());
        }
        if (context.recentEncounterSummaries() != null && !context.recentEncounterSummaries().isEmpty()) {
            sb.append(". Recent history: ").append(String.join("; ", context.recentEncounterSummaries()));
        }
        return sb.toString();
    }

    private String buildUserPrompt(DiagnosisInputRequest request, PatientClinicalContext context, List<ChunkMatch> matches) {
        StringBuilder sb = new StringBuilder();

        sb.append("PATIENT CONTEXT:\n");
        sb.append("  age: ").append(context.ageYears() != null ? context.ageYears() : "unknown").append("\n");
        sb.append("  gender: ").append(context.gender() != null ? context.gender() : "unknown").append("\n");
        sb.append("  known_allergies: ").append(nullToNone(request.knownAllergies())).append("\n");
        sb.append("  current_medications: ").append(nullToNone(request.currentMedications())).append("\n");
        if (context.recentEncounterSummaries() != null && !context.recentEncounterSummaries().isEmpty()) {
            sb.append("  recent_encounters:\n");
            context.recentEncounterSummaries().forEach(s -> sb.append("    - ").append(s).append("\n"));
        }

        sb.append("\nDOCTOR INPUT:\n");
        sb.append("  chief_complaint: ").append(request.chiefComplaint()).append("\n");
        if (request.symptoms() != null && !request.symptoms().isEmpty()) {
            sb.append("  symptoms: ").append(String.join(", ", request.symptoms())).append("\n");
        }
        VitalSignsDto vitals = request.vitalSigns();
        if (vitals != null) {
            sb.append("  vitals: bp=").append(nullToNone(vitals.bp()))
                    .append(", hr=").append(nullToNone(vitals.hr()))
                    .append(", temp=").append(nullToNone(vitals.temp()))
                    .append(", spo2=").append(nullToNone(vitals.spo2()))
                    .append(", weight=").append(nullToNone(vitals.weight()))
                    .append("\n");
        }
        if (request.clinicalNotes() != null && !request.clinicalNotes().isBlank()) {
            sb.append("  clinical_notes: ").append(request.clinicalNotes()).append("\n");
        }

        sb.append("\nCLINICAL KNOWLEDGE CONTEXT:\n");
        if (matches.isEmpty()) {
            sb.append("  (no matching chunks found in the knowledge base)\n");
        } else {
            for (ChunkMatch m : matches) {
                sb.append("  [").append(m.id()).append(" — source: ").append(m.sourceRef()).append("]: ")
                        .append(m.content()).append("\n");
            }
        }

        sb.append("\nReturn only the JSON object described in the system prompt.");
        return sb.toString();
    }

    private String nullToNone(String value) {
        return (value == null || value.isBlank()) ? "none reported" : value;
    }

    // ── LLM response parsing / persistence helpers ──────────────────────

    private LlmCdsResult parseLlmResponse(String rawOutput) {
        String json = extractJsonObject(rawOutput);
        try {
            return objectMapper.readValue(json, LlmCdsResult.class);
        } catch (JsonProcessingException e) {
            log.error("LLM output failed schema validation. Raw output: {}", rawOutput);
            throw new BusinessException("Clinical decision support returned an invalid response",
                    HttpStatus.BAD_GATEWAY, "LLM_RESPONSE_INVALID");
        }
    }

    private String extractJsonObject(String text) {
        int start = text.indexOf('{');
        int end = text.lastIndexOf('}');
        if (start == -1 || end == -1 || end < start) {
            throw new BusinessException("Clinical decision support returned a non-JSON response",
                    HttpStatus.BAD_GATEWAY, "LLM_RESPONSE_INVALID");
        }
        return text.substring(start, end + 1);
    }

    private String toJson(Object value) {
        try {
            return objectMapper.writeValueAsString(value);
        } catch (JsonProcessingException e) {
            throw new IllegalStateException("Failed to serialize value to JSON", e);
        }
    }

    private PrescriptionDto toDto(Prescription rx) {
        List<SuggestedDrugDto> drugs;
        try {
            drugs = List.of(objectMapper.readValue(rx.getDrugs(), SuggestedDrugDto[].class));
        } catch (JsonProcessingException e) {
            log.error("Stored prescription {} has unparseable drugs JSON", rx.getId());
            drugs = List.of();
        }
        List<String> diagnosisCodes = rx.getDiagnosisCodes() == null
                ? List.of()
                : List.of(rx.getDiagnosisCodes());
        return new PrescriptionDto(
                rx.getId(), rx.getCdsSessionId(), rx.getPatientId(), rx.getDoctorId(),
                diagnosisCodes, drugs, rx.getNotes(), rx.getConfirmedAt(), rx.getCreatedAt()
        );
    }
}
