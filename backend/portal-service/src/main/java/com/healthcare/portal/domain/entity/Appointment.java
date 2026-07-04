package com.healthcare.portal.domain.entity;

import com.healthcare.portal.domain.enums.AppointmentStatus;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.JdbcType;
import org.hibernate.dialect.PostgreSQLEnumJdbcType;

import java.time.OffsetDateTime;
import java.util.UUID;

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

    // DB generates this — let the DEFAULT gen_random_uuid() run
    @Column(name = "fhir_id", insertable = false, updatable = false)
    private UUID fhirId;

    @Column(name = "patient_id", nullable = false)
    private UUID patientId;

    @Enumerated(EnumType.STRING)
    @JdbcType(PostgreSQLEnumJdbcType.class)
    @Column(name = "status", nullable = false, columnDefinition = "appointment_status")
    private AppointmentStatus status;

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

    // DB default: 5 (1=highest, 9=lowest per HL7)
    @Column(name = "priority")
    private Integer priority = 5;

    // TEXT[] columns — DB defaults to '{}', let DB handle them
    @Column(name = "reason_codes", insertable = false, updatable = false)
    private String reasonCodes;

    @Column(name = "reason_displays", insertable = false, updatable = false)
    private String reasonDisplays;

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

    @Column(name = "reminder_24h_sent")
    private Boolean reminder24hSent = false;

    @Column(name = "reminder_2h_sent")
    private Boolean reminder2hSent = false;

    @Column(name = "fhir_version_id")
    private String fhirVersionId = "1";

    // DB defaults these to NOW() — let DB handle on insert
    @Column(name = "fhir_last_updated", insertable = false, updatable = false)
    private OffsetDateTime fhirLastUpdated;

    @Column(name = "created", insertable = false, updatable = false)
    private OffsetDateTime created;

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
        this.version = (this.version == null ? 1 : this.version) + 1;
    }
}