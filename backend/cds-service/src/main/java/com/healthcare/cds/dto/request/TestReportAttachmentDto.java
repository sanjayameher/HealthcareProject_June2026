package com.healthcare.cds.dto.request;

import jakarta.validation.constraints.NotBlank;

public record TestReportAttachmentDto(
        @NotBlank String filename,
        @NotBlank String mimeType,
        @NotBlank String base64Data
) {}
