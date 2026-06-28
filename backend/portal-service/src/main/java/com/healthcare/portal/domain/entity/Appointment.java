package com.healthcare.portal.domain.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.OffsetDateTime;
import java.util.UUID;

/**
 * Maps to dev.appointments — FHIR R4 Appointment resource.
 */
@Entity
@Table(name = "appointments", schema = "dev")
@Getter
@Setter
@NoArgsConstructor
@EqualsAndHashCode(of = "id")
public class Appointment {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "patient_id", nullable = false)
    private UUID patientId;

    @Column(name = "status", nullable = false, length = 30)
    private String status;

    @Column(name = "cancellation_reason")
    private String cancellationReason;

    @Column(name = "appointment_type_code", length = 30)
    private String appointmentTypeCode;

    @Column(name = "service_type_code")
    private String serviceTypeCode;

    @Column(name = "service_type_display")
    private String serviceTypeDisplay;

    @Column(name = "specialty_code")
    private String specialtyCode;

    @Column(name = "specialty_display")
    private String specialtyDisplay;

    @Column(name = "priority")
    private Integer priority;

    @Column(name = "description")
    private String description;

    @Column(name = "start_time", nullable = false)
    private OffsetDateTime startTime;

    @Column(name = "end_time", nullable = false)
    private OffsetDateTime endTime;

    // GENERATED ALWAYS AS column in PostgreSQL — read-only
    @Column(name = "duration_minutes", insertable = false, updatable = false)
    private Integer durationMinutes;

    @Column(name = "slot_id")
    private UUID slotId;

    @Column(name = "comment")
    private String comment;

    @Column(name = "patient_instruction")
    private String patientInstruction;

    @Column(name = "telehealth_meeting_id", length = 100)
    private String telehealthMeetingId;

    @Column(name = "telehealth_url")
    private String telehealthUrl;

    @Column(name = "encounter_id")
    private UUID encounterId;

    @Column(name = "based_on_service_request_id")
    private UUID basedOnServiceRequestId;

    @Column(name = "version")
    private Integer version;

    @Column(name = "created_at", updatable = false)
    private OffsetDateTime createdAt;

    @Column(name = "updated_at")
    private OffsetDateTime updatedAt;

    @PrePersist
    void prePersist() {
        this.createdAt = OffsetDateTime.now();
        this.updatedAt = OffsetDateTime.now();
        if (this.version == null) this.version = 1;
    }

    @PreUpdate
    void preUpdate() {
        this.updatedAt = OffsetDateTime.now();
    }
}
