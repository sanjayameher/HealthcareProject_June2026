package com.healthcare.portal.dto;

import jakarta.validation.constraints.NotNull;

import java.time.LocalDate;
import java.time.LocalTime;

public record AvailabilitySlotRequest(
        @NotNull LocalDate slotDate,
        @NotNull LocalTime startTime,
        @NotNull LocalTime endTime,
        String slotType,          // regular | leave | blocked  (default: regular)
        String recurrenceRule,
        Short maxAppointments,
        String notes
) {}