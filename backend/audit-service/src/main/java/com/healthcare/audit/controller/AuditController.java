package com.healthcare.audit.controller;

import com.healthcare.audit.domain.entity.AuditEvent;
import com.healthcare.audit.repository.AuditEventRepository;
import com.healthcare.common.dto.ApiResponse;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.web.PageableDefault;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.time.OffsetDateTime;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/audit")
@RequiredArgsConstructor
@Tag(name = "Audit", description = "HIPAA audit trail — read-only access for compliance officers")
public class AuditController {

    private final AuditEventRepository auditEventRepository;

    @GetMapping("/patient/{patientId}")
    @PreAuthorize("hasRole('ADMIN')")
    @Operation(summary = "Get audit events for a specific patient")
    public ResponseEntity<ApiResponse<Page<AuditEvent>>> getPatientAuditTrail(
            @PathVariable UUID patientId,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) OffsetDateTime from,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) OffsetDateTime to,
            @PageableDefault(size = 50) Pageable pageable) {
        Page<AuditEvent> events = auditEventRepository.findByPatientAndPeriod(patientId, from, to, pageable);
        return ResponseEntity.ok(ApiResponse.ok(events));
    }

    @GetMapping("/user/{userId}")
    @PreAuthorize("hasRole('ADMIN')")
    @Operation(summary = "Get audit events for a specific user")
    public ResponseEntity<ApiResponse<Page<AuditEvent>>> getUserAuditTrail(
            @PathVariable UUID userId,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) OffsetDateTime from,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) OffsetDateTime to,
            @PageableDefault(size = 50) Pageable pageable) {
        Page<AuditEvent> events = auditEventRepository.findByUserAndPeriod(userId, from, to, pageable);
        return ResponseEntity.ok(ApiResponse.ok(events));
    }
}
