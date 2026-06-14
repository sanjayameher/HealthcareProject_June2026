package com.healthcare.billing.domain.entity;

import com.healthcare.common.crypto.PhiEncryptionService;
import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.util.UUID;

/**
 * Maps to billing.coverage — FHIR R4 Coverage resource.
 * subscriber_id is PHI and stored encrypted.
 */
@Entity
@Table(name = "coverage", schema = "billing")
@Getter
@Setter
@NoArgsConstructor
@EqualsAndHashCode(of = "id")
public class Coverage {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    private UUID id;

    @Column(name = "patient_id", nullable = false)
    private UUID patientId;

    @Column(name = "payer_id", nullable = false)
    private UUID payerId;

    @Column(name = "subscriber_id_encrypted", columnDefinition = "BYTEA")
    private byte[] subscriberIdEncrypted;

    @Column(name = "subscriber_id_hmac", columnDefinition = "BYTEA")
    private byte[] subscriberIdHmac;

    @Column(name = "member_id", length = 50)
    private String memberId;

    @Column(name = "group_number", length = 50)
    private String groupNumber;

    @Column(name = "plan_name")
    private String planName;

    @Column(name = "coverage_type", length = 20)
    private String coverageType;

    @Column(name = "relationship_to_subscriber", length = 20)
    private String relationshipToSubscriber;

    @Column(name = "order_of_benefit")
    private Integer orderOfBenefit;

    @Column(name = "period_start")
    private LocalDate periodStart;

    @Column(name = "period_end")
    private LocalDate periodEnd;

    @Column(name = "status", nullable = false, length = 10)
    private String status;

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
