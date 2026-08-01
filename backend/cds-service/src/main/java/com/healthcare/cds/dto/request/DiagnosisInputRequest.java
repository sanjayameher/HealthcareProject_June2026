package com.healthcare.cds.dto.request;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import java.util.List;
import java.util.UUID;

public record DiagnosisInputRequest(
        @NotNull UUID patientId,
        @NotBlank String chiefComplaint,
        List<String> symptoms,
        VitalSignsDto vitalSigns,
        String currentMedications,
        String knownAllergies,
        String clinicalNotes,
        String provider,
        @Valid TestReportAttachmentDto testReportAttachment
) {}
