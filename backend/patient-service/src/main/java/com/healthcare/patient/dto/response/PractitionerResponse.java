package com.healthcare.patient.dto.response;

import com.healthcare.patient.domain.enums.Gender;

import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.util.UUID;

public record PractitionerResponse(
        UUID id,
        String npi,
        String givenName,
        String familyName,
        String fullNameDisplay,
        String prefix,
        String suffix,
        Gender gender,
        LocalDate birthDate,
        boolean active,
        OffsetDateTime createdAt
) {}
