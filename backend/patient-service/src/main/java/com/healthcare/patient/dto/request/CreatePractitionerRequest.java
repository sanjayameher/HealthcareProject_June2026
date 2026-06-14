package com.healthcare.patient.dto.request;

import com.healthcare.patient.domain.enums.Gender;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

import java.time.LocalDate;

public record CreatePractitionerRequest(

        @Pattern(regexp = "\\d{10}", message = "NPI must be exactly 10 digits")
        String npi,

        @NotBlank(message = "Family name is required")
        @Size(max = 100)
        String familyName,

        @NotBlank(message = "Given name is required")
        String givenName,

        String prefix,
        String suffix,
        Gender gender,
        LocalDate birthDate
) {}
