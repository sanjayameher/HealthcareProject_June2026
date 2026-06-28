package com.healthcare.portal.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;

import java.util.UUID;

public record CreateDoctorRequest(
        @NotBlank String givenName,
        @NotBlank String familyName,
        String prefix,
        String gender,
        @Pattern(regexp = "\\d{10}", message = "NPI must be 10 digits") String npi,
        UUID organizationId,
        @NotBlank @Email String email
) {}