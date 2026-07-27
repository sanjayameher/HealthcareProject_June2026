package com.healthcare.cds.dto.response;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;

public record PrescriptionDto(
        UUID id,
        UUID cdsSessionId,
        UUID patientId,
        UUID doctorId,
        List<String> diagnosisCodes,
        List<SuggestedDrugDto> drugs,
        String notes,
        OffsetDateTime confirmedAt,
        OffsetDateTime createdAt
) {}
