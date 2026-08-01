package com.healthcare.cds.controller;

import com.healthcare.cds.dto.request.DiagnosisInputRequest;
import com.healthcare.cds.dto.request.SavePrescriptionRequest;
import com.healthcare.cds.dto.request.SummarizeTranscriptRequest;
import com.healthcare.cds.dto.response.CdsResponse;
import com.healthcare.cds.dto.response.PrescriptionDto;
import com.healthcare.cds.dto.response.PrescriptionResponse;
import com.healthcare.cds.dto.response.SummarizeTranscriptResponse;
import com.healthcare.cds.security.CdsJwtService;
import com.healthcare.cds.service.CdsService;
import com.healthcare.common.dto.ApiResponse;
import com.healthcare.common.exception.BusinessException;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/cds")
@RequiredArgsConstructor
@Tag(name = "CDS", description = "RAG-based clinical decision support — differential diagnosis and prescription suggestions")
@SecurityRequirement(name = "bearerAuth")
public class CdsController {

    private final CdsService cdsService;
    private final CdsJwtService jwtService;

    @PostMapping("/diagnose")
    @PreAuthorize("hasRole('CLINICIAN')")
    @Operation(summary = "Generate a RAG-grounded differential diagnosis and prescription suggestion")
    public ResponseEntity<ApiResponse<CdsResponse>> diagnose(
            @Valid @RequestBody DiagnosisInputRequest request,
            @RequestHeader(value = "Authorization", required = false) String authHeader) {
        UUID doctorId = currentUserId(authHeader);
        CdsResponse response = cdsService.diagnose(request, doctorId, authHeader);
        return ResponseEntity.ok(ApiResponse.ok(response));
    }

    @PostMapping("/summarize-transcript")
    @PreAuthorize("hasRole('CLINICIAN')")
    @Operation(summary = "Summarize a raw voice-to-text conversation transcript into a concise chief complaint")
    public ResponseEntity<ApiResponse<SummarizeTranscriptResponse>> summarizeTranscript(
            @Valid @RequestBody SummarizeTranscriptRequest request) {
        return ResponseEntity.ok(ApiResponse.ok(cdsService.summarizeTranscript(request)));
    }

    @PostMapping("/prescriptions")
    @PreAuthorize("hasRole('CLINICIAN')")
    @Operation(summary = "Save a reviewed prescription (accepted or edited) to the patient record")
    public ResponseEntity<ApiResponse<PrescriptionResponse>> savePrescription(
            @Valid @RequestBody SavePrescriptionRequest request,
            @RequestHeader(value = "Authorization", required = false) String authHeader) {
        UUID doctorId = currentUserId(authHeader);
        PrescriptionResponse response = cdsService.savePrescription(request, doctorId);
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.created(response));
    }

    @GetMapping("/prescriptions")
    @PreAuthorize("hasAnyRole('CLINICIAN', 'ADMIN')")
    @Operation(summary = "List past CDS-assisted prescriptions for a patient")
    public ResponseEntity<ApiResponse<List<PrescriptionDto>>> getPrescriptions(
            @RequestParam UUID patientId) {
        return ResponseEntity.ok(ApiResponse.ok(cdsService.listPrescriptions(patientId)));
    }

    @GetMapping("/prescriptions/{id}")
    @PreAuthorize("hasAnyRole('CLINICIAN', 'ADMIN')")
    @Operation(summary = "Get a single prescription by ID (used for the printable view)")
    public ResponseEntity<ApiResponse<PrescriptionDto>> getPrescription(@PathVariable UUID id) {
        return ResponseEntity.ok(ApiResponse.ok(cdsService.getPrescription(id)));
    }

    private UUID currentUserId(String authHeader) {
        String token = CdsJwtService.stripBearer(authHeader);
        if (token == null) {
            throw new BusinessException("Missing authorization token", HttpStatus.UNAUTHORIZED, "AUTH_REQUIRED");
        }
        return jwtService.extractUserId(token);
    }
}
