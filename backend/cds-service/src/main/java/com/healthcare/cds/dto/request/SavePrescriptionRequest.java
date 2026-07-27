package com.healthcare.cds.dto.request;

import com.healthcare.cds.dto.response.SuggestedDrugDto;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;

import java.util.List;
import java.util.UUID;

public record SavePrescriptionRequest(
        UUID sessionId,
        @NotNull UUID patientId,
        List<String> diagnosisCodes,
        @NotEmpty List<SuggestedDrugDto> drugs,
        String notes,
        boolean accepted
) {}
