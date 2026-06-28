package com.healthcare.portal.config;

import com.healthcare.common.crypto.PhiEncryptionService;
import jakarta.persistence.AttributeConverter;
import jakarta.persistence.Converter;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

/**
 * JPA AttributeConverter that transparently encrypts/decrypts PHI String columns
 * to/from BYTEA in the database.  Uses AES-256-GCM via PhiEncryptionService.
 *
 * Usage: @Convert(converter = PhiEncryptionConverter.class)
 */
@Converter
@Component
@RequiredArgsConstructor
public class PhiEncryptionConverter implements AttributeConverter<String, byte[]> {

    private final PhiEncryptionService phi;

    @Override
    public byte[] convertToDatabaseColumn(String attribute) {
        return phi.encrypt(attribute);
    }

    @Override
    public String convertToEntityAttribute(byte[] dbData) {
        return phi.decrypt(dbData);
    }
}