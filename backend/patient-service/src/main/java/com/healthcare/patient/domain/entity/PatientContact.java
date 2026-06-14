package com.healthcare.patient.domain.entity;

import com.healthcare.patient.converter.PhiEncryptionConverter;
import com.healthcare.patient.domain.enums.ContactRelationship;
import com.healthcare.patient.domain.enums.Gender;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.ColumnTransformer;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.util.UUID;

@Entity
@Table(name = "patient_contacts")
@Getter
@Setter
@NoArgsConstructor
@EqualsAndHashCode(of = "id")
public class PatientContact {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "patient_id", nullable = false)
    private Patient patient;

    @ColumnTransformer(write = "?::dev.contact_relationship")
    @Enumerated(EnumType.STRING)
    @Column(name = "relationship", nullable = false, columnDefinition = "dev.contact_relationship")
    private ContactRelationship relationship;

    @Column(name = "priority", nullable = false)
    private short priority = 1;

    @Column(name = "name_family")
    private String nameFamily;

    @JdbcTypeCode(SqlTypes.ARRAY)
    @Column(name = "name_given", columnDefinition = "TEXT[]")
    private String[] nameGiven;

    @JdbcTypeCode(SqlTypes.ARRAY)
    @Column(name = "name_prefix", columnDefinition = "TEXT[]")
    private String[] namePrefix;

    @JdbcTypeCode(SqlTypes.ARRAY)
    @Column(name = "name_suffix", columnDefinition = "TEXT[]")
    private String[] nameSuffix;

    @Convert(converter = PhiEncryptionConverter.class)
    @Column(name = "phone", columnDefinition = "BYTEA")
    private String phone;

    @Column(name = "phone_hash", columnDefinition = "BYTEA")
    private byte[] phoneHash;

    @Convert(converter = PhiEncryptionConverter.class)
    @Column(name = "email", columnDefinition = "BYTEA")
    private String email;

    @Column(name = "email_hash", columnDefinition = "BYTEA")
    private byte[] emailHash;

    @Column(name = "fax")
    private String fax;

    @Column(name = "address_line1")
    private String addressLine1;

    @Column(name = "address_city")
    private String addressCity;

    @Column(name = "address_state", length = 2)
    private String addressState;

    @Column(name = "address_postal", length = 10)
    private String addressPostal;

    @Column(name = "address_country", length = 2)
    private String addressCountry = "US";

    @Column(name = "organization")
    private String organization;

    @ColumnTransformer(write = "?::dev.gender")
    @Enumerated(EnumType.STRING)
    @Column(name = "gender", columnDefinition = "dev.gender")
    private Gender gender;

    @Column(name = "birth_date")
    private LocalDate birthDate;

    @Column(name = "period_start")
    private LocalDate periodStart;

    @Column(name = "period_end")
    private LocalDate periodEnd;

    @Column(name = "is_active", nullable = false)
    private boolean active = true;

    @Column(name = "notes")
    private String notes;

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
