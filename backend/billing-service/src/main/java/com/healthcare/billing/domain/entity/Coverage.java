package com.healthcare.billing.domain.entity;

import com.healthcare.billing.domain.enums.CoverageStatus;
import com.healthcare.billing.domain.enums.CoverageType;
import com.healthcare.billing.domain.enums.SubscriberRelationship;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.ColumnTransformer;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.util.UUID;

@Entity
@Table(name = "coverage", schema = "dev")
@Getter
@Setter
@NoArgsConstructor
@EqualsAndHashCode(of = "id")
public class Coverage {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    private UUID id;

    @Column(name = "fhir_id", updatable = false)
    private UUID fhirId;

    @Column(name = "patient_id", nullable = false)
    private UUID patientId;

    @Column(name = "payer_id", nullable = false)
    private UUID payerId;

    @ColumnTransformer(write = "?::dev.coverage_status")
    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false, columnDefinition = "dev.coverage_status")
    private CoverageStatus status = CoverageStatus.active;

    @ColumnTransformer(write = "?::dev.coverage_type")
    @Enumerated(EnumType.STRING)
    @Column(name = "type", nullable = false, columnDefinition = "dev.coverage_type")
    private CoverageType type = CoverageType.medical;

    @Column(name = "subscriber_id", nullable = false)
    private byte[] subscriberId;

    @Column(name = "subscriber_id_hash", nullable = false)
    private byte[] subscriberIdHash;

    @Column(name = "group_number")
    private String groupNumber;

    @Column(name = "group_name")
    private String groupName;

    @Column(name = "plan_name", nullable = false)
    private String planName;

    @Column(name = "plan_id")
    private String planId;

    @ColumnTransformer(write = "?::dev.subscriber_relationship")
    @Enumerated(EnumType.STRING)
    @Column(name = "subscriber_relationship", nullable = false, columnDefinition = "dev.subscriber_relationship")
    private SubscriberRelationship subscriberRelationship = SubscriberRelationship.self;

    @Column(name = "subscriber_name_family")
    private String subscriberNameFamily;

    @Column(name = "subscriber_name_given")
    private String subscriberNameGiven;

    @Column(name = "subscriber_birth_date")
    private LocalDate subscriberBirthDate;

    @Column(name = "period_start", nullable = false)
    private LocalDate periodStart;

    @Column(name = "period_end")
    private LocalDate periodEnd;

    @Column(name = "order_of_benefit", nullable = false)
    private short orderOfBenefit = 1;

    @Column(name = "is_primary", insertable = false, updatable = false)
    private Boolean isPrimary;

    @Column(name = "copay_primary_care", precision = 10, scale = 2)
    private BigDecimal copayPrimaryCare;

    @Column(name = "copay_specialist", precision = 10, scale = 2)
    private BigDecimal copaySpecialist;

    @Column(name = "copay_emergency", precision = 10, scale = 2)
    private BigDecimal copayEmergency;

    @Column(name = "deductible_individual", precision = 10, scale = 2)
    private BigDecimal deductibleIndividual;

    @Column(name = "deductible_family", precision = 10, scale = 2)
    private BigDecimal deductibleFamily;

    @Column(name = "network_name")
    private String networkName;

    @Column(name = "requires_referral", nullable = false)
    private boolean requiresReferral = false;

    @Column(name = "pcp_required", nullable = false)
    private boolean pcpRequired = false;

    @Version
    @Column(name = "version")
    private Integer version = 1;

    @Column(name = "created_at", updatable = false)
    private OffsetDateTime createdAt;

    @Column(name = "updated_at")
    private OffsetDateTime updatedAt;

    @PrePersist
    void prePersist() {
        if (fhirId == null) fhirId = UUID.randomUUID();
        this.createdAt = OffsetDateTime.now();
        this.updatedAt = OffsetDateTime.now();
    }

    @PreUpdate
    void preUpdate() {
        this.updatedAt = OffsetDateTime.now();
    }
}
