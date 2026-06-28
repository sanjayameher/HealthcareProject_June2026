package com.healthcare.patient.controller;

import com.healthcare.common.dto.ApiResponse;
import com.healthcare.patient.dto.request.CreatePatientRequest;
import com.healthcare.patient.dto.request.UpdatePatientRequest;
import com.healthcare.patient.dto.response.PatientResponse;
import com.healthcare.patient.service.PatientService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
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
@RequestMapping("/api/v1/patients")
@RequiredArgsConstructor
@Tag(name = "Patients", description = "FHIR R4-aligned patient demographic management")
@SecurityRequirement(name = "bearerAuth")
public class PatientController {

    private final PatientService patientService;

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    @PreAuthorize("hasAnyRole('CLINICIAN', 'ADMIN')")
    @Operation(summary = "Register a new patient")
    public ResponseEntity<ApiResponse<PatientResponse>> createPatient(
            @Valid @RequestBody CreatePatientRequest request) {
        PatientResponse response = patientService.createPatient(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.created(response));
    }

    @GetMapping("/{id}")
    @PreAuthorize("hasAnyRole('CLINICIAN', 'ADMIN', 'PATIENT')")
    @Operation(summary = "Get patient by ID")
    public ResponseEntity<ApiResponse<PatientResponse>> getPatient(@PathVariable UUID id) {
        return ResponseEntity.ok(ApiResponse.ok(patientService.getPatient(id)));
    }

    @GetMapping("/by-mrn/{mrn}")
    @PreAuthorize("hasAnyRole('CLINICIAN', 'ADMIN')")
    @Operation(summary = "Get patient by MRN")
    public ResponseEntity<ApiResponse<PatientResponse>> getPatientByMrn(@PathVariable String mrn) {
        return ResponseEntity.ok(ApiResponse.ok(patientService.getPatientByMrn(mrn)));
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasAnyRole('CLINICIAN', 'ADMIN')")
    @Operation(summary = "Update patient demographics")
    public ResponseEntity<ApiResponse<PatientResponse>> updatePatient(
            @PathVariable UUID id,
            @Valid @RequestBody UpdatePatientRequest request) {
        return ResponseEntity.ok(ApiResponse.ok(patientService.updatePatient(id, request)));
    }

    @PatchMapping("/{id}/toggle")
    @PreAuthorize("hasRole('ADMIN')")
    @Operation(summary = "Activate or deactivate a patient in the clinical record")
    public ResponseEntity<ApiResponse<Void>> togglePatient(
            @PathVariable UUID id,
            @RequestParam boolean active) {
        patientService.togglePatient(id, active);
        return ResponseEntity.ok(ApiResponse.ok(null, active ? "Patient activated" : "Patient deactivated"));
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    @PreAuthorize("hasRole('ADMIN')")
    @Operation(summary = "Soft-delete a patient record")
    public ResponseEntity<Void> deletePatient(@PathVariable UUID id) {
        patientService.deletePatient(id);
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/search")
    @PreAuthorize("hasAnyRole('CLINICIAN', 'ADMIN')")
    @Operation(summary = "Search patients by name or MRN")
    public ResponseEntity<ApiResponse<Page<PatientResponse>>> searchPatients(
            @RequestParam(required = false) String name,
            @RequestParam(required = false) String mrn,
            @PageableDefault(size = 20) Pageable pageable) {
        return ResponseEntity.ok(ApiResponse.ok(patientService.searchPatients(name, mrn, pageable)));
    }
}
