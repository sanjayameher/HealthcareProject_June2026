package com.healthcare.patient.domain.entity;

import com.healthcare.patient.domain.enums.Gender;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.ColumnTransformer;
import org.hibernate.annotations.SQLDelete;
import org.hibernate.annotations.SQLRestriction;

import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@Entity
@Table(name = "patients")
@SQLDelete(sql = "UPDATE patients SET deleted_at = now() WHERE id = ? AND version = ?")
@SQLRestriction("deleted_at IS NULL")
@Getter
@Setter
@NoArgsConstructor
@EqualsAndHashCode(of = "id")
@ToString(exclude = {"names", "addresses", "telecoms", "contacts", "identifiers", "flags"})
public class Patient {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "managing_organization_id")
    private Organization managingOrganization;

    @Column(name = "mrn", nullable = false, unique = true, length = 20)
    private String mrn;

    @ColumnTransformer(write = "?::dev.gender")
    @Enumerated(EnumType.STRING)
    @Column(name = "gender", nullable = false, columnDefinition = "dev.gender")
    private Gender gender;

    @Column(name = "birth_date")
    private LocalDate birthDate;

    @Column(name = "deceased_boolean")
    private Boolean deceasedBoolean;

    @Column(name = "deceased_date_time")
    private OffsetDateTime deceasedDateTime;

    @Column(name = "multiple_birth_boolean")
    private Boolean multipleBirthBoolean;

    @Column(name = "multiple_birth_order")
    private Short multipleBirthOrder;

    @jakarta.persistence.Transient
    private String preferredLanguage;

    @Column(name = "active", nullable = false)
    private boolean active = true;

    @Column(name = "created_at", nullable = false, updatable = false)
    private OffsetDateTime createdAt;

    @Column(name = "updated_at", nullable = false)
    private OffsetDateTime updatedAt;

    @Column(name = "deleted_at")
    private OffsetDateTime deletedAt;

    @Version
    @Column(name = "version", nullable = false)
    private Integer version = 0;

    @OneToMany(mappedBy = "patient", cascade = CascadeType.ALL, orphanRemoval = true, fetch = FetchType.LAZY)
    @OrderBy("period_start DESC NULLS FIRST")
    private List<PatientName> names = new ArrayList<>();

    @OneToMany(mappedBy = "patient", cascade = CascadeType.ALL, orphanRemoval = true, fetch = FetchType.LAZY)
    private List<PatientAddress> addresses = new ArrayList<>();

    @OneToMany(mappedBy = "patient", cascade = CascadeType.ALL, orphanRemoval = true, fetch = FetchType.LAZY)
    private List<PatientTelecom> telecoms = new ArrayList<>();

    @OneToMany(mappedBy = "patient", cascade = CascadeType.ALL, orphanRemoval = true, fetch = FetchType.LAZY)
    private List<PatientContact> contacts = new ArrayList<>();

    @OneToMany(mappedBy = "patient", cascade = CascadeType.ALL, orphanRemoval = true, fetch = FetchType.LAZY)
    private List<PatientIdentifier> identifiers = new ArrayList<>();

    @OneToMany(mappedBy = "patient", cascade = CascadeType.ALL, orphanRemoval = true, fetch = FetchType.LAZY)
    private List<PatientFlag> flags = new ArrayList<>();

    @PrePersist
    void prePersist() {
        this.createdAt = OffsetDateTime.now();
        this.updatedAt = OffsetDateTime.now();
    }

    @PreUpdate
    void preUpdate() {
        this.updatedAt = OffsetDateTime.now();
    }

    public void addName(PatientName name) {
        name.setPatient(this);
        names.add(name);
    }

    public void addAddress(PatientAddress address) {
        address.setPatient(this);
        addresses.add(address);
    }

    public void addTelecom(PatientTelecom telecom) {
        telecom.setPatient(this);
        telecoms.add(telecom);
    }
}
