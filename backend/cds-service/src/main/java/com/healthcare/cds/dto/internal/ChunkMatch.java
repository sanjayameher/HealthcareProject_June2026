package com.healthcare.cds.dto.internal;

import java.util.UUID;

public record ChunkMatch(
        UUID id,
        String sourceType,
        String sourceRef,
        String content,
        double similarity
) {}
