package com.healthcare.patient.controller;

import com.healthcare.common.dto.ApiResponse;
import com.healthcare.patient.dto.request.CreateOrganizationRequest;
import com.healthcare.patient.dto.response.OrganizationResponse;
import com.healthcare.patient.service.OrganizationService;
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
@RequestMapping("/api/v1/organizations")
@RequiredArgsConstructor
@Tag(name = "Organizations", description = "Healthcare organization registry")
public class OrganizationController {

    private final OrganizationService organizationService;

    @PostMapping
    @PreAuthorize("hasRole('ADMIN')")
    @Operation(summary = "Create a new organization")
    public ResponseEntity<ApiResponse<OrganizationResponse>> createOrganization(
            @Valid @RequestBody CreateOrganizationRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.created(organizationService.createOrganization(request)));
    }

    @GetMapping("/{id}")
    @PreAuthorize("hasAnyRole('CLINICIAN', 'ADMIN', 'PATIENT')")
    @Operation(summary = "Get organization by ID")
    public ResponseEntity<ApiResponse<OrganizationResponse>> getOrganization(@PathVariable UUID id) {
        return ResponseEntity.ok(ApiResponse.ok(organizationService.getOrganization(id)));
    }

    @GetMapping
    @PreAuthorize("hasAnyRole('CLINICIAN', 'ADMIN')")
    @Operation(summary = "List organizations")
    public ResponseEntity<ApiResponse<Page<OrganizationResponse>>> listOrganizations(
            @RequestParam(required = false) String name,
            @PageableDefault(size = 20) Pageable pageable) {
        return ResponseEntity.ok(ApiResponse.ok(organizationService.listOrganizations(name, pageable)));
    }
}
