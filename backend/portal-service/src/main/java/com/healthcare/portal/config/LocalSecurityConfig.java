package com.healthcare.portal.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Profile;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.web.SecurityFilterChain;

/**
 * Permit-all security for local development only.
 * Active ONLY when running with -Dspring.profiles.active=local
 * NEVER deploy this profile to production.
 */
@Configuration
@Profile("local")
@EnableMethodSecurity(prePostEnabled = false)
public class LocalSecurityConfig {

    @Bean
    public SecurityFilterChain localFilterChain(HttpSecurity http) throws Exception {
        return http
                .csrf(csrf -> csrf.disable())
                .authorizeHttpRequests(auth -> auth.anyRequest().permitAll())
                .build();
    }
}
