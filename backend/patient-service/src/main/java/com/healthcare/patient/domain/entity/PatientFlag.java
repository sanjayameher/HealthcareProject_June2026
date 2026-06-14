package com.healthcare.patient.domain.entity;

import com.healthcare.patient.domain.enums.FlagStatus;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.ColumnTransformer;

import java.time.OffsetDateTime;
import java.util.UUID;

@Entity
@Table(name = "patient_flags")
@Getter
@Setter
@NoArgsConstructor
@EqualsAndHashCode(of = "id")
public class PatientFlag {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    private UUID id;

    @Column(name = "fhir_id", unique = true, nullable = false,
            columnDefinition = "UUID DEFAULT gen_random_uuid()")
    private UUID fhirId;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "patient_id", nullable = false)
    private Patient patient;

    @ColumnTransformer(write = "?::dev.flag_status")
    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false, columnDefinition = "dev.flag_status")
    private FlagStatus status = FlagStatus.active;

    @Column(name = "category_code")
    private String categoryCode;

    @Column(name = "category_display")
    private String categoryDisplay;

    @Column(name = "code", nullable = false)
    private String code;

    @Column(name = "code_system", nullable = false)
    private String codeSystem = "SNOMED-CT";

    @Column(name = "display", nullable = false)
    private String display;

    @Column(name = "description")
    private String description;

    @Column(name = "severity")
    private String severity;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "author_id")
    private Practitioner author;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "author_org_id")
    private Organization authorOrg;

    @Column(name = "period_start")
    private OffsetDateTime periodStart;

    @Column(name = "period_end")
    private OffsetDateTime periodEnd;

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
