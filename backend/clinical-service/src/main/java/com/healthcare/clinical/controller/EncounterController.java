package com.healthcare.clinical.controller;

import com.healthcare.clinical.domain.entity.Encounter;
import com.healthcare.clinical.repository.EncounterRepository;
import com.healthcare.common.dto.ApiResponse;
import com.healthcare.common.exception.ResourceNotFoundException;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.web.PageableDefault;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

@RestController
@RequestMapping("/api/v1/encounters")
@RequiredArgsConstructor
@Tag(name = "Encounters", description = "FHIR R4 Encounter management")
public class EncounterController {

    private final EncounterRepository encounterRepository;

    @GetMapping("/{id}")
    @PreAuthorize("hasAnyRole('CLINICIAN', 'ADMIN')")
    @Operation(summary = "Get encounter by ID")
    public ResponseEntity<ApiResponse<Encounter>> getEncounter(@PathVariable UUID id) {
        Encounter encounter = encounterRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Encounter", id));
        return ResponseEntity.ok(ApiResponse.ok(encounter));
    }

    @GetMapping("/patient/{patientId}")
    @PreAuthorize("hasAnyRole('CLINICIAN', 'ADMIN', 'PATIENT')")
    @Operation(summary = "List encounters for a patient")
    public ResponseEntity<ApiResponse<Page<Encounter>>> getPatientEncounters(
            @PathVariable UUID patientId,
            @PageableDefault(size = 20) Pageable pageable) {
        Page<Encounter> page = encounterRepository
                .findByPatientIdOrderByPeriodStartDesc(patientId, pageable);
        return ResponseEntity.ok(ApiResponse.ok(page));
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    @PreAuthorize("hasAnyRole('CLINICIAN', 'ADMIN')")
    @Operation(summary = "Create a new encounter")
    public ResponseEntity<ApiResponse<Encounter>> createEncounter(@RequestBody Encounter encounter) {
        Encounter saved = encounterRepository.save(encounter);
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.created(saved));
    }
}
