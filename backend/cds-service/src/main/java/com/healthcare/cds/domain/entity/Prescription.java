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
@Table(name = "prescriptions")
@Getter
@Setter
@NoArgsConstructor
public class Prescription {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    private UUID id;

    @Column(name = "cds_session_id")
    private UUID cdsSessionId;

    @Column(name = "patient_id", nullable = false)
    private UUID patientId;

    @Column(name = "doctor_id", nullable = false)
    private UUID doctorId;

    @JdbcTypeCode(SqlTypes.ARRAY)
    @Column(name = "diagnosis_codes", columnDefinition = "text[]")
    private String[] diagnosisCodes;

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "drugs", columnDefinition = "jsonb", nullable = false)
    private String drugs;

    @Column(name = "notes")
    private String notes;

    @Column(name = "confirmed_at")
    private OffsetDateTime confirmedAt;

    @Column(name = "created_at", updatable = false)
    private OffsetDateTime createdAt;

    @PrePersist
    void prePersist() {
        createdAt = OffsetDateTime.now();
    }
}
