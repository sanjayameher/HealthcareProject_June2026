package com.healthcare.portal.dto;

import jakarta.validation.constraints.NotBlank;

import java.util.UUID;

public record UpdateAppointmentStatusRequest(
        @NotBlank String status,          // arrived | checked_in | fulfilled | cancelled
        UUID reassignPractitionerId       // only used by admin queue re-assign flow
) {}