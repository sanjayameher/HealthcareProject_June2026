package com.healthcare.billing.domain.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.OffsetDateTime;
import java.util.UUID;

@Entity
@Table(name = "payers", schema = "dev")
@Getter
@Setter
@NoArgsConstructor
@EqualsAndHashCode(of = "id")
public class Payer {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    private UUID id;

    @Column(name = "fhir_id", updatable = false)
    private UUID fhirId;

    @Column(name = "name", nullable = false)
    private String name;

    @Column(name = "short_name")
    private String shortName;

    @Column(name = "payer_id", length = 20, unique = true)
    private String payerId;

    @Column(name = "npi", length = 10)
    private String npi;

    @Column(name = "address_line1")
    private String addressLine1;

    @Column(name = "address_line2")
    private String addressLine2;

    @Column(name = "city")
    private String city;

    @Column(name = "state", length = 2)
    private String state;

    @Column(name = "postal_code", length = 10)
    private String postalCode;

    @Column(name = "country", length = 2)
    private String country = "US";

    @Column(name = "phone", length = 20)
    private String phone;

    @Column(name = "fax", length = 20)
    private String fax;

    @Column(name = "website")
    private String website;

    @Column(name = "claims_address")
    private String claimsAddress;

    @Column(name = "appeals_address")
    private String appealsAddress;

    @Column(name = "supports_electronic_claims", nullable = false)
    private boolean supportsElectronicClaims = true;

    @Column(name = "supports_eligibility_check", nullable = false)
    private boolean supportsEligibilityCheck = true;

    @Column(name = "eligibility_api_endpoint")
    private String eligibilityApiEndpoint;

    @Column(name = "is_active", nullable = false)
    private boolean active = true;

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
