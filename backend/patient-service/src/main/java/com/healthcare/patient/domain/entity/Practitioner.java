package com.healthcare.patient.domain.entity;

import com.healthcare.patient.domain.enums.Gender;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.ColumnTransformer;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.annotations.SQLDelete;
import org.hibernate.annotations.SQLRestriction;
import org.hibernate.type.SqlTypes;

import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@Entity
@Table(name = "practitioners")
@SQLDelete(sql = "UPDATE practitioners SET deleted_at = now() WHERE id = ?")
@SQLRestriction("deleted_at IS NULL")
@Getter
@Setter
@NoArgsConstructor
@EqualsAndHashCode(of = "id")
@ToString(exclude = "roles")
public class Practitioner {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "organization_id")
    private Organization organization;

    @Column(name = "npi", unique = true, length = 10)
    private String npi;

    @Column(name = "given_name", nullable = false)
    private String givenName;

    @Column(name = "family_name", nullable = false)
    private String familyName;

    @Column(name = "prefix")
    private String prefix;

    @Column(name = "suffix")
    private String suffix;

    @Column(name = "full_name_display", insertable = false, updatable = false)
    private String fullNameDisplay;

    @ColumnTransformer(write = "?::dev.gender")
    @Enumerated(EnumType.STRING)
    @Column(name = "gender", columnDefinition = "dev.gender")
    private Gender gender;

    @Column(name = "birth_date")
    private LocalDate birthDate;

    @Column(name = "state_license")
    private String stateLicense;

    @Column(name = "state_license_state", length = 2)
    private String stateLicenseState;

    @JdbcTypeCode(SqlTypes.ARRAY)
    @Column(name = "specialty_codes", columnDefinition = "TEXT[]")
    private String[] specialtyCodes = new String[0];

    @JdbcTypeCode(SqlTypes.ARRAY)
    @Column(name = "specialty_displays", columnDefinition = "TEXT[]")
    private String[] specialtyDisplays = new String[0];

    @JdbcTypeCode(SqlTypes.ARRAY)
    @Column(name = "qualification_codes", columnDefinition = "TEXT[]")
    private String[] qualificationCodes = new String[0];

    @JdbcTypeCode(SqlTypes.ARRAY)
    @Column(name = "languages", columnDefinition = "VARCHAR(10)[]")
    private String[] languages = new String[0];

    @Column(name = "is_telehealth_enabled", nullable = false)
    private boolean telehealthEnabled = true;

    @Column(name = "telehealth_platform")
    private String telehealthPlatform;

    @Column(name = "active", nullable = false)
    private boolean active = true;

    @OneToMany(mappedBy = "practitioner", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<PractitionerRole> roles = new ArrayList<>();

    @Column(name = "created_at", updatable = false)
    private OffsetDateTime createdAt;

    @Column(name = "updated_at")
    private OffsetDateTime updatedAt;

    @Column(name = "deleted_at")
    private OffsetDateTime deletedAt;

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
