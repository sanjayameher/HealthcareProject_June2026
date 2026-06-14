package com.healthcare.clinical.domain.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import java.time.OffsetDateTime;
import java.util.Map;
import java.util.UUID;

/**
 * Maps to clinical.encounters — FHIR R4 Encounter resource.
 */
@Entity
@Table(name = "encounters", schema = "clinical")
@Getter
@Setter
@NoArgsConstructor
@EqualsAndHashCode(of = "id")
public class Encounter {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    private UUID id;

    @Column(name = "patient_id", nullable = false)
    private UUID patientId;

    @Column(name = "organization_id")
    private UUID organizationId;

    @Column(name = "status", nullable = false, length = 20)
    private String status;

    @Column(name = "class_code", nullable = false, length = 20)
    private String classCode;

    @Column(name = "class_display", length = 100)
    private String classDisplay;

    @Column(name = "type_code", length = 20)
    private String typeCode;

    @Column(name = "type_display")
    private String typeDisplay;

    @Column(name = "reason_code", length = 20)
    private String reasonCode;

    @Column(name = "reason_display")
    private String reasonDisplay;

    @Column(name = "period_start")
    private OffsetDateTime periodStart;

    @Column(name = "period_end")
    private OffsetDateTime periodEnd;

    @Column(name = "length_minutes")
    private Integer lengthMinutes;

    @Column(name = "appointment_id")
    private UUID appointmentId;

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "hospitalization", columnDefinition = "JSONB")
    private Map<String, Object> hospitalization;

    @Column(name = "discharge_disposition_code", length = 20)
    private String dischargeDispositionCode;

    @Column(name = "created_at", updatable = false)
    private OffsetDateTime createdAt;

    @Column(name = "updated_at")
    private OffsetDateTime updatedAt;

    @Version
    @Column(name = "version")
    private Integer version = 0;

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
