package com.healthcare.cds.security;

import com.healthcare.cds.config.CdsProperties;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.JwtException;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.util.UUID;

/**
 * Parses JWTs issued by portal-service. cds-service never issues tokens itself —
 * it only validates them, using the same HS256 shared secret (cds.jwt.secret,
 * which must equal portal-service's healthcare.jwt.secret).
 */
@Service
@RequiredArgsConstructor
public class CdsJwtService {

    private final CdsProperties props;

    private SecretKey signingKey() {
        return Keys.hmacShaKeyFor(props.getJwt().getSecret().getBytes(StandardCharsets.UTF_8));
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

    public static String stripBearer(String authorizationHeader) {
        if (authorizationHeader != null && authorizationHeader.startsWith("Bearer ")) {
            return authorizationHeader.substring(7);
        }
        return null;
    }
}
