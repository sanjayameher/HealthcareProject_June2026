package com.healthcare.common.security;

import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken;

import java.util.Optional;
import java.util.UUID;

public final class SecurityUtils {

    private SecurityUtils() {}

    public static Optional<Jwt> currentJwt() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth instanceof JwtAuthenticationToken jwtAuth) {
            return Optional.of(jwtAuth.getToken());
        }
        return Optional.empty();
    }

    public static Optional<UUID> currentUserId() {
        return currentJwt()
                .map(jwt -> jwt.getClaimAsString("sub"))
                .map(UUID::fromString);
    }

    public static Optional<String> currentUserRole() {
        return currentJwt()
                .map(jwt -> jwt.getClaimAsString("role"));
    }

    public static Optional<UUID> currentOrganizationId() {
        return currentJwt()
                .map(jwt -> jwt.getClaimAsString("org_id"))
                .map(UUID::fromString);
    }

    public static boolean hasRole(String role) {
        return SecurityContextHolder.getContext().getAuthentication()
                .getAuthorities()
                .stream()
                .anyMatch(a -> a.getAuthority().equals("ROLE_" + role));
    }

    public static boolean isClinician() { return hasRole("CLINICIAN"); }
    public static boolean isPatient() { return hasRole("PATIENT"); }
    public static boolean isAdmin() { return hasRole("ADMIN"); }
}
