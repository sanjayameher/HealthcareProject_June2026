package com.healthcare.portal.domain.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.OffsetDateTime;
import java.util.UUID;

@Entity
@Table(name = "admin_accounts", schema = "dev")
@Getter
@Setter
@NoArgsConstructor
@EqualsAndHashCode(of = "id")
public class AdminAccount {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "email", nullable = false, unique = true)
    private String email;

    @Column(name = "password_hash", nullable = false)
    private String passwordHash;

    @Column(name = "full_name", nullable = false)
    private String fullName;

    @Column(name = "is_super_admin", nullable = false)
    private boolean superAdmin = false;

    @Column(name = "is_active", nullable = false)
    private boolean active = true;

    @Column(name = "must_change_password", nullable = false)
    private boolean mustChangePassword = false;

    @Column(name = "created_by")
    private UUID createdBy;

    @Column(name = "last_login_at")
    private OffsetDateTime lastLoginAt;

    @jakarta.persistence.Transient
    private String lastLoginIp;

    @Column(name = "failed_login_attempts", nullable = false)
    private short failedLoginAttempts = 0;

    @Column(name = "locked_until")
    private OffsetDateTime lockedUntil;

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