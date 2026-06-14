package com.healthcare.patient.dto.response;

import java.time.OffsetDateTime;
import java.util.UUID;

public record OrganizationResponse(
        UUID id,
        String npi,
        String name,
        String typeCode,
        String typeDisplay,
        String[] alias,
        String phone,
        String fax,
        String email,
        String city,
        String state,
        String postalCode,
        boolean active,
        UUID parentId,
        OffsetDateTime createdAt
) {}
