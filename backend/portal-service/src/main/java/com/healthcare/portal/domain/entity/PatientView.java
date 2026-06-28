package com.healthcare.portal.domain.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.Immutable;

import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.util.UUID;

/**
 * Read-only JPA view of the dev.patients table managed by patient-service.
 * portal-service never writes to this table.
 */
@Entity
@Immutable
@Table(name = "patients", schema = "dev")
@Getter
@NoArgsConstructor
@EqualsAndHashCode(of = "id")
public class PatientView {

    @Id
    private UUID id;

    @Column(name = "mrn")
    private String mrn;

    @Column(name = "gender")
    private String gender;

    @Column(name = "birth_date")
    private LocalDate birthDate;

    @Column(name = "active")
    private Boolean active;

    @Column(name = "managing_organization_id")
    private UUID managingOrganizationId;

    @Column(name = "created_at", updatable = false)
    private OffsetDateTime createdAt;
}