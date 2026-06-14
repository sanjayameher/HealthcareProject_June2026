package com.healthcare.patient.controller;

import com.healthcare.common.dto.ApiResponse;
import com.healthcare.patient.dto.request.CreatePractitionerRequest;
import com.healthcare.patient.dto.response.PractitionerResponse;
import com.healthcare.patient.service.PractitionerService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
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
@RequestMapping("/api/v1/practitioners")
@RequiredArgsConstructor
@Tag(name = "Practitioners", description = "Clinician registry")
public class PractitionerController {

    private final PractitionerService practitionerService;

    @PostMapping
    @PreAuthorize("hasRole('ADMIN')")
    @Operation(summary = "Register a new practitioner")
    public ResponseEntity<ApiResponse<PractitionerResponse>> createPractitioner(
            @Valid @RequestBody CreatePractitionerRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.created(practitionerService.createPractitioner(request)));
    }

    @GetMapping("/{id}")
    @PreAuthorize("hasAnyRole('CLINICIAN', 'ADMIN', 'PATIENT')")
    @Operation(summary = "Get practitioner by ID")
    public ResponseEntity<ApiResponse<PractitionerResponse>> getPractitioner(@PathVariable UUID id) {
        return ResponseEntity.ok(ApiResponse.ok(practitionerService.getPractitioner(id)));
    }

    @GetMapping
    @PreAuthorize("hasAnyRole('CLINICIAN', 'ADMIN')")
    @Operation(summary = "List practitioners")
    public ResponseEntity<ApiResponse<Page<PractitionerResponse>>> listPractitioners(
            @RequestParam(required = false) String familyName,
            @PageableDefault(size = 20) Pageable pageable) {
        return ResponseEntity.ok(ApiResponse.ok(practitionerService.listPractitioners(familyName, pageable)));
    }
}
