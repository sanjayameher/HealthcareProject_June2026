package com.healthcare.patient.domain.entity;

import com.healthcare.patient.converter.PhiEncryptionConverter;
import com.healthcare.patient.domain.enums.IdentifierSystem;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.ColumnTransformer;

import java.time.OffsetDateTime;
import java.util.UUID;

@Entity
@Table(name = "patient_identifiers")
@Getter
@Setter
@NoArgsConstructor
@EqualsAndHashCode(of = "id")
public class PatientIdentifier {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "patient_id", nullable = false)
    private Patient patient;

    @ColumnTransformer(write = "?::dev.identifier_system")
    @Enumerated(EnumType.STRING)
    @Column(name = "system", nullable = false, columnDefinition = "dev.identifier_system")
    private IdentifierSystem system;

    @Convert(converter = PhiEncryptionConverter.class)
    @Column(name = "value", columnDefinition = "BYTEA", nullable = false)
    private String value;

    @Column(name = "value_hash", columnDefinition = "BYTEA", nullable = false)
    private byte[] valueHash;

    @Column(name = "assigner_name")
    private String assigner;

    @Column(name = "created_at", updatable = false)
    private OffsetDateTime createdAt;

    @PrePersist
    void prePersist() {
        this.createdAt = OffsetDateTime.now();
    }
}
