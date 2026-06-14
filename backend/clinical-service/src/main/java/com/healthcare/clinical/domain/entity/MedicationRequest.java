package com.healthcare.clinical.domain.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.util.UUID;

/**
 * Maps to clinical.medication_requests — FHIR R4 MedicationRequest.
 * Medication coded via RxNorm; DEA schedule tracked for controlled substances.
 */
@Entity
@Table(name = "medication_requests", schema = "clinical")
@Getter
@Setter
@NoArgsConstructor
@EqualsAndHashCode(of = "id")
public class MedicationRequest {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    private UUID id;

    @Column(name = "patient_id", nullable = false)
    private UUID patientId;

    @Column(name = "encounter_id")
    private UUID encounterId;

    @Column(name = "requester_id")
    private UUID requesterId;

    @Column(name = "status", nullable = false, length = 20)
    private String status;

    @Column(name = "intent", nullable = false, length = 20)
    private String intent;

    @Column(name = "rxnorm_code", length = 10)
    private String rxnormCode;

    @Column(name = "medication_display")
    private String medicationDisplay;

    @Column(name = "dea_schedule", length = 5)
    private String deaSchedule;

    @Column(name = "dosage_text")
    private String dosageText;

    @Column(name = "dosage_as_needed")
    private Boolean dosageAsNeeded;

    @Column(name = "dispense_quantity")
    private Integer dispenseQuantity;

    @Column(name = "dispense_unit", length = 30)
    private String dispenseUnit;

    @Column(name = "refills_allowed")
    private Integer refillsAllowed;

    @Column(name = "days_supply")
    private Integer daysSupply;

    @Column(name = "authored_on")
    private LocalDate authoredOn;

    @Column(name = "note")
    private String note;

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
