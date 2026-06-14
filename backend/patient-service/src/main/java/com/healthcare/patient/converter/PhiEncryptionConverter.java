package com.healthcare.patient.converter;

import com.healthcare.common.crypto.PhiEncryptionService;
import jakarta.persistence.AttributeConverter;
import jakarta.persistence.Converter;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

/**
 * JPA AttributeConverter that transparently encrypts PHI String fields to BYTEA
 * using AES-256-GCM via PhiEncryptionService.
 *
 * Applied to @Column(columnDefinition = "BYTEA") fields annotated with @Convert.
 */
@Converter
@Component
public class PhiEncryptionConverter implements AttributeConverter<String, byte[]> {

    private static PhiEncryptionService encryptionService;

    @Autowired
    public void setEncryptionService(PhiEncryptionService svc) {
        PhiEncryptionConverter.encryptionService = svc;
    }

    @Override
    public byte[] convertToDatabaseColumn(String attribute) {
        if (attribute == null || attribute.isBlank()) return null;
        return encryptionService.encrypt(attribute);
    }

    @Override
    public String convertToEntityAttribute(byte[] dbData) {
        if (dbData == null) return null;
        return encryptionService.decrypt(dbData);
    }
}
