package com.healthcare.portal.controller;

import com.healthcare.common.dto.ApiResponse;
import com.healthcare.portal.domain.entity.PractitionerAvailabilitySlot;
import com.healthcare.portal.dto.AvailabilitySlotRequest;
import com.healthcare.portal.service.AvailabilityService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/availability")
@RequiredArgsConstructor
@Tag(name = "Availability", description = "Practitioner calendar availability slot management")
public class AvailabilityController {

    private final AvailabilityService availabilityService;

    @GetMapping("/practitioners/{practitionerId}/month")
    @Operation(summary = "Get all slots for a practitioner in a given month")
    public ResponseEntity<ApiResponse<List<PractitionerAvailabilitySlot>>> getMonthSlots(
            @PathVariable UUID practitionerId,
            @RequestParam int year,
            @RequestParam int month) {
        return ResponseEntity.ok(ApiResponse.ok(
                availabilityService.getSlotsForMonth(practitionerId, year, month)));
    }

    @GetMapping("/practitioners/{practitionerId}/available")
    @Operation(summary = "Get available slots for a practitioner on a specific date")
    public ResponseEntity<ApiResponse<List<PractitionerAvailabilitySlot>>> getAvailableSlots(
            @PathVariable UUID practitionerId,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        return ResponseEntity.ok(ApiResponse.ok(
                availabilityService.getAvailableSlots(practitionerId, date)));
    }

    @PostMapping("/practitioners/{practitionerId}/slots")
    @ResponseStatus(HttpStatus.CREATED)
    @Operation(summary = "Add a new availability slot")
    public ResponseEntity<ApiResponse<PractitionerAvailabilitySlot>> addSlot(
            @PathVariable UUID practitionerId,
            @Valid @RequestBody AvailabilitySlotRequest req) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.created(availabilityService.addSlot(practitionerId, req)));
    }

    @PatchMapping("/slots/{slotId}/block")
    @Operation(summary = "Block a slot (leave / administrative block)")
    public ResponseEntity<ApiResponse<PractitionerAvailabilitySlot>> blockSlot(
            @PathVariable UUID slotId,
            @RequestParam(defaultValue = "blocked") String slotType,
            @RequestParam(required = false) String notes) {
        return ResponseEntity.ok(ApiResponse.ok(availabilityService.blockSlot(slotId, slotType, notes)));
    }

    @DeleteMapping("/slots/{slotId}")
    @Operation(summary = "Delete a slot (only if no booked appointment)")
    public ResponseEntity<ApiResponse<Void>> deleteSlot(@PathVariable UUID slotId) {
        availabilityService.deleteSlot(slotId);
        return ResponseEntity.ok(ApiResponse.ok(null, "Slot deleted"));
    }
}