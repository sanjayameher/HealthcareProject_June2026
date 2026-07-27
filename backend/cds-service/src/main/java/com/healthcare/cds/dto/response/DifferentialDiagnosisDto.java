package com.healthcare.cds.dto.response;

public record DifferentialDiagnosisDto(
        String icd10Code,
        String display,
        int confidencePct,
        String rationale
) {}
