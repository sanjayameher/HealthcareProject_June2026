package com.healthcare.portal.dto;

import jakarta.validation.constraints.NotNull;

import java.time.OffsetDateTime;
import java.util.UUID;

public record BookAppointmentRequest(
        @NotNull UUID patientId,
        @NotNull UUID practitionerId,
        @NotNull UUID slotId,
        @NotNull OffsetDateTime startTime,
        @NotNull OffsetDateTime endTime,
        String appointmentTypeCode,   // ROUTINE | FOLLOWUP | EMERGENCY (default: ROUTINE)
        String description
) {}