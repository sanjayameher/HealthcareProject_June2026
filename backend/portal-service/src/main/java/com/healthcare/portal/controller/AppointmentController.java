package com.healthcare.portal.controller;

import com.healthcare.common.dto.ApiResponse;
import com.healthcare.common.exception.ResourceNotFoundException;
import com.healthcare.portal.domain.entity.Appointment;
import com.healthcare.portal.repository.AppointmentRepository;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.web.PageableDefault;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.lang.Nullable;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/appointments")
@RequiredArgsConstructor
@Tag(name = "Appointments", description = "FHIR R4 Appointment scheduling")
public class AppointmentController {

    private final AppointmentRepository appointmentRepository;

    // Optional — not available when running with local profile (KafkaAutoConfiguration excluded)
    @Autowired(required = false)
    @Nullable
    private KafkaTemplate<String, Object> kafkaTemplate;

    @GetMapping("/{id}")
    @PreAuthorize("hasAnyRole('CLINICIAN', 'ADMIN', 'PATIENT')")
    @Operation(summary = "Get appointment by ID")
    public ResponseEntity<ApiResponse<Appointment>> getAppointment(@PathVariable UUID id) {
        Appointment apt = appointmentRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Appointment", id));
        return ResponseEntity.ok(ApiResponse.ok(apt));
    }

    @GetMapping("/patient/{patientId}")
    @PreAuthorize("hasAnyRole('CLINICIAN', 'ADMIN', 'PATIENT')")
    @Operation(summary = "List appointments for a patient")
    public ResponseEntity<ApiResponse<Page<Appointment>>> getPatientAppointments(
            @PathVariable UUID patientId,
            @PageableDefault(size = 20) Pageable pageable) {
        return ResponseEntity.ok(ApiResponse.ok(
                appointmentRepository.findByPatientIdOrderByStartTimeDesc(patientId, pageable)));
    }

    @GetMapping("/patient/{patientId}/upcoming")
    @PreAuthorize("hasAnyRole('CLINICIAN', 'ADMIN', 'PATIENT')")
    @Operation(summary = "List upcoming appointments for a patient (next 90 days)")
    public ResponseEntity<ApiResponse<List<Appointment>>> getUpcomingAppointments(@PathVariable UUID patientId) {
        OffsetDateTime now = OffsetDateTime.now();
        List<Appointment> upcoming = appointmentRepository
                .findUpcomingForPatient(patientId, now, now.plusDays(90));
        return ResponseEntity.ok(ApiResponse.ok(upcoming));
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    @PreAuthorize("hasAnyRole('CLINICIAN', 'ADMIN', 'PATIENT')")
    @Operation(summary = "Book an appointment")
    public ResponseEntity<ApiResponse<Appointment>> bookAppointment(@RequestBody Appointment appointment) {
        Appointment saved = appointmentRepository.save(appointment);
        if (kafkaTemplate != null) {
            kafkaTemplate.send("appointment.booked", saved.getId().toString(), saved);
        }
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.created(saved));
    }

    @PatchMapping("/{id}/cancel")
    @PreAuthorize("hasAnyRole('CLINICIAN', 'ADMIN', 'PATIENT')")
    @Operation(summary = "Cancel an appointment")
    public ResponseEntity<ApiResponse<Appointment>> cancelAppointment(@PathVariable UUID id) {
        Appointment apt = appointmentRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Appointment", id));
        apt.setStatus("cancelled");
        Appointment saved = appointmentRepository.save(apt);
        return ResponseEntity.ok(ApiResponse.ok(saved));
    }
}
