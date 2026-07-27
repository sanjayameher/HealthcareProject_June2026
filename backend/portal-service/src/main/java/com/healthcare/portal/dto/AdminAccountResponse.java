package com.healthcare.portal.dto;

import com.healthcare.portal.domain.entity.AdminAccount;

import java.time.OffsetDateTime;
import java.util.UUID;

public record AdminAccountResponse(
        UUID id,
        String email,
        String fullName,
        boolean superAdmin,
        boolean active,
        boolean mustChangePassword,
        OffsetDateTime lastLoginAt,
        short failedLoginAttempts,
        OffsetDateTime lockedUntil,
        UUID createdBy,
        OffsetDateTime createdAt,
        OffsetDateTime updatedAt
) {
    public static AdminAccountResponse from(AdminAccount a) {
        return new AdminAccountResponse(
                a.getId(), a.getEmail(), a.getFullName(),
                a.isSuperAdmin(), a.isActive(), a.isMustChangePassword(),
                a.getLastLoginAt(), a.getFailedLoginAttempts(), a.getLockedUntil(),
                a.getCreatedBy(), a.getCreatedAt(), a.getUpdatedAt()
        );
    }
}