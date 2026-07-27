package com.healthcare.cds.dto.response;

public record SuggestedDrugDto(
        String drugName,
        String dose,
        String frequency,
        String duration,
        String notes
) {}
