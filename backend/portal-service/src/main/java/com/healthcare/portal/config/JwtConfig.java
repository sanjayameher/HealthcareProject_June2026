package com.healthcare.portal.config;

import lombok.Getter;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;

@Configuration
@Getter
public class JwtConfig {

    @Value("${healthcare.jwt.secret}")
    private String secret;

    @Value("${healthcare.jwt.expiry-hours:24}")
    private int expiryHours;

    @Value("${healthcare.jwt.password-reset-minutes:15}")
    private int passwordResetMinutes;
}