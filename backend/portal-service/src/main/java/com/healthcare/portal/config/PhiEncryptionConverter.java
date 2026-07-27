package com.healthcare.portal.config;

import com.healthcare.common.crypto.PhiEncryptionService;
import jakarta.persistence.AttributeConverter;
import jakarta.persistence.Converter;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

/**
 * JPA AttributeConverter that transparently encrypts/decrypts PHI String columns
 * to/from BYTEA in the database.  Uses AES-256-GCM via PhiEncryptionService.
 *
 * Usage: @Convert(converter = PhiEncryptionConverter.class)
 *
 * Uses setter injection into a static field (not constructor injection) — Hibernate
 * instantiates converters via raw reflection very early during EntityManagerFactory
 * bootstrap, before Spring's context can service constructor-injected beans, and a
 * converter with only a required-args constructor fails at that point.
 */
@Converter
@Component
public class PhiEncryptionConverter implements AttributeConverter<String, byte[]> {

    private static PhiEncryptionService phi;

    @Autowired
    public void setPhi(PhiEncryptionService svc) {
        PhiEncryptionConverter.phi = svc;
    }

    @Override
    public byte[] convertToDatabaseColumn(String attribute) {
        return phi.encrypt(attribute);
    }

    @Override
    public String convertToEntityAttribute(byte[] dbData) {
        return phi.decrypt(dbData);
    }
}