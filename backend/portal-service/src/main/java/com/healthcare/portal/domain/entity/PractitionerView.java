package com.healthcare.portal.domain.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.Immutable;

import java.time.OffsetDateTime;
import java.util.UUID;

/**
 * Read-only JPA view of the dev.practitioners table managed by patient-service.
 * portal-service never writes to this table; only reads for display and lookups.
 */
@Entity
@Immutable
@Table(name = "practitioners", schema = "dev")
@Getter
@NoArgsConstructor
@EqualsAndHashCode(of = "id")
public class PractitionerView {

    @Id
    private UUID id;

    @Column(name = "given_name")
    private String givenName;

    @Column(name = "family_name")
    private String familyName;

    @Column(name = "full_name_display")
    private String fullNameDisplay;

    @Column(name = "prefix")
    private String prefix;

    @Column(name = "gender")
    private String gender;

    @Column(name = "active")
    private Boolean active;

    @Column(name = "organization_id")
    private UUID organizationId;

    @Column(name = "created_at", updatable = false)
    private OffsetDateTime createdAt;
}