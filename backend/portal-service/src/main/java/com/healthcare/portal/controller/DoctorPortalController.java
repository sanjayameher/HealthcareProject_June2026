package com.healthcare.portal.controller;

import com.healthcare.common.dto.ApiResponse;
import com.healthcare.portal.domain.entity.Appointment;
import com.healthcare.portal.domain.enums.AppointmentStatus;
import com.healthcare.portal.dto.BookAppointmentRequest;
import com.healthcare.portal.dto.UpdateAppointmentStatusRequest;
import com.healthcare.portal.repository.AppointmentRepository;
import com.healthcare.portal.service.AppointmentBookingService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/doctor")
@RequiredArgsConstructor
@Tag(name = "Doctor Portal", description = "Doctor-facing appointment queue and booking")
public class DoctorPortalController {

    private final AppointmentBookingService bookingService;
    private final AppointmentRepository appointmentRepo;

    @GetMapping("/{practitionerId}/queue")
    @Operation(summary = "Today's appointment queue for this doctor")
    public ResponseEntity<ApiResponse<List<Appointment>>> getQueue(@PathVariable UUID practitionerId) {
        return ResponseEntity.ok(ApiResponse.ok(bookingService.getTodaysQueueForDoctor(practitionerId)));
    }

    @GetMapping("/{practitionerId}/appointments/upcoming")
    @Operation(summary = "Upcoming appointments for this doctor (next 7 days)")
    public ResponseEntity<ApiResponse<List<Appointment>>> getUpcoming(@PathVariable UUID practitionerId) {
        OffsetDateTime now  = OffsetDateTime.now();
        List<UUID> ids = bookingService.getTodaysQueueForDoctor(practitionerId)
                .stream().map(Appointment::getId).toList();
        // Reuse the full list via a JPQL query against all appointments for this doctor
        List<AppointmentStatus> excluded = List.of(AppointmentStatus.cancelled, AppointmentStatus.noshow, AppointmentStatus.entered_in_error);
        List<Appointment> upcoming = appointmentRepo.findAllInDateRange(now, now.plusDays(7), excluded)
                .stream()
                .filter(a -> ids.contains(a.getId()))
                .toList();
        return ResponseEntity.ok(ApiResponse.ok(upcoming));
    }

    @PostMapping("/{practitionerId}/appointments")
    @ResponseStatus(HttpStatus.CREATED)
    @Operation(summary = "Book a follow-up appointment (doctor flow)")
    public ResponseEntity<ApiResponse<Appointment>> bookAppointment(
            @PathVariable UUID practitionerId,
            @Valid @RequestBody BookAppointmentRequest req) {
        // Override practitionerId from path to ensure doctor books for themselves
        BookAppointmentRequest effective = new BookAppointmentRequest(
                req.patientId(), practitionerId, req.slotId(),
                req.startTime(), req.endTime(), req.appointmentTypeCode(), req.description());
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.created(bookingService.bookAppointment(effective)));
    }

    @PatchMapping("/appointments/{id}/status")
    @Operation(summary = "Update appointment status (arrived, checked_in, fulfilled)")
    public ResponseEntity<ApiResponse<Appointment>> updateStatus(
            @PathVariable UUID id,
            @Valid @RequestBody UpdateAppointmentStatusRequest req) {
        return ResponseEntity.ok(ApiResponse.ok(bookingService.updateStatus(id, req.status(), null)));
    }

    @DeleteMapping("/appointments/{id}")
    @Operation(summary = "Cancel an appointment")
    public ResponseEntity<ApiResponse<Appointment>> cancel(@PathVariable UUID id) {
        return ResponseEntity.ok(ApiResponse.ok(bookingService.cancelAppointment(id)));
    }
}