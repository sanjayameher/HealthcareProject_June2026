package com.healthcare.portal.service;

import com.healthcare.portal.config.JwtConfig;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.JwtException;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.util.Date;
import java.util.Map;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class JwtTokenService {

    private final JwtConfig jwtConfig;

    private SecretKey signingKey() {
        return Keys.hmacShaKeyFor(jwtConfig.getSecret().getBytes(StandardCharsets.UTF_8));
    }

    /** Issue a standard access token (24 h) with role claim. */
    public String generateToken(UUID userId, String role, String email) {
        long expiryMs = (long) jwtConfig.getExpiryHours() * 3600 * 1000;
        return Jwts.builder()
                .subject(userId.toString())
                .claims(Map.of("role", role, "email", email))
                .issuedAt(new Date())
                .expiration(new Date(System.currentTimeMillis() + expiryMs))
                .signWith(signingKey())
                .compact();
    }

    /** Issue a short-lived one-time password-reset token (15 min). */
    public String generatePasswordResetToken(UUID userId, String role) {
        long expiryMs = (long) jwtConfig.getPasswordResetMinutes() * 60 * 1000;
        return Jwts.builder()
                .subject(userId.toString())
                .claims(Map.of("role", role, "purpose", "password_reset"))
                .issuedAt(new Date())
                .expiration(new Date(System.currentTimeMillis() + expiryMs))
                .signWith(signingKey())
                .compact();
    }

    public Claims parseToken(String token) {
        return Jwts.parser()
                .verifyWith(signingKey())
                .build()
                .parseSignedClaims(token)
                .getPayload();
    }

    public boolean isValid(String token) {
        try {
            parseToken(token);
            return true;
        } catch (JwtException | IllegalArgumentException e) {
            return false;
        }
    }

    public UUID extractUserId(String token) {
        return UUID.fromString(parseToken(token).getSubject());
    }

    public String extractRole(String token) {
        return parseToken(token).get("role", String.class);
    }
}