package com.healthcare.cds.dto.response;

import java.util.List;
import java.util.UUID;

public record CdsResponse(
        UUID sessionId,
        List<DifferentialDiagnosisDto> differentialDiagnoses,
        List<SuggestedDrugDto> suggestedPrescription,
        List<String> redFlags,
        List<SourceChunkDto> sourceChunks,
        String disclaimer
) {}
