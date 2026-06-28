package com.healthcare.portal.dto;

import java.util.UUID;

public record LoginResponse(
        String token,
        String role,
        UUID userId,
        String fullName,
        boolean mustChangePassword
) {}