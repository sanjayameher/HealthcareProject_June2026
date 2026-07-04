package com.healthcare.portal.controller;

import com.healthcare.common.dto.ApiResponse;
import com.healthcare.portal.domain.entity.Appointment;
import com.healthcare.portal.domain.entity.PractitionerAvailabilitySlot;
import com.healthcare.portal.domain.enums.AppointmentStatus;
import com.healthcare.portal.domain.entity.PractitionerView;
import com.healthcare.portal.dto.BookAppointmentRequest;
import com.healthcare.portal.repository.AppointmentRepository;
import com.healthcare.portal.repository.PractitionerViewRepository;
import com.healthcare.portal.service.AppointmentBookingService;
import com.healthcare.portal.service.AvailabilityService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.web.PageableDefault;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/patient")
@RequiredArgsConstructor
@Tag(name = "Patient Portal", description = "Patient-facing appointment booking and upcoming visits")
public class PatientPortalController {

    private final AppointmentBookingService bookingService;
    private final AvailabilityService availabilityService;
    private final AppointmentRepository appointmentRepo;
    private final PractitionerViewRepository practitionerRepo;

    // ── Appointments ─────────────────────────────────────────────

    @GetMapping("/{patientId}/appointments")
    @Operation(summary = "List all appointments for this patient")
    public ResponseEntity<ApiResponse<Page<Appointment>>> getAppointments(
            @PathVariable UUID patientId,
            @PageableDefault(size = 20) Pageable pageable) {
        return ResponseEntity.ok(ApiResponse.ok(
                appointmentRepo.findByPatientIdOrderByStartTimeDesc(patientId, pageable)));
    }

    @GetMapping("/{patientId}/appointments/upcoming")
    @Operation(summary = "Upcoming appointments for this patient (next 90 days)")
    public ResponseEntity<ApiResponse<List<Appointment>>> getUpcoming(@PathVariable UUID patientId) {
        OffsetDateTime now = OffsetDateTime.now();
        return ResponseEntity.ok(ApiResponse.ok(
                appointmentRepo.findUpcomingForPatient(patientId, now, now.plusDays(90),
                        List.of(AppointmentStatus.cancelled, AppointmentStatus.noshow, AppointmentStatus.entered_in_error))));
    }

    @PostMapping("/{patientId}/appointments")
    @ResponseStatus(HttpStatus.CREATED)
    @Operation(summary = "Book an appointment (patient self-booking)")
    public ResponseEntity<ApiResponse<Appointment>> bookAppointment(
            @PathVariable UUID patientId,
            @Valid @RequestBody BookAppointmentRequest req) {
        BookAppointmentRequest effective = new BookAppointmentRequest(
                patientId, req.practitionerId(), req.slotId(),
                req.startTime(), req.endTime(), req.appointmentTypeCode(), req.description());
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.created(bookingService.bookAppointment(effective)));
    }

    @DeleteMapping("/appointments/{id}")
    @Operation(summary = "Cancel an appointment")
    public ResponseEntity<ApiResponse<Appointment>> cancel(@PathVariable UUID id) {
        return ResponseEntity.ok(ApiResponse.ok(bookingService.cancelAppointment(id)));
    }

    // ── Doctor search & availability ─────────────────────────────

    @GetMapping("/doctors")
    @Operation(summary = "Browse active doctors (optionally search by name)")
    public ResponseEntity<ApiResponse<Page<PractitionerView>>> searchDoctors(
            @RequestParam(required = false) String q,
            @PageableDefault(size = 20) Pageable pageable) {
        Page<PractitionerView> page = (q != null && !q.isBlank())
                ? practitionerRepo.searchActive(q, pageable)
                : practitionerRepo.findByActive(true, pageable);
        return ResponseEntity.ok(ApiResponse.ok(page));
    }

    @GetMapping("/doctors/{practitionerId}/availability")
    @Operation(summary = "Get available slots for a doctor on a specific date")
    public ResponseEntity<ApiResponse<List<PractitionerAvailabilitySlot>>> getDoctorAvailability(
            @PathVariable UUID practitionerId,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        return ResponseEntity.ok(ApiResponse.ok(
                availabilityService.getAvailableSlots(practitionerId, date)));
    }

    @GetMapping("/doctors/{practitionerId}/availability/month")
    @Operation(summary = "Get all slots for a doctor in a month")
    public ResponseEntity<ApiResponse<List<PractitionerAvailabilitySlot>>> getDoctorMonthAvailability(
            @PathVariable UUID practitionerId,
            @RequestParam int year,
            @RequestParam int month) {
        return ResponseEntity.ok(ApiResponse.ok(
                availabilityService.getSlotsForMonth(practitionerId, year, month)));
    }
}