package com.healthcare.clinical.domain.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * Maps to clinical.observations (range-partitioned by created_at quarterly).
 * PRIMARY KEY is composite (id, created_at) — both fields required on every insert.
 */
@Entity
@Table(name = "observations", schema = "clinical")
@IdClass(ObservationId.class)
@Getter
@Setter
@NoArgsConstructor
@EqualsAndHashCode(of = {"id", "createdAt"})
public class Observation {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    private UUID id;

    @Id
    @Column(name = "created_at", nullable = false)
    private OffsetDateTime createdAt;

    @Column(name = "patient_id", nullable = false)
    private UUID patientId;

    @Column(name = "encounter_id")
    private UUID encounterId;

    @Column(name = "status", nullable = false, length = 20)
    private String status;

    @Column(name = "category_code", length = 30)
    private String categoryCode;

    @Column(name = "loinc_code", nullable = false, length = 10)
    private String loincCode;

    @Column(name = "loinc_display")
    private String loincDisplay;

    @Column(name = "effective_date_time")
    private OffsetDateTime effectiveDateTime;

    @Column(name = "value_quantity", precision = 12, scale = 4)
    private BigDecimal valueQuantity;

    @Column(name = "value_unit", length = 30)
    private String valueUnit;

    @Column(name = "value_system", length = 200)
    private String valueSystem;

    @Column(name = "value_code", length = 30)
    private String valueCode;

    @Column(name = "value_string")
    private String valueString;

    @Column(name = "value_boolean")
    private Boolean valueBoolean;

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "components", columnDefinition = "JSONB")
    private List<Map<String, Object>> components;

    @Column(name = "note")
    private String note;

    @PrePersist
    void prePersist() {
        if (this.createdAt == null) {
            this.createdAt = OffsetDateTime.now();
        }
    }
}
