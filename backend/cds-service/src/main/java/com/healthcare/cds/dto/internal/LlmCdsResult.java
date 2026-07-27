package com.healthcare.cds.dto.internal;

import com.healthcare.cds.dto.response.DifferentialDiagnosisDto;
import com.healthcare.cds.dto.response.SuggestedDrugDto;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;

import java.util.List;

/** Shape the LLM is instructed to return as JSON — parsed and schema-validated before use. */
@JsonIgnoreProperties(ignoreUnknown = true)
public record LlmCdsResult(
        List<DifferentialDiagnosisDto> differentialDiagnoses,
        List<SuggestedDrugDto> suggestedPrescription,
        List<String> redFlags,
        List<String> sourceChunkIds
) {}
