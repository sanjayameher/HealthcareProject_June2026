package com.healthcare.portal.domain.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.OffsetDateTime;
import java.util.UUID;

/**
 * Maps to portal.appointments — FHIR R4 Appointment resource.
 */
@Entity
@Table(name = "appointments", schema = "portal")
@Getter
@Setter
@NoArgsConstructor
@EqualsAndHashCode(of = "id")
public class Appointment {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    private UUID id;

    @Column(name = "patient_id", nullable = false)
    private UUID patientId;

    @Column(name = "organization_id")
    private UUID organizationId;

    @Column(name = "encounter_id")
    private UUID encounterId;

    @Column(name = "status", nullable = false, length = 20)
    private String status;

    @Column(name = "appointment_type_code", length = 30)
    private String appointmentTypeCode;

    @Column(name = "appointment_type_display")
    private String appointmentTypeDisplay;

    @Column(name = "reason_code", length = 20)
    private String reasonCode;

    @Column(name = "reason_display")
    private String reasonDisplay;

    @Column(name = "priority")
    private Integer priority;

    @Column(name = "description")
    private String description;

    @Column(name = "start_time", nullable = false)
    private OffsetDateTime startTime;

    @Column(name = "end_time", nullable = false)
    private OffsetDateTime endTime;

    @Column(name = "duration_minutes")
    private Integer durationMinutes;

    @Column(name = "slot_id")
    private UUID slotId;

    @Column(name = "comment")
    private String comment;

    @Column(name = "patient_instruction")
    private String patientInstruction;

    @Column(name = "telehealth_meeting_id", length = 100)
    private String telehealthMeetingId;

    @Column(name = "telehealth_join_url")
    private String telehealthJoinUrl;

    @Column(name = "reminder_sent_at")
    private OffsetDateTime reminderSentAt;

    @Column(name = "created_at", updatable = false)
    private OffsetDateTime createdAt;

    @Column(name = "updated_at")
    private OffsetDateTime updatedAt;

    @PrePersist
    void prePersist() {
        this.createdAt = OffsetDateTime.now();
        this.updatedAt = OffsetDateTime.now();
    }

    @PreUpdate
    void preUpdate() {
        this.updatedAt = OffsetDateTime.now();
    }
}
