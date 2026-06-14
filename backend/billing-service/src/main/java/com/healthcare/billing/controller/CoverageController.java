package com.healthcare.billing.controller;

import com.healthcare.billing.domain.entity.Coverage;
import com.healthcare.billing.repository.CoverageRepository;
import com.healthcare.common.dto.ApiResponse;
import com.healthcare.common.exception.ResourceNotFoundException;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/coverage")
@RequiredArgsConstructor
@Tag(name = "Coverage", description = "Patient insurance coverage management")
public class CoverageController {

    private final CoverageRepository coverageRepository;

    @GetMapping("/patient/{patientId}")
    @PreAuthorize("hasAnyRole('CLINICIAN', 'ADMIN', 'PATIENT')")
    @Operation(summary = "Get all coverage for a patient")
    public ResponseEntity<ApiResponse<List<Coverage>>> getPatientCoverage(@PathVariable UUID patientId) {
        return ResponseEntity.ok(ApiResponse.ok(
                coverageRepository.findByPatientIdOrderByOrderOfBenefitAsc(patientId)));
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    @PreAuthorize("hasAnyRole('ADMIN', 'CLINICIAN')")
    @Operation(summary = "Add insurance coverage for a patient")
    public ResponseEntity<ApiResponse<Coverage>> createCoverage(@RequestBody Coverage coverage) {
        Coverage saved = coverageRepository.save(coverage);
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.created(saved));
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    @Operation(summary = "Terminate coverage")
    public ResponseEntity<Void> deleteCoverage(@PathVariable UUID id) {
        if (!coverageRepository.existsById(id)) {
            throw new ResourceNotFoundException("Coverage", id);
        }
        coverageRepository.deleteById(id);
        return ResponseEntity.noContent().build();
    }
}
