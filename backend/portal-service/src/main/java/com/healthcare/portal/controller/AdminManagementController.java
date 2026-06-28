package com.healthcare.portal.controller;

import com.healthcare.common.dto.ApiResponse;
import com.healthcare.portal.domain.entity.*;
import com.healthcare.portal.dto.*;
import com.healthcare.portal.repository.PatientViewRepository;
import com.healthcare.portal.repository.PractitionerViewRepository;
import com.healthcare.portal.service.AdminManagementService;
import com.healthcare.portal.service.AppointmentBookingService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.web.PageableDefault;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/admin")
@RequiredArgsConstructor
@Tag(name = "Admin Management", description = "Hospital admin operations: doctors, patients, appointments")
public class AdminManagementController {

    private final AdminManagementService adminService;
    private final AppointmentBookingService bookingService;
    private final PractitionerViewRepository practitionerRepo;
    private final PatientViewRepository patientRepo;

    // ── Admin account creation (super-admin only) ────────────────

    @PostMapping("/accounts")
    @ResponseStatus(HttpStatus.CREATED)
    @Operation(summary = "Create a new admin account (super-admin only)")
    public ResponseEntity<ApiResponse<AdminAccount>> createAdmin(
            @Valid @RequestBody CreateAdminRequest req,
            @RequestHeader(value = "X-User-Id", required = false) UUID currentAdminId) {
        AdminAccount created = adminService.createAdmin(req, currentAdminId);
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.created(created));
    }

    // ── Doctor management ────────────────────────────────────────

    @GetMapping("/doctors")
    @Operation(summary = "List all practitioners")
    public ResponseEntity<ApiResponse<Page<PractitionerView>>> listDoctors(
            @RequestParam(required = false) Boolean active,
            @PageableDefault(size = 20) Pageable pageable) {
        Page<PractitionerView> page = (active != null)
                ? practitionerRepo.findByActive(active, pageable)
                : practitionerRepo.findAll(pageable);
        return ResponseEntity.ok(ApiResponse.ok(page));
    }

    @GetMapping("/doctors/search")
    @Operation(summary = "Search active practitioners by name")
    public ResponseEntity<ApiResponse<Page<PractitionerView>>> searchDoctors(
            @RequestParam String q,
            @PageableDefault(size = 20) Pageable pageable) {
        return ResponseEntity.ok(ApiResponse.ok(practitionerRepo.searchActive(q, pageable)));
    }

    @PostMapping("/doctors/{practitionerId}/account")
    @ResponseStatus(HttpStatus.CREATED)
    @Operation(summary = "Create portal account for an existing practitioner")
    public ResponseEntity<ApiResponse<InviteResponse>> createDoctorAccount(
            @PathVariable UUID practitionerId,
            @RequestParam String email) {
        InviteResponse invite = adminService.createDoctorAccount(practitionerId, email);
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.created(invite));
    }

    @PostMapping("/doctors/{practitionerId}/resend-invite")
    @Operation(summary = "Generate a fresh set-password link for an existing doctor account")
    public ResponseEntity<ApiResponse<InviteResponse>> resendDoctorInvite(
            @PathVariable UUID practitionerId) {
        InviteResponse invite = adminService.regenerateDoctorInvite(practitionerId);
        return ResponseEntity.ok(ApiResponse.ok(invite, "Invite link regenerated"));
    }

    @PatchMapping("/doctors/{practitionerId}/toggle")
    @Operation(summary = "Activate or deactivate a doctor account")
    public ResponseEntity<ApiResponse<Void>> toggleDoctor(
            @PathVariable UUID practitionerId,
            @RequestParam boolean active,
            @RequestParam(required = false) String reason) {
        adminService.toggleDoctorAccount(practitionerId, active, reason);
        return ResponseEntity.ok(ApiResponse.ok(null, active ? "Doctor activated" : "Doctor deactivated"));
    }

    // ── Patient management ───────────────────────────────────────

    @GetMapping("/patients")
    @Operation(summary = "List all patients")
    public ResponseEntity<ApiResponse<Page<PatientView>>> listPatients(
            @RequestParam(required = false) Boolean active,
            @PageableDefault(size = 20) Pageable pageable) {
        Page<PatientView> page = (active != null)
                ? patientRepo.findByActive(active, pageable)
                : patientRepo.findAll(pageable);
        return ResponseEntity.ok(ApiResponse.ok(page));
    }

    @PostMapping("/patients/{patientId}/account")
    @ResponseStatus(HttpStatus.CREATED)
    @Operation(summary = "Create portal account for an existing patient")
    public ResponseEntity<ApiResponse<InviteResponse>> createPatientAccount(
            @PathVariable UUID patientId,
            @RequestParam String email) {
        InviteResponse invite = adminService.createPatientAccount(patientId, email);
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.created(invite));
    }

    @PostMapping("/patients/{patientId}/resend-invite")
    @Operation(summary = "Generate a fresh set-password link for an existing patient account")
    public ResponseEntity<ApiResponse<InviteResponse>> resendPatientInvite(
            @PathVariable UUID patientId) {
        InviteResponse invite = adminService.regeneratePatientInvite(patientId);
        return ResponseEntity.ok(ApiResponse.ok(invite, "Invite link regenerated"));
    }

    @PatchMapping("/patients/{patientId}/toggle")
    @Operation(summary = "Activate or deactivate a patient account")
    public ResponseEntity<ApiResponse<Void>> togglePatient(
            @PathVariable UUID patientId,
            @RequestParam boolean active,
            @RequestParam(required = false) String reason) {
        adminService.togglePatientAccount(patientId, active, reason);
        return ResponseEntity.ok(ApiResponse.ok(null, active ? "Patient activated" : "Patient deactivated"));
    }

    // ── Appointment booking ──────────────────────────────────────

    @PostMapping("/appointments")
    @ResponseStatus(HttpStatus.CREATED)
    @Operation(summary = "Book an appointment (admin flow)")
    public ResponseEntity<ApiResponse<Appointment>> bookAppointment(
            @Valid @RequestBody BookAppointmentRequest req) {
        Appointment apt = bookingService.bookAppointment(req);
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.created(apt));
    }

    // ── Today's queue ────────────────────────────────────────────

    @GetMapping("/queue")
    @Operation(summary = "Today's appointment queue")
    public ResponseEntity<ApiResponse<List<Appointment>>> getQueue() {
        return ResponseEntity.ok(ApiResponse.ok(bookingService.getTodaysQueue()));
    }

    @PatchMapping("/appointments/{id}/status")
    @Operation(summary = "Update appointment status or reassign doctor")
    public ResponseEntity<ApiResponse<Appointment>> updateStatus(
            @PathVariable UUID id,
            @Valid @RequestBody UpdateAppointmentStatusRequest req) {
        Appointment apt = bookingService.updateStatus(id, req.status(), req.reassignPractitionerId());
        return ResponseEntity.ok(ApiResponse.ok(apt));
    }

    @DeleteMapping("/appointments/{id}")
    @Operation(summary = "Cancel an appointment")
    public ResponseEntity<ApiResponse<Appointment>> cancelAppointment(@PathVariable UUID id) {
        return ResponseEntity.ok(ApiResponse.ok(bookingService.cancelAppointment(id)));
    }
}