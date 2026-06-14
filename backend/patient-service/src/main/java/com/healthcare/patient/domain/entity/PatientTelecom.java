package com.healthcare.patient.domain.entity;

import com.healthcare.patient.converter.PhiEncryptionConverter;
import com.healthcare.patient.domain.enums.ContactSystem;
import com.healthcare.patient.domain.enums.ContactUse;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.ColumnTransformer;

import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.util.UUID;

@Entity
@Table(name = "patient_telecoms")
@Getter
@Setter
@NoArgsConstructor
@EqualsAndHashCode(of = "id")
public class PatientTelecom {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "patient_id", nullable = false)
    private Patient patient;

    @ColumnTransformer(write = "?::dev.telecom_system")
    @Enumerated(EnumType.STRING)
    @Column(name = "system", nullable = false, columnDefinition = "dev.telecom_system")
    private ContactSystem system;

    /** PHI: stored AES-256-GCM encrypted as BYTEA in the database. */
    @Convert(converter = PhiEncryptionConverter.class)
    @Column(name = "value", nullable = false, columnDefinition = "BYTEA")
    private String value;

    /** HMAC-SHA256 shadow column for equality lookup without decrypting. */
    @Column(name = "value_hash", nullable = false, columnDefinition = "BYTEA")
    private byte[] valueHmac;

    @ColumnTransformer(write = "?::dev.telecom_use")
    @Enumerated(EnumType.STRING)
    @Column(name = "use", columnDefinition = "dev.telecom_use")
    private ContactUse use;

    @Column(name = "rank", nullable = false)
    private short rank = 1;

    @Column(name = "period_start")
    private LocalDate periodStart;

    @Column(name = "period_end")
    private LocalDate periodEnd;

    @Column(name = "is_verified", nullable = false)
    private boolean verified = false;

    @Column(name = "verified_at")
    private OffsetDateTime verifiedAt;
}
