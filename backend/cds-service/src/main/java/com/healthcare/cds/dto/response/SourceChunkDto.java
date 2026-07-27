package com.healthcare.cds.dto.response;

import java.util.UUID;

public record SourceChunkDto(
        UUID id,
        String sourceType,
        String sourceRef,
        String content,
        double similarity
) {}
