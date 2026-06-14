package com.healthcare.patient.dto.request;

import com.healthcare.patient.domain.enums.Gender;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Past;

import java.time.LocalDate;
import java.util.UUID;

public record UpdatePatientRequest(

        @NotNull(message = "Gender is required")
        Gender gender,

        @Past(message = "Date of birth must be in the past")
        LocalDate birthDate,

        String preferredLanguage,

        Boolean active,

        UUID managingOrganizationId,

        @NotNull(message = "Version is required for optimistic locking")
        Integer version
) {}
