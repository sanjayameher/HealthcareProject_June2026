package com.healthcare.portal.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;

public record CreateAdminRequest(
        @NotBlank String fullName,
        @NotBlank @Email String email,
        String password            // optional; auto-generated if blank
) {}