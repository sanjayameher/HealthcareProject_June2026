package com.healthcare.cds.domain.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import java.time.OffsetDateTime;
import java.util.UUID;

@Entity
@Table(name = "cds_diagnose_sessions")
@Getter
@Setter
@NoArgsConstructor
public class CdsDiagnoseSession {

    public static final String PENDING = "pending";
    public static final String ACCEPTED = "accepted";
    public static final String EDITED = "edited";
    public static final String DISCARDED = "discarded";

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    private UUID id;

    @Column(name = "patient_id", nullable = false)
    private UUID patientId;

    @Column(name = "doctor_id", nullable = false)
    private UUID doctorId;

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "input_payload", columnDefinition = "jsonb", nullable = false)
    private String inputPayload;

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "llm_response", columnDefinition = "jsonb")
    private String llmResponse;

    @Column(name = "status", nullable = false)
    private String status = PENDING;

    @Column(name = "created_at", updatable = false)
    private OffsetDateTime createdAt;

    @Column(name = "updated_at")
    private OffsetDateTime updatedAt;

    @PrePersist
    void prePersist() {
        createdAt = OffsetDateTime.now();
        updatedAt = OffsetDateTime.now();
    }

    @PreUpdate
    void preUpdate() {
        updatedAt = OffsetDateTime.now();
    }
}
