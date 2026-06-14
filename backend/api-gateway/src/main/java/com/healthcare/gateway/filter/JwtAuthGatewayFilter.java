package com.healthcare.gateway.filter;

import lombok.extern.slf4j.Slf4j;
import org.springframework.cloud.gateway.filter.GatewayFilterChain;
import org.springframework.cloud.gateway.filter.GlobalFilter;
import org.springframework.core.Ordered;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.context.ReactiveSecurityContextHolder;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken;
import org.springframework.stereotype.Component;
import org.springframework.web.server.ServerWebExchange;
import reactor.core.publisher.Mono;

/**
 * Extracts claims from the validated JWT and forwards them as trusted headers
 * to downstream microservices (X-User-Id, X-User-Role, X-Organization-Id).
 *
 * JWT signature validation happens in Spring Security before this filter runs.
 */
@Slf4j
@Component
public class JwtAuthGatewayFilter implements GlobalFilter, Ordered {

    @Override
    public Mono<Void> filter(ServerWebExchange exchange, GatewayFilterChain chain) {
        return ReactiveSecurityContextHolder.getContext()
                .map(ctx -> ctx.getAuthentication())
                .filter(auth -> auth instanceof JwtAuthenticationToken)
                .cast(JwtAuthenticationToken.class)
                .map(JwtAuthenticationToken::getToken)
                .flatMap(jwt -> {
                    ServerWebExchange enriched = addUserHeaders(exchange, jwt);
                    return chain.filter(enriched);
                })
                .switchIfEmpty(chain.filter(exchange));
    }

    private ServerWebExchange addUserHeaders(ServerWebExchange exchange, Jwt jwt) {
        return exchange.mutate()
                .request(r -> r.headers(headers -> {
                    String sub = jwt.getSubject();
                    if (sub != null) headers.set("X-User-Id", sub);

                    String role = jwt.getClaimAsString("role");
                    if (role != null) headers.set("X-User-Role", role);

                    String orgId = jwt.getClaimAsString("org_id");
                    if (orgId != null) headers.set("X-Organization-Id", orgId);

                    // Remove the original Authorization header from internal hops
                    // to avoid double-processing in resource servers
                    // (resource servers re-validate from the same header)
                }))
                .build();
    }

    @Override
    public int getOrder() {
        return -100;
    }
}
