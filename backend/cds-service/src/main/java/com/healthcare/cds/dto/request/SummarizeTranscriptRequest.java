package com.healthcare.cds.dto.request;

import jakarta.validation.constraints.NotBlank;

public record SummarizeTranscriptRequest(
        @NotBlank String transcript,
        String provider
) {}
