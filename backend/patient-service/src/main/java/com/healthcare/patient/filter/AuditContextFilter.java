package com.healthcare.patient.filter;

import com.healthcare.common.audit.AuditContext;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.UUID;

/**
 * Populates the thread-local AuditContext from the JWT and request headers
 * so downstream service and aspect code can read audit metadata without
 * re-parsing the token.
 */
@Component
public class AuditContextFilter extends OncePerRequestFilter {

    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain chain) throws ServletException, IOException {
        try {
            var auth = SecurityContextHolder.getContext().getAuthentication();
            if (auth instanceof JwtAuthenticationToken jwtAuth) {
                Jwt jwt = jwtAuth.getToken();
                AuditContext ctx = AuditContext.builder()
                        .userId(parseUuid(jwt.getSubject()))
                        .userRole(jwt.getClaimAsString("role"))
                        .organizationId(parseUuid(jwt.getClaimAsString("org_id")))
                        .requestId(request.getHeader("X-Request-Id"))
                        .ipAddress(request.getRemoteAddr())
                        .userAgent(request.getHeader("User-Agent"))
                        .build();
                AuditContext.set(ctx);
            }
            chain.doFilter(request, response);
        } finally {
            AuditContext.clear();
        }
    }

    private UUID parseUuid(String value) {
        if (value == null) return null;
        try {
            return UUID.fromString(value);
        } catch (IllegalArgumentException e) {
            return null;
        }
    }
}
