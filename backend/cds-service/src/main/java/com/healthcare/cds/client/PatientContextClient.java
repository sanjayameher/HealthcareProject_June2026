package com.healthcare.cds.client;

import com.fasterxml.jackson.databind.JsonNode;
import com.healthcare.cds.config.CdsProperties;
import com.healthcare.cds.dto.internal.PatientClinicalContext;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpHeaders;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientException;

import java.time.LocalDate;
import java.time.Period;
import java.time.format.DateTimeParseException;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

/**
 * Fetches clinical context for the RAG prompt from patient-service and clinical-service.
 * Deliberately pulls only age/gender/clinical text — never name, MRN, or address — so
 * no direct patient identifier ever reaches the LLM. Best-effort: either upstream call
 * failing (service down, patient has no encounters yet) degrades gracefully rather than
 * blocking the diagnose request, matching this codebase's pattern for optional
 * cross-service calls (see PatientService's Kafka publish).
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class PatientContextClient {

    private final CdsProperties props;

    public PatientClinicalContext fetch(UUID patientId, String bearerToken) {
        Integer ageYears = null;
        String gender = null;
        try {
            JsonNode data = RestClient.create(props.getServices().getPatientServiceUrl())
                    .get()
                    .uri("/api/v1/patients/{id}", patientId)
                    .headers(headers -> setAuth(headers, bearerToken))
                    .retrieve()
                    .body(JsonNode.class)
                    .path("data");

            gender = data.path("gender").asText(null);
            String birthDate = data.path("birthDate").asText(null);
            if (birthDate != null && !birthDate.isBlank()) {
                try {
                    ageYears = Period.between(LocalDate.parse(birthDate), LocalDate.now()).getYears();
                } catch (DateTimeParseException e) {
                    log.warn("Could not parse patient birthDate '{}' for patient {}", birthDate, patientId);
                }
            }
        } catch (RestClientException e) {
            log.warn("patient-service unreachable while building CDS context for patient {}: {}", patientId, e.getMessage());
        }

        List<String> recentEncounters = fetchRecentEncounterSummaries(patientId, bearerToken);
        return new PatientClinicalContext(ageYears, gender, recentEncounters);
    }

    private List<String> fetchRecentEncounterSummaries(UUID patientId, String bearerToken) {
        List<String> summaries = new ArrayList<>();
        try {
            JsonNode content = RestClient.create(props.getServices().getClinicalServiceUrl())
                    .get()
                    .uri("/api/v1/encounters/patient/{patientId}?size=3", patientId)
                    .headers(headers -> setAuth(headers, bearerToken))
                    .retrieve()
                    .body(JsonNode.class)
                    .path("data")
                    .path("content");

            for (JsonNode encounter : content) {
                StringBuilder summary = new StringBuilder();
                String status = encounter.path("status").asText("");
                String periodStart = encounter.path("periodStart").asText("");
                summary.append(periodStart).append(" (").append(status).append(")");

                String chiefComplaint = encounter.path("chiefComplaint").asText(null);
                if (chiefComplaint != null && !chiefComplaint.isBlank()) {
                    summary.append(" — chief complaint: ").append(chiefComplaint);
                }
                JsonNode reasonDisplays = encounter.path("reasonDisplays");
                if (reasonDisplays.isArray() && !reasonDisplays.isEmpty()) {
                    List<String> reasons = new ArrayList<>();
                    reasonDisplays.forEach(r -> reasons.add(r.asText()));
                    summary.append(" — reasons: ").append(String.join(", ", reasons));
                }
                String assessmentPlan = encounter.path("assessmentPlan").asText(null);
                if (assessmentPlan != null && !assessmentPlan.isBlank()) {
                    summary.append(" — assessment/plan: ").append(assessmentPlan);
                }
                summaries.add(summary.toString());
            }
        } catch (RestClientException e) {
            log.warn("clinical-service unreachable while building CDS context for patient {}: {}", patientId, e.getMessage());
        }
        return summaries;
    }

    private void setAuth(HttpHeaders headers, String bearerToken) {
        if (bearerToken != null && !bearerToken.isBlank()) {
            headers.set(HttpHeaders.AUTHORIZATION, bearerToken);
        }
    }
}
