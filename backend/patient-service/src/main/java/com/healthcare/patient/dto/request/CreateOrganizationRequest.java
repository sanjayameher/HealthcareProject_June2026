package com.healthcare.patient.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

import java.util.UUID;

public record CreateOrganizationRequest(

        UUID parentId,

        @Pattern(regexp = "\\d{10}", message = "NPI must be exactly 10 digits")
        String npi,

        @NotBlank(message = "Organization name is required")
        @Size(max = 200)
        String name,

        String typeCode,
        String typeDisplay,

        String[] alias,
        String phone,
        String fax,
        String email,
        String city,

        @Pattern(regexp = "[A-Z]{2}", message = "State must be 2-letter code")
        String state,

        String postalCode
) {}
