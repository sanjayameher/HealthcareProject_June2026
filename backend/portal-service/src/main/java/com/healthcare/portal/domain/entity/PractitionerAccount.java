package com.healthcare.portal.domain.entity;

import com.healthcare.portal.config.PhiEncryptionConverter;
import jakarta.persistence.*;
import lombok.*;

import java.time.OffsetDateTime;
import java.util.UUID;

@Entity
@Table(name = "practitioner_accounts", schema = "dev")
@Getter
@Setter
@NoArgsConstructor
@EqualsAndHashCode(of = "id")
public class PractitionerAccount {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "practitioner_id", nullable = false, unique = true)
    private UUID practitionerId;

    @Convert(converter = PhiEncryptionConverter.class)
    @Column(name = "email", nullable = false)
    private String email;

    @Column(name = "email_hash", nullable = false, unique = true)
    private byte[] emailHash;

    @Column(name = "email_verified", nullable = false)
    private boolean emailVerified = false;

    @Column(name = "email_verified_at")
    private OffsetDateTime emailVerifiedAt;

    @Column(name = "password_hash", nullable = false)
    private String passwordHash;

    @Column(name = "password_changed_at")
    private OffsetDateTime passwordChangedAt;

    @Column(name = "must_change_password", nullable = false)
    private boolean mustChangePassword = true;

    @Column(name = "last_login_at")
    private OffsetDateTime lastLoginAt;

    @Transient
    private String lastLoginIp;

    @Column(name = "failed_login_attempts", nullable = false)
    private short failedLoginAttempts = 0;

    @Column(name = "locked_until")
    private OffsetDateTime lockedUntil;

    @Column(name = "is_active", nullable = false)
    private boolean active = true;

    @Column(name = "deactivated_at")
    private OffsetDateTime deactivatedAt;

    @Column(name = "deactivation_reason")
    private String deactivationReason;

    @Column(name = "created_at", updatable = false)
    private OffsetDateTime createdAt;

    @Column(name = "updated_at")
    private OffsetDateTime updatedAt;

    @PrePersist
    void prePersist() {
        this.createdAt = OffsetDateTime.now();
        this.updatedAt = OffsetDateTime.now();
        if (this.passwordChangedAt == null) this.passwordChangedAt = OffsetDateTime.now();
    }

    @PreUpdate
    void preUpdate() {
        this.updatedAt = OffsetDateTime.now();
    }
}